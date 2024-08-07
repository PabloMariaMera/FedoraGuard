# Archivo: 01-Password_grub.ks

echo "--------------------------------"
echo "--APLICANDO CONTRASEÑA DE GRUB--"
echo "--------------------------------"
var=$(echo -e 'micontrasenagrub\nmicontrasenagrub' | grub2-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}' | cut -d' ' -f7)
echo $var
echo set superusers="root">>/etc/grub.d/40_custom
echo password_pbkdf2 root $var >>/etc/grub.d/40_custom
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
chmod 600 /boot/grub2/grub.cfg
chmod 600 /boot/efi/EFI/redhat/grub.cfg
chmod 600 /boot/efi/EFI/fedora/grub.cfg

# Archivo: 02-User_root_and_without_password.ks
echo "-----------------------------------------------"
echo "-- SE CONFIGURA LA CONTRASEÑA SEGURA DE ROOT --"
echo "-----------------------------------------------"
echo

echo
/usr/bin/chage -m 2 -M 45 -W 10 root

sleep 2

echo "micontrasenaroot" | passwd --stdin root;

echo

/usr/bin/chage -l root


echo
echo "--------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS CON UID 0 --"
echo "--------------------------------------------"
echo
echo

UiD=$(cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root)

if [[ -z $UiD ]]; then

	echo "No se detectan usuarios con UID 0."

else

	echo "Se detectan los siguientes usuarios con UID 0:"
	echo
	cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root

fi

echo
echo "-------------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS SIN CONTRASEÑA --"
echo "-------------------------------------------------"
echo

echo 

Sinpass=$(cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1)

if [[ -z $Sinpass ]]; then
	
	echo "No se detectan usuarios sin contraseña."

else

	echo "Se detectan los siguientes usuarios sin contraseña:"

	cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1

fi

echo

echo "----------------------------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS/GRUPOS SUDOERS SIN CONTRASEÑA --"
echo "----------------------------------------------------------------"
echo

echo

