# HLTB for Steam

A [Millennium](https://steambrew.app/) plugin that displays [How Long To Beat](https://howlongtobeat.com/) completion times on game pages in the Steam library.

![Desktop Mode](example_desktop.png)

![Big Picture Mode](example_bigPictureMode.png)

## Features

- Shows HLTB completion times directly on game pages:
  - Main Story
  - Main + Extras
  - Completionist
- Works in both Desktop and Big Picture modes
- Caches results locally (12 hour TTL with stale-while-revalidate)
- Click "View Details" to open the full HLTB page

## Requirements

- [Millennium](https://steambrew.app/) installed on Steam
- Windows or Linux

## Installation

### From Millennium (Recommended)

1. Open Steam with Millennium installed
2. Go to Settings > Plugins
3. Search for "HLTB for Steam"
4. Click Install
5. Restart Steam

### Manual Installation

1. Download the latest release from the [Releases](../../releases) page
2. Extract the contents to your Steam plugins folder:
   - Windows: `C:\Program Files (x86)\Steam\plugins\hltb-for-millennium\`
   - Linux: `~/.steam/steam/plugins/hltb-for-millennium/`
3. Restart Steam

## Usage

Once installed, HLTB data automatically appears on game pages in your Steam library. Simply click on any game to see its completion times displayed on the header image.

## How It Works

1. When you view a game page, the plugin detects the Steam App ID
2. It queries the Steam API to get the game name
3. It searches How Long To Beat for matching games
4. Results are cached locally and displayed on the game header

## Known Limitations

- Games not in the HLTB database will show placeholder dashes
- Some games may not match correctly due to name differences between Steam and HLTB
- DLC and non-game content will not have HLTB data

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Development build with watch
npm run watch
```

To test, launch Steam with Millennium in dev mode.

## Credits

- [How Long To Beat](https://howlongtobeat.com/) for the game completion data
- [HLTB for Deck](https://github.com/hulkrelax/hltb-for-deck) for inspiration
- [Millennium](https://steambrew.app/) for the plugin framework
- [howlongtobeatpy](https://pypi.org/project/howlongtobeatpy/) for the Python API wrapper

## Disclaimer

This plugin is not affiliated with, endorsed by, or connected to How Long To Beat or HowLongToBeat.com. All game data is sourced from their public website. If you find this plugin useful, consider supporting [How Long To Beat](https://howlongtobeat.com/) directly.

## License

MIT
