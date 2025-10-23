import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/theme/app_theme.dart';

import '../components/navigation_drawer.dart';

class ContactsLog extends StatefulWidget {
  const ContactsLog({super.key});

  @override
  State<ContactsLog> createState() => _ContactsLogState();
}

class _ContactsLogState extends State<ContactsLog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(GetContactLogsEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is LogsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(130),
              child: AppBar(
                backgroundColor: AppTheme.primaryDark,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white, size: 28),
                titleSpacing: 16,
                title: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CupertinoIcons.time,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Activity Logs',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                centerTitle: false,
                bottom: TabBar(
                  tabs: const [
                    Tab(text: 'Emergency Alerts'),
                    Tab(text: 'Detailed Reports'),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            drawer: const Navigation_Drawer(select: 2),
            body: SafeArea(
              child: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is LogsLoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
        ),
      );
    }

    if (state is LogsFetchedState) {
      return TabBarView(
        children: [
          _buildLogsList(context, state.logs['logs'] ?? []),
          _buildLogsList(context, state.logs['detailed_logs'] ?? [],
              isDetailed: true),
        ],
      );
    }

    if (state is LogsErrorState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppTheme.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(GetContactLogsEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No logs available',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(BuildContext context, dynamic logsRaw,
      {bool isDetailed = false}) {
    List<Map<String, dynamic>> logs = [];
    try {
      if (logsRaw is List) {
        logs = logsRaw.map((item) {
          if (item is Map<String, dynamic>) {
            return item;
          } else if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return <String, dynamic>{};
          }
        }).toList();
      }
    } catch (e) {
      print("Error processing logs: $e");
      logs = [];
    }

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDetailed
                  ? CupertinoIcons.doc_text
                  : CupertinoIcons.exclamationmark_shield,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isDetailed
                  ? 'No detailed reports found'
                  : 'No emergency alerts found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.background,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return LogWidget(
            log: log,
            isDetailed: isDetailed,
          );
        },
      ),
    );
  }
}

class LogWidget extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isDetailed;

  const LogWidget({
    super.key,
    required this.log,
    this.isDetailed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.accent.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDetailed
                        ? AppTheme.secondary.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDetailed
                        ? CupertinoIcons.doc_text_fill
                        : CupertinoIcons.exclamationmark_shield_fill,
                    color: isDetailed ? AppTheme.secondary : AppTheme.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['city'] ?? 'Unknown Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(log['timestamp']?.toString() ?? ''),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppTheme.accent.withOpacity(0.3)),
            const SizedBox(height: 12),
            _buildInfoRow(
              CupertinoIcons.phone_fill,
              'Phone',
              log['phoneNumber']?.toString() ?? 'Unknown',
            ),
            if (isDetailed) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                CupertinoIcons.location_solid,
                'Area',
                log['area']?.toString() ?? 'Unknown',
              ),
              if (log['landmark'] != null &&
                  log['landmark'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  CupertinoIcons.placemark_fill,
                  'Landmark',
                  log['landmark']?.toString() ?? 'Unknown',
                ),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text,
                          size: 16,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log['description']?.toString() ?? 'No description',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.map_pin_ellipse,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coordinates: ${log['latitude']?.toString() ?? 'N/A'}, ${log['longitude']?.toString() ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) {
      return 'Unknown Date';
    }

    try {
      final date = DateTime.parse(timestamp);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final month = months[date.month - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$month ${date.day}, ${date.year} at $hour:$minute';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
