import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:foreground_test2/event_service.dart';
import 'package:foreground_test2/my_shared_preferences.dart';

/// 타이머 간격
const _kLgsCheckTimeInSeconds = 120; // lgs 체크 간격
const _kSilenceSoundPlayInSeconds = 5; // iOS suspend 회피용 무음 사운드 재생 간격

/// 이벤트
const _kLgsCheckEvent = 'lgsCheck'; // 체크(포그라운드 isolate -> main isolate)
const _kSilenceSoundEvent = 'silenceSound'; // 무음 사운드 재생(포그라운드 isolate -> main isolate)
const _kStopServiceEvent = 'stopService'; // 서비스 종료(main isolate -> 포그라운드 isolate)
const _kAndroidNotificationEvent = 'androidNotification'; // 안드로이드용 노티피케이션 정보 update(main isolate -> 포그라운드 isolate)

/// 포그라운드 서비스 클래스
class ForegroundService {
  static final _service = FlutterBackgroundService();
  static StreamSubscription? _serviceCheckSubscription;

  ForegroundService._();

  /// 서비스 활성여부 조회
  static bool get isEnabled => MySharedPreferences.getServiceEnabled();

  /// 초기화: main 에서 호출해야 함
  /// API 호출이 필요하므로 jwt_token 이 생성된 이후에 호출해야 함
  static Future<void> init() async {
    debugPrint('ForegroundService init()');
    // lgs 체크
    _serviceCheckSubscription?.cancel();
    _serviceCheckSubscription = _service.on(_kLgsCheckEvent).listen((_) {
      if (!isEnabled) return;
      debugPrint('$_kLgsCheckEvent Event Triggered');
      EventService.instance.start();
    });
    await _service.configure(
      androidConfiguration: AndroidConfiguration(autoStart: false, onStart: onStart, isForegroundMode: true),
      iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart, onBackground: onIosBackground),
    );
  }

  /// LGS 서비스 활성/비활성
  /// 활성화 시키면 서비스를 시작하고, 비활성화 시키면 서비스를 종료함
  static Future<void> setEnabled(bool value) async {
    debugPrint('setEnabled()');
    await MySharedPreferences.setServiceEnabled(value);
    if (value) {
      await startService();
    } else {
      await stopService();
    }
  }

  /// 서비스 시작
  static Future<void> startService() async {
    debugPrint('startService()');
    if (await _service.isRunning()) {
      return;
    }
    await _service.startService();
  }

  /// 서비스 종료
  static Future<void> stopService() async {
    debugPrint('stopService()');
    if (!await _service.isRunning()) {
      return;
    }
    _service.invoke(_kStopServiceEvent);
  }

  /// 포그라운드 서비스가 실행중인지 체크
  static Future<bool> isRunning() {
    debugPrint('isRunning()');
    return _service.isRunning();
  }

  /// 노티피케이션 정보 갱신
  static void notification(String title, String body, String assetPath) {
    debugPrint('notification()');
    if (Platform.isAndroid) {
      _service.invoke(_kAndroidNotificationEvent, {'title': title, 'body': body, 'assetPath': assetPath});
    } else {
      // iOS
    }
  }
}

/// iOS 백그라운드 작업(미사용)
/// NOTE: this method will be invoked by native
@pragma('vm:entry-point') // avoid tree shaking
bool onIosBackground(ServiceInstance service) {
  debugPrint('onIosBackground()');
  return true;
}

/// 포그라운드 서비스 작업
/// NOTE: this method will be invoked by native
@pragma('vm:entry-point') // avoid tree shaking
void onStart(ServiceInstance service) {
  debugPrint('onStart()');
  Timer? timer;
  Timer? timer2;
  if (service is AndroidServiceInstance) {
    // 서비스 시작시 초기 메시지
    service.setForegroundNotificationInfo(title: '서비스 대기중', content: '포그라운드 서비스가 대기중입니다.');
  }
  // 서비스 종료
  service.on(_kStopServiceEvent).listen((_) {
    debugPrint('$_kStopServiceEvent Event Triggered');
    timer?.cancel();
    timer2?.cancel();
    service.stopSelf();
  });
  // 안드로이드용 노티피케이션 정보 update
  service.on(_kAndroidNotificationEvent).listen((args) async {
    debugPrint('$_kAndroidNotificationEvent Event Triggered');
    if (service is AndroidServiceInstance) {
      if(args != null) {
        final title = args['title'];
        final content = args['body'];
        service.setForegroundNotificationInfo(title: title, content: content, );
      }
    }
  });
  // 이후 실행은 일정 간격 실행
  timer = Timer.periodic(const Duration(seconds: _kLgsCheckTimeInSeconds), (_) {
    debugPrint('Timer.periodic: $_kLgsCheckEvent');
    service.invoke(_kLgsCheckEvent);
  });
  if (Platform.isIOS) {
    // Only iOS: suspend 회피 시작
    timer2 = Timer.periodic(const Duration(seconds: _kSilenceSoundPlayInSeconds), (_) {
      debugPrint('Timer.periodic: $_kSilenceSoundEvent');
      service.invoke(_kSilenceSoundEvent);
    });
  }
  // 최초 1회는 즉시 실행
  service.invoke(_kLgsCheckEvent);
}