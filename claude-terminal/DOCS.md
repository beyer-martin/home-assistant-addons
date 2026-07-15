# Claude Code

Claude Code with Remote Control and Home Assistant MCP integration.

## About

This add-on provides Claude Code CLI with support for Remote Control (mobile/browser access) and automatic integration with Home Assistant via the Model Context Protocol (MCP). Access Claude's powerful AI capabilities directly from your Home Assistant dashboard, or remotely from your mobile device.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the Claude Terminal add-on
3. Start the add-on
4. Click "OPEN WEB UI" to access the terminal
5. On first use, follow the OAuth prompts to log in to your Anthropic account

## Configuration

### Basic Configuration

**Authentication:**
- First use: You'll be prompted to log in to your Anthropic account via OAuth
- Credentials are stored in `/config/claude-config` and persist across restarts
- No additional configuration needed for basic terminal access

**Remote Control Mode (Optional):**
- **Remote Control Mode**: Enable Claude Code server for mobile/browser access
  - When enabled, displays session URL and QR code
  - Connect from Claude mobile app or claude.ai/code
  - Requires Pro/Max/Team/Enterprise subscription
  - Requires OAuth authentication (use `/login` in terminal if needed)
- **Session Name**: Optional custom name for your Remote Control session
  - Makes it easier to identify in the session list
  - Example: "Home Assistant Server"

### MCP Integration (Optional)

The add-on can automatically connect Claude Code to your Home Assistant instance via the Model Context Protocol (MCP). This allows Claude to directly interact with your Home Assistant entities, automations, and services.

**Prerequisites:**
1. **Home Assistant 2025.2 or later** is required
2. Install the **Model Context Protocol Server** integration in Home Assistant:
   - Go to Settings → Devices & Services → Add Integration
   - Search for "Model Context Protocol Server"
   - Configure which entities/services to expose to Claude
3. **Create a Long-Lived Access Token**:
   - Go to your Profile (click your name in the bottom left)
   - Scroll to "Security" section
   - Under "Long-Lived Access Tokens", click "Create Token"
   - Give it a name (e.g., "Claude Terminal MCP")
   - **Copy the token immediately** (it's only shown once!)
   - Keep it safe - you'll need it for the add-on configuration

**Configuration Options:**

- **Enable MCP Integration**: Turn on automatic MCP configuration (default: disabled)
- **MCP Access Token**: **Required** - Paste your long-lived access token here (created above)
- **MCP Server URL**: Override the auto-discovered server URL if needed
  - Default: auto-discovery (tries homeassistant.local:8123)
  - Manual example: `http://homeassistant.local:8123/mcp_server/sse`

**To Enable:**
1. Ensure Home Assistant 2025.2+ is installed
2. Enable the "Model Context Protocol Server" integration in Home Assistant
3. Create a long-lived access token (see Prerequisites above)
4. In the Claude Terminal add-on configuration:
   - Enable "Enable MCP Integration"
   - Paste your access token in "MCP Access Token"
5. Restart the add-on
6. Check the add-on logs to verify MCP connection
7. Open the terminal and check MCP status with: `/mcp`

**Troubleshooting:**

If you see "Failed to reconnect to home-assistant":
- **HTTP 401 Unauthorized**: Your access token is invalid or expired
  - Create a new long-lived access token
  - Update the add-on configuration with the new token
  - Restart the add-on
- **HTTP 404 Not Found**:
  - Verify Home Assistant version is 2025.2 or later
  - Confirm the MCP Server integration is installed and running
  - Check Settings → Devices & Services → Model Context Protocol Server
- **Token not configured**:
  - Make sure you've pasted the access token in "MCP Access Token"
  - The token field should not be empty

Once enabled, Claude will have access to Home Assistant tools for querying and controlling your smart home!

## Usage

### Interactive Terminal Mode (Default)

When Remote Control is disabled, Claude launches as an interactive terminal:

```bash
node /usr/local/bin/claude
```

**Common Commands:**
- `claude --help` - See all available commands
- `claude "your prompt"` - Ask Claude a single question
- `claude process myfile.py` - Have Claude analyze a file
- `/mcp` - View connected MCP servers and available tools (when MCP is enabled)
- `/login` - Authenticate with Claude (OAuth)
- `/remote-control` - Enable Remote Control from within a session

The terminal starts in your `/config` directory, giving you immediate access to all your Home Assistant configuration files.

### Remote Control Mode

Enable **Remote Control Mode** in the add-on configuration to access Claude from your mobile device or browser.

**How it works:**
1. Enable "Remote Control Mode" in add-on configuration
2. Restart the add-on
3. Open the web UI - you'll see a session URL and QR code
4. Press spacebar to show/hide the QR code

**Connect from your device:**
- **Mobile app**: Scan the QR code with Claude mobile app ([iOS](https://apps.apple.com/app/claude-by-anthropic/id6473753684) / [Android](https://play.google.com/store/apps/details?id=com.anthropic.claude))
- **Browser**: Open the session URL at [claude.ai/code](https://claude.ai/code)
- **Session list**: Find your session by name in claude.ai/code

**Requirements:**
- Claude Pro, Max, Team, or Enterprise subscription
- OAuth authentication (not API key)
- Use `/login` in terminal if not authenticated

**Features:**
- Full local environment access (filesystem, MCP servers, tools)
- Work from both terminal and mobile/browser simultaneously
- Send images and files from your phone
- Survives network interruptions and reconnects automatically
- All execution stays on your Home Assistant machine

### Using MCP Tools

When MCP integration is enabled, Claude has direct access to Home Assistant through specialized tools. You can:

- Ask Claude to check the state of entities: *"What's the current temperature of my thermostat?"*
- Control devices: *"Turn off the living room lights"*
- Query history: *"Show me when the front door was last opened"*
- Create automations: *"Help me create an automation that turns on lights at sunset"*
- Troubleshoot: *"Why isn't my motion sensor triggering the automation?"*

Claude will automatically use the appropriate MCP tools to interact with your Home Assistant instance.

## Features

- **Web Terminal**: Access a full terminal environment via your browser
- **Remote Control**: Connect from mobile app or browser at claude.ai/code
- **QR Code Access**: Quick mobile pairing with QR code (press spacebar)
- **Claude AI**: Access Claude's AI capabilities for programming, troubleshooting and more
- **Direct Config Access**: Terminal starts in `/config` for immediate access to all Home Assistant files
- **OAuth Authentication**: Simple and secure authentication
- **Home Assistant Integration**: Access directly from your dashboard
- **Persistent Authentication**: All credentials stored securely and persist across restarts
- **MCP Integration**: Automatic connection to Home Assistant MCP Server for direct smart home control
- **Mobile & Browser Sync**: Work from multiple devices simultaneously with synchronized conversation
- **Local Execution**: All code execution and file access stays on your machine

## Troubleshooting

- If Claude doesn't start automatically, try running `node /usr/local/bin/claude -i` manually
- If you see permission errors, try restarting the add-on
- If you have authentication issues, try logging out and back in
- Check the add-on logs for any error messages

## Credits

This add-on was created with the assistance of Claude Code itself! The development process, debugging, and documentation were all completed using Claude's AI capabilities - a perfect demonstration of what this add-on can help you accomplish.