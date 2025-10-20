import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<Map<String, String>> _emergencyContacts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedContacts();
  }

  Future<void> _loadSuggestedContacts() async {
    setState(() => _isLoading = true);
    
    try {
      // Get the HomeBloc to fetch call logs and suggest contacts
      final homeBloc = context.read<HomeBloc>();
      
      // Dispatch event to get call logs and contacts
      homeBloc.add(ShowContactsEvent());
      
      // Wait a bit for the data to load
      await Future.delayed(const Duration(seconds: 2));
      
      // Get the current state to extract suggested contacts
      final state = homeBloc.state;
      
      if (state is ContactsFetchedState) {
        // Get top 4 contacts from call logs (sorted by call frequency)
        final contacts = state.contacts.take(4).toList();
        
        // Add top contacts from call logs first (these are the most important)
        for (var contact in contacts) {
          if (contact['name'] != null && contact['phone'] != null) {
            _emergencyContacts.add({
              'name': contact['name']!,
              'number': contact['phone']!,
            });
          }
        }
        
        // Add default emergency contacts (these are always important)
        _emergencyContacts.addAll([
          {'name': 'Police', 'number': '100'},
          {'name': 'Ambulance', 'number': '108'},
          {'name': 'Fire Service', 'number': '101'},
          {'name': 'Women Helpline', 'number': '1091'},
        ]);
      } else {
        // Fallback: just add default contacts
        _emergencyContacts.addAll([
          {'name': 'Police', 'number': '100'},
          {'name': 'Ambulance', 'number': '108'},
          {'name': 'Fire Service', 'number': '101'},
          {'name': 'Women Helpline', 'number': '1091'},
        ]);
      }
    } catch (e) {
      // Fallback: just add default contacts
      _emergencyContacts.addAll([
        {'name': 'Police', 'number': '100'},
        {'name': 'Ambulance', 'number': '108'},
        {'name': 'Fire Service', 'number': '101'},
        {'name': 'Women Helpline', 'number': '1091'},
      ]);
    }
    
    setState(() => _isLoading = false);
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => _AddContactDialog(
        onAdd: (name, number) {
          setState(() {
            _emergencyContacts.add({'name': name, 'number': number});
          });
        },
      ),
    );
  }

  void _removeContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one emergency contact')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user name
      await prefs.setString('user_name', _nameController.text.trim());
      
      // Save emergency contacts
      final contactNames = _emergencyContacts.map((c) => c['name']!).toList();
      final contactNumbers = _emergencyContacts.map((c) => c['number']!).toList();
      
      await prefs.setStringList('emergency_contact_names', contactNames);
      await prefs.setStringList('emergency_contact_numbers', contactNumbers);
      
      // Mark setup as completed
      await prefs.setBool('setup_completed', true);
      
      // Navigate to home screen
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving setup: $e')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Emergency Contacts'),
        backgroundColor: const Color.fromARGB(255, 106, 206, 245),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name input section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Name',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Emergency contacts section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Contact'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Contacts list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _emergencyContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _emergencyContacts[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color.fromARGB(255, 106, 206, 245),
                              child: Text(
                                contact['name']![0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(contact['name']!),
                            subtitle: Text(contact['number']!),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeContact(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Complete setup button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 106, 206, 245),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Complete Setup',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  final Function(String name, String number) onAdd;

  const _AddContactDialog({required this.onAdd});

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _numberController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty &&
                _numberController.text.trim().isNotEmpty) {
              widget.onAdd(
                _nameController.text.trim(),
                _numberController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
