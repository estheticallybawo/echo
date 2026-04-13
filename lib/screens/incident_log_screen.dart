import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/firestore_incident_service.dart';
import '../providers/gemma_provider.dart';
import '../theme.dart';

class IncidentLogScreen extends StatefulWidget {
  const IncidentLogScreen({super.key});

  @override
  State<IncidentLogScreen> createState() => _IncidentLogScreenState();
}

class _IncidentLogScreenState extends State<IncidentLogScreen> {
  String _filterActionType = 'all'; // all, emergency_press, auto_escalation, contact_action

  @override
  Widget build(BuildContext context) {
    final gemmaProvider = Provider.of<GemmaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Log'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header section
          Padding(
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: EchoColors.textTertiary),
                ),
                const SizedBox(height: 24),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'emergency_press',
                      'auto_escalation',
                      'contact_action'
                    ]
                        .map((actionType) {
                          final isSelected = _filterActionType == actionType;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _filterActionType = actionType;
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
                                  actionType.replaceAll('_', ' ').toUpperCase(),
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
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          // Incidents list with real-time stream
          Expanded(
            child: StreamBuilder<List<IncidentModel>>(
              stream: gemmaProvider.getIncidentsStream(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: EchoColors.warning),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading incidents',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: EchoColors.textPrimary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: EchoColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Empty state
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            size: 48, color: EchoColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No incidents logged yet',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: EchoColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Press the emergency button to log your first incident',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: EchoColors.textTertiary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Populated state - filter incidents based on action type
                final allIncidents = snapshot.data!;
                final filteredIncidents = _filterActionType == 'all'
                    ? allIncidents
                    : allIncidents
                        .where((incident) =>
                            incident.actionType == _filterActionType)
                        .toList();

                if (filteredIncidents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off_outlined,
                            size: 48, color: EchoColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No incidents with this filter',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: EchoColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                // Display incidents list
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: filteredIncidents.length,
                  itemBuilder: (context, index) {
                    final incident = filteredIncidents[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildIncidentCard(context, incident),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build incident card widget with threat level color coding
  Widget _buildIncidentCard(BuildContext context, IncidentModel incident) {
    // Color code by threat level
    Color threatColor = EchoColors.textTertiary;
    String threatLabel = incident.threatLevel.toUpperCase();

    switch (incident.threatLevel.toUpperCase()) {
      case 'CRITICAL':
        threatColor = EchoColors.warning;
        break;
      case 'HIGH':
        threatColor = EchoColors.warning;
        break;
      case 'MEDIUM':
        threatColor = EchoColors.primary;
        break;
      case 'LOW':
        threatColor = EchoColors.success;
        break;
    }

    // Format timestamp
    final timeString = DateFormat('MMM d, h:mm a').format(incident.timestamp);

    // Determine icon based on action type
    IconData actionIcon = Icons.warning_amber;
    switch (incident.actionType) {
      case 'emergency_press':
        actionIcon = Icons.warning_amber;
        break;
      case 'auto_escalation':
        actionIcon = Icons.auto_awesome;
        break;
      case 'contact_action':
        actionIcon = Icons.call_made;
        break;
    }

    return GestureDetector(
      onTap: () {
        _showIncidentDetail(context, incident);
      },
      child: Container(
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
                    color: threatColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(
                      actionIcon,
                      color: threatColor,
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
                        incident.actionType
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: EchoColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeString,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
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
                    color: threatColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    threatLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: threatColor,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (incident.location.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: EchoColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.location,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: EchoColors.textTertiary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (incident.location.isNotEmpty) const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trending_up,
                    size: 14, color: EchoColors.textTertiary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Threat: ${incident.threatLevel}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: EchoColors.textTertiary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Tap for details',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: EchoColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show detailed incident information in bottom sheet
  void _showIncidentDetail(BuildContext context, IncidentModel incident) {
    final timeString =
        DateFormat('EEEE, MMMM d, yyyy h:mm a').format(incident.timestamp);

    showModalBottomSheet(
      context: context,
      backgroundColor: EchoColors.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incident Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: EchoColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow('Timestamp', timeString, context),
                _detailRow(
                  'Action Type',
                  incident.actionType.replaceAll('_', ' ').toUpperCase(),
                  context,
                ),
                _detailRow(
                  'Threat Level',
                  incident.threatLevel.toUpperCase(),
                  context,
                ),
                if (incident.location.isNotEmpty)
                  _detailRow('Location', incident.location, context),
                if (incident.contactId.isNotEmpty)
                  _detailRow('Contact ID', incident.contactId, context),
                const SizedBox(height: 20),
                Text(
                  'Gemma Analysis',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: EchoColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EchoColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: EchoColors.textPrimary.withOpacity(0.1),
                    ),
                  ),
                  child: Text(
                    incident.gemmaAnalysis.isEmpty
                        ? 'Analysis pending...'
                        : incident.gemmaAnalysis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: EchoColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Helper widget for detail rows
  Widget _detailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: EchoColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: EchoColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
