import 'package:flutter/services.dart';

class EventService {
  static const channel = MethodChannel('foreground/test');

  static final instance = EventService();

  Future<void> start() async {
    await channel.invokeMethod('start');
  }

  Future<void> stop() async {
    await channel.invokeMethod('stop');
  }
}