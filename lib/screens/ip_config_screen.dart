import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../utils/helpers.dart';
import 'mousepad_screen.dart';

class IPConfigScreen extends StatefulWidget {
  const IPConfigScreen({Key? key}) : super(key: key);

  @override
  _IPConfigScreenState createState() => _IPConfigScreenState();
}

class _IPConfigScreenState extends State<IPConfigScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _deviceNameController = TextEditingController();
  
  List<Map<String, String>> _savedDevices = [];
  bool _isLoading = true;
  bool _showNameDialog = false;

  @override
  void initState() {
    super.initState();
    // Cargar configuración guardada
    _loadSavedSettings();
  }

  // Cargar configuración guardada
  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar última IP usada
      final lastIP = prefs.getString(AppConstants.keyServerIP) ?? '';
      
      // Cargar lista de dispositivos guardados
      final savedDevicesJson = prefs.getString(AppConstants.keySavedDevices) ?? '[]';
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
      await prefs.setString(AppConstants.keyServerIP, _ipController.text);
      
      // Guardar lista de dispositivos
      await prefs.setString(AppConstants.keySavedDevices, jsonEncode(_savedDevices));
      
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
  
  void _showAddDeviceDialog([String initialIP = '']) {
    _ipController.text = initialIP;
    _deviceNameController.text = initialIP.isNotEmpty 
      ? Helpers.generateDefaultDeviceName(initialIP)
      : '';
    
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
                ? Helpers.generateDefaultDeviceName(ip)
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

  void _connectToDevice(String ip, String name) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MousepadScreen(
          serverIP: ip,
          serverPort: AppConstants.defaultPort,
          deviceName: name,
        ),
      ),
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
                      onPressed: () => _showAddDeviceDialog(),
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
                                      onPressed: () => _showAddDeviceDialog(ip),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.connect_without_contact, color: Colors.white70),
                                      onPressed: () => _connectToDevice(ip, name),
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