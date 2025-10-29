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

# Function to discover Home Assistant MCP Server URL
get_home_assistant_url() {
    # Try multiple possible endpoints
    # Home Assistant add-ons can access the core instance via homeassistant.local
    local urls=(
        "http://homeassistant.local:8123/mcp_server/sse"
        "http://supervisor/core/api/mcp_server/sse"
        "http://supervisor/core/mcp_server/sse"
        "http://supervisor/mcp_server/sse"
    )

    bashio::log.info "Discovering MCP Server endpoint..."

    for url in "${urls[@]}"; do
        if test_url_accessible "$url"; then
            bashio::log.info "Found working endpoint: $url"
            echo "$url"
            return 0
        fi
    done

    # Default to most commonly working endpoint
    bashio::log.warning "Could not verify endpoint, using default: http://homeassistant.local:8123/mcp_server/sse"
    echo "http://homeassistant.local:8123/mcp_server/sse"
}

# Test if a URL is accessible (without token for discovery)
test_url_accessible() {
    local url=$1
    local response

    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Accept: text/event-stream" \
        --max-time 3 \
        "$url" 2>/dev/null || echo "000")

    # 200 = OK, 401 = Unauthorized (but server exists), 403 = Forbidden (but server exists)
    if [ "$response" = "200" ] || [ "$response" = "401" ] || [ "$response" = "403" ]; then
        return 0
    fi
    return 1
}

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

    # Get MCP server URL (use custom or discover)
    local mcp_url
    local custom_url
    custom_url=$(bashio::config 'mcp_server_url' '')

    if [ -n "$custom_url" ]; then
        mcp_url="$custom_url"
        bashio::log.info "Using custom MCP server URL: ${mcp_url}"
    else
        bashio::log.info "Auto-discovering Home Assistant MCP server URL..."
        mcp_url=$(get_home_assistant_url)
        bashio::log.info "Discovered MCP server URL: ${mcp_url}"
    fi

    bashio::log.info "Configuring MCP server connection to: ${mcp_url}"

    # Get MCP access token from configuration
    local access_token
    access_token=$(bashio::config 'mcp_access_token' '')

    if [ -z "$access_token" ]; then
        bashio::log.error "MCP Access Token is required but not configured"
        bashio::log.error "Please create a long-lived access token in Home Assistant:"
        bashio::log.error "  1. Go to your Profile → Security"
        bashio::log.error "  2. Scroll to 'Long-Lived Access Tokens'"
        bashio::log.error "  3. Click 'Create Token' and give it a name (e.g., 'Claude Terminal MCP')"
        bashio::log.error "  4. Copy the token and paste it in the add-on configuration"
        bashio::log.error "  5. Restart the add-on"
        return 1
    fi

    # Test if MCP server is accessible
    if ! test_mcp_server "$mcp_url" "$access_token"; then
        bashio::log.warning "MCP server not accessible at ${mcp_url}"
        bashio::log.warning "Make sure the 'Model Context Protocol Server' integration is installed and configured in Home Assistant"
        return 0
    fi

    # Create MCP configuration
    create_mcp_config "$mcp_url" "$access_token"

    bashio::log.info "MCP integration setup completed successfully!"
}

# Test if MCP server is accessible (with token for validation)
test_mcp_server() {
    local url=$1
    local token=$2

    bashio::log.info "Testing MCP server connectivity..."

    # Try to connect to the MCP server endpoint with auth
    local response
    response=$(curl -s -w "%{http_code}" -o /dev/null \
        -H "Authorization: Bearer ${token}" \
        -H "Accept: text/event-stream" \
        --max-time 5 \
        "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        bashio::log.info "✓ MCP server is accessible and authenticated (HTTP $response)"
        return 0
    elif [ "$response" = "401" ]; then
        bashio::log.error "✗ MCP server authentication failed (HTTP 401)"
        bashio::log.error "The access token is invalid or expired"
        bashio::log.error "Please create a new long-lived access token and update the add-on configuration"
        return 1
    elif [ "$response" = "404" ]; then
        bashio::log.warning "MCP server returned HTTP $response"
        bashio::log.warning "The MCP Server integration may not be installed or the endpoint URL is incorrect"
        bashio::log.warning "Please ensure:"
        bashio::log.warning "  1. Home Assistant 2025.2 or later is installed"
        bashio::log.warning "  2. The 'Model Context Protocol Server' integration is added"
        bashio::log.warning "  3. The integration is properly configured"
        return 1
    else
        bashio::log.warning "MCP server returned unexpected HTTP $response"
        return 1
    fi
}

# Create MCP configuration file
create_mcp_config() {
    local url=$1
    local token=$2

    bashio::log.info "Creating MCP configuration at ${MCP_CONFIG_FILE}..."

    # Create the .mcp.json configuration
    # Claude Code requires stdio transport, so we use npx @homebase-id/mcp-proxy for SSE
    # This bridges between Claude's stdio and Home Assistant's SSE endpoint
    cat > "$MCP_CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "home-assistant": {
      "command": "npx",
      "args": [
        "-y",
        "@homebase-id/mcp-proxy"
      ],
      "env": {
        "SSE_URL": "${url}",
        "API_ACCESS_TOKEN": "${token}"
      }
    }
  }
}
EOF

    # Set appropriate permissions
    chmod 644 "$MCP_CONFIG_FILE"

    bashio::log.info "✓ MCP configuration created successfully"
    bashio::log.info "  - Server: home-assistant"
    bashio::log.info "  - Transport: stdio via mcp-proxy (SSE bridge)"
    bashio::log.info "  - SSE URL: ${url}"
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
