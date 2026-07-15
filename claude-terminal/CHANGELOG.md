# Changelog

## 2.1.0

### 🚀 Features
- **Remote Control now runs as a persistent background service**:
  - Previously Remote Control ran inside the Web UI (ttyd), so the connection
    died as soon as you closed the browser tab
  - It now runs as a supervised background daemon that starts with the add-on
    and stays connected even when the Web UI is closed
  - Automatically restarts if it exits, so after a first-time `/login` it
    reconnects on its own within a few seconds — no add-on restart needed
  - Session URL / QR and status are written to `/data/.local/remote-control.log`
  - The Web UI now always opens an interactive Claude session (for `/login`,
    status, and normal terminal use) regardless of Remote Control mode

### 🛠️ Improvements
- Added `util-linux` (`script`) to allocate a pseudo-terminal for the
  background Remote Control server
- Clearer startup logs and Web UI messaging explaining background operation

## 2.0.1

### 🐛 Bug Fixes
- **Fixed ".exe" / "Cannot find module" startup crash on Alpine (musl)**:
  - Root cause: Claude Code's native binary needs `libgcc` and `libstdc++`,
    and the bundled ripgrep is glibc-only — missing on the Alpine base image
  - Added `libgcc`, `libstdc++`, and system `ripgrep` to the image
  - Set `USE_BUILTIN_RIPGREP=0` so Claude uses the system ripgrep
  - Reverted the previous `.exe` deletion hack (it removed the real launcher
    and left `which claude` empty, causing `Cannot find module '/config/remote-control'`)
- **Fixed Claude invocation**: Call `claude` directly instead of
  `node $(which claude)`
  - Wrapping the launcher with `node` caused it to load a `.exe` as a module
  - Applies to Remote Control mode, interactive mode, session picker, and auth helper

### 🛠️ Improvements
- Added `claude --version` check at build time to catch install issues early

## 2.0.0

### 🚀 Major Changes
- **Remote Control Mode**: Claude Code now runs in server mode for mobile/browser access
  - Connect from Claude mobile app or claude.ai/code
  - Scan QR code or use session URL
  - All execution stays on your Home Assistant machine
  - Requires Pro/Max/Team/Enterprise subscription and OAuth authentication
  - Enable in add-on configuration: "Remote Control Mode"

### 🗑️ Breaking Changes
- **Removed Happy Coder**: Eliminated Happy daemon and all related functionality
  - Happy was causing installation issues and conflicts
  - Remote Control provides better mobile access experience
  - Configuration options removed: `auto_start_happy_daemon`
  - All Happy-related code and dependencies removed

### 🐛 Bug Fixes
- **Fixed .exe error on Alpine Linux**: Resolved "ERR_UNKNOWN_FILE_EXTENSION: Unknown file extension .exe"
  - npm was installing Windows binary (.exe) on Linux system
  - Now explicitly removes .exe file after installation
  - Forces use of correct Node.js script
  - Ensures `node $(which claude)` works correctly

### 🛠️ Improvements
- **Updated Claude Code**: Latest version with all recent features
- **Simplified configuration**: Removed confusing auto-launch options
- **Better startup messages**: Clear indication of Remote Control vs Interactive mode
- **Environment optimizations**: Removed unused Happy directories

### 📝 Configuration Changes
- **New options**:
  - `remote_control_mode`: Enable Remote Control server (default: false)
  - `session_name`: Custom name for Remote Control session (optional)
- **Removed options**:
  - `auto_launch_claude`: No longer needed
  - `auto_start_happy_daemon`: Happy removed

## 1.5.4

### 🐛 Bug Fixes
- **Fixed mcp-proxy npm package name**: Resolved "404 Not Found" error when installing mcp-proxy
  - Changed from incorrect '@homebase-id/mcp-proxy' to correct 'mcp-proxy'
  - Package is available at npmjs.com/package/mcp-proxy
  - Properly handles SSE streaming timeout (exit code 28 is normal)
  - Uses temp file to isolate HTTP status code from streaming data

### 🛠️ Improvements
- **Added debug script**: New /opt/scripts/debug-mcp.sh for troubleshooting MCP connectivity
- **Better error handling**: Distinguishes between curl timeout (normal) and connection errors
- **Debug logging**: Shows both curl exit code and HTTP status code for diagnostics

## 1.5.3

### 🐛 Bug Fixes
- **Fixed MCP authentication**: Resolved "Failed to reconnect to home-assistant" error
  - SUPERVISOR_TOKEN cannot authenticate with MCP Server endpoint
  - Now requires user-created long-lived access token from Home Assistant
  - Added `mcp_access_token` configuration field (password type)
  - Enhanced validation with clear error messages for missing/invalid tokens
  - Updated test to verify HTTP 200 (successful auth) instead of accepting 401

### 📝 Documentation
- **Added token creation guide**: Step-by-step instructions in DOCS.md
  - How to create long-lived access token in Home Assistant
  - Where to paste the token in add-on configuration
  - Troubleshooting for common auth errors (401, 404)

