import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_session.dart';
import 'data/family_cloud.dart';
import 'data/family_storage.dart';
import 'data/family_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final cloud = await FamilyCloud.connect();
  final store = FamilyStore.empty();
  final session = AppSession(store: store, prefs: prefs, storage: FamilyStorage(prefs), cloud: cloud);
  await session.restore();
  runApp(FamilyApp(store: store, session: session));
}
