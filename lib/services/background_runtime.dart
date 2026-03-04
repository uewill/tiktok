import 'package:wakelock_plus/wakelock_plus.dart';

class BackgroundRuntime {
  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> enable() async {
    await WakelockPlus.enable();
    _enabled = true;
  }

  Future<void> disable() async {
    await WakelockPlus.disable();
    _enabled = false;
  }
}
