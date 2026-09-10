import 'package:jent_web/domain/entities/email_message.dart';

abstract class EmailRepository {
  Future<void> send(EmailMessage message);
}
