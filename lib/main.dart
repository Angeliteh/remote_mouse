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
  final TextEditingController _deviceNameController = TextEditingController();
  final String _defaultPort = "12345";
  
  // Lista de IPs guardadas
  List<Map<String, String>> _savedDevices = [];
  bool _isLoading = true;
  bool _showNameDialog = false;

  @override
  void initState() {
    super.initState();
    // Habilitado para cargar configuración guardada
    _loadSavedSettings();
  }

  // Cargar configuración guardada
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar última IP usada
      final lastIP = prefs.getString('serverIP') ?? '';
      
      // Cargar lista de dispositivos guardados
      final savedDevicesJson = prefs.getString('savedDevices') ?? '[]';
      List<dynamic> devicesList = [];
      
      try {
        devicesList = jsonDecode(savedDevicesJson);
      } catch (e) {
        print("Error al decodificar dispositivos: $e");
      }
      
      setState(() {
        _ipController.text = lastIP;
        _savedDevices = devicesList.map<Map<String, String>>((device) => 
          Map<String, String>.from(device)).toList();
        _isLoading = false;
      });
      
      print("Configuración cargada: IP=${_ipController.text}, Dispositivos guardados=${_savedDevices.length}");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error al cargar configuración: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar IP actual
      await prefs.setString('serverIP', _ipController.text);
      
      // Guardar lista de dispositivos
      await prefs.setString('savedDevices', jsonEncode(_savedDevices));
      
      print("Configuración guardada: IP=${_ipController.text}, Dispositivos guardados=${_savedDevices.length}");
    } catch (e) {
      print("Error al guardar configuración: $e");
    }
  }
  
  Future<void> _addDevice(String ip, String name) async {
    try {
      // Verificar si ya existe la IP
      int existingIndex = _savedDevices.indexWhere((device) => device['ip'] == ip);
      
      setState(() {
        if (existingIndex >= 0) {
          // Actualizar el nombre si ya existe
          _savedDevices[existingIndex]['name'] = name;
        } else {
          // Añadir nuevo dispositivo
          _savedDevices.add({
            'ip': ip,
            'name': name,
          });
        }
      });
      
      await _saveSettings();
    } catch (e) {
      print("Error al añadir dispositivo: $e");
    }
  }
  
  Future<void> _removeDevice(String ip) async {
    try {
      setState(() {
        _savedDevices.removeWhere((device) => device['ip'] == ip);
      });
      
      await _saveSettings();
    } catch (e) {
      print("Error al eliminar dispositivo: $e");
    }
  }
  
  void _showAddDeviceDialog(BuildContext context, [String initialIP = '']) {
    _ipController.text = initialIP;
    _deviceNameController.text = initialIP.isNotEmpty ? 'PC-${initialIP.split('.').last}' : '';
    
    setState(() {
      _showNameDialog = true;
    });
  }
  
  Widget _nameDialogContent() {
    return AlertDialog(
      title: Text('Añadir dispositivo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: InputDecoration(
              labelText: 'Dirección IP',
              hintText: 'Ej: 192.168.1.100',
              prefixIcon: Icon(Icons.wifi),
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _deviceNameController,
            decoration: InputDecoration(
              labelText: 'Nombre del dispositivo',
              hintText: 'Ej: PC de trabajo',
              prefixIcon: Icon(Icons.computer),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showNameDialog = false;
            });
          },
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_ipController.text.isEmpty) {
              return;
            }
            
            final ip = _ipController.text;
            final name = _deviceNameController.text.isEmpty 
                ? 'PC-${ip.split('.').last}' 
                : _deviceNameController.text;
            
            await _addDevice(ip, name);
            
            setState(() {
              _showNameDialog = false;
            });
          },
          child: Text('Guardar'),
        ),
      ],
    );
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
      body: Stack(
        children: [
          _isLoading 
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Padding(
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
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text("NUEVO DISPOSITIVO"),
                    onPressed: () => _showAddDeviceDialog(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                  
                  if (_savedDevices.isNotEmpty) ...[
                    SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Dispositivos guardados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _savedDevices.length,
                        itemBuilder: (context, index) {
                          final device = _savedDevices[index];
                          final ip = device['ip'] ?? '';
                          final name = device['name'] ?? 'Dispositivo sin nombre';
                          
                          return Card(
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 0,
                            margin: EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.computer, color: Theme.of(context).colorScheme.primary),
                              title: Text(name, style: TextStyle(color: Colors.white)),
                              subtitle: Text(ip, style: TextStyle(color: Colors.white70, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.white70),
                                    onPressed: () => _showAddDeviceDialog(context, ip),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.connect_without_contact, color: Colors.white70),
                                    onPressed: () async {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UltraLowLatencyMousepad(
                                            serverIP: ip,
                                            serverPort: _defaultPort,
                                            deviceName: name,
                    ),
                  ),
                );
              },
                                    tooltip: 'Conectar',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.white70),
                                    onPressed: () => _removeDevice(ip),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
          if (_showNameDialog)
            Center(
              child: _nameDialogContent(),
            ),
        ],
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
  final String deviceName;

  const UltraLowLatencyMousepad({
    Key? key,
    required this.serverIP,
    required this.serverPort,
    required this.deviceName,
  }) : super(key: key);

  @override
  UltraLowLatencyMousepadState createState() => UltraLowLatencyMousepadState();
}

class UltraLowLatencyMousepadState extends State<UltraLowLatencyMousepad> {
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
  
  // Control de teclado
  bool _showKeyboard = false;
  final TextEditingController _textController = TextEditingController();
  String _textBuffer = "";
  Timer? _keyboardVisibilityTimer;
  bool _showTextPreview = false;
  bool _showSpecialKeys = false;
  String _lastText = ""; // Para rastrear cambios en el texto
  
  // Añadir modos de teclado
  bool _isEditingText = false;
  
  // Añadir un flag para controlar si se está en modo scroll
  bool _isScrolling = false;

  // Nuevo sistema de teclado directo
  final FocusNode _keyboardFocusNode = FocusNode();
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado para maximizar espacio
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Configurar listener para detectar cambios en el texto
    _textController.addListener(_onTextChanged);
    
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

  // Método para detectar cambios en el texto en tiempo real
  void _onTextChanged() {
    if (!_isConnected || !_isEditingText) return;
    
    final newText = _textController.text;
    
    // Si el texto es más corto, se ha borrado algo
    if (newText.length < _lastText.length) {
      // Determinar cuántos caracteres se borraron
      final diff = _lastText.length - newText.length;
      
      // Enviar comando de retroceso (backspace) tantas veces como caracteres borrados
      for (int i = 0; i < diff; i++) {
        _sendCommand("key,backspace");
      }
    } 
    // Si el texto es más largo, se ha añadido algo
    else if (newText.length > _lastText.length) {
      // Obtener el texto añadido (los últimos caracteres)
      final addedText = newText.substring(_lastText.length);
      
      // Enviar el texto añadido
      _sendCommand("type,$addedText");
    }
    
    // Actualizar el último texto conocido
    _lastText = newText;
    
    // Actualizar también el textBuffer para mantener sincronizado
    _textBuffer = newText;
    if (newText.isNotEmpty) {
      _showTextPreview = true;
      
      // Reiniciar el temporizador para ocultar la vista previa
      _keyboardVisibilityTimer?.cancel();
      _keyboardVisibilityTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showTextPreview = false;
          });
        }
      });
    }
  }

  void _toggleKeyboard() {
    setState(() {
      _showKeyboard = !_showKeyboard;
      _showSpecialKeys = false;
      
      if (_showKeyboard) {
        _isEditingText = true;
        // No seleccionamos todo el texto automáticamente para permitir edición más natural
        _textController.text = _textBuffer;
      } else {
        _isEditingText = false;
      }
    });
  }
  
  void _startEditing() {
    setState(() {
      _isEditingText = true;
    });
  }
  
  void _stopEditing() {
    setState(() {
      _isEditingText = false;
    });
  }

  void _sendKey(String key) {
    if (_isConnected) {
      _sendCommand("key,$key");
      
      if (_settings.hapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }
  
  void _toggleSpecialKeys() {
    setState(() {
      _showSpecialKeys = !_showSpecialKeys;
    });
  }

  // Método para gestionar las pulsaciones de teclas directamente
  void _handleKeyPress(String key) {
    if (!_isConnected) return;
    
    // Enviar el comando de tecla directamente al PC
    _sendCommand("type,$key");
    
    // Actualizar el buffer de texto y mostrar vista previa
    setState(() {
      _textBuffer = key;
      _showTextPreview = true;
    });
    
    // Cancelar cualquier temporizador anterior
    _previewTimer?.cancel();
    
    // Configurar un temporizador para ocultar la vista previa después de un tiempo
    _previewTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        _showTextPreview = false;
      });
    });
    
    if (_settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
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
        title: Row(
          children: [
            // Icono de estado
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            // Nombre del dispositivo
            Expanded(
              child: Text(
                widget.deviceName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
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
      // Botón flotante para mostrar/ocultar el teclado
      floatingActionButton: Opacity(
        opacity: _showKeyboard ? 0.0 : 0.6, // Oculto cuando el teclado está visible
        child: Container(
          height: 40,
          width: 40,
          child: FloatingActionButton(
            onPressed: _toggleKeyboard,
            child: Icon(Icons.keyboard, size: 20),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.primary,
            elevation: 2,
            mini: true,
            tooltip: 'Teclado',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      body: Column(
        children: [
          // Área de vista previa de texto (condicional)
          if (_showTextPreview && _textBuffer.isNotEmpty && !_showKeyboard)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _textBuffer,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 16),
                    onPressed: _toggleKeyboard,
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
          // Área principal
          Expanded(
            child: Stack(
              children: [
                // Área táctil principal y botones
                Column(
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
                                  "Comandos enviados: $_commandsSent\n$_debugInfo",
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
                        // Usar Listener para mínima latencia
                        onPointerDown: (event) {
                          // Ignorar si está en modo scroll
                          if (_isScrolling) return;
                          
                          _lastPosition = event.position;
                          if (_settings.hapticFeedback) {
                            HapticFeedback.selectionClick();
                          }
                        },
                        onPointerMove: (event) {
                          // Ignorar si está en modo scroll
                          if (_isScrolling) return;
                          
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
                          // Mantener GestureDetector para el tap simple
                          onTap: () {
                            if (_isConnected) {
                              if (_settings.hapticFeedback) {
                                HapticFeedback.lightImpact();
                              }
                              _sendCommand("click");
                            }
                          },
                          child: Stack(
                            children: [
                              // Contenedor principal del pad
                              Container(
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
                              
                              // Área de scroll a la derecha
                              Positioned(
                                right: 8,
                                top: 16,
                                bottom: 16,
                                child: Container(
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onVerticalDragStart: (_) {
                                      // Activar modo scroll
                                      setState(() {
                                        _isScrolling = true;
                                      });
                                    },
                                    onVerticalDragUpdate: (details) {
                                      if (_isConnected) {
                                        final scrollAmount = -details.delta.dy * _settings.sensitivity * 0.6;
                                        _sendCommand("scroll,${scrollAmount.toInt()}");
                                      }
                                    },
                                    onVerticalDragEnd: (_) {
                                      // Desactivar modo scroll
                                      Future.delayed(Duration(milliseconds: 200), () {
                                        setState(() {
                                          _isScrolling = false;
                                        });
                                      });
                                    },
                                    onVerticalDragCancel: () {
                                      // Desactivar modo scroll
                                      setState(() {
                                        _isScrolling = false;
                                      });
                                    },
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Indicador superior
                                        Container(
                                          height: 40,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_up,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                            size: 16,
                                          ),
                                        ),
                                        // Indicador inferior
                                        Container(
                                          height: 40,
                                          width: 20,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Capa de bloqueo para el pad cuando se está haciendo scroll
                              if (_isScrolling)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.transparent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Botones de click modernos - Más grandes
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      height: 90,
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
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 28,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'IZQUIERDO', 
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
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
                              onTap: _isConnected ? () => _sendCommand("middle_click") : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.adjust_outlined,
                                      size: 28,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'CENTRAL', 
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
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
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.menu,
                                      size: 28,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'DERECHO', 
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w400,
                                        fontSize: 12,
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
                
                // Panel de teclado (solo si está activo)
                if (_showKeyboard)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Fila superior con botones de acción
                          Row(
                            children: [
                              Text(
                                "Teclado",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Spacer(),
                              // Botón para simular Enter
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_return,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: () => _sendKey('enter'),
                                tooltip: 'Enter',
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8),
                              // Botón para teclas especiales
                              IconButton(
                                icon: Icon(
                                  _showSpecialKeys ? Icons.keyboard : Icons.keyboard_option_key,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: _toggleSpecialKeys,
                                tooltip: 'Teclas especiales',
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                              SizedBox(width: 8),
                              // Botón para cerrar teclado
                              IconButton(
                                icon: Icon(
                                  Icons.keyboard_hide,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                onPressed: _toggleKeyboard,
                                tooltip: 'Cerrar teclado',
                                padding: EdgeInsets.all(8),
                                constraints: BoxConstraints(),
                              ),
                            ],
                          ),
                          
                          // Instrucciones para el usuario
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "Escribe texto normalmente y se enviará a la PC en tiempo real. Usa la tecla ENTER para hacer saltos de línea y la tecla de borrado para eliminar texto.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          
                          // Teclas especiales (condicional)
                          if (_showSpecialKeys)
                            Container(
                              height: 200,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Teclas de navegación
                                    Text(
                                      "Navegación:",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildSpecialKey('up', '↑'),
                                        _buildSpecialKey('down', '↓'),
                                        _buildSpecialKey('left', '←'),
                                        _buildSpecialKey('right', '→'),
                                        _buildSpecialKey('home', 'HOME'),
                                        _buildSpecialKey('end', 'END'),
                                        _buildSpecialKey('pageup', 'PGUP'),
                                        _buildSpecialKey('pagedown', 'PGDN'),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    
                                    // Teclas de función
                                    Text(
                                      "Función:",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildSpecialKey('f1', 'F1'),
                                        _buildSpecialKey('f2', 'F2'),
                                        _buildSpecialKey('f3', 'F3'),
                                        _buildSpecialKey('f4', 'F4'),
                                        _buildSpecialKey('f5', 'F5'),
                                        _buildSpecialKey('f6', 'F6'),
                                        _buildSpecialKey('f7', 'F7'),
                                        _buildSpecialKey('f8', 'F8'),
                                        _buildSpecialKey('f9', 'F9'),
                                        _buildSpecialKey('f10', 'F10'),
                                        _buildSpecialKey('f11', 'F11'),
                                        _buildSpecialKey('f12', 'F12'),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    
                                    // Teclas modificadoras
                                    Text(
                                      "Modificadores:",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildSpecialKey('ctrl', 'CTRL'),
                                        _buildSpecialKey('alt', 'ALT'),
                                        _buildSpecialKey('shift', 'SHIFT'),
                                        _buildSpecialKey('win', 'WIN'),
                                        _buildSpecialKey('esc', 'ESC'),
                                        _buildSpecialKey('tab', 'TAB'),
                                        _buildSpecialKey('insert', 'INS'),
                                        _buildSpecialKey('delete', 'DEL'),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    
                                    // Combinaciones comunes
                                    Text(
                                      "Combinaciones:",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildComboKey('ctrl+c', 'CTRL+C'),
                                        _buildComboKey('ctrl+v', 'CTRL+V'),
                                        _buildComboKey('ctrl+x', 'CTRL+X'),
                                        _buildComboKey('ctrl+z', 'CTRL+Z'),
                                        _buildComboKey('ctrl+a', 'CTRL+A'),
                                        _buildComboKey('alt+tab', 'ALT+TAB'),
                                        _buildComboKey('alt+f4', 'ALT+F4'),
                                        _buildComboKey('win+d', 'WIN+D'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Campo de texto con acciones rápidas
                          if (!_showSpecialKeys)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Campo de texto
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    decoration: InputDecoration(
                                      hintText: 'Escribe texto...',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    autofocus: true,
                                    maxLines: 3,  // Permitir múltiples líneas
                                    keyboardType: TextInputType.multiline,  // Teclado con soporte para múltiples líneas
                                    textInputAction: TextInputAction.newline,  // Configurar la tecla de acción como nueva línea
                                    onTap: _startEditing,
                                    onEditingComplete: _stopEditing,
                                  ),
                                ),
                                // Botón de borrar
                                IconButton(
                                  icon: Icon(
                                    Icons.backspace_outlined,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => _sendKey('backspace'),
                                  tooltip: 'Borrar',
                                ),
                              ],
                            ),
                            
                          // Botones de acción rápida
                          if (!_showSpecialKeys)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Botón para borrar todo
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.clear_all, size: 16),
                                    label: Text('Borrar todo'),
                                    onPressed: () {
                                      setState(() {
                                        _textController.clear();
                                        _textBuffer = '';
                                        _lastText = '';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                  // Botón para Enter
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.keyboard_return, size: 16),
                                    label: Text('Enter'),
                                    onPressed: () => _sendKey('enter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      foregroundColor: Theme.of(context).colorScheme.primary,
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialKey(String keyCode, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _sendKey(keyCode),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Método para crear botones de combinaciones de teclas
  Widget _buildComboKey(String combo, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _sendComboCommand(combo),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  // Método para enviar combinaciones de teclas
  void _sendComboCommand(String combo) {
    if (!_isConnected) return;
    
    // Dividir la combinación en teclas individuales
    final keys = combo.split('+');
    
    // Presionar todas las teclas en orden
    for (var key in keys) {
      _sendCommand("keydown,$key");
    }
    
    // Pequeña pausa para que el sistema registre la combinación
    Future.delayed(Duration(milliseconds: 100), () {
      // Soltar todas las teclas en orden inverso
      for (var key in keys.reversed) {
        _sendCommand("keyup,$key");
      }
    });
    
    if (_settings.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    _keyboardVisibilityTimer?.cancel();
    _previewTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _keyboardFocusNode.dispose();
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