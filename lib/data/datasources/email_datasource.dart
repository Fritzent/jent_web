import 'package:injectable/injectable.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';

/// Sends email via SMTP. Credentials come from `--dart-define`
/// (EMAIL_USERNAME / EMAIL_PASSWORD / EMAIL_RECIPIENT) so no secret
/// is committed to the repo.
@injectable
class EmailDatasource {
  final String _username;
  final String _password;
  final String _recipient;

  EmailDatasource(
    @Named('emailUsername') this._username,
    @Named('emailPassword') this._password,
    @Named('emailRecipient') this._recipient,
  );

  Future<void> send(EmailMessage message) async {
    final smtpServer = gmail(_username, _password);
    final email = mailer.Message()
      ..from = mailer.Address(_username, message.name)
      ..recipients.add(_recipient)
      ..headers['Reply-To'] = message.from
      ..subject = message.subject.isEmpty ? '(no subject)' : message.subject
      ..text = 'From: ${message.name} <${message.from}>\n\n${message.body}';

    await mailer.send(email, smtpServer);
  }
}
