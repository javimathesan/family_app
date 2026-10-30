import 'package:flutter/material.dart';

import 'app.dart';
import 'data/family_storage.dart';
import 'data/family_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FamilyStore.demo();
  final storage = await FamilyStorage.open();
  storage.attach(store);
  runApp(FamilyApp(store: store));
}
