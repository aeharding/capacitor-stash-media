import { WebPlugin } from '@capacitor/core';

import type { StashMediaPlugin } from './definitions';

export class StashMediaWeb extends WebPlugin implements StashMediaPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
