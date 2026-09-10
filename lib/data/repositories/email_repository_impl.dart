import 'package:injectable/injectable.dart';
import 'package:jent_web/data/datasources/email_datasource.dart';
import 'package:jent_web/domain/entities/email_message.dart';
import 'package:jent_web/domain/repositories/email_repository.dart';

@LazySingleton(as: EmailRepository)
class EmailRepositoryImpl implements EmailRepository {
  final EmailDatasource _datasource;

  EmailRepositoryImpl(this._datasource);

  @override
  Future<void> send(EmailMessage message) => _datasource.send(message);
}
