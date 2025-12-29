import { definePlugin, IconsModule, Field, DialogButton } from '@steambrew/client';
import { log } from './services/logger';
import {
  initUIMode,
  getCurrentConfig,
  getCurrentDocument,
  registerModeChangeListener,
  onModeChange,
} from './ui/uiMode';
import { setupObserver, resetState, disconnectObserver } from './injection/observer';
import { exposeDebugTools, removeDebugTools } from './debug/tools';
import { removeStyles } from './display/styles';
import { removeExistingDisplay } from './display/components';
import { clearCache, getCacheStats } from './services/cache';

const { useState } = (window as any).SP_REACT;

let unsubscribeModeChange: (() => void) | null = null;

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

    unsubscribeModeChange = onModeChange(async (newMode, newDoc) => {
      log('Reinitializing for mode change...');

      // Clean up old document first
      const oldDoc = getCurrentDocument();
      if (oldDoc && oldDoc !== newDoc) {
        removeDebugTools(oldDoc);
        removeStyles(oldDoc);
        removeExistingDisplay(oldDoc);
      }

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

function cleanup(): void {
  log('Cleaning up HLTB plugin...');

  if (unsubscribeModeChange) {
    unsubscribeModeChange();
    unsubscribeModeChange = null;
  }

  disconnectObserver();

  const doc = getCurrentDocument();
  if (doc) {
    removeDebugTools(doc);
    removeStyles(doc);
    removeExistingDisplay(doc);
  }

  resetState();
  log('HLTB plugin cleanup complete');
}

const SettingsContent = () => {
  const [message, setMessage] = useState('');

  const onCacheStats = () => {
    const stats = getCacheStats();
    if (stats.count === 0) {
      setMessage('Cache is empty');
    } else {
      const age = stats.oldestTimestamp
        ? Math.round((Date.now() - stats.oldestTimestamp) / (1000 * 60 * 60 * 24))
        : 0;
      setMessage(`${stats.count} games cached, oldest is ${age} days old`);
    }
  };

  const onClearCache = () => {
    clearCache();
    setMessage('Cache cleared');
  };

  return (
    <>
      <Field label="Cache Statistics" bottomSeparator="standard">
        <DialogButton onClick={onCacheStats} style={{ padding: '8px 16px' }}>View Stats</DialogButton>
      </Field>
      <Field label="Clear Cache" bottomSeparator="standard">
        <DialogButton onClick={onClearCache} style={{ padding: '8px 16px' }}>Clear</DialogButton>
      </Field>
      {message && <Field description={message} />}
    </>
  );
};

export default definePlugin(() => {
  init();
  return {
    title: 'HLTB for Steam',
    icon: <IconsModule.Settings />,
    content: <SettingsContent />,
    onUnload: cleanup,
  };
});
