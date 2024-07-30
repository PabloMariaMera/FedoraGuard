%post --log=/installationlog.txt

ping -c 4 1.1.1.1

# Verifica si el archivo /etc/system-release existe
if [ -f /etc/system-release ]; then
    # Lee el contenido del archivo
    system_release=$(cat /etc/system-release)

    # Comprueba si el contenido indica que es Fedora
    if [[ $system_release == *"Fedora"* ]]; then
        echo "Sistema operativo detectado: Fedora"
        echo "Ejecutando: dnf upgrade"
        dnf upgrade -y
        echo "Ejecutando: dnf group install 'Fedora Workstation'"
        dnf group install -y "Fedora Workstation"
        systemctl set-default graphical.target
        systemctl enable gdm
    # Comprueba si el contenido indica que es Red Hat
    elif [[ $system_release == *"Red Hat"* ]]; then
        echo "Sistema operativo detectado: Red Hat"
        echo "Ejecutando: dnf group install 'graphical-server-environment'"
        dnf group install -y "graphical-server-environment"
        systemctl set-default graphical.target
    else
        echo "Sistema operativo no soportado: $system_release"
    fi
else
    echo "El archivo /etc/system-release no existe."
fi

dnf install policycoreutils-python-utils usbguard -y

%end
