import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

// Clase para almacenar la configuración del mouse
class MouseSettings {
  double sensitivity;
  bool hapticFeedback;
  int updateFrequency;
  bool darkMode;
  bool showDebugInfo;
  
  MouseSettings({
    this.sensitivity = AppConstants.defaultSensitivity,
    this.hapticFeedback = AppConstants.defaultHapticFeedback,
    this.updateFrequency = AppConstants.defaultUpdateFrequency,
    this.darkMode = AppConstants.defaultDarkMode,
    this.showDebugInfo = AppConstants.defaultShowDebugInfo,
  });
  
  // Convertir a JSON para almacenamiento
  Map<String, dynamic> toJson() => {
    'sensitivity': sensitivity,
    'hapticFeedback': hapticFeedback,
    'updateFrequency': updateFrequency,
    'darkMode': darkMode,
    'showDebugInfo': showDebugInfo,
  };
  
  // Crear objeto desde JSON
  factory MouseSettings.fromJson(Map<String, dynamic> json) {
    return MouseSettings(
      sensitivity: json['sensitivity'] ?? AppConstants.defaultSensitivity,
      hapticFeedback: json['hapticFeedback'] ?? AppConstants.defaultHapticFeedback,
      updateFrequency: json['updateFrequency'] ?? AppConstants.defaultUpdateFrequency,
      darkMode: json['darkMode'] ?? AppConstants.defaultDarkMode,
      showDebugInfo: json['showDebugInfo'] ?? AppConstants.defaultShowDebugInfo,
    );
  }
  
  // Guardar configuración
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyMouseSettings, jsonEncode(toJson()));
  }
  
  // Cargar configuración
  static Future<MouseSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(AppConstants.keyMouseSettings);
    if (settingsJson == null) {
      return MouseSettings();
    }
    try {
      return MouseSettings.fromJson(jsonDecode(settingsJson));
    } catch (e) {
      return MouseSettings();
    }
  }
} 