Nopass=$(cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD")

if [[ -z $Nopass ]]; then

	echo "No se detectan usuarios sin contraseña en sudoers."

else

	echo "Se detectan usuarios/grupos sin contraseña en sudoers:"
	echo

	cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD"

fi

# Archivo: 03-Parameters_kernel.ks
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
echo "-----------------------------------"
echo "--APLICANDO PARÁMETROS DEL KERNEL--"
echo "-----------------------------------"
echo -e "\n"
echo " EL SCRIPT GUARDARÁ UNA COPIA DE LOS ARCHIVOS ORGINALES POR SI SE DESEARA RESTAURAR CONFIGURACIONES ANTERIORES EN:"
echo " /etc/sysctl.conf.bak_$tiempo"
echo "/etc/sysctl.d_$tiempo/"
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR, HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"
#####################################################################
mkdir /etc/sysctl.d_$tiempo
cp -r /etc/sysctl.d/* /etc/sysctl.d_$tiempo
cp /etc/sysctl.conf /etc/sysctl.conf.bak_$tiempo
rm -f /etc/sysctl.conf


sudo sysctl -w net.ipv4.conf.all.send_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.send_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.secure_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.secure_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.log_martians=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.log_martians=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.tcp_syncookies=1 >>/etc/sysctl.conf
sudo sysctl -w fs.suid_dumpable=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_ra=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_ra=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_redirects=0 >>/etc/sysctl.conf
##############################ADICIONALES####################
cat >> /etc/sysctl.conf << EOF
# PARÁMETROS REVISABLES
# ----------------------
# Deshabilitar ping
net.ipv4.icmp_echo_ignore_all = 1
###
# Paquetes entre interfaces (desactivar si el equipo no actúa como router)
net.ipv4.ip_forward = 0
###
# Habilitar reverse path filtering
#net.ipv4.conf.all.rp_filter = 1
#net.ipv4.conf.default.rp_filter = 1
###
#Deshabilitar vulnerabilidad de marca de tiempo en TCP
#net.ipv4.tcp_timestamps = 0
###
#Bloqueo de ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
###
# Modificar el tamaño de las colas de espera de TCP
###
#net.ipv4.tcp_max_syn_backlog = 1280
EOF
echo  " >>>>>>>>EL PROCESO A FINALIZADO<<<<<<<< "

# Archivo: 04-Parameters_SSH.ks
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )


echo "-----------------------------------"
echo "-- MODIFICANDO CONFIGURACION SSH --"
echo "-----------------------------------"
echo -e "\n"
echo " ANTES DE COMENZAR SE CREARÁ UN BACKUP DEL FICHERO "/etc/ssh/sshd_config" " 
echo " CON LA SIGUIENTE NOMENCLATURA "/etc/ssh/sshd_config_backup[fecha/hora]" "
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE EL SCRIPT FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"

cp -r /etc/ssh/sshd_config /etc/ssh/sshd_config_bakup$tiempo

rm -rf /etc/ssh/sshd_config



PORT=22

semanage port -a -t ssh_port_t -p tcp $PORT

cat >>/etc/ssh/sshd_config <<EOF
#	$OpenBSD: sshd_config,v 1.103 2018/04/09 20:41:22 tj Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp $PORT
#
Port $PORT
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

Protocol 2

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# This system is following system-wide crypto policy. The changes to
# crypto properties (Ciphers, MACs, ...) will not have any effect here.
# They will be overridden by command-line options passed to the server
# on command line.
# Please, check manual pages for update-crypto-policies(8) and sshd_config(5).

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:

LoginGraceTime 1m
PermitRootLogin no
#StrictModes yes
MaxAuthTries 3
MaxSessions 1

#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile	.ssh/authorized_keys

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
PermitEmptyPasswords no
PasswordAuthentication yes

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication no
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
# WARNING: 'UsePAM no' is not supported in Fedora and may cause several
# problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes

# It is recommended to use pam_motd in /etc/pam.d/sshd instead of PrintMotd,
# as it is more configurable and versatile than the built-in version.
PrintMotd no

#PrintLastLog yes
#TCPKeepAlive yes
PermitUserEnvironment no
#Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
Banner /etc/ssh/issue

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem	sftp	/usr/libexec/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
	X11Forwarding no
	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server

EOF


service sshd start

service sshd reload


echo "El script ha finalizado de configurar los parámetros de SSH"
# Archivo: 05-Handling_register_activity.ks
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

# Archivo: 08-Limits_permissions_passExpiration.ks
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
#Evitando generacion de ficheros core
echo "----------------------------------------"
echo "--SUPRIMIENDO GENERACIÓN FICHEROS CORE--"
echo "----------------------------------------"
echo -e "\n"
echo " ANTES DE COMENZAR SE CREARÁ UN BACKUP DEL FICHERO "/etc/security/limits.conf" CON LA SIGUIENTE NOMENCLATURA "/etc/security/limits.conf_backup[fecha/hora]""
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE EL SCRIPT FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"

cp -r /etc/security/limits.conf /etc/security/limits.conf_bakup_$tiempo
cat /etc/security/limits.conf |grep -v "#" >/etc/security/limits.conf.R
cat >/etc/security/limits.conf <<EOF
#############################################
# Párámetros incluidos por la guía CCN-STIC #
#############################################

#<domain>      <type>  <item>         <value>
EOF
cat /etc/security/limits.conf.R >>/etc/security/limits.conf
var1=$(cat /etc/security/limits.conf |grep "soft    core")
if [ -z "$var1" ]
then
cat >>/etc/security/limits.conf <<EOF
*               soft    core            0
EOF
else
sed -i -e 's/.*soft    core.*/*               soft    core            0/' /etc/security/limits.conf

fi
var1=$(cat /etc/security/limits.conf |grep "hard    core")
if [ -z "$var1" ]
then
cat >>/etc/security/limits.conf <<EOF
*               hard    core            0
EOF
else
sed -i -e 's/.*hard    core.*/*               hard    core            0/' /etc/security/limits.conf
fi
rm -rf /etc/security/limits.conf.R

echo "*               soft   nofile    4096" >> /etc/security/limits.conf
echo "*               hard   nofile    65536" >> /etc/security/limits.conf
echo "*               soft   nproc     4096" >> /etc/security/limits.conf
echo "*               hard   nproc     4096" >> /etc/security/limits.conf
echo "*               soft   locks     4096" >> /etc/security/limits.conf
echo "*               hard   locks     4096" >> /etc/security/limits.conf
echo "*               soft   stack     10240" >> /etc/security/limits.conf
echo "*               hard   stack     32768" >> /etc/security/limits.conf
echo "*               soft   memlock   64" >> /etc/security/limits.conf
echo "*               hard   memlock   64" >> /etc/security/limits.conf
echo "*               hard   maxlogins 1" >> /etc/security/limits.conf
echo "# Límite soft 32GB, hard 64GB" >> /etc/security/limits.conf
echo "*               soft   fsize     33554432" >> /etc/security/limits.conf
echo "*               hard   fsize     67108864" >> /etc/security/limits.conf
echo "# Límites para root" >> /etc/security/limits.conf
echo "root            soft   nofile    4096" >> /etc/security/limits.conf
echo "root            hard   nofile    65536" >> /etc/security/limits.conf
echo "root            soft   nproc     4096" >> /etc/security/limits.conf
echo "root            hard   nproc     4096" >> /etc/security/limits.conf
echo "root            oft    stack     10240" >> /etc/security/limits.conf
echo "root            hard   stack     32768" >> /etc/security/limits.conf
echo "root            soft   fsize     33554432" >> /etc/security/limits.conf
#echo "*		hard 	rss		40000" >> /etc/security/limits.conf
echo "# FIN DE FICHERO" >>/etc/security/limits.conf
#Caducidad de las contraseñas y permisos a usuarios
echo "--------------------------------------------------------------"
echo "--FORZANDO CADUCIDAD EN LAS CONTRASEÑAS DE USUARIO (45 DÍAS)--"
echo "--------------------------------------------------------------"
echo -e "\n"
echo -e "\n"
sed -i -e 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS  45/' /etc/login.defs
sed -i -e 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS  2/' /etc/login.defs
sed -i -e 's/^PASS_WARN_AGE.*/PASS_WARN_AGE  10/' /etc/login.defs
var1=$(cat /etc/login.defs |grep "PASS_MIN_LEN")
if [ -z "$var1" ]
then
cat >>/etc/login.defs <<EOF
PASS_MIN_LEN  12
EOF
else
sed -i -e 's/^PASS_MIN_LEN.*/PASS_MIN_LEN  12/' /etc/login.defs
fi
var1=$(cat /etc/login.defs |grep "ENCRYPT_METHOD")
if [ -z "$var1" ]
then
cat >>/etc/login.defs <<EOF
ENCRYPT_METHOD  SHA512
EOF
else
sed -i -e 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD  SHA512/' /etc/login.defs
fi
sed -i -e 's/^UMASK.*/UMASK	027/' /etc/login.defs
cat /etc/login.defs |grep -v "#"|grep "PASS"


#######################################################################################
echo "---------------------------------------"
echo "--FORZANDO COMPLEJIDAD DE CONTRASEÑAS--"
echo "---------------------------------------"
echo -e "\n"

sed -i -e 's/minlen.*/minlen = 8/' /etc/security/pwquality.conf
sed -i -e 's/# minlen.*/minlen = 8/' /etc/security/pwquality.conf
sed -i -e 's/dcredit.*/dcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# dcredit.*/dcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/ucredit.*/ucredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# ucredit.*/ucredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/lcredit.*/lcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# lcredit.*/lcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/ocredit.*/ocredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# ocredit.*/ocredit = 1/' /etc/security/pwquality.conf

#Sobre usuarios ya existentes

echo "------------------------------------------------------------"
echo "--MODIFICANDO CADUCIDAD CONTRASEÑAS USUARIOS YA EXISTENTES--"
echo "------------------------------------------------------------"
echo -e "\n"

echo "Los usuarios que se modificarán seran los siguientes:"
for LOGIN in `cut -d: -f1 /etc/passwd |grep -v "nobody"`
do
   USERID=`id -u $LOGIN `
 if [ $USERID -ge 1000 ]; then
	echo $LOGIN
      passwd -e $LOGIN
      /usr/bin/chage -m 2 -M 45 -W 10 $LOGIN
   fi
done

#Permisos en los directorios de los usuarios#
echo "-----------------------------------------------------"
echo "--MODIFICANDO PERMISOS DIRECTORIO /home DE USUARIOS--"
echo "-----------------------------------------------------"
echo -e "\n"

for USU in `cut -d: -f1 /etc/passwd |grep -v "nobody"`
do
   USERID=`id -u $USU `
 if [ $USERID -ge 1000 ]; then
	echo $USU
   /bin/chmod g-w /home/$USU
   /bin/chmod o-rwx /home/$USU
   fi
done


# Archivo: 09-Parameters_gnome.ks
echo "------------------------------------------------------------------"
echo "--CREANDO UN BANNER Y MODIFICANDO PARÁMETROS DE INICIO DE SESIÓN--"
echo "------------------------------------------------------------------"
echo -e "\n"

####################BBDD USUARIO#############
mkdir /etc/dconf/db/gdm.d/ &>/dev/null
mkdir /etc/dconf/db/local.d/ &>/dev/null

touch /etc/dconf/profile/user &>/dev/null
cat > /etc/dconf/profile/user << EOF
user-db:user
system-db:local
EOF
########################BBDD GLOBAL###########
touch /etc/dconf/profile/gdm &>/dev/null
cat > /etc/dconf/profile/gdm << EOF
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
EOF

############################BANNER#####################################################################
touch /etc/dconf/db/gdm.d/01-banner-message &>/dev/null
BANN="ES UN DELITO CONTINUAR SIN LA DEBIDA AUTORIZACIÓN"
echo $BANN
cat > /etc/dconf/db/gdm.d/01-banner-message << EOF
[org/gnome/login-screen]
banner-message-enable=true
banner-message-text='$BANN'
EOF
cat > /etc/issue.net << EOF
'$BANN'
EOF
cat > /etc/issue << EOF
'$BANN'
EOF
cat > /etc/motd << EOF
'$BANN'
EOF
#######################################################################################################
echo "-----------------------------------------------------------"
echo "--SE VA A LIMITAR EL TIEMPO DE INACTIVIDAD DE LA PANTALLA--"
echo "-----------------------------------------------------------"
echo -e "\n"

#################################NO USER##########################################################
touch /etc/dconf/db/gdm.d/00-login-screen &>/dev/null
cat > /etc/dconf/db/gdm.d/00-login-screen << EOF
[org/gnome/login-screen]
# Do not show the user list
disable-user-list=true
EOF
#################<<<<TIEMPO DE INACTIVIDAD>>>>####################################################
touch /etc/dconf/db/local.d/00-screensaver &>/dev/null
cat > /etc/dconf/db/local.d/00-screensaver << EOF
# Specify the dconf path
[org/gnome/desktop/session]

# Number of seconds of inactivity before the screen goes blank
idle-delay=uint32 600

# Specify the dconf path
[org/gnome/desktop/screensaver]

# Lock the screen after the screen is blank
lock-enabled=true

# Number of seconds after the screen is blank before locking the screen
lock-delay=uint32 0
EOF
#########################################################################################################
mkdir /etc/dconf/db/local.d/locks/ &>/dev/null
touch /etc/dconf/db/local.d/locks/screensaver &>/dev/null
cat > /etc/dconf/db/local.d/locks/screensaver << EOF
 Lock desktop screensaver settings
/org/gnome/desktop/session/idle-delay
/org/gnome/desktop/screensaver/lock-enabled
/org/gnome/desktop/screensaver/lock-delay
EOF
################################################
#######################################################
touch /etc/dconf/db/local.d/03-privacy &>/dev/null
cat > /etc/dconf/db/local.d/03-privacy << EOF
[org/gnome/desktop/media-privacy]
hide-identity=true
old-files-age=0
remember-recent-files=false
remove-old-temp-files=true
EOF
#####################################################
#####################################################
touch /etc/dconf/db/local.d/03-privacy &>/dev/null
cat > /etc/dconf/db/local.d/03-privacy << EOF
[org/gnome/desktop/media-handlingl]
automount=false
automount-open=false
autorun-never=true
EOF
#################################EQUIPOS PORTATILES######################################################################
#touch /etc/dconf/db/local.d/05-power
#AQUI SE CONFIGURA TIEMPO DE INACTIVIDAD (power)
#cat > /etc/dconf/db/local.d/05-power << EOF
#[org/gnome/settings-daemon/plugins/power]
#active=true
#sleep-inactive-ac-type='blank'
#sleep-inactive-ac-timeout=10
#sleep-inactive-battery-timeout=10#
#sleep-inactive-battery-type='blank'
#EOF
#################################EQUIPOS PORTATILES###################################################################
#touch /etc/dconf/db/local.d/locks/power
#cat > /etc/dconf/db/local.d/locks/power << EOF
#/org/gnome/settings-daemon/plugins/power/sleepinactive-
#ac-timeout
#/org/gnome/settings-daemon/plugins/power/sleepinactive-
#ac-type
#/org/gnome/settings-daemon/plugins/power/sleepinactive-
#battery-timeout
#/org/gnome/settings-daemon/plugins/power/sleepinactive-
#battery-type
#EOF
#######################################################################################################
#touch /etc/dconf/db/local.d/06-debug
#cat > /etc/dconf/db/local.d/06-debug << EOF
#[org/gtk/settings/debug]
#enable-inspector-keybinding=false
#inspector-warning-false=false
#EOF
#######################################################################################################
#Fijando timeout de inactividad para las sesiones de usuario (15 minutos)"
echo -e "\n"
echo "TMOUT=600" >> /etc/profile.local
echo "export TMOUT" >> /etc/profile.local
chmod 644 /etc/profile.local

echo "El script ha finalizado de configurar los parámetros de gnome"
echo "Se va a cerrar sesión para aplicar los cambios"

dconf update
systemctl restart display-manager
systemctl restart gdm.service

# Archivo: 13-Antivirus_install.ks
echo "---------------------------------"
echo "--Instalando antivirus ClamAV--"
echo "---------------------------------"
dnf install -y clamav clamav-data clamav-devel clamav-filesystem clamav-update clamd
dnf -y autoremove
dnf -y clean all

sed -i "s/#TCPSocket/TCPSocket/g" /etc/clamd.d/scan.conf
systemctl enable --now clamav-freshclam
systemctl enable --now clamd@scan


# Archivo: 06-Uninstall_no_needed_users.ks
echo "---------------------------------------"
echo "--DESINSTALANDO USUARIOS INNECESARIOS--"
echo "---------------------------------------"

cat /etc/shells|grep -q "/sbin/shutdown"

	if ! [[ $? = 0 ]]; then
	
		echo "/sbin/shutdown" >> /etc/shells
	fi

cat /etc/shells|grep -q "/sbin/halt"

	if ! [[ $? = 0 ]]; then
	
		echo "/sbin/halt" >> /etc/shells
	fi
	
########################################
#userdel -r netdump
#userdel -r sync
#userdel -r rpc
#userdel -r dbus
#userdel -r gopher
#userdel -r ftp #si desinstalamos el ftp
groupdel games
groupdel floppy
userdel games
#userdel -r lp
#userdel -r uucp
#userdel -r pcap
#userdel -r haldaemon
#userdel -r sshd #si desinstalamos el ssh
#userdel -r mail
#userdel -r chrony
#userdel -r geoclue
#chsh -s /bin/bash root

########################################
chsh -s /sbin/shutdown shutdown
chsh -s /sbin/halt halt
### disable login root  change from /bin/bash to /bin/false
#usermod -s /bin/false root
usermod -s /bin/false nobody
# Archivo: 07-Failed_attempts.ks
echo "--------------------------------------------"
echo "--BLOQUEO DE CUENTAS POR INTENTOS FALLIDOS--"
echo "--------------------------------------------"
echo -e "\n"
echo " ANTES DE COMENZAR SE CREARÁ UN BACKUP DE LA CARPETA PAM.D EN EL DIRECTORIO /etc/pam.d_backup[fecha/hora]"
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE EL SCRIPT FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
mkdir /etc/pam.d_bakup_$tiempo
cp -r /etc/pam.d/* /etc/pam.d_bakup_$tiempo
cat >/etc/pam.d/password-auth <<EOF
#######################################
#PARÁMETROS GUIA CCN-STIC  SYSTEM-AUTH#
#######################################

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=8 even_deny_root unlock_time=0
auth        sufficient    pam_unix.so try_first_pass nullok
auth        [default=die] pam_faillock.so authfail audit deny=8 even_deny_root unlock_time=0
auth        required      pam_deny.so

account     required      pam_faillock.so
account     required      pam_unix.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    requisite     pam_pwhistory.so debug use_authtok remember=20 retry=3
password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so

EOF
cat >/etc/pam.d/system-auth <<EOF
########################################
#PARÁMETROS GUIA CCN-STIC PASSWORD-AUTH#
########################################

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=8 even_deny_root unlock_time=0
auth        sufficient    pam_unix.so try_first_pass nullok
auth        [default=die] pam_faillock.so authfail audit deny=8 even_deny_root unlock_time=0
auth        required      pam_deny.so

account     required      pam_faillock.so
account     required      pam_unix.so
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    requisite     pam_pwhistory.so debug use_authtok remember=20 retry=3
password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
EOF
##para desbloquear un usuario sudo faillock --user <user> --reset
##para ver bloqueos sudo faillock
echo  " >>>>>>>>EL PROCESO A FINALIZADO CORRECTAMENTE<<<<<<<<"
# Archivo: 10-Unnecessary_items_efi.ks
echo "----------------------------------------------------"
echo "-- SE ELIMINARÁN PROGRAMAS Y DRIVERS INNECESARIOS --"
echo "----------------------------------------------------"
echo

#dnf remove chrony.x86_64 firstboot.x86_64 speech-dispatcher.x86_64 postfix

dnf remove -y firstboot.x86_64 speech-dispatcher.x86_64 postfix

dnf remove -y xinetd telnet-server rsh-server \
  telnet rsh ypbind ypserv tfsp-server bind \
  vsfptd dovecot squid net-snmpd talk-server talk
#Drivers de targetas de sonido, wifi, win tv etc..
dnf remove -y ivtv-* iwl*firmware aic94xx-firmware

echo "------------------------------------------------------------------------"
echo "-- RESTRINGIR EL MONTAJE Y DESMONTAJE DINÁMICO DE SISTEMAS DE ARCHIVOS--"
echo "------------------------------------------------------------------------"

touch /etc/modprobe.d/limites_archivos.conf
cat > /etc/modprobe.d/limites_archivos.conf << EOF
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
#Comentar en caso de instalacion EFI
#install fat /bin/true
#Comentar en caso de instalacion EFI
#install vfat /bin/true
install cifs /bin/true
install nfs /bin/true
install nfsv3 /bin/true
install nfsv4 /bin/true
install gfs2 /bin/true
install bnep /bin/true
install bluetooth /bin/true
install btusb /bin/true
install net-pf-31 /bin/true
EOF


#Drivers wifi
for i in $(find /lib/modules/$(uname -r)/kernel/drivers/net/wireless -name "*.ko*" -type f);do \
  echo blacklist "$i" >>/etc/modprobe.d/limites-wireless.conf;done

echo "-----------------------------------------------------------------------"
echo "-- SE DESHABILITARAN Y ENMASCARARÁN DEMONIOS Y PROCESOS INNECESARIOS --"
echo "-----------------------------------------------------------------------"


systemctl mask bluetooth.target
systemctl mask printer.target
systemctl mask remote-fs.target
systemctl mask rpcbind.target
systemctl mask runlevel4.target
systemctl mask runlevel5.target
systemctl mask runlevel6.target
systemctl mask smartcard.target
systemctl mask sound.target
systemctl mask console-getty.service
systemctl mask debug-shell.service
systemctl mask rdisc.service
systemctl mask ctrl-alt-del.target
systemctl mask iprutils.target
systemctl mask fstrim.timer
systemctl mask container-getty@.service 
systemctl mask console-getty.service
systemctl mask kexec.target
systemctl mask cpupower.service
systemctl mask ebtables.service
systemctl mask dbus-org.freedesktop.hostname1.service
systemctl mask dbus-org.freedesktop.portable1.service
systemctl mask debug-shell.service
systemctl mask dracut-cmdline.service
systemctl mask dracut-initqueue.service
systemctl mask dracut-mount.service
systemctl mask dracut-pre-mount.service
systemctl mask dracut-pre-pivot.service
systemctl mask dracut-pre-trigger.service
systemctl mask dracut-pre-udev.service
systemctl mask dracut-shutdown.service
systemctl mask getty@.service
systemctl mask import-state.service
systemctl mask iprdump.service
systemctl mask iprinit.service
systemctl mask iprupdate.service
systemctl mask kmod-static-nodes.service
systemctl mask loadmodules.service
systemctl mask nftables.service
systemctl mask nis-domainname.service
systemctl mask plymouth-halt.service
systemctl mask plymouth-kexec.service
systemctl mask plymouth-poweroff.service
systemctl mask plymouth-quit-wait.service
systemctl mask plymouth-quit.service
systemctl mask plymouth-read-write.service
systemctl mask plymouth-reboot.service
systemctl mask plymouth-start.service
systemctl mask plymouth-switch-root.service
systemctl mask rdisc.service
systemctl mask rescue.service
systemctl mask serial-getty@.service
# Necesario DNS systemctl mask systemd-resolved.service
systemctl mask tuned.service

##########################################################################################
echo "-------------------------------------------------"
echo "-- SE BLOQUEARÁN LOS COMPILADORES DEL SISTEMA  --"
echo "-------------------------------------------------"
sudo chmod 000 /usr/bin/byacc 2>>/dev/null
sudo chmod 000 /usr/bin/yacc 2>>/dev/null
sudo chmod 000 /usr/bin/bcc 2>>/dev/null
sudo chmod 000 /usr/bin/kgcc 2>>/dev/null
sudo chmod 000 /usr/bin/cc 2>>/dev/null
sudo chmod 000 /usr/bin/gcc 2>>/dev/null
sudo chmod 000 /usr/bin/*c++ 2>>/dev/null
sudo chmod 000 /usr/bin/*g++ 2>>/dev/null


# Archivo: 10-Unnecessary_items.ks
echo "----------------------------------------------------"
echo "-- SE ELIMINARÁN PROGRAMAS Y DRIVERS INNECESARIOS --"
echo "----------------------------------------------------"
echo

#dnf remove chrony.x86_64 firstboot.x86_64 speech-dispatcher.x86_64 postfix

dnf remove -y firstboot.x86_64 speech-dispatcher.x86_64 postfix

dnf remove -y xinetd telnet-server rsh-server \
  telnet rsh ypbind ypserv tfsp-server bind \
  vsfptd dovecot squid net-snmpd talk-server talk
#Drivers de targetas de sonido, wifi, win tv etc..
dnf remove -y ivtv-* iwl*firmware aic94xx-firmware

echo "------------------------------------------------------------------------"
echo "-- RESTRINGIR EL MONTAJE Y DESMONTAJE DINÁMICO DE SISTEMAS DE ARCHIVOS--"
echo "------------------------------------------------------------------------"

touch /etc/modprobe.d/limites_archivos.conf
cat > /etc/modprobe.d/limites_archivos.conf << EOF
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
install squashfs /bin/true
install udf /bin/true
#Comentar en caso de instalacion EFI
install fat /bin/true
#Comentar en caso de instalacion EFI
install vfat /bin/true
install cifs /bin/true
install nfs /bin/true
install nfsv3 /bin/true
install nfsv4 /bin/true
install gfs2 /bin/true
install bnep /bin/true
install bluetooth /bin/true
install btusb /bin/true
install net-pf-31 /bin/true
EOF


#Drivers wifi
for i in $(find /lib/modules/$(uname -r)/kernel/drivers/net/wireless -name "*.ko*" -type f);do \
  echo blacklist "$i" >>/etc/modprobe.d/limites-wireless.conf;done

echo "-----------------------------------------------------------------------"
echo "-- SE DESHABILITARAN Y ENMASCARARÁN DEMONIOS Y PROCESOS INNECESARIOS --"
echo "-----------------------------------------------------------------------"


systemctl mask bluetooth.target
systemctl mask printer.target
systemctl mask remote-fs.target
systemctl mask rpcbind.target
systemctl mask runlevel4.target
systemctl mask runlevel5.target
systemctl mask runlevel6.target
systemctl mask smartcard.target
systemctl mask sound.target
systemctl mask console-getty.service
systemctl mask debug-shell.service
systemctl mask rdisc.service
systemctl mask ctrl-alt-del.target
systemctl mask iprutils.target
systemctl mask fstrim.timer
systemctl mask container-getty@.service 
systemctl mask console-getty.service
systemctl mask kexec.target
systemctl mask cpupower.service
systemctl mask ebtables.service
systemctl mask dbus-org.freedesktop.hostname1.service
systemctl mask dbus-org.freedesktop.portable1.service
systemctl mask debug-shell.service
systemctl mask dracut-cmdline.service
systemctl mask dracut-initqueue.service
systemctl mask dracut-mount.service
systemctl mask dracut-pre-mount.service
systemctl mask dracut-pre-pivot.service
systemctl mask dracut-pre-trigger.service
systemctl mask dracut-pre-udev.service
systemctl mask dracut-shutdown.service
systemctl mask getty@.service
systemctl mask import-state.service
systemctl mask iprdump.service
systemctl mask iprinit.service
systemctl mask iprupdate.service
systemctl mask kmod-static-nodes.service
systemctl mask loadmodules.service
systemctl mask nftables.service
systemctl mask nis-domainname.service
systemctl mask plymouth-halt.service
systemctl mask plymouth-kexec.service
systemctl mask plymouth-poweroff.service
systemctl mask plymouth-quit-wait.service
systemctl mask plymouth-quit.service
systemctl mask plymouth-read-write.service
systemctl mask plymouth-reboot.service
systemctl mask plymouth-start.service
systemctl mask plymouth-switch-root.service
systemctl mask rdisc.service
systemctl mask rescue.service
systemctl mask serial-getty@.service
systemctl mask systemd-resolved.service
systemctl mask tuned.service

##########################################################################################
echo "-------------------------------------------------"
echo "-- SE BLOQUEARÁN LOS COMPILADORES DEL SISTEMA  --"
echo "-------------------------------------------------"
sudo chmod 000 /usr/bin/byacc 2>>/dev/null
sudo chmod 000 /usr/bin/yacc 2>>/dev/null
sudo chmod 000 /usr/bin/bcc 2>>/dev/null
sudo chmod 000 /usr/bin/kgcc 2>>/dev/null
sudo chmod 000 /usr/bin/cc 2>>/dev/null
sudo chmod 000 /usr/bin/gcc 2>>/dev/null
sudo chmod 000 /usr/bin/*c++ 2>>/dev/null
sudo chmod 000 /usr/bin/*g++ 2>>/dev/null


# Archivo: 11-Orphan_packages.ks
echo "---------------------------------"
echo "--ELIMINANDO PAQUETES HUÉRFANOS--"
echo "---------------------------------"
dnf install -y yum-utils
dnf -y autoremove
dnf -y clean all
dnf -y remove `package-cleanup --orphans`
dnf -y remove `package-cleanup --leaves`
# Archivo: 12-USB_limitation.ks

#evitando usb 
echo "----------------------------------------------------------------"
echo "-- SE DENEGARÁ EL ACCESO A LOS DISPOSITIVOS DE ALMACENAMIENTO --"
echo "----------------------------------------------------------------"
echo -e "\n"


cat > /etc/usbguard/usbguard-daemon.conf << EOF
####REGLAS GUIA#####
# Ruta de reglas
RuleFile=/etc/usbguard/rules.conf

# Regla por defecto
#
ImplicitPolicyTarget=block

#
# Política de de dispositivos activa.
#
# Cómo tratar los dispositivos que ya están conectados cuando
# demonio se inicia:
# #
# * allow - autoriza cada dispositivo presente en el sistema
# * block: desautoriza todos los dispositivos presentes en el sistema
# * reject: elimina todos los dispositivos presentes en el sistema
# * keep - solo sincroniza el estado interno y mantiene el dispositivo
# * apply-policy - evalúa el conjunto de reglas para cada dispositivo
#
PresentDevicePolicy=apply-policy
PresentControllerPolicy=apply-policy

# Política de de dispositivos insertados
#
# Cómo tratar los dispositivos USB que ya están conectados
# con el demonio activo:
#
# * block: desautoriza todos los dispositivos presentes en el sistema
# * reject: elimina todos los dispositivos presentes en el sistema
# * apply-policy - evalúa el conjunto de reglas para cada dispositivo
#
InsertedDevicePolicy=apply-policy

###
RestoreControllerDeviceState=false
###
DeviceManagerBackend=uevent

#Usuarios permitidos para interfaz IPC
IPCAllowedUsers=root aCdCmN610
IPCAllowedGroups=wheel

###
IPCAccessControlFiles=/etc/usbguard/IPCAccessControl.d/

###Generación de reglas por puerto USB
DeviceRulesWithPort=false
###
AuditBackend=FileAudit
AuditFilePath=/var/log/usbguard/usbguard-audit.log
EOF
systemctl enable usbguard.service
systemctl restart usbguard.service
systemctl status usbguard.service
echo ">>>>El SCRIPT ha finalizado<<<<"

