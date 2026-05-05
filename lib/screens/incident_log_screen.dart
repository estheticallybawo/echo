import 'package:flutter/material.dart';
import '../theme.dart';

class IncidentLogScreen extends StatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  State<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends State<IncidentLogScreen> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Log'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Safety History',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'All activations and safety events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: EchoColors.textTertiary,
                ),
              ),
              const SizedBox(height: 24),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'active', 'resolved', 'false-alarm']
                      .map((status) {
                    final isSelected = _filterStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _filterStatus = status;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? EchoColors.primary
                                : EchoColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? EchoColors.primary
                                  : EchoColors.textPrimary
                                      .withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.replaceAll('-', ' ').toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? EchoColors.surface
                                      : EchoColors.textSecondary,
                                ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Incident list
              ...[
                {
                  'date': 'Today at 2:45 PM',
                  'type': 'Emergency Activated',
                  'location': 'Downtown Area',
                  'duration': '3 min 42 sec',
                  'status': 'resolved',
                  'icon': Icons.warning_amber,
                },
                {
                  'date': 'Yesterday 10:30 AM',
                  'type': 'Fake Call Used',
                  'location': 'Shopping District',
                  'duration': '2 min 15 sec',
                  'status': 'false-alarm',
                  'icon': Icons.phone,
                },
                {
                  'date': 'Mar 5 at 9:15 PM',
                  'type': 'Emergency Activated',
                  'location': 'Residential Area',
                  'duration': '8 min 20 sec',
                  'status': 'resolved',
                  'icon': Icons.warning_amber,
                },
              ].map((incident) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildIncidentCard(incident),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual incident card
  Widget _buildIncidentCard(Map<String, dynamic> incident) {
    Color statusColor = EchoColors.primary;
    if (incident['status'] == 'resolved') {
      statusColor = EchoColors.success;
    } else if (incident['status'] == 'false-alarm') {
      statusColor = EchoColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EchoColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EchoColors.textPrimary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    incident['icon'] as IconData,
                    color: statusColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident['type'] as String,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: EchoColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      incident['date'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EchoColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (incident['status'] as String)
                      .replaceAll('-', ' ')
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on,
                  size: 14, color: EchoColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                incident['location'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EchoColors.textTertiary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule,
                  size: 14, color: EchoColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                incident['duration'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: EchoColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _showIncidentDetails(context, incident);
            },
            child: Text(
              'View Details',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show detailed view of incident
  void _showIncidentDetails(
    BuildContext context,
    Map<String, dynamic> incident,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EchoColors.surfaceSecondary,
          title: Text(
            incident['type'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Date', incident['date'] as String),
              _detailRow('Location', incident['location'] as String),
              _detailRow('Duration', incident['duration'] as String),
              _detailRow(
                'Status',
                (incident['status'] as String)
                    .replaceAll('-', ' ')
                    .toUpperCase(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Helper widget for detail rows
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: EchoColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: EchoColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
