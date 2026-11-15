import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forma/core/navigation/app_router.dart';
import 'package:forma/core/theme/app_theme.dart';
import 'package:forma/core/theme/theme_provider.dart';
import 'package:forma/core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService().initialize();
  runApp(const ProviderScope(child: FormaApp()));
}

class FormaApp extends ConsumerWidget {
  const FormaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FORMA',
      debugShowCheckedModeBanner: false,
      theme: FormaTheme.lightTheme,
      darkTheme: FormaTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 380),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: appRouter,
    );
  }
}
