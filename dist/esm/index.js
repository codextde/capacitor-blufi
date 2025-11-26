import { registerPlugin } from '@capacitor/core';
const Blufi = registerPlugin('Blufi', {
    web: () => import('./web').then((m) => new m.BlufiWeb()),
});
export * from './definitions';
export { Blufi };
//# sourceMappingURL=index.js.map