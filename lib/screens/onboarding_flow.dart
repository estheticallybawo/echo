// ignore_for_file: unused_element_parameter, camel_case_types

import 'package:flutter/material.dart';
import '../services/llama_config.dart';
import '../services/llama_threat_service.dart';
import '../theme.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(7, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: index <= _currentPage
                          ? EchoColors.primary
                          : EchoColors.surfaceSecondary,
                    ),
                  ),
                );
              }),
            ),
          ),

          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _OnboardingPage1_HinyStory(),
                _OnboardingPage2_Permissions(),
                _OnboardingPage3_VoicePhrase(),
                _OnboardingPage4_InnerCircle(),
                _OnboardingPage5_AutoPost(),
                _OnboardingPage6_ConfirmationSounds(),
                _OnboardingPage7_SystemTest(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goToPreviousPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToNextPage,
                    child: Text(_currentPage == 6 ? 'Complete' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 1: Hiny's Story
class _OnboardingPage1_HinyStory extends StatelessWidget {
  const _OnboardingPage1_HinyStory({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Iniubong "Hiny" Umoren',
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(color: EchoColors.primary),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EchoColors.surfaceSecondary,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: EchoColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '26 years old. 2021. A fake job offer in Uyo. One last phone call. No one could reach her in time.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: EchoColors.textSecondary,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Echo exists so this never happens again.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: EchoColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

/// Page 2: Permissions
class _OnboardingPage2_Permissions extends StatefulWidget {
  const _OnboardingPage2_Permissions({super.key});

  @override
  State<_OnboardingPage2_Permissions> createState() =>
      _OnboardingPage2_PermissionsState();
}

class _OnboardingPage2_PermissionsState
    extends State<_OnboardingPage2_Permissions> {
  final Map<String, bool> permissions = {
    'Location': false,
    'Microphone': false,
    'Contacts': false,
    'Notifications': false,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'App Permissions',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Echo needs access to keep you safe',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          ...permissions.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EchoColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Switch(
                      value: permissions[entry.key]!,
                      onChanged: (value) {
                        setState(() {
                          permissions[entry.key] = value;
                        });
                      },
                      activeThumbColor: EchoColors.primary,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'You can change these in Settings anytime.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: EchoColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Page 3: Voice Phrase Recording
class _OnboardingPage3_VoicePhrase extends StatefulWidget {
  const _OnboardingPage3_VoicePhrase({super.key});

  @override
  State<_OnboardingPage3_VoicePhrase> createState() =>
      _OnboardingPage3_VoicePhraseState();
}

class _OnboardingPage3_VoicePhraseState
    extends State<_OnboardingPage3_VoicePhrase> {
  bool _isRecording = false;
  bool _hasRecorded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Your Safety Phrase',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a unique phrase you\'ll say to activate Echo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'e.g., "I need help now"',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EchoColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRecording = !_isRecording;
                  if (_isRecording == false) {
                    _hasRecorded = true;
                  }
                });
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? EchoColors.warning.withOpacity(0.2)
                      : EchoColors.surfaceSecondary,
                  border: Border.all(
                    color: _isRecording
                        ? EchoColors.warning
                        : EchoColors.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording
                          ? EchoColors.warning
                          : EchoColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording ? 'RECORDING' : 'TAP TO START',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isRecording
                            ? EchoColors.warning
                            : EchoColors.primary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (_hasRecorded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EchoColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EchoColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: EchoColors.success),
                  const SizedBox(width: 12),
                  Text(
                    'Phrase recorded successfully',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EchoColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Page 4: Inner Circle Contacts
class _OnboardingPage4_InnerCircle extends StatefulWidget {
  const _OnboardingPage4_InnerCircle({super.key});

  @override
  State<_OnboardingPage4_InnerCircle> createState() =>
      _OnboardingPage4_InnerCircleState();
}

class _OnboardingPage4_InnerCircleState
    extends State<_OnboardingPage4_InnerCircle> {
  final List<String> _selectedContacts = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Inner Circle',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Who\'ll be notified immediately?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          ...['Mom', 'Sister', 'Best Friend', 'Trusted colleague'].map((name) {
            final isSelected = _selectedContacts.contains(name);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedContacts.remove(name);
                    } else {
                      _selectedContacts.add(name);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EchoColors.primary.withOpacity(0.1)
                        : EchoColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? EchoColors.primary
                          : EchoColors.textPrimary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EchoColors.surfaceTertiary,
                        ),
                        child: const Center(child: Icon(Icons.person)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: EchoColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Page 5: Auto-Post Consent
class _OnboardingPage5_AutoPost extends StatefulWidget {
  const _OnboardingPage5_AutoPost({super.key});

  @override
  State<_OnboardingPage5_AutoPost> createState() =>
      _OnboardingPage5_AutoPostState();
}

class _OnboardingPage5_AutoPostState extends State<_OnboardingPage5_AutoPost> {
  bool _autoPostConsent = false;
  bool _twitterConnected = false;
  bool _isConnectingTwitter = false;

  // Post template customization state
  late TextEditingController _postTemplateController;
  bool _includeLocation = true;
  bool _includeContactInfo = false;

  @override
  void initState() {
    super.initState();
    _postTemplateController = TextEditingController(
      text: "{Username} needs urgent help, she/he is in a {analyzed situation} last live location is at {location} if you can do much please tag anyone who can, tweet by Echo"
          
    );
  }

  @override
  void dispose() {
    _postTemplateController.dispose();
    super.dispose();
  }

  Future<void> _connectTwitter() async {
    setState(() {
      _isConnectingTwitter = true;
    });

    // PLACEHOLDER: Implement Twitter OAuth 2.0 flow here
    // Expected behavior:
    // 1. Launch Twitter identity provider (e.g., flutter_appauth)
    // 2. User authorizes Echo app permissions
    // 3. Store access token in secure storage
    // 4. Verify token with Twitter API
    // 5. Display success/failure

    // For now, simulate OAuth flow with 2-second delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _twitterConnected = true;
        _isConnectingTwitter = false;
      });
    }
  }

  String _buildPreviewPost() {
    String preview = _postTemplateController.text;

    // Replace placeholders with sample values
    preview = preview.replaceAll(
      '[LOCATION]',
      _includeLocation ? 'Downtown, City' : '[Your Location]',
    );
    preview = preview.replaceAll('[PANIC_LEVEL]', '8');

    if (_includeContactInfo) {
      preview = preview.replaceAll(
        '[CONTACT_INFO]',
        '+1 (555) 123-4567 Emergency\n',
      );
    } else {
      preview = preview.replaceAll('[CONTACT_INFO]', '');
    }

    return preview;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Public Alert Network',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Set up auto-posting with Gemma 4',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),

          // SECTION 2: Template Customization
          Text(
            'Customize Your Post Template',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: EchoColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Post template editor
          Text(
            'Post Template (use [PLACEHOLDERS])',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: EchoColors.textSecondary.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _postTemplateController,
              maxLines: 6,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText:
                    'Enter your post template with placeholders like [LOCATION], [THREAT_LEVEL], [PANIC_LEVEL]',
                hintStyle: TextStyle(
                  color: EchoColors.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),

          // Template options
          CheckboxListTile(
            value: _includeLocation,
            onChanged: (value) {
              setState(() {
                _includeLocation = value ?? false;
              });
            },
            title: Text(
              'Include location in post',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _includeContactInfo,
            onChanged: (value) {
              setState(() {
                _includeContactInfo = value ?? false;
              });
            },
            title: Text(
              'Include emergency contact info',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            subtitle: Text(
              '(Phone number will be visible to public)',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: EchoColors.warning),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 24),

          // SECTION 3: Live Preview
          Text(
            'Step 2: Preview Live Example',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: EchoColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EchoColors.success.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EchoColors.success.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: EchoColors.success,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Post (when posted)',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'During emergency',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: EchoColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _buildPreviewPost(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    fontFamily: 'Courier',
                    color: EchoColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: EchoColors.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This preview updates as you customize your template',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Twitter OAuth Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _twitterConnected
                  ? EchoColors.success.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _twitterConnected
                    ? EchoColors.success
                    : Colors.blue.shade400,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                if (!_twitterConnected)
                  ElevatedButton.icon(
                    onPressed: _isConnectingTwitter ? null : _connectTwitter,
                    icon: const Icon(Icons.link),
                    label: _isConnectingTwitter
                        ? const Text('CONNECTING...')
                        : const Text('CONNECT TWITTER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: EchoColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Twitter Connected',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: EchoColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _twitterConnected = false;
                          });
                        },
                        child: Text(
                          'Disconnect',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: EchoColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Final consent checkbox
          Row(
            children: [
              Checkbox(
                value: _autoPostConsent,
                onChanged: (value) {
                  setState(() {
                    _autoPostConsent = value ?? false;
                  });
                },
                activeColor: EchoColors.primary,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I approve this template for auto-posting',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gemma 4 will generate posts using this template during emergencies',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: EchoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EchoColors.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔐 Your Privacy',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: EchoColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Twitter OAuth uses secure authentication. Your template is stored locally and only shared when you approve during emergency. You can edit or reject any post before it\'s sent.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Page 6: Confirmation Sounds
class _OnboardingPage6_ConfirmationSounds extends StatefulWidget {
  const _OnboardingPage6_ConfirmationSounds({super.key});

  @override
  State<_OnboardingPage6_ConfirmationSounds> createState() =>
      _OnboardingPage6_ConfirmationSoundsState();
}

class _OnboardingPage6_ConfirmationSoundsState
    extends State<_OnboardingPage6_ConfirmationSounds> {
  String _selectedSound = 'Serene Chime';
  bool _vibrationEnabled = true;
  bool _isPreviewPlaying = false;

  Future<void> _playAudioPreview(String soundName) async {
    // PLACEHOLDER: Developers will wire AudioService here
    // Expected behavior:
    // 1. Load pre-recorded confirmation sound from assets
    // 2. Play sound for 1-2 seconds
    // 3. Trigger haptic feedback simultaneously

    setState(() {
      _isPreviewPlaying = true;
    });

    // Simulate audio playback with haptic feedback
    if (_vibrationEnabled) {
      // Would call: HapticFeedback.mediumImpact()
      // This is a placeholder showing where haptic would be triggered
    }

    // Simulate 2-second audio playback
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isPreviewPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Confirmation Sounds',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hear alerts when important events happen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),

          // Audio selection cards
          ...['Serene Chime', 'Digital Bell', 'Subtle Pulsing'].map((sound) {
            bool isSelected = _selectedSound == sound;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSound = sound;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EchoColors.primary.withOpacity(0.1)
                        : EchoColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? EchoColors.primary
                          : EchoColors.textPrimary.withOpacity(0.08),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EchoColors.primary
                                  : EchoColors.textSecondary.withOpacity(
                                      0.2,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.volume_up,
                              color: isSelected
                                  ? Colors.white
                                  : EchoColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sound,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? EchoColors.primary
                                            : EchoColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getSoundDescription(sound),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: EchoColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPreviewPlaying && isSelected
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: isSelected
                                  ? EchoColors.primary
                                  : EchoColors.textSecondary,
                            ),
                            onPressed: () => _playAudioPreview(sound),
                          ),
                        ],
                      ),

                      // Audio visualization bars
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              10,
                              (index) => Container(
                                width: 3,
                                height: _isPreviewPlaying
                                    ? (8 + (index * 2)).toDouble()
                                    : 8,
                                decoration: BoxDecoration(
                                  color: EchoColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Haptic feedback toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EchoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: EchoColors.textPrimary.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EchoColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.vibration,
                    color: EchoColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haptic Feedback',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vibration along with sounds',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: EchoColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  },
                  activeColor: EchoColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Implementation note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EchoColors.textSecondary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🔊 Audio files play via ConfirmationSoundSystem. Haptic patterns trigger via native channels (Android Vibrator, iOS CoreHaptics).',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSoundDescription(String sound) {
    switch (sound) {
      case 'Serene Chime':
        return 'Calm, melodic alert (best for focus)';
      case 'Digital Bell':
        return 'Sharp, modern tone (high clarity)';
      case 'Subtle Pulsing':
        return 'Soft, rhythmic pattern (discreet)';
      default:
        return 'Customizable confirmation sound';
    }
  }
}

/// Page 7: System Test Drill
class _OnboardingPage7_SystemTest extends StatefulWidget {
  const _OnboardingPage7_SystemTest({super.key});

  @override
  State<_OnboardingPage7_SystemTest> createState() =>
      _OnboardingPage7_SystemTestState();
}

class _OnboardingPage7_SystemTestState
    extends State<_OnboardingPage7_SystemTest> {
  final LlamaThreatService _gemmaService = LlamaThreatService();

  bool _isRunning = false;
  bool _testComplete = false;
  bool _testPassed = false;
  String _overallStatus = 'Not started';
  String? _errorMessage;
  Map<String, dynamic>? _drillResult;

  final Map<String, String> _stepStates = {
    'health': 'pending',
    'warmup': 'pending',
    'inference': 'pending',
  };

  final Map<String, int> _stepTimingsMs = {
    'health': 0,
    'warmup': 0,
    'inference': 0,
    'total': 0,
  };

  Future<void> _runSystemDrill() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _testComplete = false;
      _testPassed = false;
      _overallStatus = 'Running live drill...';
      _errorMessage = null;
      _drillResult = null;
      _stepStates['health'] = 'pending';
      _stepStates['warmup'] = 'pending';
      _stepStates['inference'] = 'pending';
      _stepTimingsMs['health'] = 0;
      _stepTimingsMs['warmup'] = 0;
      _stepTimingsMs['inference'] = 0;
      _stepTimingsMs['total'] = 0;
    });

    final totalStopwatch = Stopwatch()..start();

    try {
      // Step 1: Real server health check.
      setState(() {
        _stepStates['health'] = 'running';
        _overallStatus = 'Checking Gemma server health...';
      });

      final healthStopwatch = Stopwatch()..start();
      final isHealthy = await LlamaConfig.isServerHealthy();
      healthStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['health'] = healthStopwatch.elapsedMilliseconds;
      });

      if (!isHealthy) {
        setState(() {
          _stepStates['health'] = 'failure';
          _overallStatus = 'Gemma server offline';
          _errorMessage =
              'Unable to reach Gemma at ${LlamaConfig.activeHost}. Start llama-server and retry.';
        });
        return;
      }

      setState(() {
        _stepStates['health'] = 'success';
      });

      // Step 2: Warm-up call to reduce first-token latency.
      setState(() {
        _stepStates['warmup'] = 'running';
        _overallStatus = 'Warming up Gemma...';
      });

      final warmupStopwatch = Stopwatch()..start();
      final warmupPrompt =
          'This is an onboarding warm-up drill ping. Return emergency assessment JSON now.';
      final warmupResult = await _gemmaService.assessThreat(
        warmupPrompt,
        maxTokens: 40,
      );
      warmupStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['warmup'] = warmupStopwatch.elapsedMilliseconds;
      });

      final warmupThreat = (warmupResult['threat'] ?? 'unknown').toString();
      if (warmupThreat == 'unknown') {
        setState(() {
          _stepStates['warmup'] = 'failure';
          _overallStatus = 'Gemma warm-up failed';
          _errorMessage = 'Warm-up response was not parseable JSON.';
        });
        return;
      }

      setState(() {
        _stepStates['warmup'] = 'success';
      });

      // Step 3: Run an actual onboarding drill inference.
      setState(() {
        _stepStates['inference'] = 'running';
        _overallStatus = 'Running live threat drill...';
      });

      final inferenceStopwatch = Stopwatch()..start();
      final drillInput =
          'This is a drill. I am safe. Simulate a report: I think someone is following me from a black car while I walk home.';
      final drillResult = await _gemmaService.assessThreat(
        drillInput,
        maxTokens: 56,
      );
      inferenceStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['inference'] = inferenceStopwatch.elapsedMilliseconds;
      });

      final drillThreat = (drillResult['threat'] ?? 'unknown').toString();
      final drillConfidence = drillResult['confidence'];
      final validConfidence = drillConfidence is num;

      if (drillThreat == 'unknown' || !validConfidence) {
        setState(() {
          _stepStates['inference'] = 'failure';
          _overallStatus = 'Drill inference failed';
          _errorMessage = 'Gemma returned an invalid drill payload.';
        });
        return;
      }

      setState(() {
        _stepStates['inference'] = 'success';
        _drillResult = drillResult;
        _testPassed = true;
        _overallStatus = 'Gemma active: live drill passed';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _overallStatus = 'Drill failed with exception';
        _errorMessage = e.toString();

        if (_stepStates['health'] == 'running') {
          _stepStates['health'] = 'failure';
        } else if (_stepStates['warmup'] == 'running') {
          _stepStates['warmup'] = 'failure';
        } else if (_stepStates['inference'] == 'running') {
          _stepStates['inference'] = 'failure';
        }
      });
    } finally {
      totalStopwatch.stop();

      if (!mounted) return;
      setState(() {
        _stepTimingsMs['total'] = totalStopwatch.elapsedMilliseconds;
        _testComplete = true;
        _isRunning = false;
      });
    }
  }

  IconData _statusIcon(String state) {
    switch (state) {
      case 'running':
        return Icons.autorenew;
      case 'success':
        return Icons.check_circle;
      case 'failure':
        return Icons.error;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  Color _statusColor(String state) {
    switch (state) {
      case 'running':
        return EchoColors.primary;
      case 'success':
        return EchoColors.success;
      case 'failure':
        return EchoColors.warning;
      default:
        return EchoColors.textTertiary;
    }
  }

  String _statusText(String state) {
    switch (state) {
      case 'running':
        return 'Running';
      case 'success':
        return 'Passed';
      case 'failure':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  Widget _buildStepCard({
    required String stepKey,
    required String title,
    required String subtitle,
  }) {
    final state = _stepStates[stepKey] ?? 'pending';
    final timing = _stepTimingsMs[stepKey] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(state).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(state), color: _statusColor(state)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _statusText(state),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _statusColor(state),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timing > 0 ? '${timing} ms' : '--',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: EchoColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text('System Test', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 24),
          Text(
            'Live Gemma readiness report',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildStepCard(
            stepKey: 'health',
            title: 'Step 1 - Server Health Check',
            subtitle: 'Verifies Gemma endpoint is reachable.',
          ),
          _buildStepCard(
            stepKey: 'warmup',
            title: 'Step 2 - Warm-up Call',
            subtitle: 'Runs a small prompt to reduce cold-start latency.',
          ),
          _buildStepCard(
            stepKey: 'inference',
            title: 'Step 3 - Live Drill Inference',
            subtitle: 'Analyzes a drill scenario and validates JSON output.',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _testPassed
                  ? EchoColors.success.withOpacity(0.1)
                  : EchoColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _testPassed
                    ? EchoColors.success
                    : EchoColors.textSecondary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _testPassed ? Icons.check_circle : Icons.info,
                      color: _testPassed
                          ? EchoColors.success
                          : EchoColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _overallStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _testPassed
                              ? EchoColors.success
                              : EchoColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total activation time: ${_stepTimingsMs['total']} ms',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: EchoColors.textSecondary,
                  ),
                ),
                if (_drillResult != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Gemma is now active | Confidence: ${_drillResult!['confidence']}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EchoColors.textSecondary,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: EchoColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _isRunning ? null : _runSystemDrill,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _isRunning
                  ? 'RUNNING LIVE DRILL...'
                  : _testComplete
                      ? 'RUN DRILL AGAIN'
                      : 'START TEST DRILL',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _testPassed
                ? 'Gemma is active and onboarding drill is using real inference.'
                : 'Run the drill to verify Gemma activity in real time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EchoColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
