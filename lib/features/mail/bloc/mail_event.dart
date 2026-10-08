abstract class MailEvent {}

class ToggleOpenEmailMenu extends MailEvent {}

class ToggleCloseEmailMenu extends MailEvent {}

class ToggleMinimizeEmailMenu extends MailEvent {}

class ToggleExpandEmailMenu extends MailEvent {}

class SendEmail extends MailEvent {
  final String name;
  final String from;
  final String subject;
  final String body;

  SendEmail({
    required this.name,
    required this.from,
    required this.subject,
    required this.body,
  });
}
