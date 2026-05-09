import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// hide PaymentMethod car flutter_stripe exporte son propre type du même nom
import 'package:flutter_stripe/flutter_stripe.dart' hide PaymentMethod;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/config/stripe_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../invoice/data/models/invoice_model.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.invoiceId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _selected;
  bool _isLoading = false;
  String? _error;

  // ── Pay entry point ─────────────────────────────────────────────────────────

  Future<void> _pay() async {
    if (_selected == null || _isLoading) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      if (_selected!.isStripe) {
        await _payWithStripe();
      } else {
        await _payDirect();
      }
    } on StripeException catch (e) {
      // Annulation volontaire de la sheet → pas d'erreur à afficher
      if (e.error.code != FailureCode.Canceled) {
        setState(() => _error = e.error.localizedMessage ?? 'Erreur Stripe');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Direct payment (cash / virement / mobile) ───────────────────────────────

  Future<void> _payDirect() async {
    final repo = ref.read(paymentRepositoryProvider);
    await repo.initDirectPayment(
      invoiceId: widget.invoiceId,
      method: _selected!.apiValue,
    );
    if (mounted) _showSuccess();
  }

  // ── Stripe card payment ──────────────────────────────────────────────────────

  Future<void> _payWithStripe() async {
    final repo = ref.read(paymentRepositoryProvider);

    // 1. Créer le PaymentIntent côté backend
    final intent = await repo.createStripeIntent(widget.invoiceId);

    // 2. Initialiser la Payment Sheet Stripe
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: StripeConfig.merchantName,
        returnURL: StripeConfig.returnUrl,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF6366F1), // AppColors.doctorColor
          ),
          shapes: PaymentSheetShape(
            borderRadius: 12,
          ),
        ),
        billingDetailsCollectionConfiguration:
            const BillingDetailsCollectionConfiguration(
          name: CollectionMode.automatic,
          email: CollectionMode.automatic,
        ),
      ),
    );

    // 3. Afficher la Payment Sheet native Stripe
    //    → Lance 3D Secure si nécessaire automatiquement
    await Stripe.instance.presentPaymentSheet();

    // 4. Confirmer côté backend (re-vérifie avec l'API Stripe)
    await repo.confirmStripePayment(
      invoiceId: widget.invoiceId,
      paymentIntentId: intent.paymentIntentId,
    );

    if (mounted) _showSuccess();
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Régler la facture',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Bandeau montant ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            color: Colors.white,
            child: Column(
              children: [
                Text('Montant à régler',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  '${widget.amount.toStringAsFixed(2)} DT',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text('Facture #${widget.invoiceId}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Liste des méthodes ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionLabel('Paiement en espèces / virement'),
                const SizedBox(height: 8),
                ...PaymentMethod.values
                    .where((m) => !m.isStripe)
                    .map((m) => _MethodTile(
                          method: m,
                          selected: _selected == m,
                          onTap: () =>
                              setState(() { _selected = m; _error = null; }),
                        )),

                const SizedBox(height: 20),
                _SectionLabel('Paiement en ligne sécurisé'),
                const SizedBox(height: 8),
                _MethodTile(
                  method: PaymentMethod.card,
                  selected: _selected == PaymentMethod.card,
                  onTap: () =>
                      setState(() { _selected = PaymentMethod.card; _error = null; }),
                  badge: 'Visa · Mastercard · 3D Secure',
                  highlighted: true,
                ),

                // ── Info Stripe ──────────────────────────────────────────────
                const SizedBox(height: 12),
                if (_selected == PaymentMethod.card)
                  _StripeInfoCard(amount: widget.amount),

                // ── Erreur ───────────────────────────────────────────────────
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Bouton payer ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selected == null || _isLoading) ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.doctorColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          _selected == null
                              ? 'Sélectionnez un mode de paiement'
                              : _selected == PaymentMethod.card
                                  ? 'Payer ${widget.amount.toStringAsFixed(2)} DT par carte'
                                  : 'Confirmer le paiement en ${_selected!.label.toLowerCase()}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Paiement confirmé !',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, fontSize: 19)),
            const SizedBox(height: 8),
            Text(
              '${widget.amount.toStringAsFixed(2)} DT réglés avec succès.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop(); // retour à la liste des factures
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Fermer',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3));
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool highlighted;

  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        highlighted ? AppColors.doctorColor : AppColors.doctorColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? activeColor : AppColors.divider,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icône
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: selected
                    ? activeColor.withValues(alpha: 0.12)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon,
                  color: selected ? activeColor : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? activeColor
                              : AppColors.textPrimary)),
                  if (badge != null)
                    Text(badge!,
                        style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? activeColor.withValues(alpha: 0.7)
                                : AppColors.textSecondary)),
                ],
              ),
            ),
            // Radio
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? activeColor : AppColors.divider,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _StripeInfoCard extends StatelessWidget {
  final double amount;
  const _StripeInfoCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.08),
            const Color(0xFF8B5CF6).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo Stripe simplifié
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('stripe',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5)),
              ),
              const SizedBox(width: 10),
              Text('Paiement sécurisé',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          const _StripeFeatureRow(
            icon: Icons.lock_rounded,
            text: 'Chiffrement SSL 256-bit — données jamais stockées',
          ),
          const SizedBox(height: 6),
          const _StripeFeatureRow(
            icon: Icons.verified_user_rounded,
            text: '3D Secure automatique si requis par votre banque',
          ),
          const SizedBox(height: 6),
          const _StripeFeatureRow(
            icon: Icons.credit_card_rounded,
            text: 'Visa, Mastercard, American Express',
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Carte test Stripe
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Text('Test : 4242 4242 4242 4242 — exp 12/26 — CVC 123',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber.shade800,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripeFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StripeFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6366F1)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
        ],
      );
}
