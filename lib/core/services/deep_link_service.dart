import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

/// Gère les deep links de l'application (schéma `medicare://`).
///
/// Routes supportées :
///   - `medicare://payment/success` → `/payment/success`
///   - `medicare://payment/cancel`  → `/payment/cancel`
class DeepLinkService {
  DeepLinkService._();

  static final _logger = Logger();
  static AppLinks? _appLinks;
  static StreamSubscription<Uri>? _sub;

  /// À appeler une seule fois après construction du [GoRouter].
  static Future<void> init(GoRouter router) async {
    if (_appLinks != null) return; // déjà initialisé
    _appLinks = AppLinks();

    // 1. Lien initial (cold start)
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) _handle(initial, router);
    } catch (e) {
      _logger.w('DeepLinkService initial link error: $e');
    }

    // 2. Liens reçus pendant que l'app est en mémoire
    _sub = _appLinks!.uriLinkStream.listen(
      (uri) => _handle(uri, router),
      onError: (Object e) => _logger.w('DeepLinkService stream error: $e'),
    );
  }

  static void _handle(Uri uri, GoRouter router) {
    _logger.i('Deep link reçu : $uri');

    if (uri.scheme != 'medicare') return;

    final host = uri.host;
    final firstSegment =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';

    // medicare://payment/success ou medicare://payment?status=success
    if (host == 'payment') {
      final status = firstSegment.isNotEmpty
          ? firstSegment
          : (uri.queryParameters['status'] ?? '');

      if (status == 'success') {
        final invoiceId = uri.queryParameters['invoiceId'] ?? '';
        final target = invoiceId.isNotEmpty
            ? '/payment/success?invoiceId=$invoiceId'
            : '/payment/success';
        router.go(target);
        return;
      }
      if (status == 'cancel' || status == 'canceled' || status == 'cancelled') {
        router.go('/payment/cancel');
        return;
      }
    }

    // TODO: ajouter d'autres routes deep-link si besoin.
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    _appLinks = null;
  }
}
