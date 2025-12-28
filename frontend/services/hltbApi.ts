import { callable } from '@steambrew/client';
import { getCache, setCache } from './cache';

export interface HltbGameResult {
  game_id: number; // HLTB game ID (for URL)
  game_name: string;
  comp_main: number; // seconds
  comp_plus: number; // seconds
  comp_100: number; // seconds
  comp_all: number; // seconds
}

interface BackendResponse {
  success: boolean;
  error?: string;
  data?: HltbGameResult;
}

const GetHltbData = callable<[{ app_id: number }], string>('GetHltbData');

export async function fetchHltbData(appId: number): Promise<HltbGameResult | null> {
  // Check cache first
  const cached = getCache(appId);
  if (cached) {
    return cached.notFound ? null : cached.data;
  }

  try {
    const resultJson = await GetHltbData({ app_id: appId });
    const result: BackendResponse = JSON.parse(resultJson);

    if (!result.success || !result.data) {
      console.log('[HLTB] Backend error:', result.error);
      setCache(appId, null);
      return null;
    }

    setCache(appId, result.data);
    return result.data;
  } catch (e) {
    console.error('[HLTB] Backend call error:', e);
    return null;
  }
}

export function formatTime(seconds: number): string {
  if (!seconds || seconds === 0) return '--';
  const hours = Math.round((seconds / 3600) * 10) / 10;
  if (hours < 1) {
    const mins = Math.round(seconds / 60);
    return `${mins}m`;
  }
  return `${hours}h`;
}
