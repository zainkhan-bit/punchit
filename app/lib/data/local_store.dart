import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  String? read();
  Future<void> write(String value);
  Future<void> clear();
}

class SharedPrefsStore implements LocalStore {
  static const _key = 'punchit_data_v1';

  final SharedPreferences _prefs;

  SharedPrefsStore(this._prefs);

  @override
  String? read() => _prefs.getString(_key);

  @override
  Future<void> write(String value) => _prefs.setString(_key, value);

  @override
  Future<void> clear() => _prefs.remove(_key);
}

class MemoryStore implements LocalStore {
  String? _value;

  @override
  String? read() => _value;

  @override
  Future<void> write(String value) async => _value = value;

  @override
  Future<void> clear() async => _value = null;
}
