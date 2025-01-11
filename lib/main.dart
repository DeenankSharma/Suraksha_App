import 'package:flutter/material.dart';
import 'package:flutter_setup/bloc/home_bloc.dart';
import 'package:flutter_setup/router/router_config.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HomeBloc>(create: (context) => HomeBloc()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme:
            ThemeData(primaryColor: const Color.fromARGB(255, 106, 206, 245)),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
