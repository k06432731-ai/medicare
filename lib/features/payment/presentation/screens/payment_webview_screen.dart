import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// WebView pour le paiement Konnect.
///
/// Ouvre le `payUrl` fourni par Konnect et intercepte la redirection vers
/// `medicare://payment/success?ref=xxx` ou `medicare://payment/fail`.
///
/// Retourne via `Navigator.pop` :
/// - `String paymentRef` en cas de succès (le `?ref=` parsé)
/// - `null` en cas d'échec / annulation
class PaymentWebviewScreen extends StatefulWidget {
  final String payUrl;
  final String paymentRef;

  const PaymentWebviewScreen({
    super.key,
    required this.payUrl,
    required this.paymentRef,
  });

  @override
  State<PaymentWebviewScreen> createState() => _PaymentWebviewScreenState();
}

class _PaymentWebviewScreenState extends State<PaymentWebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            // Intercepte la redirection deep-link Medicare
            if (url.startsWith('medicare://payment/success')) {
              final uri = Uri.tryParse(url);
              final ref = uri?.queryParameters['ref'] ?? widget.paymentRef;
              if (mounted) Navigator.of(context).pop(ref);
              return NavigationDecision.prevent;
            }
            if (url.startsWith('medicare://payment/fail')) {
              if (mounted) Navigator.of(context).pop(null);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.payUrl));
  }

  Future<bool> _confirmExit() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Annuler le paiement ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'Si vous quittez maintenant, votre paiement ne sera pas validé.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmExit()) {
          if (mounted) navigator.pop(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Paiement Konnect',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await _confirmExit()) {
                if (mounted) navigator.pop(null);
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.doctorColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
