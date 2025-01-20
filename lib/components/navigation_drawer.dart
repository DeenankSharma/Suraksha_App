import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:go_router/go_router.dart';

class Navigation_Drawer extends StatelessWidget {
  const Navigation_Drawer({super.key, required this.select});
  final int select;
  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color.fromARGB(255, 0, 56, 147);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 106, 206, 245),
              primaryBlue.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color.fromARGB(255, 0, 110, 255).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      // backgroundImage: AssetImage("assets/image.jpg"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Satoshi',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'email',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerItem(
                    icon: Icons.home,
                    title: 'Home',
                    isSelected: select == 1,
                    onTap: () {
                      context.read<HomeBloc>().add(HomeScreenEvent());
                      context.go('/home');
                    },
                  ),
                  DrawerItem(
                    icon: Icons.history,
                    title: 'Previous Logs',
                    isSelected: select == 2,
                    onTap: () {
                      context.read<HomeBloc>().add(GetContactLogsEvent());
                      context.go('/contacts');
                    },
                  ),
                  DrawerItem(
                    icon: Icons.contacts,
                    title: 'Manage Contacts',
                    isSelected: select == 3,
                    onTap: () {
                      context.read<HomeBloc>().add(ShowContactsEvent());
                      context.go('/manage_contacts');
                    },
                  ),
                  const SizedBox(height: 340),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Divider(color: Colors.white54, thickness: 1),
                  ),
                  DrawerItem(
                    icon: Icons.settings,
                    title: 'Settings',
                    isSelected: select == 4,
                    onTap: () {
                      context.read<HomeBloc>().add(OpenSettingsEvent());
                      context.go('/profile');
                    },
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

class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
