import 'package:flutter/cupertino.dart';

import 'app/bule_app.dart';
import 'data/repositories/local_app_repository.dart';
import 'data/services/local/preferences_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(BuleApp(repository: LocalAppRepository(PreferencesStore())));
}
