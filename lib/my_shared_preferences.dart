import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAppUidKey = 'app_uid_key'; // 앱 UID 정보 저장 키
const String _kServiceEnabledKey = 'service_enabled_key'; // 서비스 활성 여부 저장 키

class MySharedPreferences {
  static SharedPreferences? _prefs;

  MySharedPreferences._();

  /// 초기화: main 에서 호출해야 함
  static Future<void> init() async {
    debugPrint('MySharedPreferences init()');
    _prefs = await SharedPreferences.getInstance();
  }

  /// 전체 데이터 삭제: 회원 탈퇴시 호출해야 함
  static Future<bool> clear() async {
    return await _prefs!.clear();
  }

  /// AppUid
  static Future<void> setAppUid(String value) async {
    await _prefs!.setString(_kAppUidKey, value);
  }

  static String? getAppUid() {
    return _prefs!.getString(_kAppUidKey);
  }

  static Future<void> removeAppUid() async {
    await _prefs!.remove(_kAppUidKey);
  }

  /// ServiceEnabled
  static Future<void> setServiceEnabled(bool value) async {
    await _prefs!.setBool(_kServiceEnabledKey, value);
  }

  static bool getServiceEnabled() {
    return _prefs!.getBool(_kServiceEnabledKey) ?? false;
  }

  static Future<void> removeServiceEnabled() async {
    await _prefs!.remove(_kServiceEnabledKey);
  }
}
