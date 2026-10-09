import 'package:flutter_test/flutter_test.dart';
import 'package:findthedifference/services/settings_service.dart';

/// Regression tests for the player-name persistence rule (MASTER_RULES):
///
/// NEVER use SharedPreferences.setStringList for player names — on Android
/// it is backed by an UNORDERED StringSet (HashSet), so after an app restart
/// the names came back in arbitrary order and renames appeared "not saved".
/// Names are now stored as ONE order-preserving JSON string via setString,
/// key `findthedifference_player_names_json`. These tests cover the
/// encode/decode round-trip used by SpotSettings.
void main() {
  test('names survive an encode/decode round-trip in exact slot order', () {
    const names = {
      'solo': 'Wajiha',
      'p1': 'Detective 1',
      'p2': 'Zara',
    };
    final encoded = SpotSettings.encodeNames(names);
    // A single JSON string, not a list.
    expect(encoded.startsWith('{'), isTrue);
    final decoded = SpotSettings.decodeNames(encoded);
    expect(decoded.keys.toList(), orderedEquals(names.keys.toList()));
    expect(decoded['solo'], 'Wajiha');
    expect(decoded['p2'], 'Zara');
  });

  test('decodeNames falls back to defaults on bad/empty input', () {
    expect(SpotSettings.decodeNames(null), SpotSettings.defaultNames);
    expect(SpotSettings.decodeNames('not json at all'),
        SpotSettings.defaultNames);
  });

  test('empty strings fall back to defaults', () {
    final decoded =
        SpotSettings.decodeNames('{"solo": "  ", "p1": "Ali", "p2": "Bo"}');
    expect(decoded['solo'], SpotSettings.defaultNames['solo']);
    expect(decoded['p1'], 'Ali');
  });
}
