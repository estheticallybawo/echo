import 'package:flutter/material.dart';
import '../theme.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: GuardianColors.surfaceSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Tier 1: Inner Circle (high priority)
              _buildTierSection(
                context,
                tier: 'Inner Circle',
                description: 'First responders to your emergency',
                contacts: [
                  {'name': 'Mom', 'phone': '+234 XXX XXX XXX', 'tier': 1},
                  {'name': 'Sister', 'phone': '+234 XXX XXX XXX', 'tier': 1},
                  {'name': 'Best Friend', 'phone': '+234 XXX XXX XXX', 'tier': 1},
                ],
                color: GuardianColors.primary,
              ),
              const SizedBox(height: 28),

              // Tier 2: Extended Network
              _buildTierSection(
                context,
                tier: 'Extended Network',
                description: 'Secondary contacts & support',
                contacts: [
                  {'name': 'Trusted Colleague', 'phone': '+234 XXX XXX XXX', 'tier': 2},
                  {'name': 'Neighbor', 'phone': '+234 XXX XXX XXX', 'tier': 2},
                  {'name': 'Support Group', 'phone': '+234 XXX XXX XXX', 'tier': 2},
                ],
                color: GuardianColors.warning,
              ),
              const SizedBox(height: 28),

              // Proximity-Based Suggestions
              _buildProximitySuggestions(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddContactDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build a tier section with contacts
  Widget _buildTierSection(
    BuildContext context, {
    required String tier,
    required String description,
    required List<Map<String, dynamic>> contacts,
    required Color color,
  }) {
    // Filter by search query
    final filtered = contacts
        .where((c) =>
            (c['name'] as String).toLowerCase().contains(_searchQuery) ||
            _searchQuery.isEmpty)
        .toList();

    if (filtered.isEmpty && _searchQuery.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: GuardianColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...filtered.map((contact) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildContactCard(contact),
          );
        }),
      ],
    );
  }

  /// Individual contact card
  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GuardianColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: GuardianColors.textPrimary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GuardianColors.surfaceTertiary,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GuardianColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact['phone'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showContactOptions(context, contact);
            },
            color: GuardianColors.textTertiary,
          ),
        ],
      ),
    );
  }

  /// Proximity-based suggestions
  Widget _buildProximitySuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: GuardianColors.success,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nearby Contacts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: GuardianColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'People near your location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: GuardianColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: GuardianColors.textPrimary.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GuardianColors.surfaceTertiary,
                ),
                child: const Center(
                  child: Icon(Icons.location_on, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Security',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GuardianColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '200m away • Emergency Services',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: GuardianColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {},
                color: GuardianColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show options for a contact
  void _showContactOptions(BuildContext context, Map<String, dynamic> contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GuardianColors.surfaceSecondary,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Remove'),
                textColor: GuardianColors.warning,
                iconColor: GuardianColors.warning,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show add contact dialog
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: GuardianColors.surfaceSecondary,
          title: Text(
            'Add Contact',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: GuardianColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
