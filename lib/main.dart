import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/router/router_config.dart';
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
              title: 'Suraksha - Emergency Safety App',
              theme: ThemeData(
                primaryColor: const Color.fromARGB(255, 106, 206, 245),
                useMaterial3: true,
              ),
              routerConfig: snapshot.data,
            ),
          );
        }

        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
