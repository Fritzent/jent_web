// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:jent_web/data/datasources/email_datasource.dart' as _i763;
import 'package:jent_web/data/repositories/email_repository_impl.dart' as _i724;
import 'package:jent_web/di/injection.dart' as _i786;
import 'package:jent_web/domain/repositories/email_repository.dart' as _i414;
import 'package:jent_web/domain/usecases/send_email_usecase.dart' as _i343;
import 'package:jent_web/presentation/pages/home/home_bloc.dart' as _i195;
import 'package:jent_web/presentation/pages/ignite/ignite_bloc.dart' as _i359;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.factory<_i359.IgniteBloc>(() => _i359.IgniteBloc());
    gh.factory<String>(
      () => appModule.emailRecipient,
      instanceName: 'emailRecipient',
    );
    gh.factory<String>(
      () => appModule.emailUsername,
      instanceName: 'emailUsername',
    );
    gh.factory<String>(
      () => appModule.emailPassword,
      instanceName: 'emailPassword',
    );
    gh.factory<_i763.EmailDatasource>(
      () => _i763.EmailDatasource(
        gh<String>(instanceName: 'emailUsername'),
        gh<String>(instanceName: 'emailPassword'),
        gh<String>(instanceName: 'emailRecipient'),
      ),
    );
    gh.lazySingleton<_i414.EmailRepository>(
      () => _i724.EmailRepositoryImpl(gh<_i763.EmailDatasource>()),
    );
    gh.factory<_i343.SendEmailUseCase>(
      () => _i343.SendEmailUseCase(gh<_i414.EmailRepository>()),
    );
    gh.factory<_i195.HomeBloc>(
      () => _i195.HomeBloc(gh<_i343.SendEmailUseCase>()),
    );
    return this;
  }
}

class _$AppModule extends _i786.AppModule {}
