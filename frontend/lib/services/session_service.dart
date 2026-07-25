import 'package:shared_preferences/shared_preferences.dart';

class SessionService {

  static Future<void> saveUser({
    required int userId,
    required String name,
    required String email,
    required String accessToken,
  }) async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      'is_logged_in',
      true,
    );

    await prefs.setInt(
      'user_id',
      userId,
    );

    await prefs.setString(
      'name',
      name,
    );

    await prefs.setString(
      'email',
      email,
    );
    await prefs.setString(
      'access_token',
      accessToken,
    );
  }
  static Future<String> getAccessToken() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      'access_token',
    ) ??
        '';
  }

  static Future<bool> isLoggedIn() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      'is_logged_in',
    ) ??
        false;
  }

  static Future<String> getName() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      'name',
    ) ??
        '';
  }

  static Future<String> getEmail() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      'email',
    ) ??
        '';
  }
  static Future<int> getUserId() async {

    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getInt(
      'user_id',
    ) ??
        0;
  }

  static Future<void> logout() async {

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.clear();
  }
}