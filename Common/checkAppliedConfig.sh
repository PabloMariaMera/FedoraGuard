#!/bin/bash

# Definimos los colores
RED='\033[0;31m'    # Rojo
GREEN='\033[0;32m'  # Verde
NC='\033[0m'        # Sin color (reset)

# Lista de configuraciones
# 01-Password_grub
items="$items check_password_grub"
# 02-User_root_and_without_password
items="$items uid_0_users no_password_users no_password_sudoers"
# 03-Parameters_kernel
items="$items kernel_parameters"
# 04-Parameters_SSH
items="$items ssh_parameters"
# 05-Handling_register_activity
items="$items audit_config audit_daemon"
# 06-Uninstall_no_needed_users
items="$items no_needed_users allow_root"
# 07-Failed_attempts
items="$items pamd_faillock"
# 08-Limits_permissions_passExpiration
items="$items avoid_cores password_expiration password_encryption_sha512 password_complexity home_permissions"
# 09-Parameters_gnome
items="$items login_banner no_user_list inactivity_blackscreen inactivity_lock"
# 10-Unnecessary_items_efi
items="$items no_needed_packages_drivers no_auto_mount no_needed_daemons no_compilers"
# 11-Orphan_packages
items="$items no_orphan_packages"
# 12-USB_limitation
items="$items usbguard_installed usbguard_config usbguard_daemon"
# 13-Antivirus_install
items="$items clamav_installed clamav_daemon"
# 14-Configure_cockpit
items="$items cockpit_installed cockpit_daemon"

