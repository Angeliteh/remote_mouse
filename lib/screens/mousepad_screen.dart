import 'package:flutter/material.dart';
import 'dart:async';
import '../models/mouse_settings.dart';
import '../services/websocket_service.dart';
import '../utils/helpers.dart';
import '../widgets/grid_painter.dart';
import '../widgets/settings_dialog.dart';

class MousepadScreen extends StatefulWidget {
  final String serverIP;
  final String serverPort;
  final String deviceName;

  const MousepadScreen({
    super.key,
    required this.serverIP,
    required this.serverPort,
    required this.deviceName,
  });

  @override
  MousepadScreenState createState() => MousepadScreenState();
}

class MousepadScreenState extends State<MousepadScreen> {
  // WebSocket service
  final WebSocketService _websocketService = WebSocketService();
  
  // Optimización de movimiento
  Offset? _lastPosition;
  
  // Configuración
  late MouseSettings _settings;
  bool _settingsLoaded = false;
  
  // Buffer para acumular movimientos
  Timer? _sendTimer;
  final List<Offset> _movementBuffer = [];
  
  // Info de depuración
  String _debugInfo = "";
  
  // Control de teclado
  bool _showKeyboard = false;
  final TextEditingController _textController = TextEditingController();
  String _textBuffer = "";
  Timer? _keyboardVisibilityTimer;
  bool _showTextPreview = false;
  String _lastText = ""; // Para rastrear cambios en el texto
  
  // Estado de edición de texto
  bool _isEditingText = false;
  
  // Estado de scroll
  bool _isScrolling = false;

  // Teclado directo
  final FocusNode _keyboardFocusNode = FocusNode();
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    // Ocultar barra de estado para maximizar espacio
    Helpers.setFullScreenMode();
    
    // Configurar listener para detectar cambios en el texto
    _textController.addListener(_onTextChanged);
    
    // Configurar callbacks del servicio WebSocket
    _setupWebSocketCallbacks();
    
