import 'package:flutter/material.dart';
import '../models/mouse_settings.dart';

class SettingsDialog extends StatefulWidget {
  final MouseSettings settings;
  final Function(MouseSettings) onSettingsChanged;

  const SettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  SettingsDialogState createState() => SettingsDialogState();
}

class SettingsDialogState extends State<SettingsDialog> {
  late MouseSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    // Crear una copia de la configuración para no modificar la original
    _currentSettings = MouseSettings(
      sensitivity: widget.settings.sensitivity,
      hapticFeedback: widget.settings.hapticFeedback,
      updateFrequency: widget.settings.updateFrequency,
      darkMode: widget.settings.darkMode,
      showDebugInfo: widget.settings.showDebugInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 10),
                Text(
                  'Configuración',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Divider(color: Colors.white12, thickness: 1),
            const SizedBox(height: 16),
            
            // Sensibilidad
            Text(
              'Sensibilidad del mouse:',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('1.0', style: TextStyle(color: Colors.white60, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentSettings.sensitivity,
                      min: 1.0,
                      max: 30.0,
                      divisions: 29,
                      label: _currentSettings.sensitivity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _currentSettings.sensitivity = value;
                        });
                      },
                    ),
                  ),
                ),
                Text('30.0', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Frecuencia de actualización
            Text(
              'Frecuencia de actualización:',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Lenta', style: TextStyle(color: Colors.white60, fontSize: 12)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: theme.colorScheme.primary,
                      inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentSettings.updateFrequency.toDouble(),
                      min: 4.0,
                      max: 16.0,
                      divisions: 6,
                      label: "${(1000 / _currentSettings.updateFrequency).round()} Hz",
                      onChanged: (value) {
                        setState(() {
                          _currentSettings.updateFrequency = value.toInt();
                        });
                      },
                    ),
                  ),
                ),
                Text('Rápida', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Opciones adicionales
            SwitchListTile(
              title: Text('Feedback táctil', style: TextStyle(color: Colors.white70)),
              subtitle: Text('Vibración al hacer clic', style: TextStyle(color: Colors.white38, fontSize: 12)),
              activeColor: theme.colorScheme.primary,
              value: _currentSettings.hapticFeedback,
              onChanged: (value) {
                setState(() {
                  _currentSettings.hapticFeedback = value;
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Modo oscuro', style: TextStyle(color: Colors.white70)),
              subtitle: Text('Interfaz con fondo negro', style: TextStyle(color: Colors.white38, fontSize: 12)),
              activeColor: theme.colorScheme.primary,
              value: _currentSettings.darkMode,
              onChanged: (value) {
                setState(() {
                  _currentSettings.darkMode = value;
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Información de depuración', style: TextStyle(color: Colors.white70)),
              subtitle: Text('Mostrar mensajes técnicos', style: TextStyle(color: Colors.white38, fontSize: 12)),
              activeColor: theme.colorScheme.primary,
              value: _currentSettings.showDebugInfo,
              onChanged: (value) {
                setState(() {
                  _currentSettings.showDebugInfo = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCELAR'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onSettingsChanged(_currentSettings);
                    Navigator.of(context).pop();
                  },
                  child: const Text('GUARDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 