#!/usr/bin/with-contenv bashio

# Enable strict error handling
set -e
set -o pipefail

# Initialize environment for Claude Code CLI using /data (HA best practice)
init_environment() {
    # Use /data exclusively - guaranteed writable by HA Supervisor
    local data_home="/data/home"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local claude_config_dir="/data/.config/claude"

    bashio::log.info "Initializing Claude Code environment in /data..."

    # Create all required directories
    if ! mkdir -p "$data_home" "$config_dir/claude" "$cache_dir" "$state_dir" "/data/.local"; then
        bashio::log.error "Failed to create directories in /data"
        exit 1
    fi

    # Set permissions
    chmod 755 "$data_home" "$config_dir" "$cache_dir" "$state_dir" "$claude_config_dir"

    # Set XDG and application environment variables
    export HOME="$data_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="/data/.local/share"

    # Claude-specific environment variables
    export ANTHROPIC_CONFIG_DIR="$claude_config_dir"
    export ANTHROPIC_HOME="/data"

    # Alpine/musl: use system ripgrep instead of the bundled glibc-only one
    export USE_BUILTIN_RIPGREP=0

    # Migrate any existing authentication files from legacy locations
    migrate_legacy_auth_files "$claude_config_dir"

    bashio::log.info "Environment initialized:"
    bashio::log.info "  - Home: $HOME"
    bashio::log.info "  - Config: $XDG_CONFIG_HOME"
    bashio::log.info "  - Claude config: $ANTHROPIC_CONFIG_DIR"
    bashio::log.info "  - Cache: $XDG_CACHE_HOME"
}

