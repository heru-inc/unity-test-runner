import { describe, it, expect, vi, beforeEach, afterEach, beforeAll, afterAll, test } from 'vitest';
import Action from './action';
import Docker from './docker';

describe('Docker', () => {
  it.skip('runs', async () => {
    const image = 'unity-builder:2022.3.7f1-webgl';
    const parameters = {
      workspace: Action.rootFolder,
      projectPath: `${Action.rootFolder}/test-project`,
      buildName: 'someBuildName',
      buildsPath: 'build',
      method: '',
    };
    await Docker.run(image, parameters);
  });

  describe('getTestPlatforms', () => {
    it('runs playmode, editmode and COMBINE_RESULTS for all with coverage', () => {
      expect(Docker.getTestPlatforms('all', 'generateHtmlReport')).toStrictEqual(
        'playmode;editmode;COMBINE_RESULTS',
      );
    });

    it('skips COMBINE_RESULTS for all without coverage', () => {
      expect(Docker.getTestPlatforms('all', '')).toStrictEqual('playmode;editmode');
    });

    test.each(['playmode', 'editmode', 'standalone'])('runs only %s', (testMode) => {
      expect(Docker.getTestPlatforms(testMode, 'generateHtmlReport')).toStrictEqual(testMode);
      expect(Docker.getTestPlatforms(testMode, '')).toStrictEqual(testMode);
    });
  });
});
