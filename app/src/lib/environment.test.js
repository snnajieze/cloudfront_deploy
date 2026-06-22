import { getEnvironmentLabel } from '../lib/environment.js';

describe('getEnvironmentLabel', () => {
  it('returns "Development" for the devel environment', () => {
    expect(getEnvironmentLabel('devel')).toBe('Development');
  });

  it('returns "Staging" for the stage environment', () => {
    expect(getEnvironmentLabel('stage')).toBe('Staging');
  });

  it('returns "Local" when given an unrecognized or missing value', () => {
    expect(getEnvironmentLabel('something-else')).toBe('Local');
    expect(getEnvironmentLabel(undefined)).toBe('Local');
  });
});
