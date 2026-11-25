import 'package:flutter/widgets.dart';

import 'app.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthController();
  await auth.initialize();
  runApp(TermiApp(auth: auth));
}
