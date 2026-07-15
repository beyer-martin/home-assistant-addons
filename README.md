# Claude Code for Home Assistant

This repository contains a custom add-on that integrates Anthropic's Claude Code CLI with Home Assistant, featuring Remote Control for mobile access and automatic MCP integration.

## Installation

To add this repository to your Home Assistant instance:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu in the top right corner
3. Select **Repositories**
4. Add the URL: `https://github.com/beyer-martin/home-assistant-addons`
5. Click **Add**

## Add-ons

### Claude Code

Claude Code with Remote Control and Home Assistant integration. Access Claude's AI capabilities from your dashboard, or remotely from your mobile device.

**Features:**
- **Remote Control**: Connect from Claude mobile app or claude.ai/code
- **QR Code Access**: Quick mobile pairing (press spacebar to show QR)
- **Web Terminal**: Full terminal environment in your Home Assistant UI
- **MCP Integration**: Automatic connection to Home Assistant for smart home control
- **OAuth Authentication**: Simple and secure login
- **Persistent Sessions**: Credentials and sessions survive restarts
- **Direct Config Access**: Terminal starts in `/config` directory
- **Multi-Device Support**: Work from terminal, browser, and mobile simultaneously

**What you can do:**
- Code generation and explanation
- Debug Home Assistant issues
- Create and modify automations
- Control smart home devices via MCP
- Access from anywhere with Remote Control

**Requirements for Remote Control:**
- Claude Pro, Max, Team, or Enterprise subscription
- OAuth authentication (not API key)

[Full Documentation](claude-terminal/DOCS.md)

## Support

If you have any questions or issues with this add-on, please create an issue in this repository.

## Credits

This add-on was created with the assistance of Claude Code itself! The development process, debugging, and documentation were all completed using Claude's AI capabilities.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
