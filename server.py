import asyncio
import websockets
import pyautogui
import keyboard
import socket
import argparse
import logging
from datetime import datetime

# Configuración básica de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger('remote_mouse_server')

# Configuración para máxima velocidad
pyautogui.FAILSAFE = True
pyautogui.MINIMUM_DURATION = 0
pyautogui.MINIMUM_SLEEP = 0
pyautogui.PAUSE = 0

class RemoteMouseServer:
    def __init__(self, host='0.0.0.0', port=12345, sensitivity=1.0, debug=False):
        self.host = host
        self.port = port
        self.debug = debug
        self.mouse_sensitivity = sensitivity
        self.pressed_keys = set()
        self.start_time = datetime.now()
        
    async def handle_client(self, websocket):
        """Manejador principal para conexiones WebSocket"""
        client_info = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        logger.info(f"Cliente conectado: {client_info}")
        
        try:
            async for message in websocket:
                if self.debug:
                    logger.info(f"Recibido: {message}")
                
                await self.process_message(message)
                
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Cliente desconectado: {client_info}")
            
            # Liberar teclas presionadas al desconectar
            for key in list(self.pressed_keys):
                try:
                    keyboard.release(key)
                    self.pressed_keys.remove(key)
                except Exception as e:
                    if self.debug:
                        logger.error(f"Error al liberar tecla {key}: {e}")
    
    async def process_message(self, message):
        """Procesar los mensajes recibidos del cliente"""
        try:
            parts = message.split(',')
            command = parts[0]
            
            # Procesar comandos de movimiento (prioridad máxima)
            if command == "move":
                if len(parts) >= 3:
                    # Aplicar sensibilidad y convertir a enteros
                    dx = int(float(parts[1]) * self.mouse_sensitivity)
                    dy = int(float(parts[2]) * self.mouse_sensitivity)
                    # Usar moveRel para mayor velocidad
                    pyautogui.moveRel(dx, dy, _pause=False)
            
            # Comandos de ratón
            elif command == "click":
                pyautogui.click(_pause=False)
            elif command == "right_click":
                pyautogui.rightClick(_pause=False)
            elif command == "middle_click":
                pyautogui.middleClick(_pause=False)
            elif command == "scroll":
                if len(parts) >= 2:
                    amount = int(float(parts[1]))
                    pyautogui.scroll(amount, _pause=False)
            
            # Comandos de teclado
            elif command == "key":
                if len(parts) >= 2:
                    key = parts[1]
                    pyautogui.press(key, _pause=False)
            elif command == "keydown":
                if len(parts) >= 2:
                    key = parts[1]
                    keyboard.press(key)
                    self.pressed_keys.add(key)
            elif command == "keyup":
                if len(parts) >= 2:
                    key = parts[1]
                    keyboard.release(key)
                    if key in self.pressed_keys:
                        self.pressed_keys.remove(key)
            elif command == "type":
                # El texto puede contener comas, así que tomamos todo después de "type,"
                text = message[5:]
                pyautogui.write(text, _pause=False)
                
        except Exception as e:
            if self.debug:
                logger.error(f"Error al procesar mensaje: {e}")
    
    def get_local_ip(self):
        """Obtener la dirección IP local"""
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"
    
    def show_connection_info(self):
        """Mostrar información de conexión"""
        local_ip = self.get_local_ip()
        logger.info("=" * 50)
        logger.info(f"Servidor RemoteMouse iniciado")
        logger.info(f"IP local: {local_ip}")
        logger.info(f"Puerto: {self.port}")
        logger.info(f"URL de conexión: ws://{local_ip}:{self.port}")
        logger.info("=" * 50)
        logger.info("Para conectar desde la app, usa la dirección IP anterior.")
        logger.info("Presiona Ctrl+C para detener el servidor.")
    
    async def start(self):
        """Iniciar el servidor WebSocket"""
        self.show_connection_info()
        
        async with websockets.serve(self.handle_client, self.host, self.port):
            # Ejecutar indefinidamente hasta que se interrumpa
            await asyncio.Future()

def main():
    parser = argparse.ArgumentParser(description='Servidor RemoteMouse Optimizado')
    parser.add_argument('--host', default='0.0.0.0', help='Dirección IP para escuchar (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=12345, help='Puerto para escuchar (default: 12345)')
    parser.add_argument('--sensitivity', type=float, default=1.0, help='Sensibilidad del mouse (default: 1.0)')
    parser.add_argument('--debug', action='store_true', help='Habilitar mensajes de depuración')
    args = parser.parse_args()
    
    # Crear y ejecutar el servidor
    server = RemoteMouseServer(
        host=args.host, 
        port=args.port, 
        sensitivity=args.sensitivity,
        debug=args.debug
    )
    
    try:
        asyncio.run(server.start())
    except KeyboardInterrupt:
        logger.info("Servidor detenido por el usuario")
    except Exception as e:
        logger.error(f"Error en el servidor: {e}")

if __name__ == "__main__":
    main() 