### ⚠️ Breaking Change
- **Configuration required**: MCP integration now requires manual token input
  - Users must create a long-lived access token in Home Assistant
  - Token must be pasted in "MCP Access Token" configuration field
  - Add-on will not connect to MCP without valid token

## 1.5.2

### 🐛 Bug Fixes
- **Fixed MCP configuration schema error**: Resolved "Does not adhere to MCP server configuration schema" error
  - Claude Code requires stdio transport, but Home Assistant MCP uses SSE
  - Implemented `@homebase-id/mcp-proxy` to bridge stdio to SSE transport
  - Changed from direct SSE config to stdio command-based config
  - Passes SSE_URL and API_ACCESS_TOKEN via environment variables to proxy

### 🛠️ Improvements
- **Verified endpoint discovery**: Confirmed `homeassistant.local:8123/mcp_server/sse` works in add-on environment
- **Smart fallback**: Tries homeassistant.local first, then Supervisor API paths

## 1.5.1

### 🐛 Bug Fixes
- **Fixed MCP Server endpoint discovery**: Resolved HTTP 404 errors when connecting to Home Assistant MCP Server
  - Implemented automatic endpoint discovery with multiple fallback URLs
  - Corrected endpoint path from `/core/mcp_server/sse` to `/mcp_server/sse`
  - Added intelligent URL testing (homeassistant.local, Supervisor API)
  - Enhanced error messages with specific troubleshooting steps for 404 errors
  - Updated configuration description to reflect auto-discovery default

### 🛠️ Improvements
- **Better MCP troubleshooting**: Added comprehensive error messages and setup validation
- **Flexible configuration**: Auto-discovery works out-of-the-box, manual override still available

## 1.5.0

### ✨ New Features
- **Home Assistant MCP Integration**: Automatic connection to Home Assistant's Model Context Protocol Server
  - Added configuration option to enable MCP integration
  - Auto-configures Claude Code to connect to HA MCP Server via SSE transport
  - Allows Claude to directly query and control Home Assistant entities
  - Uses Supervisor API token for secure authentication
  - Creates project-level `.mcp.json` configuration in `/config` directory
  - Optional custom MCP server URL override
  - Includes setup script with connectivity testing and status commands

### 🛠️ Improvements
- **Enhanced documentation**: Added comprehensive MCP setup and usage guide
- **Better MCP diagnostics**: New setup script supports status checking and connection testing
- **Seamless integration**: MCP auto-configuration runs on startup if enabled
- **Smart home control**: Direct interaction with Home Assistant entities through Claude

## 1.4.0

### ✨ New Features
- **Happy Mobile Client Integration**: Added support for Happy mobile client with persistent authentication
  - Installed `happy-coder` CLI alongside Claude Code
  - Persistent config storage in `/data/.config/happy` (survives restarts)
  - Added Happy launch option to session picker (option 6)
  - Added Happy daemon mode for background service (option 7)
  - QR code pairing for mobile device connection
  - Full E2E encryption for secure mobile coding

### 🛠️ Improvements
- **Enhanced session picker**: Expanded options to include Happy mobile client
  - Option 6: Launch Happy with QR code for mobile connection
  - Option 7: Start Happy daemon for persistent background service
- **Updated documentation**: Added Happy mobile client usage instructions
- **Better mobile workflow**: Code on-the-go with full Claude capabilities

## 1.3.2

