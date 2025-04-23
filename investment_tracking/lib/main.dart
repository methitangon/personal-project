import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

  await di.init();

  runApp(const MyApp());
}
