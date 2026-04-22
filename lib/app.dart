import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/navigation/route_observer.dart';
import 'package:yastik_alti/ui/screens/root_screen.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart'; //

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yastık Altı',
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: AppColors.background,
      ),

      navigatorObservers: [routeObserver],

      home: const RootScreen(),
    );
  }
}