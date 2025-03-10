# Remote Mouse - Servidor

Este es el servidor para la aplicación Remote Mouse que permite controlar el mouse y teclado de tu PC desde un dispositivo móvil usando WebSockets.

## Requisitos

- Python 3.7 o superior
- Las bibliotecas listadas en `requirements.txt`
- Conexión de red entre el dispositivo móvil y el PC

## Instalación

1. Clona o descarga este repositorio
2. Instala las dependencias:

```bash
pip install -r requirements.txt
```

## Uso

1. Ejecuta el servidor:

```bash
python server.py
```

2. El servidor mostrará tu dirección IP local y puerto (por defecto: 12345)
3. En la aplicación móvil, introduce esta dirección IP y conéctate

### Opciones de la línea de comandos

- `--host`: Especifica la dirección IP para escuchar (por defecto: 0.0.0.0)
- `--port`: Especifica el puerto (por defecto: 12345)
- `--debug`: Habilita mensajes de depuración

Ejemplo:
```bash
python server.py --port 9876 --debug
```

## Problemas comunes

### Permisos de sistema

En algunos sistemas operativos (especialmente macOS), es posible que necesites dar permisos de accesibilidad a Python o Terminal para controlar el mouse y teclado.

#### En macOS:
1. Ve a Preferencias del Sistema > Seguridad y Privacidad > Privacidad > Accesibilidad
2. Añade Terminal o la aplicación desde la que ejecutas Python

#### En Windows:
1. Ejecuta el script como administrador si encuentras problemas de permisos

### Firewall

Asegúrate de que el puerto que uses (por defecto 12345) esté abierto en tu firewall.

## Protocolo de comunicación

La aplicación móvil se comunica con el servidor usando los siguientes comandos:

- `move,dx,dy` - Mover el cursor
- `click` - Clic izquierdo
- `right_click` - Clic derecho
- `middle_click` - Clic central
- `scroll,amount` - Desplazamiento vertical
- `key,keycode` - Presionar una tecla
- `keydown,keycode` y `keyup,keycode` - Presionar/soltar teclas
- `type,text` - Escribir texto

## Seguridad

Este servidor permite control total del mouse y teclado. Úsalo solo en redes de confianza y nunca lo expongas a Internet sin autenticación adecuada.
