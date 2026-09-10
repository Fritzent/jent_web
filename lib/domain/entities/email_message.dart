class EmailMessage {
  final String name;
  final String from;
  final String subject;
  final String body;

  const EmailMessage({
    required this.name,
    required this.from,
    required this.subject,
    required this.body,
  });

  bool get canSend =>
      subject.trim().isNotEmpty || body.trim().isNotEmpty;
}
