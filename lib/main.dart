import 'package:flutter/material.dart';

import 'app.dart';
import 'services/expense_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(SpendTrackApp(repository: ExpenseDatabase()));
}