### 🐛 Bug Fixes
- **Improved installation reliability** (#16): Enhanced resilience for network issues during installation
  - Added retry logic (3 attempts) for npm package installation
  - Configured npm with longer timeouts for slow/unstable connections
  - Explicitly set npm registry to avoid DNS resolution issues
  - Added 10-second delay between retry attempts

### 🛠️ Improvements
- **Enhanced network diagnostics**: Better troubleshooting for connection issues
  - Added DNS resolution checks to identify network configuration problems
  - Check connectivity to GitHub Container Registry (ghcr.io)
  - Extended connection timeouts for virtualized environments
  - More detailed error messages with specific solutions
- **Better virtualization support**: Improved guidance for VirtualBox and Proxmox users
  - Enhanced VirtualBox detection with detailed configuration requirements
  - Added Proxmox/QEMU environment detection
  - Specific network adapter recommendations for VM installations
  - Clear guidance on minimum resource requirements (2GB RAM, 8GB disk)

## 1.3.1

### 🐛 Critical Fix
- **Restored config directory access**: Fixed regression where add-on couldn't access Home Assistant configuration files
  - Re-added `config:rw` volume mapping that was accidentally removed in 1.2.0
  - Users can now properly access and edit their configuration files again

## 1.3.0

### ✨ New Features
- **Full Home Assistant API Access**: Enabled complete API access for automations and entity control
  - Added `hassio_api`, `homeassistant_api`, and `auth_api` permissions
  - Set `hassio_role` to 'manager' for full Supervisor access
  - Created comprehensive API examples script (`ha-api-examples.sh`)
  - Includes Supervisor API, Core API, and WebSocket examples
  - Python and bash code examples for entity control

### 🐛 Bug Fixes
- **Fixed authentication paste issues** (#14): Added authentication helper for clipboard problems
  - New authentication helper script with multiple input methods
  - Manual code entry option when clipboard paste fails
  - File-based authentication via `/config/auth-code.txt`
  - Integrated into session picker as menu option

### 🛠️ Improvements
- **Enhanced diagnostics** (#16): Added comprehensive health check system
  - System resource monitoring (memory, disk space)
  - Permission and dependency validation
  - VirtualBox-specific troubleshooting guidance
  - Automatic health check on startup
  - Improved error handling with strict mode

## 1.2.1

### 🔧 Internal Changes
- Fixed YAML formatting issues for better compatibility
- Added document start marker and fixed line lengths

## 1.2.0

### 🔒 Authentication Persistence Fix (PR #15)
- **Fixed OAuth token persistence**: Tokens now survive container restarts
  - Switched from `/config` to `/data` directory (Home Assistant best practice)
  - Implemented XDG Base Directory specification compliance
  - Added automatic migration for existing authentication files
  - Removed complex symlink/monitoring systems for simplicity
  - Maintains full backward compatibility

## 1.1.4

### 🧹 Maintenance
- **Cleaned up repository**: Removed erroneously committed test files (thanks @lox!)
- **Improved codebase hygiene**: Cleared unnecessary temporary and test configuration files

## 1.1.3

### 🐛 Bug Fixes
- **Fixed session picker input capture**: Resolved issue with ttyd intercepting stdin, preventing proper user input
- **Improved terminal interaction**: Session picker now correctly captures user choices in web terminal environment

## 1.1.2

### 🐛 Bug Fixes
- **Fixed session picker input handling**: Improved compatibility with ttyd web terminal environment
- **Enhanced input processing**: Better handling of user input with whitespace trimming
- **Improved error messages**: Added debugging output showing actual invalid input values
- **Better terminal compatibility**: Replaced `echo -n` with `printf` for web terminals

## 1.1.1

### 🐛 Bug Fixes  
- **Fixed session picker not found**: Moved scripts from `/config/scripts/` to `/opt/scripts/` to avoid volume mapping conflicts
- **Fixed authentication persistence**: Improved credential directory setup with proper symlink recreation
- **Enhanced credential management**: Added proper file permissions (600) and logging for debugging
- **Resolved volume mapping issues**: Scripts now persist correctly without being overwritten

## 1.1.0

### ✨ New Features
- **Interactive Session Picker**: New menu-driven interface for choosing Claude session types
  - 🆕 New interactive session (default)
  - ⏩ Continue most recent conversation (-c)
  - 📋 Resume from conversation list (-r) 
  - ⚙️ Custom Claude command with manual flags
  - 🐚 Drop to bash shell
  - ❌ Exit option
- **Configurable auto-launch**: New `auto_launch_claude` setting (default: true for backward compatibility)
- **Added nano text editor**: Enables `/memory` functionality and general text editing

### 🛠️ Architecture Changes
- **Simplified credential management**: Removed complex modular credential system
- **Streamlined startup process**: Eliminated problematic background services
- **Cleaner configuration**: Reduced complexity while maintaining functionality
- **Improved reliability**: Removed sources of startup failures from missing script dependencies

### 🔧 Improvements
- **Better startup logging**: More informative messages about configuration and setup
- **Enhanced backward compatibility**: Existing users see no change in behavior by default
- **Improved error handling**: Better fallback behavior when optional components are missing

## 1.0.2

### 🔒 Security Fixes
- **CRITICAL**: Fixed dangerous filesystem operations that could delete system files
- Limited credential searches to safe directories only (`/root`, `/home`, `/tmp`, `/config`)
- Replaced unsafe `find /` commands with targeted directory searches
- Added proper exclusions and safety checks in cleanup scripts

### 🐛 Bug Fixes
- **Fixed architecture mismatch**: Added missing `armv7` support to match build configuration
- **Fixed NPM package installation**: Pinned Claude Code package version for reliable builds
- **Fixed permission conflicts**: Standardized credential file permissions (600) across all scripts
- **Fixed race conditions**: Added proper startup delays for credential management service
- **Fixed script fallbacks**: Implemented embedded scripts when modules aren't found

### 🛠️ Improvements
- Added comprehensive error handling for all critical operations
- Improved build reliability with better package management
- Enhanced credential management with consistent permission handling
- Added proper validation for script copying and execution
- Improved startup logging for better debugging

### 🧪 Development
- Updated development environment to use Podman instead of Docker
- Added proper build arguments for local testing
- Created comprehensive testing framework with Nix development shell
- Added container policy configuration for rootless operation

## 1.0.0

- First stable release of Claude Terminal add-on:
  - Web-based terminal interface using ttyd
  - Pre-installed Claude Code CLI
  - User-friendly interface with clean welcome message
  - Simple claude-logout command for authentication
  - Direct access to Home Assistant configuration
  - OAuth authentication with Anthropic account
  - Auto-launches Claude in interactive mode