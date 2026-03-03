typedef InAppNotifier = void Function(String title, String body);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  InAppNotifier? _notifier;

  void register(InAppNotifier notifier) {
    _notifier = notifier;
  }

  void unregister(InAppNotifier notifier) {
    if (_notifier == notifier) {
      _notifier = null;
    }
  }

  void sendInApp(String title, String body) {
    final cb = _notifier;
    if (cb != null) {
      cb(title, body);
    }
  }
}
