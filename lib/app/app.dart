import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';
import 'theme.dart';

class EduLearnApp extends StatelessWidget {
  const EduLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter.router;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduLearn',
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
