import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _showDeleted = false;

  bool get isDarkMode => _isDarkMode;
  bool get showDeleted => _showDeleted;

  void toggleDarkMode(value) {
    _isDarkMode = value;
    notifyListeners();
    _saveSetting();
  }

  void toggleShowDeleted(value) {
    _showDeleted = value;
    notifyListeners();
    _saveSetting();
  }

  Future<void> _saveSetting() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
    prefs.setBool('showDeleted', _showDeleted);
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _showDeleted = prefs.getBool('showDeleted') ?? false;
    notifyListeners();
  }
}

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    Provider.of<SettingsProvider>(context, listen: false).loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Row(
                children: [
                  Text("Dark mode "),
                  Switch(
                    value: context.watch<SettingsProvider>().isDarkMode,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleDarkMode(value);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Text("Montre les recettes supprimées"),
                  Switch(
                    value: context.watch<SettingsProvider>().showDeleted,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleShowDeleted(value);
                    },
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
