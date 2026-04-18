import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen settings for managing AI models
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  bool _offlineAIDownloaded = false; // Replace with actual state
  bool _e4bDownloaded = false;
  bool _autoUpdate = true;
  bool _darkModeEnabled = false;
  int _cacheSizeBytes = 157286400; // 150 MB (example)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Offline AI Section
            _buildAIModelCard(
              context,
              title: 'Offline AI',
              version: '1.2.0',
              size: '2.6 GB',
              isDownloaded: _offlineAIDownloaded,
              description: 'Standard threat assessment',
              onTap: _offlineAIDownloaded
                  ? () => _showManageDialog(context, 'Offline AI')
                  : () => _showDownloadDialog(context, 'Offline AI'),
              onDelete: _offlineAIDownloaded
                  ? () => _showDeleteConfirm(context, 'Offline AI')
                  : null,
            ),
            const SizedBox(height: 20),

            // Enhanced AI (E4B) Section
            _buildAIModelCard(
              context,
              title: 'Enhanced AI (E4B)',
              version: 'Not Installed',
              size: '3.6 GB',
              isDownloaded: _e4bDownloaded,
              description: 'Better pattern recognition\n(Requires 12GB RAM)',
              warning: ' May impact battery life',
              onTap: _e4bDownloaded
                  ? () => _showManageDialog(context, 'Enhanced AI')
                  : () => _showDownloadDialog(context, 'Enhanced AI'),
              onDelete: _e4bDownloaded
                  ? () => _showDeleteConfirm(context, 'Enhanced AI')
                  : null,
            ),
            const SizedBox(height: 32),

            // Settings Section
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Auto-update toggle
            _buildSettingTile(
              context,
              icon: Icons.system_update_outlined,
              title: 'Auto-Update Models',
              subtitle: 'Update to latest AI when available',
              isToggle: true,
              toggleValue: _autoUpdate,
              onToggle: (value) => setState(() => _autoUpdate = value),
            ),
            const SizedBox(height: 12),

            // Dark Mode toggle
            _buildDarkModeToggle(context),
            const SizedBox(height: 12),

            // Clear cache
            _buildSettingTile(
              context,
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              subtitle:
                  'Free up: ${((_cacheSizeBytes / 1024 / 1024).toStringAsFixed(0))} MB',
              onTap: () => _showClearCacheConfirm(context),
            ),
            const SizedBox(height: 32),

            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EchoColors.primaryLight.withOpacity(0.1),
                border: Border.all(color: EchoColors.primary, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ' Why Download AI Models?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          inherit: false,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Faster threat assessment (offline = no network required)\n'
                    '• Works anywhere, even without internet\n'
                    '• Better accuracy with local processing',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EchoColors.textSecondary,
                          inherit: false,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildAIModelCard(
    BuildContext context, {
    required String title,
    required String version,
    required String size,
    required bool isDownloaded,
    required String description,
    String? warning,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? EchoColors.surfaceSecondary
        : const Color(0xFFF0F7FF);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDownloaded
              ? EchoColors.success.withOpacity(0.3)
              : (isDarkMode ? EchoColors.surfaceTertiary : const Color(0xFFE8F1FF)),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 8),
                        if (isDownloaded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: EchoColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check,
                                    size: 12, color: EchoColors.success),
                                const SizedBox(width: 4),
                                Text(
                                  'Ready',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: EchoColors.success, inherit: false),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version: $version',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: EchoColors.textTertiary,
                            inherit: false,
                          ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDelete,
                  color: EchoColors.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EchoColors.textSecondary,
                ),
          ),
          if (warning != null) ...[
            const SizedBox(height: 8),
            Text(
              warning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EchoColors.warning,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Size: $size',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EchoColors.textTertiary,
                      inherit: false,
                    ),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: isDownloaded
                      ? EchoColors.surfaceTertiary
                      : EchoColors.primary,
                ),
                child: Text(
                  isDownloaded ? 'Manage' : 'Get',
                  style: TextStyle(
                    color: isDownloaded
                        ? EchoColors.textPrimary
                        : EchoColors.surface,
                    inherit: false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isToggle = false,
    bool toggleValue = false,
    Function(bool)? onToggle,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDarkMode
        ? EchoColors.surfaceSecondary
        : const Color(0xFFF0F7FF);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: EchoColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          inherit: false,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EchoColors.textTertiary,
                          inherit: false,
                        ),
                  ),
                ],
              ),
            ),
            if (isToggle)
              Switch(
                value: toggleValue,
                onChanged: onToggle,
                activeColor: EchoColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tileColor = isDarkMode
        ? EchoColors.surfaceSecondary
        : const Color(0xFFF0F7FF);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dark_mode_outlined,
            color: EchoColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        inherit: false,
                      ),
                ),
                Text(
                  _darkModeEnabled
                      ? 'Dark mode enabled'
                      : 'Light mode enabled',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EchoColors.textTertiary,
                        inherit: false,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: _darkModeEnabled,
            onChanged: (value) => setState(() => _darkModeEnabled = value),
            activeColor: EchoColors.primary,
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, String modelName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download $modelName?'),
        content: Text(
          modelName == 'Offline AI'
              ? 'Download 2.6 GB model for better threat detection.'
              : 'Download 3.6 GB model for enhanced pattern recognition.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (modelName == 'Offline AI') {
                  _offlineAIDownloaded = true;
                } else {
                  _e4bDownloaded = true;
                }
              });
              if (mounted) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('$modelName downloaded successfully.'),
                  ),
                );
              }
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _showManageDialog(BuildContext context, String modelName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage $modelName'),
        content: Text(
          'Version: 1.2.0\n'
          'Last Updated: Today\n'
          'Storage: ${modelName == 'Offline AI' ? '2.6 GB' : '3.6 GB'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String modelName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $modelName?'),
        content: Text(
          'Are you sure? You\'ll need to re-download it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (modelName == 'Offline AI') {
                  _offlineAIDownloaded = false;
                } else {
                  _e4bDownloaded = false;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EchoColors.warning,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will free up storage but may slow down future operations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _cacheSizeBytes = 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EchoColors.warning,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
