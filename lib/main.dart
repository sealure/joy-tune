import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'db/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地数据库
  await AppDatabase.initialize();

  runApp(const ProviderScope(child: ViaMusicApp()));
}
