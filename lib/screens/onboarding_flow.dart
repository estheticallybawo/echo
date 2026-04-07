// ignore_for_file: unused_element_parameter, camel_case_types

import 'package:flutter/material.dart';
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
                          ? GuardianColors.primary
                          : GuardianColors.surfaceSecondary,
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
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: GuardianColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GuardianColors.surfaceSecondary,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: GuardianColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '26 years old. 2021. A fake job offer in Uyo. One last phone call. No one could reach her in time.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: GuardianColors.textSecondary,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Guardian exists so this never happens again.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: GuardianColors.primary,
            ),
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
            'Guardian needs access to keep you safe',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GuardianColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          ...permissions.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GuardianColors.surfaceSecondary,
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
                      activeThumbColor: GuardianColors.primary,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Text(
            'You can change these in Settings anytime.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: GuardianColors.textTertiary,
            ),
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
            'Create a unique phrase you\'ll say to activate Guardian',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GuardianColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'e.g., "I need help now"',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: GuardianColors.textTertiary,
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
                      ? GuardianColors.warning.withOpacity(0.2)
                      : GuardianColors.surfaceSecondary,
                  border: Border.all(
                    color: _isRecording
                        ? GuardianColors.warning
                        : GuardianColors.primary,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording
                          ? GuardianColors.warning
                          : GuardianColors.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording ? 'RECORDING' : 'TAP TO START',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isRecording
                            ? GuardianColors.warning
                            : GuardianColors.primary,
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
                color: GuardianColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: GuardianColors.success),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: GuardianColors.success),
                  const SizedBox(width: 12),
                  Text(
                    'Phrase recorded successfully',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: GuardianColors.success,
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
              color: GuardianColors.textTertiary,
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
                        ? GuardianColors.primary.withOpacity(0.1)
                        : GuardianColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? GuardianColors.primary
                          : GuardianColors.textPrimary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: GuardianColors.surfaceTertiary,
                        ),
                        child: const Center(child: Icon(Icons.person)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(name,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: GuardianColors.primary),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Public Alert',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-post to public networks?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GuardianColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GuardianColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When activated, Guardian can:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...[
                  'Tweet your location & status',
                  'Post to emergency networks',
                  'Share your live situation',
                ].map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            color: GuardianColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Checkbox(
                value: _autoPostConsent,
                onChanged: (value) {
                  setState(() {
                    _autoPostConsent = value ?? false;
                  });
                },
                activeColor: GuardianColors.primary,
              ),
              Expanded(
                child: Text(
                  'I consent to public alerts',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
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
  String _selectedSound = 'default';

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
              color: GuardianColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          ...['Serene Chime', 'Digital Bell', 'Subtle Pulsing']
              .map((sound) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSound = sound;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _selectedSound == sound
                        ? GuardianColors.primary.withOpacity(0.1)
                        : GuardianColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedSound == sound
                          ? GuardianColors.primary
                          : GuardianColors.textPrimary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up),
                      const SizedBox(width: 12),
                      Expanded(child: Text(sound)),
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () {},
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

/// Page 7: System Test Drill
class _OnboardingPage7_SystemTest extends StatefulWidget {
  const _OnboardingPage7_SystemTest({super.key});

  @override
  State<_OnboardingPage7_SystemTest> createState() =>
      _OnboardingPage7_SystemTestState();
}

class _OnboardingPage7_SystemTestState
    extends State<_OnboardingPage7_SystemTest> {
  bool _testComplete = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'System Test',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 32),
          if (!_testComplete)
            Column(
              children: [
                Icon(
                  Icons.flash_on,
                  size: 60,
                  color: GuardianColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Run a test to verify everything works',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GuardianColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _testComplete = true;
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START TEST DRILL'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: GuardianColors.success,
                ),
                const SizedBox(height: 24),
                Text(
                  'Guardian is ready',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: GuardianColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Text(
                  'All systems tested and verified.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
