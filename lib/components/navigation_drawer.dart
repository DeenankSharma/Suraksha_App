import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:go_router/go_router.dart';

class Navigation_Drawer extends StatelessWidget {
  const Navigation_Drawer({super.key, required this.select});
  final int select;
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color.fromARGB(255, 0, 56, 147);
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryBlue),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage("assets/image.jpg"),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'john.doe@example.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerItem(
                    icon: Icons.home,
                    title: 'Home',
                    onTap: () {
                      context.go('/home');
                    },
                  ),
                  DrawerItem(
                    icon: Icons.history,
                    title: 'Previous Logs',
                    onTap: () {
                      context.go('/contacts');
                    },
                  ),
                  DrawerItem(
                    icon: Icons.contacts,
                    title: 'Manage Contacts',
                    onTap: () {
                      context.read<HomeBloc>().add(ShowContactsEvent());
                      context.go('/manage_contacts');
                    },
                  ),
                  const SizedBox(
                    height: 260,
                  ),
                  const Divider(),
                  DrawerItem(
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      context.go('/profile');
                    },
                  ),
                  DrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      context.go('/settings');
                    },
                  ),
                  // const Divider(),
                  DrawerItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DrawerItem Widget for Reusability
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      onTap: onTap,
    );
  }
}
