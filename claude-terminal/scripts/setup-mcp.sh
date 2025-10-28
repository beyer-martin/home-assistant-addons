#!/usr/bin/with-contenv bashio

# MCP Auto-Configuration Script for Claude Terminal
# Automatically configures Claude Code to connect to Home Assistant MCP Server

# Enable strict error handling
set -e
set -o pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
MCP_CONFIG_FILE="/config/.mcp.json"
DEFAULT_MCP_URL="http://supervisor/core/mcp_server/sse"

# Main setup function
setup_mcp_integration() {
    bashio::log.info "Starting MCP integration setup..."

    # Check if MCP integration is enabled
    local enable_mcp
    enable_mcp=$(bashio::config 'enable_mcp_integration' 'false')

    if [ "$enable_mcp" != "true" ]; then
        bashio::log.info "MCP integration is disabled. Enable in add-on configuration to use."
        return 0
    fi

    # Get MCP server URL (use custom or default)
    local mcp_url
    mcp_url=$(bashio::config 'mcp_server_url' "$DEFAULT_MCP_URL")

    bashio::log.info "Configuring MCP server connection to: ${mcp_url}"

    # Verify SUPERVISOR_TOKEN is available
    if [ -z "$SUPERVISOR_TOKEN" ]; then
        bashio::log.error "SUPERVISOR_TOKEN not found - cannot configure MCP"
        return 1
    fi

    # Test if MCP server is accessible
    if ! test_mcp_server "$mcp_url"; then
        bashio::log.warning "MCP server not accessible at ${mcp_url}"
        bashio::log.warning "Make sure the 'Model Context Protocol Server' integration is installed and configured in Home Assistant"
        return 0
    fi

    # Create MCP configuration
    create_mcp_config "$mcp_url"

    bashio::log.info "MCP integration setup completed successfully!"
}

# Test if MCP server is accessible
test_mcp_server() {
    local url=$1

    bashio::log.info "Testing MCP server connectivity..."

    # Try to connect to the MCP server endpoint
    local response
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Accept: text/event-stream" \
        --max-time 5 \
        "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ] || [ "$response" = "401" ]; then
        # 200 = successful connection
        # 401 = server is there but auth might need adjustment (still means server exists)
        bashio::log.info "✓ MCP server is accessible"
        return 0
    else
        bashio::log.warning "MCP server returned HTTP $response"
        return 1
    fi
}

# Create MCP configuration file
create_mcp_config() {
    local url=$1

    bashio::log.info "Creating MCP configuration at ${MCP_CONFIG_FILE}..."

    # Create the .mcp.json configuration
    # Using project-scope configuration so it applies to all Claude sessions
    cat > "$MCP_CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "home-assistant": {
      "transport": {
        "type": "sse",
        "url": "${url}",
        "headers": {
          "Authorization": "Bearer ${SUPERVISOR_TOKEN}"
        }
      },
      "metadata": {
        "description": "Home Assistant MCP Server - Control and query your Home Assistant instance",
        "configuredBy": "claude-terminal-addon",
        "autoConfigured": true
      }
    }
  }
}
EOF

    # Set appropriate permissions
    chmod 644 "$MCP_CONFIG_FILE"

    bashio::log.info "✓ MCP configuration created successfully"
    bashio::log.info "  - Server: home-assistant"
    bashio::log.info "  - Transport: SSE (Server-Sent Events)"
    bashio::log.info "  - URL: ${url}"
    bashio::log.info ""
    bashio::log.info "You can now use Home Assistant tools in Claude Code!"
    bashio::log.info "Use '/mcp' command in Claude to view available MCP tools."
}

# Show MCP status
show_mcp_status() {
    if [ -f "$MCP_CONFIG_FILE" ]; then
        bashio::log.info "MCP Configuration found at ${MCP_CONFIG_FILE}"

        # Pretty print the config
        if command -v jq &> /dev/null; then
            bashio::log.info "Configuration:"
            cat "$MCP_CONFIG_FILE" | jq -C '.'
        fi
    else
        bashio::log.info "No MCP configuration found"
    fi
}

# Main execution
main() {
    case "${1:-setup}" in
        setup)
            setup_mcp_integration
            ;;
        status)
            show_mcp_status
            ;;
        test)
            local url="${2:-$DEFAULT_MCP_URL}"
            test_mcp_server "$url"
            ;;
        *)
            echo "Usage: $0 {setup|status|test [url]}"
            exit 1
            ;;
    esac
}

# Run main function if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
