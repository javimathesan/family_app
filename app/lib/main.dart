import 'package:flutter/material.dart';

import 'app.dart';
import 'data/family_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = FamilyStore.demo();
  runApp(FamilyApp(store: store));
}
