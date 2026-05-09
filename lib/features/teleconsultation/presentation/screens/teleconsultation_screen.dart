import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/auth_state.dart';

const _kVideoColor = Color(0xFF4F46E5); // indigo

class TeleconsultationScreen extends ConsumerStatefulWidget {
  final int appointmentId;
  final String doctorName;
  final String patientName;
  final DateTime scheduledAt;

  const TeleconsultationScreen({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.patientName,
    required this.scheduledAt,
  });

  @override
  ConsumerState<TeleconsultationScreen> createState() =>
      _TeleconsultationScreenState();
}

class _TeleconsultationScreenState
    extends ConsumerState<TeleconsultationScreen> {
  final _jitsi = JitsiMeet();
  bool _joining = false;
  bool _inCall = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _jitsi.hangUp();
    super.dispose();
  }

  Future<void> _joinMeeting() async {
    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final displayName = user?.fullName ?? 'Utilisateur';
    final email = user?.email ?? '';

    setState(() => _joining = true);

    try {
      await _jitsi.join(
        JitsiMeetConferenceOptions(
          serverURL: 'https://meet.jit.si',
          room: 'medicare-apt-${widget.appointmentId}',
          configOverrides: {
            'startWithAudioMuted': false,
            'startWithVideoMuted': false,
            'subject': 'Téléconsultation Medicare',
            'prejoinConfig': {'enabled': false},
          },
          featureFlags: {
            'welcomepage.enabled': false,
            'call-integration.enabled': false,
            'pip.enabled': true,
          },
          userInfo: JitsiMeetUserInfo(
            displayName: displayName,
            email: email,
          ),
        ),
        JitsiMeetEventListener(
          conferenceJoined: (url) {
            if (mounted) setState(() => _inCall = true);
          },
          conferenceTerminated: (url, error) {
            if (mounted) setState(() { _inCall = false; _joining = false; });
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM yyyy • HH:mm', 'fr_FR');
    final isToday =
        DateUtils.isSameDay(widget.scheduledAt, DateTime.now());
    final minutesUntil =
        widget.scheduledAt.difference(DateTime.now()).inMinutes;
    final isNow = minutesUntil <= 15 && minutesUntil >= -60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Téléconsultation'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Video icon banner ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _kVideoColor,
                    _kVideoColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam_rounded,
                      color: Colors.white, size: 60),
                  const SizedBox(height: 12),
                  Text('Consultation vidéo',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isNow ? '🟢 Maintenant' : fmt.format(widget.scheduledAt),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Participants ─────────────────────────────────────────
            _ParticipantCard(
              icon: Icons.medical_services_rounded,
              role: 'Médecin',
              name: 'Dr. ${widget.doctorName}',
              color: AppColors.doctorColor,
            ),
            const SizedBox(height: 12),
            _ParticipantCard(
              icon: Icons.person_rounded,
              role: 'Patient',
              name: widget.patientName,
              color: AppColors.patientColor,
            ),

            const SizedBox(height: 24),

            // ── Room info ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kVideoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.meeting_room_rounded,
                        color: _kVideoColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Salle de réunion sécurisée',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(
                          'medicare-apt-${widget.appointmentId}',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textHint,
                              letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Timing notice ────────────────────────────────────────
            if (!isNow && !isToday)
              _InfoBanner(
                icon: Icons.schedule_rounded,
                message:
                    'Le bouton de connexion sera actif 15 minutes avant le début de la consultation.',
                color: AppColors.warning,
              ),
            if (isToday && !isNow && minutesUntil > 15)
              _InfoBanner(
                icon: Icons.schedule_rounded,
                message:
                    'Votre consultation est prévue aujourd\'hui à ${DateFormat('HH:mm').format(widget.scheduledAt)}. '
                    'Vous pourrez rejoindre 15 min avant.',
                color: AppColors.primary,
              ),
            if (_inCall)
              _InfoBanner(
                icon: Icons.check_circle_rounded,
                message: 'Vous êtes en consultation. L\'interface vidéo est active.',
                color: AppColors.success,
              ),

            const SizedBox(height: 24),

            // ── Join button ──────────────────────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: (isNow || _inCall) && !_joining
                    ? _joinMeeting
                    : null,
                icon: _joining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _inCall
                            ? Icons.videocam_rounded
                            : Icons.video_call_rounded,
                        size: 22),
                label: Text(
                  _joining
                      ? 'Connexion en cours…'
                      : _inCall
                          ? 'Reprendre la consultation'
                          : 'Rejoindre la consultation',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVideoColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.textHint.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tips ─────────────────────────────────────────────────
            _InfoBanner(
              icon: Icons.tips_and_updates_rounded,
              message:
                  'Conseils : Utilisez une connexion Wi-Fi, placez-vous dans un endroit calme et bien éclairé.',
              color: _kVideoColor,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ParticipantCard extends StatelessWidget {
  final IconData icon;
  final String role;
  final String name;
  final Color color;

  const _ParticipantCard({
    required this.icon,
    required this.role,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary)),
                Text(name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ],
        ),
      );
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _InfoBanner(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
            ),
          ],
        ),
      );
}
