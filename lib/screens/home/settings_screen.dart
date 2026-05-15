import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/user_preferences_provider.dart';
import '../../services/model/model_catalog.dart';
import '../../services/model/model_download_service.dart';
import '../../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool micEnabled = true;
  bool locationEnabled = true;
  bool contactsEnabled = true;
  bool notificationsEnabled = true;
  bool alwaysListeningEnabled = true;
  bool cloudProcessingEnabled = false;
  bool saveVoiceSnippetsEnabled = false;
  final ModelDownloadService _modelDownloadService = ModelDownloadService();
  ModelDownloadState? _modelState;
  ModelCatalogEntry _selectedModel = ModelCatalog.gemma4E2bQ5;

  @override
  Widget build(BuildContext context) {
    final userPrefs = context.watch<UserPreferencesProvider>();
    final displayName = userPrefs.fullName ?? 'Ada Chukwu';
    final displayPhone = userPrefs.phone ?? '+234 812 345 6789';

    return Scaffold(
      backgroundColor: const Color(0xFF02091A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: [Color(0xFF0F3169), Color(0xFF02091A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (Navigator.canPop(context))
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Account'),
                const SizedBox(height: 16),
                _buildProfileCard(displayName, displayPhone),
                const SizedBox(height: 40),
                _buildSectionHeader('Updates'),
                const SizedBox(height: 16),
                _buildAiUpdateCard(),
                const SizedBox(height: 40),
                _buildSectionHeader('Background Protection'),
                const SizedBox(height: 16),
                _buildToggleCard(
                  Icons.hearing_rounded,
                  'Always Listening',
                  'Continuously listens for your safety phrase while active.',
                  alwaysListeningEnabled,
                  (v) => setState(() => alwaysListeningEnabled = v),
                ),
                _buildToggleCard(
                  Icons.cloud_outlined,
                  'Cloud Processing',
                  'Allow optional cloud voice/TTS and bridge processing for the demo.',
                  cloudProcessingEnabled,
                  (v) => setState(() => cloudProcessingEnabled = v),
                ),
                _buildToggleCard(
                  Icons.audio_file_outlined,
                  'Save Voice Snippets',
                  'Keep raw audio clips for review. If off, audio is deleted after analysis.',
                  saveVoiceSnippetsEnabled,
                  (v) => setState(() => saveVoiceSnippetsEnabled = v),
                ),
                _buildToggleCard(
                  Icons.mic_none_rounded,
                  'Microphone',
                  'Used for background listening only when Echo is active to detect distress.',
                  micEnabled,
                  (v) => setState(() => micEnabled = v),
                ),
                _buildToggleCard(
                  Icons.location_on_outlined,
                  'Location',
                  'So your contacts know exactly where to find you in an emergency.',
                  locationEnabled,
                  (v) => setState(() => locationEnabled = v),
                ),
                _buildToggleCard(
                  Icons.contacts_outlined,
                  'Contacts',
                  'Lets you choose people who should be alerted when you need help.',
                  contactsEnabled,
                  (v) => setState(() => contactsEnabled = v),
                ),
                _buildToggleCard(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  'So you receive updates when someone responds to your alert.',
                  notificationsEnabled,
                  (v) => setState(() => notificationsEnabled = v),
                ),
                const SizedBox(height: 40),
                _buildSectionHeader('Permissions & Consent'),
                const SizedBox(height: 16),
                _buildPermissionCard(),
                const SizedBox(height: 40),
                _buildSectionHeader('Emergency Phase'),
                const SizedBox(height: 16),
                _buildPhaseCard(),
                const SizedBox(height: 40),
                _buildSectionHeader('Legal'),
                const SizedBox(height: 16),
                _buildActionCard(
                  Icons.privacy_tip_outlined,
                  'Terms & Privacy',
                  'Read our commitment to your security.',
                  () {
                    Navigator.pushNamed(context, '/terms-privacy');
                  },
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        'Microphone permission is used for voice SOS and distress detection flows. Background usage runs only when enabled. '
        'Cloud processing can send audio/text to configured demo providers such as ElevenLabs or Telegram. You can revoke permissions or disable these features at any time in system settings.',
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAiUpdateCard() {
    final model = _selectedModel;
    final compatibility = _modelDownloadService.checkCompatibility(
      model,
      const DeviceProfile(availableRamGb: 12, freeStorageGb: 8),
    );
    final state = _modelState?.model.id == model.id ? _modelState : null;
    final status = state?.status ?? ModelDownloadStatus.notInstalled;
    final progress = state?.progress ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Download Path',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _bulletPoint(
            'Preview compatible Gemma model options for APK testing.',
          ),
          _bulletPoint(
            'Keep Android/on-device runtime work separate from Chrome demo.',
          ),
          _bulletPoint('Show RAM and storage requirements before a download.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ModelCatalog.all.map((option) {
              final selected = option.id == model.id;
              return ChoiceChip(
                selected: selected,
                label: Text(
                  option.recommended
                      ? '${option.displayName} *'
                      : option.displayName,
                ),
                labelStyle: GoogleFonts.poppins(
                  color: selected
                      ? EchoColors.primaryDark
                      : const Color(0xFFF2F3F5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: const Color.fromARGB(
                  255,
                  8,
                  87,
                  255,
                ).withOpacity(0.2),
                backgroundColor: EchoColors.primaryDark,
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
                onSelected: (_) => setState(() => _selectedModel = option),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        model.displayName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${model.sizeGb.toStringAsFixed(1)} GB',
                      style: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Version: ${model.version} - ${status.name}',
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${model.description} Quantized ${model.quantization} - Requires ${model.minRamGb.toStringAsFixed(0)}GB RAM',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  compatibility.isCompatible
                      ? 'Chrome demo uses your local server; APK exposes this download path.'
                      : compatibility.reason ?? 'Device is not compatible.',
                  style: GoogleFonts.poppins(
                    color: Colors.amber.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (status == ModelDownloadStatus.downloading) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(
                        EchoColors.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        compatibility.isCompatible &&
                            status != ModelDownloadStatus.downloading
                        ? _simulateModelDownload
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      status == ModelDownloadStatus.installed
                          ? 'Installed for APK Demo'
                          : status == ModelDownloadStatus.downloading
                          ? 'Downloading... ${(progress * 100).round()}%'
                          : 'Preview Download Path',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateModelDownload() async {
    await for (final state in _modelDownloadService.simulateDownload(
      _selectedModel,
    )) {
      if (!mounted) return;
      setState(() => _modelState = state);
    }
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleCard(
    IconData icon,
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFffffff),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFffffff).withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: EchoColors.switchOn,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: EchoColors.switchOff,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String displayName, String displayPhone) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    displayPhone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFffffff).withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFffffff),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '"Ditto"',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: _showDittoInfo,
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFffffff),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your active emergency duress code. Enter this if you are forced to deactivate Echo.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Change Phase',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDittoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F3169),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'What is Ditto?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Ditto is your secret duress code. If an attacker forces you to turn off Echo, enter "Ditto" instead of your real code. The app can appear to turn off while starting the trusted-contact escalation path in the background.',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white38,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
