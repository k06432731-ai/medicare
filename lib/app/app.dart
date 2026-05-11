import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/network/dio_client.dart';
import '../core/security/app_lock_provider.dart';
import '../core/services/deep_link_service.dart';
import '../core/services/notification_service.dart';
import '../core/theme/theme_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/settings/providers/locale_provider.dart';

class MedicareApp extends ConsumerStatefulWidget {
  const MedicareApp({super.key});

  @override
  ConsumerState<MedicareApp> createState() => _MedicareAppState();
}

class _MedicareAppState extends ConsumerState<MedicareApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register the 401 hook so Dio can trigger logout without a circular dep
    registerOn401Hook(() {
      ref.read(authProvider.notifier).logout();
    });

    // Initialise les notifications locales (pas de Firebase nécessaire)
    NotificationService.instance.initialize();

    // Initialise l'écoute des deep links après la construction du routeur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService.init(ref.read(routerProvider));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Surveille le compteur non-lus pour déclencher les bannières OS
    ref.listenManual<AsyncValue<int>>(unreadCountProvider, (prev, next) {
      next.whenOrNull(
        data: (count) =>
            NotificationService.instance.onUnreadCountChanged(count),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        ref.read(appLockProvider.notifier).onBackground();
        break;
      case AppLifecycleState.resumed:
        ref.read(appLockProvider.notifier).onForeground();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'MediCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: LocaleNotifier.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
