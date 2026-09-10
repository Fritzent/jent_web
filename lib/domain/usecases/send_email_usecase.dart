import 'package:injectable/injectable.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:jent_web/domain/repositories/email_repository.dart';

@injectable
class SendEmailUseCase {
  final EmailRepository _repository;

  SendEmailUseCase(this._repository);

  Future<void> call(EmailMessage message) => _repository.send(message);
}
