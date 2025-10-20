import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/contact_widget.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:permission_handler/permission_handler.dart';
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
      final contactNames = prefs.getStringList('emergency_contact_names') ?? [];
      final contactNumbers = prefs.getStringList('emergency_contact_numbers') ?? [];
      
      setState(() {
        _emergencyContacts = [];
        for (int i = 0; i < contactNames.length && i < contactNumbers.length; i++) {
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
      final contactNumbers = _emergencyContacts.map((c) => c['number']!).toList();
      
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
            // Find and update by name and number to avoid reference issues
            final index = _emergencyContacts.indexWhere((c) => 
              c['name'] == contact['name'] && c['number'] == contact['number']);
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
        title: const Text('Remove Emergency Contact'),
        content: Text('Are you sure you want to remove ${contact['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Find and remove by name and number to avoid reference issues
                _emergencyContacts.removeWhere((c) => 
                  c['name'] == contact['name'] && c['number'] == contact['number']);
              });
              _saveEmergencyContacts();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  List<Map<String, dynamic>> _filterAndSortContacts(List<Map<String, dynamic>> contacts) {
    List<Map<String, dynamic>> filteredContacts = contacts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredContacts = contacts.where((contact) {
        final name = contact['displayName']?.toString().toLowerCase() ?? '';
        final phones = contact['phones'] as List? ?? [];
        final phoneNumbers = phones.map((phone) => phone.toString()).join(' ');
        
        return name.contains(_searchQuery.toLowerCase()) || 
               phoneNumbers.contains(_searchQuery);
      }).toList();
    }

    // Apply sorting
    if (_sortByCallFrequency) {
      // Sort by call frequency (descending) then by saved status, then by name
      filteredContacts.sort((a, b) {
        final aCalls = a['callCount'] ?? 0;
        final bCalls = b['callCount'] ?? 0;
        
        if (aCalls != bCalls) {
          return bCalls.compareTo(aCalls); // Descending order
        }
        
        // If call counts are equal, prioritize saved contacts
        if (a['isSaved'] && !b['isSaved']) return -1;
        if (!a['isSaved'] && b['isSaved']) return 1;
        
        return a['displayName'].compareTo(b['displayName']);
      });
    } else {
      // Default sorting: saved contacts first, then by name
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or number...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
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
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 56, 147),
                  width: 2,
                ),
              ),
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
              Expanded(
                child: Text(
                  'Sort by:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                selectedColor: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _sortByCallFrequency ? Colors.grey[600] : const Color.fromARGB(255, 0, 56, 147),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
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
                selectedColor: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _sortByCallFrequency ? const Color.fromARGB(255, 0, 56, 147) : Colors.grey[600],
                  fontWeight: FontWeight.w500,
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
          title: const Text('Add Emergency Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  hintText: 'Enter contact name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
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
                    const SnackBar(
                      content: Text('Please enter both name and phone number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 56, 147),
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
    // Create a manual contact object
    final manualContact = {
      'id': 'manual_${DateTime.now().millisecondsSinceEpoch}',
      'displayName': name,
      'phones': [phone],
      'isSaved': false,
      'callCount': 0,
      'isManual': true, // Flag to identify manually added contacts
    };

    // Add the contact using the existing bloc event
    context.read<HomeBloc>().add(AddContactEvent(manualContact));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $name to emergency contacts'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ContactsErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
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
            ),
          ),
          drawer: Navigation_Drawer(select: 3),
          body: Column(
            children: [
              _buildSearchAndSortBar(),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddContactDialog(context),
            backgroundColor: const Color.fromARGB(255, 0, 56, 147),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, HomeState state) {
    if (state is ContactsLoadingState) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
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
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contacts (${_emergencyContacts.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._emergencyContacts.map((contact) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Text(
                          contact['name']![0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(contact['name']!),
                      subtitle: Text(contact['number']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editEmergencyContact(contact),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeEmergencyContact(contact),
                          ),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _addEmergencyContact,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Emergency Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contacts, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Device Contacts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
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
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading contacts',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.error,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withOpacity(0.7),
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
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No contacts found matching "$_searchQuery"'
                  : 'No device contacts found',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.withOpacity(0.7),
              ),
            ),
          ],
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
                // Add to emergency contacts locally
                final phone = contact['phones']?.isNotEmpty == true 
                    ? contact['phones'][0].toString() 
                    : '';
                final name = contact['displayName'] ?? 'Unknown';
                
                if (phone.isNotEmpty) {
                  setState(() {
                    // Check if contact already exists in emergency contacts
                    final exists = _emergencyContacts.any((ec) => 
                        ec['number'] == phone);
                    
                    if (!exists) {
                      _emergencyContacts.add({
                        'name': name,
                        'number': phone,
                      });
                    }
                  });
                  _saveEmergencyContacts();
                  
                  // Also dispatch to HomeBloc for backend sync
                  context.read<HomeBloc>().add(AddContactEvent(contact));
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $name to emergency contacts')),
                  );
                }
              },
              onRemove: () {
                // Remove from emergency contacts if it exists there
                final phone = contact['phones']?.isNotEmpty == true 
                    ? contact['phones'][0].toString() 
                    : '';
                
                if (phone.isNotEmpty) {
                  setState(() {
                    _emergencyContacts.removeWhere((ec) => 
                        ec['number'] == phone);
                  });
                  _saveEmergencyContacts();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed ${contact['displayName']} from emergency contacts')),
                  );
                }
                
                // Also dispatch to HomeBloc for backend sync
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
  State<_EmergencyContactDialog> createState() => _EmergencyContactDialogState();
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
      title: Text(widget.initialName == null ? 'Add Emergency Contact' : 'Edit Emergency Contact'),
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
              widget.onSave(
                _nameController.text.trim(),
                _numberController.text.trim(),
              );
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.initialName == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
