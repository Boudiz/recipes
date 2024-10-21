import 'package:flutter/widgets.dart';

import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await deleteDatabase("recipes_database.db");
}
