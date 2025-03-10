import asyncio
import websockets
import pyautogui
import keyboard
import socket
import threading
import argparse
import logging
import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox
import time
from datetime import datetime
import sys
import os

# Intentar importar la biblioteca para la bandeja del sistema
try:
    import pystray
    from PIL import Image, ImageDraw
    TRAY_SUPPORTED = True
except ImportError:
    TRAY_SUPPORTED = False

# Configurar pyautogui para máxima velocidad
pyautogui.MINIMUM_DURATION = 0
pyautogui.MINIMUM_SLEEP = 0
pyautogui.PAUSE = 0

# Variable para ajustar la sensibilidad del movimiento del ratón
MOUSE_SENSITIVITY = 1.0

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger('RemoteMouseServer')

class RemoteMouseServer:
    def __init__(self, host='0.0.0.0', port=12345, sensitivity=1.0):
        self.host = host
        self.port = port
        self.clients = set()
        self.running = False
        self.server = None
        self.log_callback = print
        self.status_callback = None
        self.clients_callback = None
        self.command_count = 0
        self.start_time = None
        self.sensitivity = sensitivity
    
    async def ws_handler(self, websocket):
        # Registrar cliente
        client_info = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        self.clients.add(websocket)
        self.log_callback(f"Cliente conectado: {client_info}")
        
        if self.clients_callback:
            self.clients_callback(len(self.clients))
        
        try:
            # Procesar mensajes
            async for message in websocket:
                self.command_count += 1
                await self.process_message(message)
        except websockets.exceptions.ConnectionClosed:
            self.log_callback(f"Conexión cerrada: {client_info}")
        finally:
            # Eliminar cliente
            self.clients.remove(websocket)
            self.log_callback(f"Cliente desconectado: {client_info}")
            
            if self.clients_callback:
                self.clients_callback(len(self.clients))
    
    async def process_message(self, message):
        try:
            parts = message.split(',')
            command = parts[0]
            
            if command == "move":
                # Movimiento relativo del ratón
                dx, dy = int(float(parts[1]) * self.sensitivity), int(float(parts[2]) * self.sensitivity)
                pyautogui.moveRel(dx, dy, _pause=False)
            
            elif command == "click":
                # Click izquierdo
                pyautogui.click(_pause=False)
            
            elif command == "right_click":
                # Click derecho
                pyautogui.rightClick(_pause=False)
            
            elif command == "middle_click":
                # Click central
                pyautogui.middleClick(_pause=False)
            
            elif command == "scroll":
                # Desplazamiento
                amount = int(parts[1])
                pyautogui.scroll(amount, _pause=False)
            
            elif command == "key":
                # Presionar una tecla
                key = parts[1]
                pyautogui.press(key, _pause=False)
            
            elif command == "keydown":
                # Mantener presionada una tecla
                key = parts[1]
                pyautogui.keyDown(key, _pause=False)
            
            elif command == "keyup":
                # Soltar una tecla
                key = parts[1]
                pyautogui.keyUp(key, _pause=False)
            
            elif command == "type":
                # Escribir texto
                text = parts[1]
                pyautogui.write(text, _pause=False)
            
        except Exception as e:
            self.log_callback(f"Error al procesar mensaje: {e}")
    
    async def start_server(self):
        self.running = True
        self.start_time = time.time()
        self.log_callback(f"Iniciando servidor en {self.host}:{self.port}")
        
        if self.status_callback:
            self.status_callback("Iniciando...")
        
        try:
            self.server = await websockets.serve(self.ws_handler, self.host, self.port)
            
            if self.status_callback:
                self.status_callback("Ejecutando")
            
            self.log_callback(f"Servidor iniciado. Esperando conexiones...")
            self.log_callback(f"Dirección IP local: {self.get_local_ip()}")
            
            await self.server.wait_closed()
        except Exception as e:
            self.log_callback(f"Error al iniciar servidor: {e}")
            if self.status_callback:
                self.status_callback("Error")
            self.running = False
    
    def stop_server(self):
        if self.server:
            self.log_callback("Deteniendo servidor...")
            self.server.close()
            self.running = False
            if self.status_callback:
                self.status_callback("Detenido")
    
    def get_local_ip(self):
        try:
            # Crear un socket para determinar la IP local
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except Exception:
            return "127.0.0.1"
    
    def get_uptime(self):
        if self.start_time:
            uptime_seconds = int(time.time() - self.start_time)
            hours, remainder = divmod(uptime_seconds, 3600)
            minutes, seconds = divmod(remainder, 60)
            return f"{hours:02}:{minutes:02}:{seconds:02}"
        return "00:00:00"

class ServerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Remote Mouse Server")
        self.root.geometry("500x400")
        self.root.resizable(True, True)
        
        # Icono para la aplicación y la bandeja
        self.icon_data = self.create_icon_data()
        
        # Estilo
        self.style = ttk.Style()
        self.style.configure("TButton", padding=6, relief="flat", background="#4834DF")
        self.style.configure("TLabel", padding=6)
        
        # Servidor
        self.server = RemoteMouseServer()
        self.server.log_callback = self.log
        self.server.status_callback = self.update_status
        self.server.clients_callback = self.update_clients
        
        # Variables
        self.status_var = tk.StringVar(value="Detenido")
        self.ip_var = tk.StringVar(value=self.server.get_local_ip())
        self.port_var = tk.StringVar(value="12345")
        self.clients_var = tk.StringVar(value="0")
        self.commands_var = tk.StringVar(value="0")
        self.uptime_var = tk.StringVar(value="00:00:00")
        self.autostart_var = tk.BooleanVar(value=False)
        self.minimize_to_tray_var = tk.BooleanVar(value=True)
        
        # Bandeja del sistema
        self.tray_icon = None
        self.setup_tray_icon()
        
        # Crear interfaz
        self.create_widgets()
        
        # Actualizar estadísticas periódicamente
        self.update_stats()
        
        # Protocolo de cierre
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
        
        # Iniciar automáticamente si está configurado
        if self.autostart_var.get():
            self.root.after(1000, self.start_server)
    
    def create_icon_data(self):
        # Crear un icono simple para la aplicación
        width = 64
        height = 64
        img = Image.new('RGBA', (width, height), color=(0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        
        # Dibujar un círculo morado
        d.ellipse((5, 5, width-5, height-5), fill=(72, 52, 223, 255))
        
        # Dibujar un "cursor" blanco en el centro
        d.rectangle((width//2-10, height//2-10, width//2+10, height//2+10), fill=(255, 255, 255, 255))
        
        return img
    
    def setup_tray_icon(self):
        if not TRAY_SUPPORTED:
            return
            
        # Crear menú para la bandeja del sistema
        menu = (
            pystray.MenuItem('Mostrar', self.show_window),
            pystray.MenuItem('Iniciar servidor', self.start_server_from_tray),
            pystray.MenuItem('Detener servidor', self.stop_server_from_tray),
            pystray.MenuItem('Salir', self.exit_app)
        )
        
        # Crear icono de bandeja
        self.tray_icon = pystray.Icon("RemoteMouseServer", self.icon_data, "Remote Mouse Server", menu)
    
    def show_window(self, icon=None, item=None):
        # Mostrar la ventana principal
        self.root.deiconify()
        self.root.state('normal')
        self.root.focus_force()
    
    def hide_window(self):
        # Ocultar la ventana principal
        self.root.withdraw()
        
        # Iniciar icono de bandeja si no está activo
        if TRAY_SUPPORTED and self.tray_icon and not self.tray_icon.visible:
            threading.Thread(target=self.tray_icon.run, daemon=True).start()
    
    def start_server_from_tray(self, icon=None, item=None):
        if not self.server.running:
            self.start_server()
    
    def stop_server_from_tray(self, icon=None, item=None):
        if self.server.running:
            self.stop_server()
    
    def exit_app(self, icon=None, item=None):
        # Detener el servidor si está en ejecución
        if self.server.running:
            self.server.stop_server()
        
        # Detener el icono de bandeja
        if TRAY_SUPPORTED and self.tray_icon:
            self.tray_icon.stop()
        
        # Cerrar la aplicación
        self.root.quit()
        sys.exit(0)
    
    def create_widgets(self):
        # Frame principal
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Frame superior - Información y controles
        top_frame = ttk.Frame(main_frame)
        top_frame.pack(fill=tk.X, pady=(0, 10))
        
        # Información del servidor
        info_frame = ttk.LabelFrame(top_frame, text="Información del servidor")
        info_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0, 5))
        
        # IP y Puerto
        ttk.Label(info_frame, text="Dirección IP:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Label(info_frame, textvariable=self.ip_var, font=("", 10, "bold")).grid(row=0, column=1, sticky=tk.W, padx=5, pady=2)
        
        ttk.Label(info_frame, text="Puerto:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        port_entry = ttk.Entry(info_frame, textvariable=self.port_var, width=10)
        port_entry.grid(row=1, column=1, sticky=tk.W, padx=5, pady=2)
        
        # Estado
        ttk.Label(info_frame, text="Estado:").grid(row=2, column=0, sticky=tk.W, padx=5, pady=2)
        status_label = ttk.Label(info_frame, textvariable=self.status_var, font=("", 10, "bold"))
        status_label.grid(row=2, column=1, sticky=tk.W, padx=5, pady=2)
        
        # Controles
        control_frame = ttk.LabelFrame(top_frame, text="Controles")
        control_frame.pack(side=tk.RIGHT, fill=tk.BOTH, padx=(5, 0))
        
        self.start_button = ttk.Button(control_frame, text="Iniciar", command=self.start_server)
        self.start_button.pack(fill=tk.X, padx=10, pady=5)
        
        self.stop_button = ttk.Button(control_frame, text="Detener", command=self.stop_server, state=tk.DISABLED)
        self.stop_button.pack(fill=tk.X, padx=10, pady=5)
        
        # Opciones
        options_frame = ttk.LabelFrame(control_frame, text="Opciones")
        options_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Opción de inicio automático
        autostart_check = ttk.Checkbutton(options_frame, text="Iniciar al abrir", variable=self.autostart_var)
        autostart_check.pack(fill=tk.X, padx=5, pady=2)
        
        # Opción de minimizar a bandeja
        if TRAY_SUPPORTED:
            minimize_check = ttk.Checkbutton(options_frame, text="Minimizar a bandeja", variable=self.minimize_to_tray_var)
            minimize_check.pack(fill=tk.X, padx=5, pady=2)
            
            # Botón para minimizar a bandeja
            minimize_button = ttk.Button(control_frame, text="Minimizar", command=self.hide_window)
            minimize_button.pack(fill=tk.X, padx=10, pady=5)
        
        # Frame de estadísticas
        stats_frame = ttk.LabelFrame(main_frame, text="Estadísticas")
        stats_frame.pack(fill=tk.X, pady=(0, 10))
        
        # Grid para estadísticas
        ttk.Label(stats_frame, text="Clientes conectados:").grid(row=0, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Label(stats_frame, textvariable=self.clients_var, font=("", 10, "bold")).grid(row=0, column=1, sticky=tk.W, padx=5, pady=2)
        
        ttk.Label(stats_frame, text="Comandos procesados:").grid(row=0, column=2, sticky=tk.W, padx=5, pady=2)
        ttk.Label(stats_frame, textvariable=self.commands_var, font=("", 10, "bold")).grid(row=0, column=3, sticky=tk.W, padx=5, pady=2)
        
        ttk.Label(stats_frame, text="Tiempo de actividad:").grid(row=1, column=0, sticky=tk.W, padx=5, pady=2)
        ttk.Label(stats_frame, textvariable=self.uptime_var, font=("", 10, "bold")).grid(row=1, column=1, sticky=tk.W, padx=5, pady=2)
        
        # Frame de registro
        log_frame = ttk.LabelFrame(main_frame, text="Registro")
        log_frame.pack(fill=tk.BOTH, expand=True)
        
        # Área de texto para el registro
        self.log_text = scrolledtext.ScrolledText(log_frame, height=10)
        self.log_text.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.log_text.config(state=tk.DISABLED)
        
        # Información de ayuda
        help_frame = ttk.Frame(main_frame)
        help_frame.pack(fill=tk.X, pady=(10, 0))
        
        help_text = "Para conectar: Abre la aplicación Remote Mouse en tu dispositivo e ingresa la IP y puerto mostrados arriba."
        ttk.Label(help_frame, text=help_text, wraplength=480, justify=tk.LEFT).pack(fill=tk.X)
    
    def log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        
        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, log_message)
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)
    
    def update_status(self, status):
        self.status_var.set(status)
        
        if status == "Ejecutando":
            self.start_button.config(state=tk.DISABLED)
            self.stop_button.config(state=tk.NORMAL)
        else:
            self.start_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
    
    def update_clients(self, count):
        self.clients_var.set(str(count))
    
    def update_stats(self):
        if self.server.running:
            self.commands_var.set(str(self.server.command_count))
            self.uptime_var.set(self.server.get_uptime())
        
        # Actualizar cada segundo
        self.root.after(1000, self.update_stats)
    
    def start_server(self):
        # Actualizar puerto si se cambió
        self.server.port = int(self.port_var.get())
        
        # Iniciar servidor en un hilo separado
        def run_server():
            asyncio.run(self.server.start_server())
        
        threading.Thread(target=run_server, daemon=True).start()
    
    def stop_server(self):
        self.server.stop_server()
    
    def on_closing(self):
        if self.server.running:
            if messagebox.askyesno("Confirmar", "El servidor está en ejecución. ¿Deseas detenerlo y salir?"):
                self.server.stop_server()
                self.exit_app()
        else:
            self.exit_app()
        
        # Si está configurado para minimizar a bandeja en lugar de cerrar
        if TRAY_SUPPORTED and self.minimize_to_tray_var.get():
            self.hide_window()
            return
            
        self.exit_app()

def parse_arguments():
    parser = argparse.ArgumentParser(description='Remote Mouse Server')
    parser.add_argument('--nogui', action='store_true', help='Ejecutar sin interfaz gráfica')
    parser.add_argument('--port', type=int, default=12345, help='Puerto para el servidor (predeterminado: 12345)')
    parser.add_argument('--sensitivity', type=float, default=1.0, help='Sensibilidad del ratón (predeterminado: 1.0)')
    parser.add_argument('--minimized', action='store_true', help='Iniciar minimizado en la bandeja del sistema')
    parser.add_argument('--autostart', action='store_true', help='Iniciar el servidor automáticamente al abrir')
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()
    
    if args.nogui:
        # Modo consola
        server = RemoteMouseServer(port=args.port, sensitivity=args.sensitivity)
        try:
            asyncio.run(server.start_server())
        except KeyboardInterrupt:
            print("Servidor detenido por el usuario")
    else:
        # Modo GUI
        root = tk.Tk()
        app = ServerGUI(root)
        
        # Configurar sensibilidad
        app.server.sensitivity = args.sensitivity
        
        # Configurar puerto
        if args.port != 12345:
            app.port_var.set(str(args.port))
        
        # Configurar inicio automático
        if args.autostart:
            app.autostart_var.set(True)
            root.after(1000, app.start_server)
        
        # Iniciar minimizado si se solicita
        if args.minimized and TRAY_SUPPORTED:
            root.withdraw()
            app.tray_icon.run_detached()
        
        root.mainloop() 