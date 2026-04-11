import 'package:flutter/material.dart';
import '../theme.dart';

class PostConfirmationScreen extends StatefulWidget {
  final String userName;
  final String situation;
  final String location;
  final String postContent;
  final VoidCallback onDismiss;
  final VoidCallback? onViewPost; // Navigate to Echo's X page

  const PostConfirmationScreen({
    super.key,
    required this.userName,
    required this.situation,
    required this.location,
    required this.postContent,
    required this.onDismiss,
    this.onViewPost,
  });

  @override
  State<PostConfirmationScreen> createState() => _PostConfirmationScreenState();
}

class _PostConfirmationScreenState extends State<PostConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Header
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [EchoColors.primary, EchoColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Success Icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Alert Posted Successfully',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your safety alert has been shared on Echo',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Post Preview
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Posted to Echo',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: EchoColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Tweet Content Preview
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: EchoColors.surfaceSecondary,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // X/Twitter Handle
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: EchoColors.primary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.safety_check,
                                    size: 20,
                                    color: EchoColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Echo Safety Network',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '@EchoSafetyNet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: EchoColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Post Content
                            Text(
                              widget.postContent,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Box
                      Container(
                        decoration: BoxDecoration(
                          color: EchoColors.primary.withOpacity(0.1),
                          border: Border.all(
                            color: EchoColors.primary.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: EchoColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your network has been notified and will help coordinate support.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: EchoColors.primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // View Post Button (optional)
                      if (widget.onViewPost != null)
                        ElevatedButton(
                          onPressed: widget.onViewPost,
                          child: const Text('View on Echo'),
                        ),
                      if (widget.onViewPost != null) const SizedBox(height: 12),

                      // Dismiss Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EchoColors.primary,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss();
                        },
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
