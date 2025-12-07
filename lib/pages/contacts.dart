import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/contact_widget.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Contacts extends StatefulWidget {
  const Contacts({super.key});

  @override
  State<Contacts> createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortByCallFrequency = false;
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeBloc>().add(ShowContactsEvent());
      _loadEmergencyContacts();
    });
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactNames =
          prefs.getStringList('emergency_contact_names') ?? [];
      final contactNumbers =
          prefs.getStringList('emergency_contact_numbers') ?? [];

      setState(() {
        _emergencyContacts = [];
        for (int i = 0;
            i < contactNames.length && i < contactNumbers.length;
            i++) {
          _emergencyContacts.add({
            'name': contactNames[i],
            'number': contactNumbers[i],
          });
        }
      });
    } catch (e) {
      print('Error loading emergency contacts: $e');
    }
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactNames = _emergencyContacts.map((c) => c['name']!).toList();
      final contactNumbers =
          _emergencyContacts.map((c) => c['number']!).toList();

      await prefs.setStringList('emergency_contact_names', contactNames);
      await prefs.setStringList('emergency_contact_numbers', contactNumbers);
    } catch (e) {
      print('Error saving emergency contacts: $e');
    }
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => _EmergencyContactDialog(
        onSave: (name, number) {
          setState(() {
            _emergencyContacts.add({'name': name, 'number': number});
          });
          _saveEmergencyContacts();
        },
      ),
    );
  }

  void _editEmergencyContact(Map<String, String> contact) {
    showDialog(
      context: context,
      builder: (context) => _EmergencyContactDialog(
        initialName: contact['name'],
        initialNumber: contact['number'],
        onSave: (name, number) {
          setState(() {
            final index = _emergencyContacts.indexWhere((c) =>
                c['name'] == contact['name'] &&
                c['number'] == contact['number']);
            if (index != -1) {
              _emergencyContacts[index] = {'name': name, 'number': number};
            }
          });
          _saveEmergencyContacts();
        },
      ),
    );
  }

  void _removeEmergencyContact(Map<String, String> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Remove Emergency Contact'),
        content:
            Text('Are you sure you want to remove ${contact['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyContacts.removeWhere((c) =>
                    c['name'] == contact['name'] &&
                    c['number'] == contact['number']);
              });
              _saveEmergencyContacts();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSortContacts(
      List<Map<String, dynamic>> contacts) {
    List<Map<String, dynamic>> filteredContacts = contacts;

    if (_searchQuery.isNotEmpty) {
      filteredContacts = contacts.where((contact) {
        final name = contact['displayName']?.toString().toLowerCase() ?? '';
        final phones = contact['phones'] as List? ?? [];
        final phoneNumbers = phones.map((phone) => phone.toString()).join(' ');

        return name.contains(_searchQuery.toLowerCase()) ||
            phoneNumbers.contains(_searchQuery);
      }).toList();
    }

    if (_sortByCallFrequency) {
      filteredContacts.sort((a, b) {
        final aCalls = a['callCount'] ?? 0;
        final bCalls = b['callCount'] ?? 0;

        if (aCalls != bCalls) {
          return bCalls.compareTo(aCalls);
        }

        if (a['isSaved'] && !b['isSaved']) return -1;
        if (!a['isSaved'] && b['isSaved']) return 1;

        return a['displayName'].compareTo(b['displayName']);
      });
    } else {
      filteredContacts.sort((a, b) {
        if (a['isSaved'] && !b['isSaved']) return -1;
        if (!a['isSaved'] && b['isSaved']) return 1;
        return a['displayName'].compareTo(b['displayName']);
      });
    }

    return filteredContacts;
  }

  Widget _buildSearchAndSortBar() {
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
          // Search bar
          TextField(
            controller: _searchController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or number...',
              prefixIcon: Icon(CupertinoIcons.search, color: AppTheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        CupertinoIcons.clear_circled,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
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
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Sort options
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
                      selected: !_sortByCallFrequency,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortByCallFrequency = false;
                          });
                        }
                      },
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _sortByCallFrequency
                            ? AppTheme.textSecondary
                            : AppTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: _sortByCallFrequency
                            ? AppTheme.accent
                            : AppTheme.primary,
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('Call Frequency'),
                      selected: _sortByCallFrequency,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _sortByCallFrequency = true;
                          });
                        }
                      },
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _sortByCallFrequency
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: _sortByCallFrequency
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
  }

  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Emergency Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'Enter contact name',
                  prefixIcon: Icon(CupertinoIcons.person, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(CupertinoIcons.phone, color: AppTheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppTheme.primary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty &&
                    phoneController.text.trim().isNotEmpty) {
                  _addManualContact(
                    context,
                    nameController.text.trim(),
                    phoneController.text.trim(),
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('Please enter both name and phone number'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Contact'),
            ),
          ],
        );
      },
    );
  }

  void _addManualContact(BuildContext context, String name, String phone) {
    final manualContact = {
      'id': 'manual_${DateTime.now().millisecondsSinceEpoch}',
      'displayName': name,
      'phones': [phone],
      'isSaved': false,
      'callCount': 0,
      'isManual': true,
    };

    context.read<HomeBloc>().add(AddContactEvent(manualContact));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to emergency contacts'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ContactsErrorState) {
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddContactDialog(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(CupertinoIcons.add, color: Colors.white),
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency Contacts Section
          if (_emergencyContacts.isNotEmpty) ...[
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
                        'Emergency Contacts (${_emergencyContacts.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._emergencyContacts.map(
                    (contact) => Card(
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
                              (contact['name'] ?? 'U').isNotEmpty 
                                  ? contact['name']![0].toUpperCase() 
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
                          contact['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          contact['number']!,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.pencil,
                                color: AppTheme.secondary,
                              ),
                              onPressed: () => _editEmergencyContact(contact),
                            ),
                            IconButton(
                              icon: Icon(
                                CupertinoIcons.delete,
                                color: AppTheme.error,
                              ),
                              onPressed: () => _removeEmergencyContact(contact),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addEmergencyContact,
                      icon: const Icon(CupertinoIcons.add),
                      label: const Text('Add Emergency Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Device Contacts Section
          if (state is ContactsFetchedState) ...[
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
                  _buildDeviceContactsList(state),
                ],
              ),
            ),
          ],

          // Error state
          if (state is ContactsErrorState)
            Center(
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceContactsList(ContactsFetchedState state) {
    final filteredContacts = _filterAndSortContacts(state.contacts);

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
                _searchQuery.isNotEmpty
                    ? 'No contacts found matching "$_searchQuery"'
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
            final phone = contact['phones']?.isNotEmpty == true
                ? contact['phones'][0].toString()
                : '';
            final name = contact['displayName'] ?? 'Unknown';

            if (phone.isNotEmpty) {
              setState(() {
                final exists =
                    _emergencyContacts.any((ec) => ec['number'] == phone);

                if (!exists) {
                  _emergencyContacts.add({
                    'name': name,
                    'number': phone,
                  });
                }
              });
              _saveEmergencyContacts();

              context.read<HomeBloc>().add(AddContactEvent(contact));

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $name to emergency contacts'),
                  backgroundColor: AppTheme.success,
                ),
              );
            }
          },
          onRemove: () {
            final phone = contact['phones']?.isNotEmpty == true
                ? contact['phones'][0].toString()
                : '';

            if (phone.isNotEmpty) {
              setState(() {
                _emergencyContacts
                    .removeWhere((ec) => ec['number'] == phone);
              });
              _saveEmergencyContacts();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Removed ${contact['displayName']} from emergency contacts'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
            }

            context.read<HomeBloc>().add(RemoveContactEvent(contact));
          },
        );
      },
    );
  }
}

class _EmergencyContactDialog extends StatefulWidget {
  final String? initialName;
  final String? initialNumber;
  final Function(String name, String number) onSave;

  const _EmergencyContactDialog({
    this.initialName,
    this.initialNumber,
    required this.onSave,
  });

  @override
  State<_EmergencyContactDialog> createState() =>
      _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<_EmergencyContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _numberController.text = widget.initialNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(widget.initialName == null
          ? 'Add Emergency Contact'
          : 'Edit Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(CupertinoIcons.person, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(CupertinoIcons.phone, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppTheme.primary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _numberController.text.trim().isNotEmpty) {
              widget.onSave(
                _nameController.text.trim(),
                _numberController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
          ),
          child: Text(widget.initialName == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
