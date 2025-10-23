import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/router/router_config.dart';
import 'package:flutter_setup/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GoRouter>(
      future: AppRouter.initializeRouter(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return BlocProvider(
            create: (context) => HomeBloc(),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Suraksha - Women Safety App',
              theme: AppTheme.lightTheme,
              routerConfig: snapshot.data,
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
