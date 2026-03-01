# NekoShinobi's Personal Noctalia Plugins

Personal plugin repository for [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell).

## Overview

This is a personal collection of custom plugins for Noctalia Shell. These plugins are experimental and maintained separately from the main Noctalia plugins registry.

## Available Plugins

### APC UPS Monitor
**Version:** 1.0.0
- Real-time UPS monitoring via apcupsd
- Battery level, load, and runtime display
- Color-coded status indicators (normal/warning/critical)
- Detailed panel with comprehensive UPS information
- Customizable update interval (1-60 seconds)
- Configurable alert thresholds
- Bar widget shows battery or load percentage

See [apcupsd/README.md](apcupsd/README.md) for detailed documentation.

### Yay Updater
**Version:** 1.5.2
- Automatic update checks every 4 hours (configurable 1-24 hours)
- Visual update count on bar widget
- Detailed package list with repository detection
- One-click system update via terminal
- Customizable terminal emulator
- Auto-refresh on panel open
- IPC commands for automation

See [yay-updater/README.md](yay-updater/README.md) for detailed documentation.

## Installation

Add this repository as a custom plugin source in Noctalia Shell settings:

```
https://github.com/NekoShinobi/noctalia-plugins
```

## License

MIT - See individual plugin licenses in their respective directories.
