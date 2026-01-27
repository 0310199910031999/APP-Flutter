abstract class NotificationService {
  Future<void> init();
  Future<void> requestPermissions();
  Future<void> showLocal({required String title, required String body});
}
