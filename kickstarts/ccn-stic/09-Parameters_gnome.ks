%post --log=/root/logs/09-Parameters_gnome.ks
#!/bin/bash
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

%end