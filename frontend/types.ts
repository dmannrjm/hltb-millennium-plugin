import { EUIMode } from '@steambrew/client';

// Re-export for convenience
export { EUIMode };

// HLTB game data from backend
export interface HltbGameResult {
  game_id: number;
  game_name: string;
  comp_main: number | null; // hours
  comp_plus: number | null; // hours
  comp_100: number | null; // hours
  comp_all: number | null; // hours
}

// Cache entry for localStorage
export interface CacheEntry {
  data: HltbGameResult | null;
  timestamp: number;
  notFound: boolean;
}

// Result from fetchHltbData with stale-while-revalidate support
export interface FetchResult {
  data: HltbGameResult | null;
  fromCache: boolean;
  refreshPromise: Promise<HltbGameResult | null> | null;
}

// Selector configuration for each UI mode
export interface UIModeConfig {
  mode: EUIMode;
  modeName: string;
  headerImageSelector: string;
  fallbackImageSelector: string;
  containerSelector: string;
  appIdPattern: RegExp;
}

// Detected game page info
export interface GamePageInfo {
  appId: number;
  container: HTMLElement;
}
