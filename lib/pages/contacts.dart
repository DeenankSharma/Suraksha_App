import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/contact_widget.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class Contacts extends StatelessWidget {
  Contacts({super.key});

  final _searchController = TextEditingController();
  final _searchQuery = ValueNotifier<String>('');
  final _sortByCallFrequency = ValueNotifier<bool>(false);

  void _removeEmergencyContact(BuildContext context, Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove Emergency Contact'),
        content: Text(
            'Are you sure you want to remove ${contact['displayName'] ?? contact['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              // Emit Remove Event directly
              context.read<HomeBloc>().add(RemoveContactEvent(contact));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterAndSortContacts(
      List<Map<String, dynamic>> contacts, String searchQuery, bool sortByCallFrequency) {
    List<Map<String, dynamic>> filteredContacts = List.from(contacts);

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filteredContacts = filteredContacts.where((contact) {
        final name = contact['displayName']?.toString().toLowerCase() ?? '';
        final phones = contact['phones'] as List? ?? [];
        final phoneNumbers = phones.map((phone) => phone.toString()).join(' ');

        return name.contains(searchQuery.toLowerCase()) ||
            phoneNumbers.contains(searchQuery);
      }).toList();
    }

    // Sort
    if (sortByCallFrequency) {
      filteredContacts.sort((a, b) {
        final aCalls = a['callCount'] ?? 0;
        final bCalls = b['callCount'] ?? 0;
        if (aCalls != bCalls) {
          return bCalls.compareTo(aCalls);
        }
        return (a['displayName'] ?? '').compareTo(b['displayName'] ?? '');
      });
    } else {
      filteredContacts.sort((a, b) {
        return (a['displayName'] ?? '').compareTo(b['displayName'] ?? '');
      });
    }

    return filteredContacts;
  }

  Widget _buildSearchAndSortBar() {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, searchQuery, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _sortByCallFrequency,
          builder: (context, sortByCallFrequency, _) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accent.withOpacity(0.3),
                  ),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by name or number...',
                      prefixIcon: Icon(CupertinoIcons.search, color: AppTheme.primary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                CupertinoIcons.clear_circled,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.accent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppTheme.background,
                    ),
                    onChanged: (value) {
                      _searchQuery.value = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Name'),
                              selected: !sortByCallFrequency,
                              onSelected: (selected) {
                                if (selected) {
                                  _sortByCallFrequency.value = false;
                                }
                              },
                              selectedColor: AppTheme.primary.withOpacity(0.2),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: sortByCallFrequency
                                    ? AppTheme.textSecondary
                                    : AppTheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: sortByCallFrequency
                                    ? AppTheme.accent
                                    : AppTheme.primary,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Call Frequency'),
                              selected: sortByCallFrequency,
                              onSelected: (selected) {
                                if (selected) {
                                  _sortByCallFrequency.value = true;
                                }
                              },
                              selectedColor: AppTheme.primary.withOpacity(0.2),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: sortByCallFrequency
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: sortByCallFrequency
                                    ? AppTheme.primary
                                    : AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final state = context.read<HomeBloc>().state;
        if (state is! ContactsLoadingState && 
            state is! ContactsFetchedState && 
            state is! ContactsErrorState) {
          context.read<HomeBloc>().add(ShowContactsEvent());
        }
      }
    });

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        // --- Navigation Logic ---
        if (state is NavigateToLoginState) {
          context.go('/login');
        } else if (state is NavigateToOtpState) {
          context
              .read<HomeBloc>()
              .add(SendOtpEvent(phoneNumber: state.phoneNumber));
          context.go('/otp');
        } else if (state is NavigateToHomeState) {
          context.read<HomeBloc>().add(HomeScreenEvent());
          context.go('/home');
        }
        // --- Error Handling ---
        else if (state is ContactsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
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
                        CupertinoIcons.person_2_fill,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Emergency Contacts',
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
            ),
          ),
          drawer: const Navigation_Drawer(select: 3),
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchAndSortBar(),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is ContactsLoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
        ),
      );
    }

    if (state is ContactsFetchedState) {
      // 1. Separate contacts based on 'isSaved' property from BLoC state
      final savedContacts =
          state.contacts.where((c) => c['isSaved'] == true).toList();
      final deviceContacts =
          state.contacts.where((c) => c['isSaved'] == false).toList();

      return ValueListenableBuilder<String>(
        valueListenable: _searchQuery,
        builder: (context, searchQuery, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: _sortByCallFrequency,
            builder: (context, sortByCallFrequency, _) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (savedContacts.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.error.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_shield_fill,
                                  color: AppTheme.error,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Emergency Contacts (${savedContacts.length})',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...savedContacts.map(
                              (contact) {
                                final displayName = contact['displayName'] ??
                                    contact['contactName'] ??
                                    'Unknown';
                                String phoneNumber = '';
                                if (contact['phones'] != null &&
                                    (contact['phones'] as List).isNotEmpty) {
                                  phoneNumber = contact['phones'][0].toString();
                                } else if (contact['contactPhoneNumber'] != null) {
                                  phoneNumber =
                                      contact['contactPhoneNumber'].toString();
                                }

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppTheme.accent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.error,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      phoneNumber,
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        CupertinoIcons.minus_circle,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () => _removeEmergencyContact(context, contact),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (deviceContacts.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.person_crop_circle_fill,
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Device Contacts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDeviceContactsList(context, deviceContacts, searchQuery, sortByCallFrequency),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // Error state handling
    if (state is ContactsErrorState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: AppTheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading contacts',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HomeBloc>().add(ShowContactsEvent());
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

    // Default loading/empty state
    return Center(
      child: CircularProgressIndicator(
        color: AppTheme.primary,
      ),
    );
  }

  Widget _buildDeviceContactsList(BuildContext context, List<Map<String, dynamic>> deviceContacts, String searchQuery, bool sortByCallFrequency) {
    final filteredContacts = _filterAndSortContacts(deviceContacts, searchQuery, sortByCallFrequency);

    if (filteredContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.search,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                searchQuery.isNotEmpty
                    ? 'No contacts found matching "$searchQuery"'
                    : 'No device contacts found',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return ContactWidget(
          contact: contact,
          onAdd: () {
            final name = contact['displayName'] ?? 'Unknown';
            // Emit Add Event directly
            context.read<HomeBloc>().add(AddContactEvent(contact));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Adding $name to emergency contacts...'),
                backgroundColor: AppTheme.primary,
              ),
            );
          },
          onRemove: () {
            // Emit Remove Event directly
            context.read<HomeBloc>().add(RemoveContactEvent(contact));
          },
        );
      },
    );
  }
}
