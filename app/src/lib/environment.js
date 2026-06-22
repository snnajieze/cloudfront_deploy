/**
 * Returns a human-readable label for the environment the app is running in.
 *
 * `envValue` is the raw environment key (e.g. "devel", "stage") and is
 * normally passed in from App.jsx, which reads Vite's import.meta.env at
 * the call site. Keeping import.meta access out of this module means the
 * function stays a plain, easily testable pure function under Jest too.
 */
export function getEnvironmentLabel(envValue) {
  switch (envValue) {
    case 'devel':
      return 'Development';
    case 'stage':
      return 'Staging';
    default:
      return 'Local';
  }
}
