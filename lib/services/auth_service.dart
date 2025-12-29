import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? token;
  static Map<String, dynamic>? doctorData;

  static const String _tokenKey = "auth_token";
  static const String _doctorDataKey = "doctor_data";

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    final dataString = prefs.getString(_doctorDataKey);
    if (dataString != null) {
      doctorData = jsonDecode(dataString);
    }
  }

  static Future<void> setToken(String newToken) async {
    token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
  }

  static Future<void> setDoctorData(Map<String, dynamic> data) async {
    doctorData = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorDataKey, jsonEncode(data));
  }

  static bool get isLoggedIn => token != null;

  static Future<void> logout() async {
    token = null;
    doctorData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_doctorDataKey);
  }
}

