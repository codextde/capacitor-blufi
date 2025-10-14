import { registerPlugin } from '@capacitor/core';

import type { BlufiPlugin } from './definitions';

const Blufi = registerPlugin<BlufiPlugin>('Blufi', {
  web: () => import('./web').then((m) => new m.BlufiWeb()),
});

export * from './definitions';
export { Blufi };