# One-time migration of existing authentication files
migrate_legacy_auth_files() {
    local target_dir="$1"
    local migrated=false

    bashio::log.info "Checking for existing authentication files to migrate..."

    # Check common legacy locations
    local legacy_locations=(
        "/root/.config/anthropic"
        "/root/.anthropic" 
        "/config/claude-config"
        "/tmp/claude-config"
    )

    for legacy_path in "${legacy_locations[@]}"; do
        if [ -d "$legacy_path" ] && [ "$(ls -A "$legacy_path" 2>/dev/null)" ]; then
            bashio::log.info "Migrating auth files from: $legacy_path"
            
            # Copy files to new location
            if cp -r "$legacy_path"/* "$target_dir/" 2>/dev/null; then
                # Set proper permissions
                find "$target_dir" -type f -exec chmod 600 {} \;
                
                # Create compatibility symlink if this is a standard location
                if [[ "$legacy_path" == "/root/.config/anthropic" ]] || [[ "$legacy_path" == "/root/.anthropic" ]]; then
                    rm -rf "$legacy_path"
                    ln -sf "$target_dir" "$legacy_path"
                    bashio::log.info "Created compatibility symlink: $legacy_path -> $target_dir"
                fi
                
                migrated=true
                bashio::log.info "Migration completed from: $legacy_path"
            else
                bashio::log.warning "Failed to migrate from: $legacy_path"
            fi
        fi
    done

    if [ "$migrated" = false ]; then
        bashio::log.info "No existing authentication files found to migrate"
    fi
}

# Install required tools
install_tools() {
    bashio::log.info "Installing additional tools..."
    if ! apk add --no-cache ttyd jq curl; then
        bashio::log.error "Failed to install required tools"
        exit 1
    fi
    bashio::log.info "Tools installed successfully"
}

# Setup session picker script
setup_session_picker() {
    # Copy session picker script from built-in location
    if [ -f "/opt/scripts/claude-session-picker.sh" ]; then
        if ! cp /opt/scripts/claude-session-picker.sh /usr/local/bin/claude-session-picker; then
            bashio::log.error "Failed to copy claude-session-picker script"
            exit 1
        fi
        chmod +x /usr/local/bin/claude-session-picker
        bashio::log.info "Session picker script installed successfully"
    else
        bashio::log.warning "Session picker script not found, using auto-launch mode only"
    fi

    # Setup authentication helper if it exists
    if [ -f "/opt/scripts/claude-auth-helper.sh" ]; then
        chmod +x /opt/scripts/claude-auth-helper.sh
        bashio::log.info "Authentication helper script ready"
    fi
}

# Setup MCP integration
setup_mcp_integration() {
    if [ -f "/opt/scripts/setup-mcp.sh" ]; then
        chmod +x /opt/scripts/setup-mcp.sh
        bashio::log.info "Setting up MCP integration..."

        # Source the script and run setup
        source /opt/scripts/setup-mcp.sh
        setup_mcp_integration || bashio::log.warning "MCP setup encountered issues but continuing..."
    else
        bashio::log.warning "MCP setup script not found"
    fi
}

# Legacy monitoring functions removed - using simplified /data approach

# Log file used by the Remote Control background service
REMOTE_CONTROL_LOG="/data/.local/remote-control.log"

# Start Claude Remote Control as a persistent background service.
#
# This runs INDEPENDENTLY of the Web UI (ttyd), so the connection to
# claude.ai/code and the mobile app stays alive even when the browser tab
# is closed. The service is supervised: if it exits (e.g. before you have
# logged in, or after a network drop), it restarts automatically. That means
# once you run /login in the Web UI, it reconnects on its own within seconds.
start_remote_control_daemon() {
    local remote_control_mode
    remote_control_mode=$(bashio::config 'remote_control_mode' 'false')

    if [ "$remote_control_mode" != "true" ]; then
        bashio::log.info "Remote Control: disabled"
        return 0
    fi

    local session_name
    session_name=$(bashio::config 'session_name' '')

    mkdir -p /data/.local
    : > "$REMOTE_CONTROL_LOG"

    # Build the remote-control command, quoting the session name safely
    local rc_cmd="claude remote-control"
    if [ -n "$session_name" ]; then
        rc_cmd="claude remote-control --name \"${session_name}\""
    fi

    bashio::log.info "Starting Claude Remote Control as a persistent background service"
    bashio::log.info "  - Keeps running even when the Web UI / browser is closed"
    bashio::log.info "  - Connect from the Claude mobile app or claude.ai/code"
    bashio::log.info "  - Session URL / QR are written to: ${REMOTE_CONTROL_LOG}"
    bashio::log.info "  - If you see auth errors, open the Web UI once and run: /login"

    # Supervised background loop. A pseudo-terminal is allocated via 'script'
    # because remote-control is a full-screen server that expects a TTY.
    (
        while true; do
            echo "===== $(date) Starting Remote Control =====" >> "$REMOTE_CONTROL_LOG"
            script -qfc "${rc_cmd}" /dev/null >> "$REMOTE_CONTROL_LOG" 2>&1
            echo "===== $(date) Remote Control exited; retrying in 15s =====" >> "$REMOTE_CONTROL_LOG"
            sleep 15
        done
    ) >/dev/null 2>&1 &

    bashio::log.info "Remote Control service started (supervisor PID $!)"
}

# Determine the Claude launch command for the Web UI terminal (ttyd).
# The Web UI always runs an interactive Claude session. In Remote Control mode
# it just shows a note that the background service is running; the actual
# Remote Control connection is handled by start_remote_control_daemon.
get_claude_launch_command() {
    local remote_control_mode
    remote_control_mode=$(bashio::config 'remote_control_mode' 'false')

    if [ "$remote_control_mode" = "true" ]; then
        bashio::log.info "Web UI: interactive Claude (Remote Control runs in background)"
        echo "clear && echo '═══════════════════════════════════════════════════' && echo '🚀 Remote Control is running in the BACKGROUND' && echo '═══════════════════════════════════════════════════' && echo '' && echo 'It stays connected even if you close this page.' && echo '' && echo '📱 Connect from: Claude mobile app or claude.ai/code' && echo '📄 Status / session URL: /data/.local/remote-control.log' && echo '' && echo 'ℹ️  Not connected yet? Run  /login  below, then it' && echo '    reconnects automatically within a few seconds.' && echo '═══════════════════════════════════════════════════' && echo '' && sleep 2 && claude"
    else
        bashio::log.info "Web UI: interactive Claude terminal"
        echo "clear && echo '═══════════════════════════════════════════════════' && echo '🤖 Claude Code Terminal' && echo '═══════════════════════════════════════════════════' && echo '' && echo 'Welcome to Claude Code!' && echo '' && echo 'Starting Claude...' && echo '' && sleep 1 && claude"
    fi
}

# Start main web terminal (ttyd). This blocks and keeps the container alive.
start_web_terminal() {
    local port=7681
    bashio::log.info "Starting Claude Code Web UI terminal on port ${port}..."

    # Log environment information for debugging
    bashio::log.info "Environment: ANTHROPIC_CONFIG_DIR=${ANTHROPIC_CONFIG_DIR}, HOME=${HOME}"

    # Get the appropriate launch command based on configuration
    local launch_command
    launch_command=$(get_claude_launch_command)

    # Run ttyd with improved configuration
    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        bash -c "$launch_command"
}

# Run health check
run_health_check() {
    if [ -f "/opt/scripts/health-check.sh" ]; then
        bashio::log.info "Running system health check..."
        chmod +x /opt/scripts/health-check.sh
        /opt/scripts/health-check.sh || bashio::log.warning "Some health checks failed but continuing..."
    fi
}

# Main execution
main() {
    bashio::log.info "Initializing Claude Code add-on..."

    # Run diagnostics first (especially helpful for VirtualBox issues)
    run_health_check

    init_environment
    install_tools
    setup_session_picker

    # Setup MCP integration
    setup_mcp_integration

    # Start Remote Control as a persistent background service (if enabled).
    # Runs independently of the Web UI so it survives closing the browser.
    start_remote_control_daemon

    # Start web terminal with Claude Code (this blocks, so must be last)
    start_web_terminal
}

# Execute main function
main "$@"