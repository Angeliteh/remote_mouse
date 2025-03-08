import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:async';
import 'dart:convert'; // Para jsonEncode y jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Habilitado

// Nota: Para usar SharedPreferences, necesitas añadir la dependencia en pubspec.yaml:
// shared_preferences: ^2.2.2

void main() {
  // Configuración básica
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mouse Remoto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF6C5CE7), // Morado claro
        scaffoldBackgroundColor: Color(0xFF191A2E), // Azul muy oscuro casi negro
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF6C5CE7), // Morado claro
          secondary: Color(0xFF5E72EB), // Azul medio
          tertiary: Color(0xFF4834DF), // Morado oscuro
          surface: Color(0xFF262A43), // Azul oscuro
          background: Color(0xFF191A2E), // Azul muy oscuro casi negro
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C5CE7),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF5E72EB),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF262A43),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF5E72EB), width: 2),
          ),
        ),
      ),
      home: const IPConfigScreen(),
    );
  }
}

class IPConfigScreen extends StatefulWidget {
  const IPConfigScreen({Key? key}) : super(key: key);

  @override
  _IPConfigScreenState createState() => _IPConfigScreenState();
}

class _IPConfigScreenState extends State<IPConfigScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: "12345");

  @override
  void initState() {
    super.initState();
    // Habilitado para cargar configuración guardada
    _loadSavedSettings();
  }

  // Habilitado para cargar configuración guardada
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _ipController.text = prefs.getString('serverIP') ?? '';
        _portController.text = prefs.getString('serverPort') ?? '12345';
      });
      print("Configuración cargada: IP=${_ipController.text}, Puerto=${_portController.text}");
    } catch (e) {
      print("Error al cargar configuración: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('serverIP', _ipController.text);
      await prefs.setString('serverPort', _portController.text);
      print("Configuración guardada: IP=${_ipController.text}, Puerto=${_portController.text}");
    } catch (e) {
      print("Error al guardar configuración: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mouse_outlined,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Remote Mouse',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 36),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Dirección IP',
                hintText: 'Ej: 192.168.1.100',
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Puerto',
                hintText: 'Ej: 12345',
                prefixIcon: Icon(Icons.settings_ethernet),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () async {
                if (_ipController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ingresa una dirección IP'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  return;
                }
                
                // Habilitado para guardar configuración
                await _saveSettings();
                
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UltraLowLatencyMousepad(
                      serverIP: _ipController.text,
                      serverPort: _portController.text,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'CONECTAR',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase para almacenar la configuración
class MouseSettings {
  double sensitivity;
  bool hapticFeedback;
  int updateFrequency;
  bool darkMode;
  bool showDebugInfo;
  
  MouseSettings({
    this.sensitivity = 8.0, // Reducida de 15.0 a 8.0 para una sensibilidad más baja por defecto
    this.hapticFeedback = true,
    this.updateFrequency = 8,
    this.darkMode = true,
    this.showDebugInfo = false,
  });
  
  // Convertir a/desde JSON para almacenamiento
  Map<String, dynamic> toJson() => {
    'sensitivity': sensitivity,
    'hapticFeedback': hapticFeedback,
    'updateFrequency': updateFrequency,
    'darkMode': darkMode,
    'showDebugInfo': showDebugInfo,
  };
  
  factory MouseSettings.fromJson(Map<String, dynamic> json) {
    return MouseSettings(
      sensitivity: json['sensitivity'] ?? 8.0, // Reducida de 25.0 a 8.0
      hapticFeedback: json['hapticFeedback'] ?? true,
      updateFrequency: json['updateFrequency'] ?? 8,
      darkMode: json['darkMode'] ?? true,
      showDebugInfo: json['showDebugInfo'] ?? false,
    );
  }
  
  // Guardar configuración - Habilitado
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mouseSettings', jsonEncode(toJson()));
  }
  
  // Cargar configuración - Habilitado
  static Future<MouseSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString('mouseSettings');
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

class UltraLowLatencyMousepad extends StatefulWidget {
  final String serverIP;
  final String serverPort;

  const UltraLowLatencyMousepad({
    Key? key,
    required this.serverIP,
    required this.serverPort,
  }) : super(key: key);

  @override
  _UltraLowLatencyMousepadState createState() => _UltraLowLatencyMousepadState();
}

class _UltraLowLatencyMousepadState extends State<UltraLowLatencyMousepad> {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _statusMessage = "Conectando...";
  
  // Optimización de movimiento
  Offset? _lastPosition;
  
  // Configuración
  late MouseSettings _settings;
  bool _settingsLoaded = false;
  
  // Buffer para acumular movimientos
  Timer? _sendTimer;
  final List<Offset> _movementBuffer = [];
  
  // Contador de comandos
  int _commandsSent = 0;
  String _debugInfo = "";

  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado para maximizar espacio
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Cargar configuración
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    _settings = await MouseSettings.load();
    setState(() {
      _settingsLoaded = true;
    });
    
    // Conectar al servidor
    _connectToServer();
    
    // Iniciar temporizador para envío de movimientos
    _startSendTimer();
  }
  
  void _startSendTimer() {
    // Enviar comandos acumulados según la frecuencia configurada
    _sendTimer = Timer.periodic(Duration(milliseconds: _settings.updateFrequency), (_) {
      _processMovementBuffer();
    });
  }
  
  void _processMovementBuffer() {
    if (_movementBuffer.isEmpty || !_isConnected) return;
    
    // Calcular el movimiento acumulado
    double totalDx = 0;
    double totalDy = 0;
    
    for (var delta in _movementBuffer) {
      totalDx += delta.dx;
      totalDy += delta.dy;
    }
    
    // Limpiar el buffer
    _movementBuffer.clear();
    
    // Aplicar sensibilidad
    final finalDx = totalDx * _settings.sensitivity;
    final finalDy = totalDy * _settings.sensitivity;
    
    // Enviar comando si hay movimiento significativo
    if (finalDx.abs() > 0.1 || finalDy.abs() > 0.1) {
      _sendCommand("move,${finalDx.toInt()},${finalDy.toInt()}");
    }
  }

  void _connectToServer() {
    try {
      setState(() {
        _statusMessage = "Conectando...";
      });
      
      final wsUrl = 'ws://${widget.serverIP}:${widget.serverPort}';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          // Ignorar mensajes para reducir latencia
          if (_settings.showDebugInfo) {
            setState(() {
              _debugInfo += "\nRecibido: $message";
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _statusMessage = "Desconectado";
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isConnected = false;
              _statusMessage = "Error: $error";
              if (_settings.showDebugInfo) {
                _debugInfo += "\nError: $error";
              }
            });
          }
        },
      );
      
      setState(() {
        _isConnected = true;
        _statusMessage = "Conectado";
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _statusMessage = "Error al conectar";
          if (_settings.showDebugInfo) {
            _debugInfo += "\nError al conectar: $e";
          }
        });
      }
    }
  }

  void _sendCommand(String command) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(command);
        _commandsSent++;
        
        if (_settings.showDebugInfo) {
          setState(() {
            _debugInfo += "\nEnviado: $command";
            // Limitar el tamaño del debug info
            if (_debugInfo.length > 1000) {
              _debugInfo = _debugInfo.substring(_debugInfo.length - 1000);
            }
          });
        }
      } catch (e) {
        // Ignorar errores para reducir latencia
      }
    }
  }
  
  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        settings: _settings,
        onSettingsChanged: (newSettings) {
          setState(() {
            _settings = newSettings;
          });
          _settings.save();
          
          // Reiniciar el timer con la nueva frecuencia
          _sendTimer?.cancel();
          _startSendTimer();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(_isConnected ? 'Conectado' : 'Desconectado'),
        centerTitle: true,
        backgroundColor: _isConnected 
            ? Color(0xFF4834DF) // Morado oscuro
            : Color(0xFF992E2E), // Rojo oscuro
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettingsDialog,
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: Row(
        children: [
          // Área táctil principal y botones (ocupando la mayor parte)
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // Área de debug (opcional)
                if (_settings.showDebugInfo)
                  Container(
                    height: 100,
                    color: Colors.black,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _debugInfo,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                // Área táctil principal
                Expanded(
                  child: Listener(
                    // Usar Listener en lugar de GestureDetector para mínima latencia
                    onPointerDown: (event) {
                      _lastPosition = event.position;
                      if (_settings.hapticFeedback) {
                        HapticFeedback.selectionClick();
                      }
                    },
                    onPointerMove: (event) {
                      if (_lastPosition != null) {
                        // Calcular delta desde la última posición
                        final dx = event.position.dx - _lastPosition!.dx;
                        final dy = event.position.dy - _lastPosition!.dy;
                        
                        // Añadir al buffer de movimientos
                        if (dx != 0 || dy != 0) {
                          _movementBuffer.add(Offset(dx, dy));
                        }
                        
                        // Actualizar posición
                        _lastPosition = event.position;
                      }
                    },
                    onPointerUp: (event) {
                      _lastPosition = null;
                    },
                    onPointerCancel: (event) {
                      _lastPosition = null;
                    },
                    child: GestureDetector(
                      // Mantener GestureDetector solo para los gestos de tap
                      onTap: () {
                        if (_isConnected) {
                          if (_settings.hapticFeedback) {
                            HapticFeedback.lightImpact();
                          }
                          _sendCommand("click");
                        }
                      },
                      onDoubleTap: () {
                        if (_isConnected) {
                          if (_settings.hapticFeedback) {
                            HapticFeedback.mediumImpact();
                          }
                          _sendCommand("right_click");
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            // Fondo decorativo
                            Positioned.fill(
                              child: CustomPaint(
                                painter: GridPainter(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  spacing: 20,
                                ),
                              ),
                            ),
                            // Contenido principal - Simplificado, solo el icono
                            Center(
                              child: Icon(
                                Icons.touch_app,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Botones de click modernos - Más grandes
                Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  height: 90, // Aumentado de 70 a 90
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) {
                            if (_isConnected && _settings.hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                          },
                          onTap: _isConnected ? () => _sendCommand("click") : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF5E72EB),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.mouse,
                                  size: 32, // Aumentado de 24 a 32
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'CLIC IZQUIERDO', 
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14, // Aumentado de 12 a 14
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, color: Theme.of(context).colorScheme.background),
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) {
                            if (_isConnected && _settings.hapticFeedback) {
                              HapticFeedback.mediumImpact();
                            }
                          },
                          onTap: _isConnected ? () => _sendCommand("right_click") : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF4834DF),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.ads_click,
                                  size: 32, // Aumentado de 24 a 32
                                  color: Colors.white,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'CLIC DERECHO', 
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14, // Aumentado de 12 a 14
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Área de scroll a la derecha - Rediseñada y menos invasiva
          Container(
            width: 20, // Reducido aún más
            margin: EdgeInsets.only(
              top: _settings.showDebugInfo ? 100 : 16,
              right: 4,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent, // Completamente transparente
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (_isConnected) {
                  final scrollAmount = -details.delta.dy * _settings.sensitivity * 0.6;
                  _sendCommand("scroll,${scrollAmount.toInt()}");
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Indicador superior
                  Container(
                    height: 40,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      size: 16,
                    ),
                  ),
                  // Indicador inferior
                  Container(
                    height: 40,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
    }
    super.dispose();
  }
}

// Diálogo de configuración
class SettingsDialog extends StatefulWidget {
  final MouseSettings settings;
  final Function(MouseSettings) onSettingsChanged;

  const SettingsDialog({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
  }) : super(key: key);

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.primary,
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
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentSettings.sensitivity,
                      min: 1.0,
                      max: 30.0, // Reducido de 50.0 a 30.0 para mayor precisión
                      divisions: 29, // Ajustado para 30 divisiones
                      label: _currentSettings.sensitivity.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _currentSettings.sensitivity = value;
                        });
                      },
                    ),
                  ),
                ),
                Text('30.0', style: TextStyle(color: Colors.white60, fontSize: 12)), // Cambiado de 50.0 a 30.0
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
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _currentSettings.updateFrequency.toDouble(),
                      min: 4.0,  // 250Hz (valor más bajo = más rápido)
                      max: 16.0, // 60Hz (valor más alto = más lento)
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
              activeColor: Theme.of(context).colorScheme.primary,
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
              activeColor: Theme.of(context).colorScheme.primary,
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
              activeColor: Theme.of(context).colorScheme.primary,
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
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

// Clase para dibujar una cuadrícula decorativa
class GridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  
  GridPainter({required this.color, required this.spacing});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    
    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Líneas verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}