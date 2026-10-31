-- Reglas de detección iniciales.
INSERT INTO rules (code, title, description, severity, recommendation, enabled) VALUES
  ('SERVICIO_SIN_CIFRAR', 'Servicio sin cifrar expuesto', 'Telnet, FTP y otros protocolos sin cifrar escuchan en todas las interfaces, así que usuario, contraseña y datos viajan en texto plano.', 'alta', 'Desactiva el servicio o cámbialo por su versión cifrada (SSH en lugar de Telnet, SFTP en lugar de FTP).', TRUE),
  ('ACCESO_REMOTO_EXPUESTO', 'Acceso remoto expuesto', 'Escritorio remoto, SMB, VNC o SSH escuchan en todas las interfaces y reciben intentos de acceso constantes.', 'alta', 'Limita el acceso con firewall, VPN o una lista de IP permitidas.', TRUE),
  ('BD_EXPUESTA', 'Base de datos visible en toda la red', 'Una base de datos escucha en todas las interfaces y no solo en local.', 'alta', 'Haz que escuche en 127.0.0.1 o en una red privada y limita el acceso con firewall.', TRUE),
  ('SERVIDOR_DESARROLLO', 'Servidor de desarrollo abierto', 'Un servidor pensado para desarrollo escucha en todas las interfaces, normalmente sin autenticación ni endurecimiento.', 'media', 'Cierra el servidor al terminar de desarrollar o haz que escuche solo en 127.0.0.1.', TRUE),
  ('EJECUTABLE_SOSPECHOSO', 'Ejecutable sospechoso', 'Un proceso corre desde una carpeta temporal o sigue activo aunque su archivo fue borrado. Es una técnica común para esconder malware.', 'alta', 'Verifica el origen del archivo y su huella antes de decidir.', TRUE),
  ('PROCESO_ANOMALO', 'Proceso anómalo en un puerto', 'El proceso no coincide con el servicio esperado en ese puerto, o corre con permisos de administrador sin necesitarlos.', 'media', 'Confirma que el proceso es legítimo y ejecútalo con el mínimo de privilegios.', TRUE)
ON CONFLICT (code) DO NOTHING;