    // Cargar configuración
    _loadSettings();
  }
  
  void _setupWebSocketCallbacks() {
    _websocketService.onStatusChanged = (status) {
      if (mounted) {
        setState(() {
          // Actualizar estado si es necesario
        });
      }
    };
    
    _websocketService.onMessageReceived = (message) {
      if (_settings.showDebugInfo) {
        setState(() {
          _debugInfo += "\nRecibido: $message";
          _debugInfo = Helpers.trimLog(_debugInfo, 1000);
        });
      }
    };
    
    _websocketService.onCommandSent = (count) {
      if (_settings.showDebugInfo) {
        setState(() {
          // Actualizar contador si es necesario
        });
      }
    };
  }
  
  Future<void> _loadSettings() async {
    _settings = await MouseSettings.load();
    setState(() {
      _settingsLoaded = true;
    });
    
    // Conectar al servidor
    await _websocketService.connect(widget.serverIP, widget.serverPort);
    
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
    if (_movementBuffer.isEmpty || !_websocketService.isConnected) return;
    
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

  void _sendCommand(String command) {
    _websocketService.sendCommand(command);
    
    if (_settings.showDebugInfo) {
      setState(() {
        _debugInfo += "\nEnviado: $command";
        _debugInfo = Helpers.trimLog(_debugInfo, 1000);
      });
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
    if (!_websocketService.isConnected || !_isEditingText) return;
    
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
    if (!_showKeyboard) {
      // Si estamos abriendo el teclado, enfocamos el campo de texto
      _focusKeyboard();
    } else {
      // Si estamos cerrando el teclado, ocultamos el teclado del sistema
      FocusManager.instance.primaryFocus?.unfocus();
    }
    
    setState(() {
      _showKeyboard = !_showKeyboard;
      
      if (_showKeyboard) {
        _isEditingText = true;
        _textController.text = _textBuffer;
        
        // Al abrir el teclado, siempre mostramos la barra de texto
        _showTextPreview = true;
        // Cancelamos cualquier temporizador que pudiera ocultar la barra
        _keyboardVisibilityTimer?.cancel();
      } else {
        _isEditingText = false;
      }
    });
  }
  
  void _focusKeyboard() {
    // Mostrar el teclado del sistema
    Future.delayed(Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });
  }

  void _sendKey(String key) {
    if (_websocketService.isConnected) {
      _sendCommand("key,$key");
      
      if (_settings.hapticFeedback) {
        Helpers.vibrate(hapticFeedback: true);
      }
    }
  }

  // Método para crear botones de teclas especiales
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
    if (!_websocketService.isConnected) return;
    
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
      Helpers.vibrate(hapticFeedback: true, isStrong: true);
    }
  }

  // Método para borrar texto preexistente (simulando tecla backspace)
  void _sendBackspace() {
    if (_websocketService.isConnected) {
      _sendCommand("key,backspace");
      
      if (_settings.hapticFeedback) {
        Helpers.vibrate(hapticFeedback: true);
      }
      
      // Actualizar el buffer local solo si tenemos texto almacenado
      if (_textBuffer.isNotEmpty) {
        setState(() {
          _textBuffer = _textBuffer.substring(0, _textBuffer.length - 1);
          _lastText = _textBuffer;
          _textController.text = _textBuffer;
        });
      }
    }
  }
  
  // Método para borrar todo el texto (simulando múltiples backspace)
  void _clearAllText() {
    if (_websocketService.isConnected) {
      // Si hay texto en el buffer local, borramos esa cantidad de caracteres
      int amountToDelete = _textBuffer.isNotEmpty ? _textBuffer.length : 15;
      
      // Enviamos múltiples backspace para borrar el texto
      for (int i = 0; i < amountToDelete; i++) {
        _sendCommand("key,backspace");
      }
      
      setState(() {
        _textBuffer = "";
        _lastText = "";
        _textController.text = "";
      });
      
      if (_settings.hapticFeedback) {
        Helpers.vibrate(hapticFeedback: true, isStrong: true);
      }
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
                color: _websocketService.isConnected ? Colors.green : Colors.red,
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
        backgroundColor: _websocketService.isConnected 
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
      floatingActionButton: Container(
        height: 40,
        width: 40,
        child: FloatingActionButton(
          onPressed: _toggleKeyboard,
          child: Icon(_showKeyboard ? Icons.keyboard_hide : Icons.keyboard, size: 20),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 2,
          mini: true,
          tooltip: _showKeyboard ? 'Ocultar teclado' : 'Mostrar teclado',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop, // Movido a la esquina superior derecha
      body: Stack(
        children: [
          // Columna principal con el área táctil y botones
          Column(
            children: [
              // Área de vista previa de texto (siempre visible cuando se está escribiendo)
              if (_showKeyboard || (_showTextPreview && _textBuffer.isNotEmpty))
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_showKeyboard)
                        // Indicador de teclado activo
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "TECLADO",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _textBuffer.isEmpty ? "Presiona aquí para escribir..." : _textBuffer,
                          style: TextStyle(
                            color: _textBuffer.isEmpty ? Colors.white38 : Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Botón de retroceso (backspace)
                      // Siempre mostramos el botón de backspace con el teclado abierto
                      if (_showKeyboard || _textBuffer.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.backspace_outlined, size: 18),
                          onPressed: _sendBackspace,
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(),
                        ),
                      SizedBox(width: 4),
                      // Botón para limpiar todo el texto
                      if (_showKeyboard || _textBuffer.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear_all, size: 18),
                          onPressed: _clearAllText,
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
                                      "Comandos enviados: ${_websocketService.commandsSent}\n$_debugInfo",
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
                                Helpers.vibrate(hapticFeedback: true);
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
                                if (_websocketService.isConnected) {
                                  if (_settings.hapticFeedback) {
                                    Helpers.vibrate(hapticFeedback: true);
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
                                          if (_websocketService.isConnected) {
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
                                    if (_websocketService.isConnected && _settings.hapticFeedback) {
                                      Helpers.vibrate(hapticFeedback: true);
                                    }
                                  },
                                  onTap: _websocketService.isConnected ? () => _sendCommand("click") : null,
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
                                    if (_websocketService.isConnected && _settings.hapticFeedback) {
                                      Helpers.vibrate(hapticFeedback: true, isStrong: true);
                                    }
                                  },
                                  onTap: _websocketService.isConnected ? () => _sendCommand("middle_click") : null,
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
                                    if (_websocketService.isConnected && _settings.hapticFeedback) {
                                      Helpers.vibrate(hapticFeedback: true, isStrong: true);
                                    }
                                  },
                                  onTap: _websocketService.isConnected ? () => _sendCommand("right_click") : null,
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
                  ],
                ),
              ),
            ],
          ),
          
          // Teclado invisible para capturar el texto
          if (_showKeyboard)
            Positioned(
              bottom: -50, // Fuera de la pantalla para que no sea visible
              left: 0,
              right: 0,
              child: Container(
                height: 0, // Sin altura visible
                child: TextField(
                  controller: _textController,
                  focusNode: _keyboardFocusNode,
                  autofocus: true,
                  onChanged: (text) {
                    if (_isEditingText && _websocketService.isConnected) {
                      if (text.length > _lastText.length) {
                        // Se ha agregado texto
                        final addedText = text.substring(_lastText.length);
                        _sendCommand("type,$addedText");
                        setState(() {
                          _textBuffer = text;
                          _lastText = text;
                          _showTextPreview = true;
                        });
                      } else if (text.length < _lastText.length) {
                        // Se ha borrado texto
                        final diff = _lastText.length - text.length;
                        for (int i = 0; i < diff; i++) {
                          _sendCommand("key,backspace");
                        }
                        setState(() {
                          _textBuffer = text;
                          _lastText = text;
                          _showTextPreview = true;
                        });
                      }
                    }
                  },
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
    _keyboardVisibilityTimer?.cancel();
    _previewTimer?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _keyboardFocusNode.dispose();
    _websocketService.disconnect();
    super.dispose();
  }
} 