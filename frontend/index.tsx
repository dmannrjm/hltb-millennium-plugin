import React from 'react';
import { definePlugin } from '@steambrew/client';
import { log } from './services/logger';
import {
  initUIMode,
  getCurrentConfig,
  registerModeChangeListener,
  onModeChange,
} from './ui/uiMode';
import { setupObserver, resetState } from './injection/observer';
import { exposeDebugTools } from './debug/tools';

async function init(): Promise<void> {
  log('Initializing HLTB plugin...');

  try {
    const { mode, document } = await initUIMode();
    const config = getCurrentConfig();

    log('Mode:', config.modeName);
    log('Using selectors:', {
      headerImage: config.headerImageSelector,
      fallbackImage: config.fallbackImageSelector,
      container: config.containerSelector,
    });

    await setupObserver(document, config);
    exposeDebugTools(document);

    registerModeChangeListener();

    onModeChange(async (newMode, newDoc) => {
      log('Reinitializing for mode change...');
      resetState();
      const newConfig = getCurrentConfig();
      await setupObserver(newDoc, newConfig);
      exposeDebugTools(newDoc);
      log('Reinitialized for', newConfig.modeName, 'mode');
    });
  } catch (e) {
    log('Failed to initialize:', e);
  }
}

export default definePlugin(() => {
  init();
  return {
    icon: <React.Fragment />,
  };
});
