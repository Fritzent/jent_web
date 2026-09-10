import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/domain/entities/email_message.dart';

void main() {
  group('EmailMessage.canSend', () {
    test('false when subject and body are blank', () {
      const message = EmailMessage(
        name: 'Ada',
        from: 'ada@mail.com',
        subject: '  ',
        body: '',
      );

      expect(message.canSend, isFalse);
    });

    test('true when subject or body has content', () {
      expect(
        const EmailMessage(
          name: 'Ada',
          from: 'ada@mail.com',
          subject: 'Hi',
          body: '',
        ).canSend,
        isTrue,
      );
      expect(
        const EmailMessage(
          name: 'Ada',
          from: 'ada@mail.com',
          subject: '',
          body: 'Hello',
        ).canSend,
        isTrue,
      );
    });
  });
}
