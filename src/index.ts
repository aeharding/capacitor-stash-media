import { registerPlugin } from '@capacitor/core';

import type { StashMediaPlugin } from './definitions';

const StashMedia = registerPlugin<StashMediaPlugin>('StashMedia', {
  web: () => import('./web').then(m => new m.StashMediaWeb()),
});

export * from './definitions';
export { StashMedia };
