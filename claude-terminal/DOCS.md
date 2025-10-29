# Claude Terminal

A terminal interface for Anthropic's Claude Code CLI in Home Assistant.

## About

This add-on provides a web-based terminal with Claude Code CLI pre-installed, allowing you to access Claude's powerful AI capabilities directly from your Home Assistant dashboard. The terminal provides full access to Claude's code generation, explanation, and problem-solving capabilities.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the Claude Terminal add-on
3. Start the add-on
4. Click "OPEN WEB UI" to access the terminal
5. On first use, follow the OAuth prompts to log in to your Anthropic account

## Configuration

### Basic Configuration

No configuration is needed! The add-on uses OAuth authentication, so you'll be prompted to log in to your Anthropic account the first time you use it.

Your OAuth credentials are stored in the `/config/claude-config` directory and will persist across add-on updates and restarts, so you won't need to log in again.

### MCP Integration (Optional)

The add-on can automatically connect Claude Code to your Home Assistant instance via the Model Context Protocol (MCP). This allows Claude to directly interact with your Home Assistant entities, automations, and services.

**Prerequisites:**
1. **Home Assistant 2025.2 or later** is required
2. Install the **Model Context Protocol Server** integration in Home Assistant:
   - Go to Settings → Devices & Services → Add Integration
   - Search for "Model Context Protocol Server"
   - Configure which entities/services to expose to Claude

**Configuration Options:**

- **Enable MCP Integration**: Turn on automatic MCP configuration (default: disabled)
- **MCP Server URL**: Override the auto-discovered server URL if needed
  - Default: auto-discovery (tries common URLs)
  - Manual example: `http://homeassistant.local:8123/mcp_server/sse`

**To Enable:**
1. Ensure Home Assistant 2025.2+ is installed
2. Enable the "Model Context Protocol Server" integration in Home Assistant
3. In the Claude Terminal add-on configuration, enable "Enable MCP Integration"
4. Restart the add-on
5. Check the add-on logs to verify MCP connection
6. Open the terminal and check MCP status with: `/mcp`

**Troubleshooting:**

If you see "HTTP 404" errors in the logs:
- Verify Home Assistant version is 2025.2 or later
- Confirm the MCP Server integration is installed and running
- Check Settings → Devices & Services → Model Context Protocol Server
- If using a custom Home Assistant URL or port, specify it manually in "MCP Server URL"
- The endpoint format is: `http://YOUR_HA_HOST:8123/mcp_server/sse`

Once enabled, Claude will have access to Home Assistant tools for querying and controlling your smart home!

## Usage

Claude launches automatically when you open the terminal. You can also start Claude manually with:

```bash
node /usr/local/bin/claude
```

### Common Commands

- `claude -i` - Start an interactive Claude session
- `claude --help` - See all available commands
- `claude "your prompt"` - Ask Claude a single question
- `claude process myfile.py` - Have Claude analyze a file
- `claude --editor` - Start an interactive editor session
- `/mcp` - View connected MCP servers and available tools (when MCP is enabled)

The terminal starts directly in your `/config` directory, giving you immediate access to all your Home Assistant configuration files. This makes it easy to get help with your configuration, create automations, and troubleshoot issues.

### Happy Mobile Client

Access Claude from your mobile device using the Happy mobile client:

1. From the session picker, choose option **6** to launch Happy with QR code
2. Scan the QR code with the Happy mobile app
3. Start coding on your phone with Claude's full capabilities

You can also run Happy in daemon mode (option **7**) to keep it running in the background for persistent mobile access.

Happy authentication is stored in `/data/.config/happy` and persists across add-on restarts.

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
- **Auto-Launching**: Claude starts automatically when you open the terminal
- **Claude AI**: Access Claude's AI capabilities for programming, troubleshooting and more
- **Happy Mobile Client**: Connect to Claude from your mobile device with QR code pairing
- **Direct Config Access**: Terminal starts in `/config` for immediate access to all Home Assistant files
- **Simple Setup**: Uses OAuth for easy authentication
- **Home Assistant Integration**: Access directly from your dashboard
- **Persistent Authentication**: All credentials stored securely and persist across restarts
- **MCP Integration**: Optional automatic connection to Home Assistant MCP Server for direct smart home control through Claude

## Troubleshooting

- If Claude doesn't start automatically, try running `node /usr/local/bin/claude -i` manually
- If you see permission errors, try restarting the add-on
- If you have authentication issues, try logging out and back in
- Check the add-on logs for any error messages

## Credits

This add-on was created with the assistance of Claude Code itself! The development process, debugging, and documentation were all completed using Claude's AI capabilities - a perfect demonstration of what this add-on can help you accomplish.