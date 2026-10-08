/// PIN that unlocks private areas (Photos, Notes). Defaults to '1234';
/// override via --dart-define=VAULT_PIN when needed.
const String vaultPin = String.fromEnvironment(
  'VAULT_PIN',
  defaultValue: '1234',
);
