%post --log=/root/logs/05-Handling_register_activity.ks
#!/bin/bash
echo "----------------------------------------------------------------------"
echo "-- SE VAN A INCLUIR LAS REGLAS NECESARIAS PARA LA HERRAMIENTA AUDIT --"
echo "----------------------------------------------------------------------"
echo -e "\n"

cat >/etc/audit/rules.d/audit.rules <<EOF
# Elimina las reglas existentes
-D

# Cantidad de Buffer
## Aumentar este parámetro si es necesario
-b 8192

# Modo de Fallo
## Valores posibles: 0 (silencioso), 1 (printk, imprimir un mensaje de fallo), 2 (panic, detener el sistema)
-f 1

# Ignorar errores
## p.ej. causado por usuarios o archivos no encontrados en el entorno local 
-i 

# Auditoría propia ----------------------------------------------- ----------------

## Auditar los registros de auditoría
### Intentos exitosos y no exitosos de leer información de los registros de auditoría
-w /var/log/audit/ -k auditlog

## Configuración auditada
### Modificaciones a la configuración de auditoría que ocurren mientras las funciones de recopilación de auditoría están operativas

-w /etc/audit/ -p wa -k auditconfig
-w /etc/libaudit.conf -p wa -k auditconfig
-w /etc/audisp/ -p wa -k audispconfig

## Supervisar el uso de herramientas de gestión de auditoría
-w /sbin/auditctl -p x -k audittools
-w /sbin/auditd -p x -k audittools

###########################################Filtros ---------------------------------------------------------------------

## Ignorar los registros SELinux AVC
#-a always,exclude -F msgtype=AVC

## Ignorar los registros actuales del directorio de trabajo
#-a always,exclude -F msgtype=CWD

## Para no revisar cron si crea muchos registros
#-a never,user -F subj_type=crond_t
#-a exit,never -F subj_type=crond_t

## Evita registros masivos de chrony
#-a never,exit -F arch=b64 -S adjtimex -F auid=unset -F uid=chrony -F subj_type=chronyd_t

## Eliminar registros de VMWare tools
#-a exit,never -F arch=b32 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2
#-a exit,never -F arch=b64 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2

### Filtro de eventos de alto volumen (especialmente en estaciones de trabajo Linux)
#-a exit,never -F arch=b32 -F dir=/dev/shm -k sharedmemaccess
#-a exit,never -F arch=b64 -F dir=/dev/shm -k sharedmemaccess
#-a exit,never -F arch=b32 -F dir=/var/lock/lvm -k locklvm
#-a exit,never -F arch=b64 -F dir=/var/lock/lvm -k locklvm


# Reglas -----------------------------------------------------------------------

## Parámetros del kernel
-w /etc/sysctl.conf -p wa -k sysctl

## Carga y descarga del módulo Kernel
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/insmod -k modules
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/modprobe -k modules
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/rmmod -k modules
-a always,exit -F arch=b64 -S finit_module -S init_module -S delete_module -F auid!=-1 -k modules
-a always,exit -F arch=b32 -S finit_module -S init_module -S delete_module -F auid!=-1 -k modules
## Configuración Modprobe
-w /etc/modprobe.conf -p wa -k modprobe

## Uso de KExec (todas las acciones)
-a always,exit -F arch=b64 -S kexec_load -k KEXEC
-a always,exit -F arch=b32 -S sys_kexec_load -k KEXEC

## Archivos especiales
-a exit,always -F arch=b32 -S mknod -S mknodat -k specialfiles
-a exit,always -F arch=b64 -S mknod -S mknodat -k specialfiles

## Operaciones de montaje 
-a always,exit -F arch=b64 -S mount -S umount2 -F auid!=-1 -k mount
-a always,exit -F arch=b32 -S mount -S umount -S umount2 -F auid!=-1 -k mount

# Cambios en swap 
-a always,exit -F arch=b64 -S swapon -S swapoff -F auid!=-1 -k swap
-a always,exit -F arch=b32 -S swapon -S swapoff -F auid!=-1 -k swap

## Hora
-a exit,always -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time
-a exit,always -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time
### Zona horaria local
-w /etc/localtime -p wa -k localtime

## Stunnel
-w /usr/sbin/stunnel -p x -k stunnel

## Configuración de Cron y trabajos programados
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/crontabs/ -k cron

## Bases de datos de usuarios, grupos y contraseñas
-w /etc/group -p wa -k etcgroup
-w /etc/passwd -p wa -k etcpasswd
-w /etc/gshadow -k etcgroup
-w /etc/shadow -k etcpasswd
-w /etc/security/opasswd -k opasswd

