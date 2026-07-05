import 'package:shared_preferences/shared_preferences.dart';

/// Thin synchronous cache over SharedPreferences. Call [init] before runApp;
/// writes are fire-and-forget.
class Storage {
  Storage._(this._prefs);

  static late Storage instance;

  final SharedPreferences _prefs;

  static Future<void> init() async {
    instance = Storage._(await SharedPreferences.getInstance());
  }

  int get bestScore => _prefs.getInt('bestScore') ?? 0;
  set bestScore(int v) => _prefs.setInt('bestScore', v);

  int get bestDistance => _prefs.getInt('bestDistance') ?? 0;
  set bestDistance(int v) => _prefs.setInt('bestDistance', v);

  int get coinBank => _prefs.getInt('coinBank') ?? 0;
  set coinBank(int v) => _prefs.setInt('coinBank', v);

  int get gamesPlayed => _prefs.getInt('gamesPlayed') ?? 0;
  set gamesPlayed(int v) => _prefs.setInt('gamesPlayed', v);

  bool get soundOn => _prefs.getBool('soundOn') ?? true;
  set soundOn(bool v) => _prefs.setBool('soundOn', v);

  bool get musicOn => _prefs.getBool('musicOn') ?? true;
  set musicOn(bool v) => _prefs.setBool('musicOn', v);

  bool get tutorialSeen => _prefs.getBool('tutorialSeen') ?? false;
  set tutorialSeen(bool v) => _prefs.setBool('tutorialSeen', v);

  String get equippedSkin => _prefs.getString('equippedSkin') ?? 'dash';
  set equippedSkin(String v) => _prefs.setString('equippedSkin', v);

  List<String> get ownedSkins =>
      _prefs.getStringList('ownedSkins') ?? const ['dash'];
  set ownedSkins(List<String> v) => _prefs.setStringList('ownedSkins', v);

  Future<void> resetProgress() async {
    for (final k in [
      'bestScore',
      'bestDistance',
      'coinBank',
      'gamesPlayed',
      'tutorialSeen',
      'equippedSkin',
      'ownedSkins',
    ]) {
      await _prefs.remove(k);
    }
  }
}
