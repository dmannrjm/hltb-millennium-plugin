import json

import Millennium
import PluginUtils  # type: ignore
import requests
from howlongtobeatpy import HowLongToBeat

logger = PluginUtils.Logger()

STEAM_API_URL = 'https://store.steampowered.com/api/appdetails'


def get_game_name_from_steam(app_id: int) -> str | None:
    """Get game name from Steam API."""
    try:
        response = requests.get(f'{STEAM_API_URL}?appids={app_id}')
        if response.status_code != 200:
            return None

        data = response.json()
        app_data = data.get(str(app_id), {})

        if app_data.get('success') and app_data.get('data', {}).get('name'):
            return app_data['data']['name']
        return None
    except Exception as e:
        logger.error(f'Steam API error: {e}')
        return None


def GetHltbData(app_id: int) -> str:
    """Get HLTB data for a Steam app. Called from frontend."""
    logger.log(f'GetHltbData called for app_id: {app_id}')

    # Get game name from Steam
    game_name = get_game_name_from_steam(app_id)
    if not game_name:
        logger.error(f'Could not get game name for app_id: {app_id}')
        return json.dumps({'success': False, 'error': 'Could not get game name'})

    logger.log(f'Got game name: {game_name}')

    # Search HLTB using the library
    try:
        results = HowLongToBeat().search(game_name)
    except Exception as e:
        logger.error(f'HLTB search error: {e}')
        return json.dumps({'success': False, 'error': f'HLTB search error: {e}'})

    if not results:
        logger.log(f'No HLTB results for: {game_name}')
        return json.dumps({'success': False, 'error': 'No HLTB results'})

    # Take the best match (first result, highest similarity)
    match = results[0]
    logger.log(f'Found match: {match.game_name} (id: {match.game_id}, similarity: {match.similarity})')

    # Convert time from hours to seconds (frontend expects seconds)
    def hours_to_seconds(hours):
        return int(hours * 3600) if hours else 0

    return json.dumps({
        'success': True,
        'data': {
            'game_id': match.game_id,
            'game_name': match.game_name,
            'comp_main': hours_to_seconds(match.main_story),
            'comp_plus': hours_to_seconds(match.main_extra),
            'comp_100': hours_to_seconds(match.completionist),
            'comp_all': hours_to_seconds(match.all_styles),
        }
    })


class Plugin:
    def _front_end_loaded(self):
        logger.log("Frontend loaded")

    def _load(self):
        logger.log(f"bootstrapping HLTB plugin, millennium {Millennium.version()}")
        Millennium.ready()

    def _unload(self):
        logger.log("unloading")
