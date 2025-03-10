import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Helpers {
  // Ocultar barra de estado para maximizar espacio
  static void setFullScreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  // Generar nombre predeterminado para un dispositivo basado en su IP
  static String generateDefaultDeviceName(String ip) {
    if (ip.isEmpty) return 'Dispositivo';
    
    final parts = ip.split('.');
    if (parts.length > 0) {
      return 'PC-${parts.last}';
    }
    return 'PC-$ip';
  }
  
  // Ejecutar vibración si está habilitada
  static void vibrate({bool hapticFeedback = true, bool isStrong = false}) {
    if (hapticFeedback) {
      if (isStrong) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }
  
  // Reducir el tamaño del log para evitar problemas de memoria
  static String trimLog(String log, int maxLength) {
    if (log.length > maxLength) {
      return log.substring(log.length - maxLength);
    }
    return log;
  }
} 