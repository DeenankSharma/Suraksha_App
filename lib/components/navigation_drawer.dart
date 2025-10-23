import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navigation_Drawer extends StatefulWidget {
  const Navigation_Drawer({super.key, required this.select});
  final int select;

  @override
  State<Navigation_Drawer> createState() => _Navigation_DrawerState();
}

class _Navigation_DrawerState extends State<Navigation_Drawer> {
  String userName = 'User';
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'User';
      final phone = prefs.getString('pn') ?? '';

      setState(() {
        userName = name;
        phoneNumber = phone.isNotEmpty ? '+91 $phone' : 'Phone not set';
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        top: false,
        child: Container(
          color: AppTheme.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
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
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  DrawerItem(
                    icon: CupertinoIcons.home,
                    title: 'Home',
                    isSelected: widget.select == 1,
                    onTap: () {
                      context.read<HomeBloc>().add(HomeScreenEvent());
                      context.go('/home');
                    },
                  ),
                  DrawerItem(
                    icon: CupertinoIcons.time,
                    title: 'Activity Logs',
                    isSelected: widget.select == 2,
                    onTap: () {
                      context.read<HomeBloc>().add(GetContactLogsEvent());
                      context.go('/contacts');
                    },
                  ),
                  DrawerItem(
                    icon: CupertinoIcons.person_2_fill,
                    title: 'Emergency Contacts',
                    isSelected: widget.select == 3,
                    onTap: () {
                      context.read<HomeBloc>().add(ShowContactsEvent());
                      context.go('/manage_contacts');
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      color: AppTheme.accent.withOpacity(0.5),
                      thickness: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DrawerItem(
                    icon: CupertinoIcons.settings,
                    title: 'Settings',
                    isSelected: widget.select == 4,
                    onTap: () {
                      context.read<HomeBloc>().add(OpenSettingsEvent());
                      context.go('/profile');
                    },
                  ),
                ],
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accent.withOpacity(0.3),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Suraksha',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? AppTheme.primary.withOpacity(0.1)
            : Colors.transparent,
        border: isSelected
            ? Border.all(
                color: AppTheme.primary.withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
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
