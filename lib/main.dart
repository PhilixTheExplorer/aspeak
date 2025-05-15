import 'package:flutter/material.dart';
import 'core/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "ASPEAK",
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
