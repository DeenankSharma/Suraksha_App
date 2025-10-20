// logs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';

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
    // Load logs when the page is opened
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
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: AppBar(
                iconTheme: IconThemeData(color: Colors.white),
                backgroundColor:
                    const Color.fromARGB(255, 0, 56, 147).withOpacity(0.9),
                elevation: 0,
                title: Text(
                  'Suraksha',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: MediaQuery.of(context).size.height * 0.03,
                        letterSpacing: 1.2,
                      ),
                ),
                centerTitle: false,
                bottom: TabBar(
                  tabs: [
                    Tab(text: 'Emergency Logs'),
                    Tab(text: 'Detailed Logs'),
                  ],
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                ),
              ),
            ),
            drawer: Navigation_Drawer(select: 2),
            body: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is LogsLoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
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
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading logs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(GetContactLogsEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const Center(
      child: Text('No logs available'),
    );
  }

  Widget _buildLogsList(BuildContext context, dynamic logsRaw,
      {bool isDetailed = false}) {
    // Convert logs to proper type
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
        child: Text(
          isDetailed ? 'No detailed logs found' : 'No emergency logs found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 106, 206, 245).withOpacity(0.3),
              const Color.fromARGB(255, 0, 56, 147).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    log['city'] ?? 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 0, 56, 147),
                    ),
                  ),
                  Text(
                    _formatDate(log['timestamp']?.toString() ?? ''),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Phone: ${log['phoneNumber']?.toString() ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (isDetailed) ...[
                const SizedBox(height: 8),
                Text(
                  'Area: ${log['area']?.toString() ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (log['landmark'] != null && log['landmark'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Landmark: ${log['landmark']?.toString() ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Description: ${log['description']?.toString() ?? 'No description'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${log['latitude']?.toString() ?? 'N/A'}, ${log['longitude']?.toString() ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) {
      return 'Unknown Date';
    }
    
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
