import { EUIMode, type UIModeConfig } from '../types';

// Library selectors (same for Desktop and Big Picture modes)
const LIBRARY_SELECTORS = {
  headerImageSelector: '._3NBxSLAZLbbbnul8KfDFjw._2dzwXkCVAuZGFC-qKgo8XB',
  fallbackImageSelector: 'img.HNbe3eZf6H7dtJ042x1vM[src*="library_hero"]',
  containerSelector: '.NZMJ6g2iVnFsOOp-lDmIP',
  appIdPattern: /\/assets\/(\d+)/,
};

export function getConfigForMode(mode: EUIMode): UIModeConfig {
  return {
    mode,
    modeName: mode === EUIMode.GamePad ? 'Big Picture' : 'Desktop',
    ...LIBRARY_SELECTORS,
  };
}