## Cambios en el archivo Sudoers
-w /etc/sudoers -p wa -k actions

## Passwd
-w /usr/bin/passwd -p x -k passwd_modification

## Herramientas para cambiar identificadores de grupo
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification
-w /usr/sbin/addgroup -p x -k group_modification
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/adduser -p x -k user_modification

## Configuración e información de inicio de sesión
-w /etc/login.defs -p wa -k login
-w /etc/securetty -p wa -k login
-w /var/log/faillog -p wa -k login
-w /var/log/lastlog -p wa -k login
-w /var/log/tallylog -p wa -k login

## Entorno de red
### Cambios en el nombre de host
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k network_modifications
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_modifications
### Cambios a otros archivos
-w /etc/hosts -p wa -k network_modifications
-w /etc/sysconfig/network -p wa -k network_modifications
-w /etc/network/ -p wa -k network
-a always,exit -F dir=/etc/NetworkManager/ -F perm=wa -k network_modifications
-w /etc/sysconfig/network -p wa -k network_modifications
### Cambios para issue
-w /etc/issue -p wa -k etcissue
-w /etc/issue.net -p wa -k etcissue

## Scripts de inicio del sistema
-w /etc/inittab -p wa -k init
-w /etc/init.d/ -p wa -k init
-w /etc/init/ -p wa -k init

## Rutas de búsqueda de la biblioteca
-w /etc/ld.so.conf -p wa -k libpath

## Configuración Pam
-w /etc/pam.d/ -p wa -k pam
-w /etc/security/limits.conf -p wa  -k pam
-w /etc/security/pam_env.conf -p wa -k pam
-w /etc/security/namespace.conf -p wa -k pam
-w /etc/security/namespace.init -p wa -k pam

## Configuración de postfix
-w /etc/aliases -p wa -k mail
-w /etc/postfix/ -p wa -k mail

## Configuración SSH
-w /etc/ssh/sshd_config -k sshd

# Systemd
-w /bin/systemctl -p x -k systemd 
-w /etc/systemd/ -p wa -k systemd

## Eventos SELinux que modifican los controles de acceso obligatorios (MAC) del sistema
-w /etc/selinux/ -p wa -k mac_policy

## Fallas de acceso a elementos críticos
-a exit,always -F arch=b64 -S open -F dir=/etc -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/bin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/sbin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/usr/bin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/usr/sbin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/var -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/home -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/srv -F success=0 -k unauthedfileaccess

## Solicitudes de cambio de ID de proceso (cambio de cuentas)
-w /bin/su -p x -k priv_esc
-w /usr/bin/sudo -p x -k priv_esc
-w /etc/sudoers -p rw -k priv_esc

## Estado de energía
-w /sbin/shutdown -p x -k power
-w /sbin/poweroff -p x -k power
-w /sbin/reboot -p x -k power
-w /sbin/halt -p x -k power

## Información de inicio de sesión
-w /var/run/utmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/log/wtmp -p wa -k session

## Modificaciones de control de acceso discrecional (DAC)
-a always,exit -F arch=b32 -S chmod -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fchmod -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fchownat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S fsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S lremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S lsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S removexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chmod  -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fchmod -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fchownat -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S fsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S lremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S lsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S removexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -F auid>=500 -F auid!=4294967295 -k perm_mod

# Reglas especiales ----------------------------------------------- ----------------

## Explotación API de 32 bits
### Si su sistema es de 64 bits, todo debe estar ejecutándose en modo de 64 bits.
### Esta regla detectará cualquier uso de las llamadas al sistema de 32 bits.
### Esto podría ser una señal de que alguien está explotando un bug en el sistema de 32 bits.

-a always,exit -F arch=b32 -S all -k 32bit_api

## Reconocimiento
-w /usr/bin/whoami -p x -k recon
-w /etc/issue -p r -k recon
-w /etc/hostname -p r -k recon

## Actividades sospechosas
-w /usr/bin/wget -p x -k susp_activity
-w /usr/bin/curl -p x -k susp_activity
-w /usr/bin/base64 -p x -k susp_activity
-w /bin/nc -p x -k susp_activity
-w /bin/netcat -p x -k susp_activity
-w /usr/bin/ncat -p x -k susp_activity
-w /usr/bin/ssh -p x -k susp_activity
-w /usr/bin/socat -p x -k susp_activity
-w /usr/bin/wireshark -p x -k susp_activity
-w /usr/bin/rawshark -p x -k susp_activity
-w /usr/bin/rdesktop -p x -k sbin_susp
-w /sbin/iptables -p x -k sbin_susp 
-w /sbin/ifconfig -p x -k sbin_susp
-w /usr/sbin/tcpdump -p x -k sbin_susp
-w /usr/sbin/traceroute -p x -k sbin_susp

