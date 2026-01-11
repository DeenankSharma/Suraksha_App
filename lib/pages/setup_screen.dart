import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SetupScreen extends StatelessWidget {
  SetupScreen({super.key});

  final _nameController = TextEditingController();
  final _emergencyContacts = ValueNotifier<List<Map<String, String>>>([]);
  final _isLoading = ValueNotifier<bool>(false);

  Future<void> _loadSuggestedContacts(BuildContext context) async {
    _isLoading.value = true;

    try {
      final homeBloc = context.read<HomeBloc>();
      homeBloc.add(ShowContactsEvent());
      await Future.delayed(const Duration(seconds: 2));

      final state = homeBloc.state;
      final List<Map<String, String>> contacts = [];

      if (state is ContactsFetchedState) {
        final fetchedContacts = state.contacts.take(4).toList();

        for (var contact in fetchedContacts) {
          if (contact['name'] != null && contact['phone'] != null) {
            contacts.add({
              'name': contact['name']!,
              'number': contact['phone']!,
            });
          }
        }
      }

      ///default emergency contacts
      contacts.addAll([
        {'name': 'Police', 'number': '100'},
        {'name': 'Ambulance', 'number': '108'},
        {'name': 'Women Helpline', 'number': '1091'},
      ]);

      _emergencyContacts.value = contacts;
    } catch (e) {
      _emergencyContacts.value = [
        {'name': 'Police', 'number': '100'},
        {'name': 'Ambulance', 'number': '108'},
        {'name': 'Women Helpline', 'number': '1091'},
      ];
    }

    _isLoading.value = false;
  }

  void _addContact(BuildContext context, String name, String number) {
    final current = List<Map<String, String>>.from(_emergencyContacts.value);
    current.add({'name': name, 'number': number});
    _emergencyContacts.value = current;
  }

  void _removeContact(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        final contacts = _emergencyContacts.value;
        final contactName = index < contacts.length ? contacts[index]['name'] : 'Unknown';
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Remove Contact'),
          content: Text('Are you sure you want to remove $contactName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppTheme.primary)),
            ),
            ElevatedButton(
              onPressed: () {
                final current = List<Map<String, String>>.from(_emergencyContacts.value);
                current.removeAt(index);
                _emergencyContacts.value = current;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeSetup(BuildContext context) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your name'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final contacts = _emergencyContacts.value;
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one emergency contact'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    _isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_name', _nameController.text.trim());

      final contactNames = contacts.map((c) => c['name']!).toList();
      final contactNumbers = contacts.map((c) => c['number']!).toList();

      await prefs.setStringList('emergency_contact_names', contactNames);
      await prefs.setStringList('emergency_contact_numbers', contactNumbers);

      await prefs.setBool('setup_completed', true);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Setup completed successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving setup: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }

    _isLoading.value = false;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted && _emergencyContacts.value.isEmpty && !_isLoading.value) {
        _loadSuggestedContacts(context);
      }
    });

    return ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (context, isLoading, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: AppBar(
              backgroundColor: AppTheme.primaryDark,
              elevation: 0,
              centerTitle: true,
              title: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.shield_lefthalf_fill,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Suraksha Setup',
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
            ),
          ),
          body: SafeArea(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Setting up your profile...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryDark,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  CupertinoIcons.person_add_solid,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome to Suraksha',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Set up your profile and emergency contacts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                CupertinoIcons.person_circle,
                                'Personal Information',
                                'Tell us your name',
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.5),
                                  ),
                                ),
                                child: TextField(
                                  controller: _nameController,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter your full name',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textSecondary.withOpacity(0.5),
                                    ),
                                    prefixIcon: Icon(
                                      CupertinoIcons.person,
                                      color: AppTheme.primary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildSectionHeader(
                                CupertinoIcons.person_2_fill,
                                'Emergency Contacts',
                                'Add people who will receive alerts',
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _AddContactDialog(
                                        onAdd: (name, number) {
                                          _addContact(context, name, number);
                                        },
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    CupertinoIcons.add_circled,
                                    color: AppTheme.primary,
                                  ),
                                  label: Text(
                                    'Add Emergency Contact',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppTheme.primary,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<List<Map<String, String>>>(
                                valueListenable: _emergencyContacts,
                                builder: (context, contacts, _) {
                                  if (contacts.isEmpty) {
                                    return Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.accent.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            CupertinoIcons.person_2,
                                            size: 48,
                                            color: AppTheme.textSecondary.withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No emergency contacts added yet',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: contacts
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      final index = entry.key;
                                      final contact = entry.value;
                                      final isEmergencyService = [
                                        '100',
                                        '108',
                                        '101',
                                        '1091'
                                      ].contains(contact['number']);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isEmergencyService
                                                ? AppTheme.error.withOpacity(0.3)
                                                : AppTheme.accent.withOpacity(0.5),
                                            width: isEmergencyService ? 2 : 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          leading: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isEmergencyService
                                                  ? AppTheme.error
                                                  : AppTheme.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: isEmergencyService
                                                  ? Icon(
                                                      CupertinoIcons.shield_fill,
                                                      color: Colors.white,
                                                      size: 24,
                                                    )
                                                  : Text(
                                                      contact['name']![0].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          title: Text(
                                            contact['name']!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.phone,
                                                size: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                contact['number']!,
                                                style: TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              CupertinoIcons.delete,
                                              color: AppTheme.error,
                                              size: 22,
                                            ),
                                            onPressed: () => _removeContact(context, index),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => _completeSetup(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Complete Setup',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        CupertinoIcons.arrow_right_circle_fill,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      CupertinoIcons.info_circle,
                                      color: AppTheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'You can always modify these settings later from the Settings page',
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
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddContactDialog extends StatelessWidget {
  final Function(String name, String number) onAdd;

  _AddContactDialog({required this.onAdd});

  final _nameController = TextEditingController();
  final _numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            CupertinoIcons.person_add,
            color: AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text('Add Emergency Contact'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Contact Name',
              labelStyle: TextStyle(color: AppTheme.primary),
              hintText: 'e.g., Mom, Dad, Sister',
              prefixIcon: Icon(CupertinoIcons.person, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(color: AppTheme.primary),
              hintText: 'Enter phone number',
              prefixIcon: Icon(CupertinoIcons.phone, color: AppTheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.accent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _numberController.text.trim().isNotEmpty) {
              onAdd(
                _nameController.text.trim(),
                _numberController.text.trim(),
              );
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please enter both name and phone number'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Add Contact'),
        ),
      ],
    );
  }
}
