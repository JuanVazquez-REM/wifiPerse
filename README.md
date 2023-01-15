# wifiPerse
Herramienta en bash para la automatización de ataques a redes wifi (WPA2), con la intención de obtener la contrañesa de la red.

Actualmente se cuenta con 2 métodos de ataque:

1. **HandShake**:
Para esto se hace uso de un ataque DeAuth global, por lo tanto es algo agresivo. Entrando más en detalle se envía *10 paquetes deauth a todos los dispositivos de la red*. Es decir que requerimos de usuarios autenticados a la red wifi.

2. **PKMID**:
Este ataque no requiere de usuarios autenticados a la red, ya que se comunica directo con el router y después de una serie de procedimientos obtener el hash de dicha red. Claro que si el router es vulnerable, obtendremos el hash.



## Uso
Tras ejecutar la herramienta *como un usuario privilegiado*, se muestra un panel de ayuda, en el cual se encuentran los 2 modos de ataque.


Una vez seleccionado el modo de ataque, la herramienta realizara una comprobación para las herramientas a utilizar, de ser necesario las descarga e instalara.

Una vez concluido con el ataque de forma exitosa, es decir que se obtuvo el hash, se procede a realizar una ataque de fuerza bruta, con un diccionario seleccionado o uno por defecto (rockyou.txt).