## Inyección
### Estas reglas vigilan la inyección de código por parte de la instalación de ptrace.
-a always,exit -F arch=b32 -S ptrace -k tracing
-a always,exit -F arch=b64 -S ptrace -k tracing
-a always,exit -F arch=b32 -S ptrace -F a0=0x4 -k code_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x4 -k code_injection
-a always,exit -F arch=b32 -S ptrace -F a0=0x5 -k data_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x5 -k data_injection
-a always,exit -F arch=b32 -S ptrace -F a0=0x6 -k register_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x6 -k register_injection

## Abuso de privilegios
### El propósito de esta regla es detectar cuándo un administrador accede al directorio de inicio de los usuarios comunes.
-a always,exit -F dir=/home -F uid=0 -F auid>=1000 -F auid!=4294967295 -C auid!=obj_uid -k power_abuse

# Gestión de software ---------------------------------------------------------

# RPM (CentOS)
-w /usr/bin/rpm -p x -k software_mgmt
-w /usr/bin/yum -p x -k software_mgmt
-w /usr/bin/dnf -p x -k software_mgmt

# Software especial ----------------------------------------------- -------------

## Secretos específicos de GDS
#-w /etc/puppet/ssl -p wa -k puppet_ssl

## IBM Bigfix BESClient
#-a exit,always -F arch=b64 -S open -F dir=/opt/BESClient -F success=0 -k soft_besclient
#-w /var/opt/BESClient/ -p wa -k soft_besclient

# Eventos de gran volumen ---------------------------------------------- ------------

## ELIMINAR SI SE CAUSA UN VOLUMEN EXCESIVO EN EL SISTEMA

## Ejecuciones de comandos root
-a exit,always -F arch=b64 -F euid=0 -S execve -k rootcmd
-a exit,always -F arch=b32 -F euid=0 -S execve -k rootcmd

## Eventos de eliminación de archivos por usuario
-a always,exit -F arch=b32 -S rmdir -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete
-a always,exit -F arch=b64 -S rmdir -S unlink -S unlinkat -S rename -S renameat -F auid>=500 -F auid!=4294967295 -k delete

## Acceso a archivos
### Acceso no autorizado (sin éxito)
-a always,exit -F arch=b32 -S creat -S open -S openat -S open_by_handle_at -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k file_access
-a always,exit -F arch=b32 -S creat -S open -S openat -S open_by_handle_at -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k file_access
-a always,exit -F arch=b64 -S creat -S open -S openat -S open_by_handle_at -S truncate -S ftruncate -F exit=-EACCES -F auid>=500 -F auid!=4294967295 -k file_access
-a always,exit -F arch=b64 -S creat -S open -S openat -S open_by_handle_at -S truncate -S ftruncate -F exit=-EPERM -F auid>=500 -F auid!=4294967295 -k file_access

### Creación fallida
-a always,exit -F arch=b32 -S creat,link,mknod,mkdir,symlink,mknodat,linkat,symlinkat -F exit=-EACCES -k file_creation
-a always,exit -F arch=b64 -S mkdir,creat,link,symlink,mknod,mknodat,linkat,symlinkat -F exit=-EACCES -k file_creation
-a always,exit -F arch=b32 -S link,mkdir,symlink,mkdirat -F exit=-EPERM -k file_creation
-a always,exit -F arch=b64 -S mkdir,link,symlink,mkdirat -F exit=-EPERM -k file_creation

### Modificación fallida
-a always,exit -F arch=b32 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EACCES -k file_modification
-a always,exit -F arch=b64 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EACCES -k file_modification
-a always,exit -F arch=b32 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EPERM -k file_modification
-a always,exit -F arch=b64 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EPERM -k file_modification

# Hacer la configuración inmutable --------------------------------------------
## - e 2
EOF
echo "--------------------------------------------------------------"
echo "-- AHORA SE MODIFICARÁ EL FICHERO DE CONFIGURACIÓN DE AUDIT --"
echo "--------------------------------------------------------------"
echo -e "\n"

# permisos solo a root para la modificación de estos parámetros
chmod 600 /etc/audit/auditd.conf

# audit fichero de configuración, modificación para 120Mb / 3 meses de logs aproximadamente.
sed -i -e 's/^max_log_file .*/max_log_file = 10/' /etc/audit/auditd.conf
sed -i -e 's/^num_logs.*/num_logs = 12/' /etc/audit/auditd.conf
sed -i -e 's/^max_log_file_action.*/max_log_file_action = ROTATE/' /etc/audit/auditd.conf

systemctl enable auditd
service auditd restart

%end