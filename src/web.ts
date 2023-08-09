import { WebPlugin } from '@capacitor/core';

import type { StashMediaPlugin } from './definitions';

export class StashMediaWeb extends WebPlugin implements StashMediaPlugin {
  async savePhoto(): Promise<void> {
    throw new Error('Unsupported on the web');
  }

  async copyPhotoToClipboard(): Promise<void> {
    throw new Error('Unsupported on the web');
  }
}
