import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController pnController = TextEditingController();
    final Future<String> pn = getPN();
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is ProfileUpdatedState) {
          emailController.text = state.email;
          addressController.text = state.address;
          pnController.text = pn.toString();
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
