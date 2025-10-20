import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    _loadUserName();
  }

  Future<void> _loadPhoneNumber() async {
    final pn = await getPN();
    setState(() {
      phoneNumber = pn;
    });
  }

  Future<void> _loadUserName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';
    setState(() {
      nameController.text = userName;
    });
  }

  Future<void> _updateUserName() async {
    if (nameController.text.trim().isNotEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', nameController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ProfileUpdatedState) {
          emailController.text = state.email;
          addressController.text = state.address;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile', style: TextStyle(color: Colors.white)),
            backgroundColor:
                const Color.fromARGB(255, 0, 56, 147).withOpacity(0.9),
          ),
          drawer: const Navigation_Drawer(select: 4),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 106, 206, 245),
                  const Color.fromARGB(255, 0, 56, 147).withOpacity(0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Phone Number Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Color.fromARGB(255, 0, 56, 147)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              phoneNumber.isNotEmpty ? '+91 $phoneNumber' : 'Loading...',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name Field
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Colors.white),
                        onPressed: _updateUserName,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: const OutlineInputBorder(),
                      enabled: state is ProfileUpdatedState
                          ? state.isEditing
                          : false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Current Address',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: const OutlineInputBorder(),
                      enabled: state is ProfileUpdatedState
                          ? state.isEditing
                          : false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HomeBloc>().add(UpdateProfileEvent(
                            email: emailController.text,
                            address: addressController.text,
                            isEditing: state is ProfileUpdatedState
                                ? state.isEditing
                                : false,
                          ));
                    },
                    child: Text(state is ProfileUpdatedState && state.isEditing
                        ? 'Save'
                        : 'Edit'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> getPN() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pn = prefs.getString('pn');
    return pn!;
  }
}
