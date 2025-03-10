import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _statusMessage = "Desconectado";
  
  // Callbacks
  Function(String)? onStatusChanged;
  Function(String)? onMessageReceived;
  Function(int)? onCommandSent;
  
  // Contador de comandos
  int _commandsSent = 0;
  
  // Getters
  bool get isConnected => _isConnected;
  String get statusMessage => _statusMessage;
  int get commandsSent => _commandsSent;
  
  // Conectar al servidor
  Future<bool> connect(String serverIP, String serverPort) async {
    try {
      _updateStatus("Conectando...");
      
      final wsUrl = 'ws://$serverIP:$serverPort';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) {
          if (onMessageReceived != null) {
            onMessageReceived!(message.toString());
          }
        },
        onDone: () {
          _isConnected = false;
          _updateStatus("Desconectado");
        },
        onError: (error) {
          _isConnected = false;
          _updateStatus("Error: $error");
        },
      );
      
      _isConnected = true;
      _updateStatus("Conectado");
      return true;
      
    } catch (e) {
      _isConnected = false;
      _updateStatus("Error al conectar");
      return false;
    }
  }
  
  // Desconectar del servidor
  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
      _isConnected = false;
      _updateStatus("Desconectado");
    }
  }
  
  // Enviar comando al servidor
  void sendCommand(String command) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(command);
        _commandsSent++;
        
        if (onCommandSent != null) {
          onCommandSent!(_commandsSent);
        }
      } catch (e) {
        // Ignorar errores para reducir latencia
      }
    }
  }
  
  // Actualizar estado con callback
  void _updateStatus(String newStatus) {
    _statusMessage = newStatus;
    if (onStatusChanged != null) {
      onStatusChanged!(newStatus);
    }
  }
  
  // Verificar si está conectado
  bool checkConnection() {
    return _isConnected && _channel != null;
  }
} 