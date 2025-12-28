import { sleep } from '@steambrew/client';
import type { UIModeConfig } from '../types';
import { log } from '../services/logger';
import { fetchHltbData } from '../services/hltbApi';
import { getCache } from '../services/cache';
import { detectGamePage } from './detector';
import {
  createLoadingDisplay,
  createDisplay,
  getExistingDisplay,
  removeExistingDisplay,
} from '../display/components';
import { injectStyles } from '../display/styles';

const MAX_RETRIES = 20;
const RETRY_DELAY_MS = 250;

let currentAppId: number | null = null;
let observer: MutationObserver | null = null;

export function resetState(): void {
  currentAppId = null;
}

export function getCurrentAppId(): number | null {
  return currentAppId;
}

async function handleGamePage(doc: Document, config: UIModeConfig): Promise<void> {
  const gamePage = detectGamePage(doc, config);
  if (!gamePage) {
    return;
  }

  const { appId, container } = gamePage;

  // Check if display already exists for this app
  const existingDisplay = getExistingDisplay(doc);
  if (appId === currentAppId && existingDisplay) {
    return;
  }

  currentAppId = appId;
  log('Found game page for appId:', appId);

  removeExistingDisplay(doc);

  // Ensure container has relative positioning for absolute child
  container.style.position = 'relative';
  container.appendChild(createLoadingDisplay(doc));

  try {
    const result = await fetchHltbData(appId);

    const updateDisplayForApp = (targetAppId: number) => {
      const existing = getExistingDisplay(doc);
      if (!existing) return false;

      const cached = getCache(targetAppId);
      const data = cached?.entry?.data;

      if (data && (data.comp_main > 0 || data.comp_plus > 0 || data.comp_100 > 0)) {
        existing.innerHTML = createDisplay(doc, data).innerHTML;
        return true;
      }
      return false;
    };

    // Always try to update display for the current game (might be different from fetched game)
    if (currentAppId !== appId) {
      log('Game changed during fetch, updating display for current game:', currentAppId);
      updateDisplayForApp(currentAppId);
      return;
    }

    updateDisplayForApp(appId);

    // Handle background refresh for stale data
    if (result.refreshPromise) {
      result.refreshPromise.then((newData) => {
        if (newData && currentAppId === appId) {
          updateDisplayForApp(appId);
        }
      });
    }
  } catch (e) {
    log('Error fetching HLTB data:', e);
  }
}

export async function setupObserver(doc: Document, config: UIModeConfig): Promise<void> {
  // Clean up existing observer
  if (observer) {
    observer.disconnect();
    observer = null;
  }

  injectStyles(doc);

  observer = new MutationObserver(() => {
    handleGamePage(doc, config);
  });

  observer.observe(doc.body, {
    childList: true,
    subtree: true,
  });

  log('MutationObserver set up for', config.modeName, 'mode');

  // Retry loop to find game page
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    const gamePage = detectGamePage(doc, config);
    if (gamePage) {
      log('setupObserver: game page found on attempt', attempt, 'of', MAX_RETRIES);
      handleGamePage(doc, config);
      return;
    }
    await sleep(RETRY_DELAY_MS);
  }

  log('setupObserver: no game page found after', MAX_RETRIES, 'attempts');
}

export function disconnectObserver(): void {
  if (observer) {
    observer.disconnect();
    observer = null;
  }
}
