import 'package:flutter/material.dart';
import 'package:jent_web/core/utils/web/url_strategy_config.dart';
import 'package:jent_web/di/injection.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  configureUrlStrategy();

  runApp(const App());
}