check_configuration() {
    local item=$1

    if [ "$item" == "check_password_grub" ]; then
        echo -n "GRUB password: "
        if grep -q "password_pbkdf2" /etc/grub.d/40_custom; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "uid_0_users" ]; then
        echo -n "UID 0 users: "
        UiD=$(cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root)
        if [[ -z $UiD ]]; then
            return 0  # Solo root tiene UID 0
        else
            #cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root
            return 1  # Hay otros usuarios con UID 0

        fi

    elif [ "$item" == "no_password_users" ]; then
        echo -n "No password users: "
        Sinpass=$(cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1)
        if [[ -z $Sinpass ]]; then
            return 0  # Todos los usuarios tienen contraseña
        else
            #cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1
            return 1  # Hay usuarios sin contraseña
        fi

    elif [ "$item" == "no_password_sudoers" ]; then
        echo -n "No password sudoers: "
        Nopass=$(cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD")
        if [[ -z $Nopass ]]; then
            return 0  # No hay NOPASSWD en sudoers
        else
            #cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD"
            return 1  # Hay NOPASSWD en sudoers
        fi

    elif [ "$item" == "kernel_parameters" ]; then
        echo -n "Kernel parameters: "
        some_params=(
            "net.ipv4.conf.all.send_redirects=0"
            "net.ipv4.conf.default.accept_redirects=0"
            "net.ipv6.conf.all.accept_source_route=0"
            "net.ipv4.icmp_echo_ignore_broadcasts=1"
            "fs.suid_dumpable=0"
        )
        for param in "${some_params[@]}"; do
            if ! grep -q "^$param" /etc/sysctl.conf; then
                #echo "Falta o está mal configurado: $param"
                return 1
            fi
        done
        return 0 # todos los parámetros están configurados

    elif [ "$item" == "ssh_parameters" ]; then
        echo -n "SSH parameters: "
        some_configs=(
            "Banner /etc/ssh/issue"
            "UsePAM yes"
            "GSSAPIAuthentication no"
            "PermitRootLogin no"
            "MaxAuthTries 3"
            "PermitEmptyPasswords no"
        )
        for config in "${some_configs[@]}"; do
            # Verificar si la línea existe y no está comentada
            if ! grep -q "^$config" /etc/ssh/sshd_config; then
                #echo "Falta o está comentado: $config"
                return 1
            fi
        done
        return 0  # Configurado

    elif [ "$item" == "audit_config" ]; then
        echo -n "Audit config: "
        some_params=(
            "-w /etc/audit/ -p wa -k auditconfig"
            "-w /sbin/auditctl -p x -k audittools"
            "-w /etc/sysctl.conf -p wa -k sysctl"
            "-w /etc/sudoers -p wa -k actions"
            "-a always,exit -F arch=b64 -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod"
            "-a always,exit -F dir=/home -F uid=0 -F auid>=1000 -F auid!=4294967295 -C auid!=obj_uid -k power_abuse"
        )
        for param in "${some_params[@]}"; do
            if ! grep -q "^$param" /etc/audit/rules.d/audit.rules; then
                #echo "Falta o está mal configurado: $param"
                return 1
            fi
        done
        return 0 # todos los parámetros están configurados

    elif [ "$item" == "audit_daemon" ]; then
        echo -n "Audit daemon: "
        if systemctl is-active auditd > /dev/null 2>&1; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "no_needed_users" ]; then
        echo -n "No needed users: "
        if [[ $(cat /etc/passwd | grep -c games:x:) == 0 ]] && [[ $(cat /etc/group | grep -c floppy:x:) == 0 ]]; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "allow_root" ]; then
        echo -n "Allow root: "
        if [[ $(cat /etc/passwd | grep root:x:0 | grep -c /bin/false) == "1" ]]; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "pamd_faillock" ]; then
        echo -n "PAMD faillock: "
        if grep -q "pam_faillock.so" /etc/pam.d/system-auth; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "avoid_cores" ]; then
        echo -n "Avoid cores: "
        if grep -q "root            soft   fsize     33554432" /etc/security/limits.conf; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "password_expiration" ]; then
        echo -n "Password expiration: "
        if grep -q "PASS_MAX_DAYS  45" /etc/login.defs && grep -q "PASS_MIN_LEN  12" /etc/login.defs; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "password_encryption_sha512" ]; then
        echo -n "Password encryption SHA512: "
        if grep -q "ENCRYPT_METHOD  SHA512" /etc/login.defs; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "password_complexity" ]; then
        echo -n "Password complexity: "
        if grep -q "dcredit = 1" /etc/security/pwquality.conf && grep -q "ocredit = 1" /etc/security/pwquality.conf; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "home_permissions" ]; then
        echo -n "Home permissions: "
        # Recorremos cada directorio en /home
        for dir in /home/*; do
        if [ -d "$dir" ]; then
            # Obtener el nombre del directorio (que debería ser el nombre del usuario)
            user=$(basename "$dir")
            # Comprobar que el directorio pertenece al usuario correspondiente
            owner=$(stat -c "%U" "$dir")
            if [ "$owner" != "$user" ]; then
                #echo "El directorio $dir no pertenece a su usuario correspondiente (esperado: $user, encontrado: $owner)"
                return 1  # No configurado
            fi
            # Comprobar que los permisos del directorio sean 700
            perms=$(stat -c "%A" "$dir")
            if [ "$perms" != "drwx------" ]; then
                #echo "Permisos incorrectos en $dir (esperado: drwx------, encontrado: $perms)"
                return 1  # No configurado
            fi
        fi
        done
        return 0  # Configurado

    elif [ "$item" == "login_banner" ]; then
        echo -n "Login banner: "
        if grep -qr "banner-message-enable=true" /etc/dconf/db/gdm.d/; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "no_user_list" ]; then
        echo -n "No login user list: "
        if grep -qr "disable-user-list=true" /etc/dconf/db/gdm.d/; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "inactivity_blackscreen" ]; then
        echo -n "Inactivity blackscreen: "
        if grep -qr "idle-delay=" /etc/dconf/db/local.d/; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "inactivity_lock" ]; then
        echo -n "Inactivity lock: "
        if grep -qr "lock-enabled=true" /etc/dconf/db/local.d/; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "no_needed_packages_drivers" ]; then
        echo -n "No needed packages drivers: "
        # Lista de paquetes a verificar (usando patrones de grep)
        packages=(
            "firstboot.x86_64"
            "speech-dispatcher.x86_64"
            "postfix"
            "xinetd"
            "telnet-server"
            "rsh-server"
            "telnet"
            "rsh"
            "ypbind"
            "ypserv"
            "tfsp-server"
            "bind"
            "vsfptd"
            "dovecot"
            "squid"
            "net-snmpd"
            "talk-server"
            "talk"
            "ivtv-"
            "iwl.*firmware"
            "aic94xx-firmware"
        )
        # Convertir la lista de paquetes a una cadena separada por |
        pattern=$(IFS="|"; echo "${packages[*]}")
        # Verificar cada paquete
        for package in "${packages[@]}"; do
            # Verificar si el paquete está instalado
            if rpm -q "$package" &> /dev/null; then
                # echo "El paquete $package está instalado."
                return 1  # No configurado
            fi
        done
        return 0  # Configurado  

    elif [ "$item" == "no_auto_mount" ]; then
        echo -n "No auto mount: "
        if grep -qr "install squashfs" /etc/modprobe.d/; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "no_needed_daemons" ]; then
        echo -n "No needed daemons: "
        services=(
        "bluetooth.target"
        "printer.target"
        "remote-fs.target"
        "rpcbind.target"
        "smartcard.target"
        "sound.target"
        "tuned.service"
        "debug-shell.service"
        "dracut-cmdline.service"
        "console-getty.service"
        "rescue.service"
        )
        # Verificar el estado de cada servicio
        any_active=false
        for service in "${services[@]}"; do
            if systemctl is-enabled --quiet "$service"; then
                #echo "El servicio $service está activo."
                return 1  # No configurado
            fi
        done
        return 0  # Configurado

    elif [ "$item" == "no_compilers" ]; then
        echo -n "No compilers: "
        files=(
            "/usr/bin/byacc"
            "/usr/bin/yacc"
            "/usr/bin/bcc"
            "/usr/bin/kgcc"
            "/usr/bin/cc"
            "/usr/bin/gcc"
            "/usr/bin/*c++"
            "/usr/bin/*g++"
        )
        # Verificar los permisos de cada archivo
        for file in "${files[@]}"; do
            # Expandir comodines en la lista de archivos
            for expanded_file in $file; do
                if [ -e "$expanded_file" ]; then
                    permissions=$(stat -c "%a" "$expanded_file")
                    if [ "$permissions" != "000" ]; then
                        #echo "El archivo $expanded_file NO tiene permisos 000 (actual: $permissions)."
                        return 1  # No configurado
                    fi
                fi
            done
        done
        return 1  # No configurado

    elif [ "$item" == "no_orphan_packages" ]; then
        echo -n "No orphan packages: "
        if false; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "usbguard_installed" ]; then
        echo -n "USBGuard installed: "
        if yum list installed usbguard --quiet; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "usbguard_config" ]; then
        echo -n "USBGuard config: "
        if false; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "usbguard_daemon" ]; then
        echo -n "USBGuard daemon: "
        if false; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "clamav_installed" ]; then
        echo -n "ClamAV installed: "
        if false; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "clamav_daemon" ]; then
        echo -n "ClamAV daemon: "
        if systemctl is-active clamav-freshclam > /dev/null 2>&1 && systemctl is-active clamd@scan > /dev/null 2>&1; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "cockpit_installed" ]; then
        echo -n "Cockpit installed: "
        if false; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    elif [ "$item" == "cockpit_daemon" ]; then
        echo -n "Cockpit daemon: "
        if systemctl is-active cockpit.socket > /dev/null 2>&1; then
            return 0  # Configurado
        else
            return 1  # No configurado
        fi

    else
        echo -n "$item: "
        return 1  # No configurado
    fi

}

# Contadores
configured_count=0
unconfigured_count=0

# Iterar sobre los elementos
for item in ${items}; do
    if check_configuration "$item"; then
        echo -e "${GREEN}CORRECTO${NC}"
        ((configured_count++))
    else
        echo -e "${RED}NO CORRECTO${NC}"
        ((unconfigured_count++))
    fi
done

echo
echo " # Correctos: $configured_count"
echo " # Incorrectos: $unconfigured_count"
echo " # Total: $((configured_count + unconfigured_count))"
echo
echo "Puntuación: $((configured_count * 100 / (configured_count + unconfigured_count)))/100"