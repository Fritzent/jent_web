import 'package:flutter/material.dart';
import 'package:jent_web/utils/web/url_strategy_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  runApp(const App());
}