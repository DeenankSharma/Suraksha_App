import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/components/navigation_drawer.dart';
import 'package:flutter_setup/theme/app_theme.dart';
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
        SnackBar(
          content: const Text('Name updated successfully!'),
          backgroundColor: AppTheme.success,
        ),
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
                        CupertinoIcons.settings,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Settings',
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
          drawer: const Navigation_Drawer(select: 4),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accent.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.phone_fill,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              phoneNumber.isNotEmpty
                                  ? '+91 $phoneNumber'
                                  : 'Loading...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          CupertinoIcons.lock_fill,
                          color: AppTheme.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: TextStyle(color: AppTheme.primary),
                      hintText: 'Enter your name',
                      prefixIcon: Icon(
                        CupertinoIcons.person,
                        color: AppTheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          CupertinoIcons.checkmark_circle,
                          color: AppTheme.success,
                        ),
                        onPressed: _updateUserName,
                        tooltip: 'Save name',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(color: AppTheme.primary),
                      hintText: 'Enter your email',
                      prefixIcon: Icon(
                        CupertinoIcons.mail,
                        color: AppTheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabled: state is ProfileUpdatedState
                          ? state.isEditing
                          : false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Current Address',
                      labelStyle: TextStyle(color: AppTheme.primary),
                      hintText: 'Enter your address',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 48.0),
                        child: Icon(
                          CupertinoIcons.location_solid,
                          color: AppTheme.primary,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabled: state is ProfileUpdatedState
                          ? state.isEditing
                          : false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<HomeBloc>().add(UpdateProfileEvent(
                              email: emailController.text,
                              address: addressController.text,
                              isEditing: state is ProfileUpdatedState
                                  ? state.isEditing
                                  : false,
                            ));
                      },
                      icon: Icon(
                        state is ProfileUpdatedState && state.isEditing
                            ? CupertinoIcons.checkmark
                            : CupertinoIcons.pencil,
                      ),
                      label: Text(
                        state is ProfileUpdatedState && state.isEditing
                            ? 'Save Changes'
                            : 'Edit Profile',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: AppTheme.accent.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    CupertinoIcons.shield_lefthalf_fill,
                    'About Suraksha',
                    'Women safety app for emergency situations',
                    AppTheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    CupertinoIcons.info_circle,
                    'Version',
                    '1.0.0',
                    AppTheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    CupertinoIcons.heart_fill,
                    'Support',
                    'Contact us for help and support MDGSPACE',
                    AppTheme.error,
                  ),
                ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getPN() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final pn = prefs.getString('pn');
    return pn ?? '';
  }
}
