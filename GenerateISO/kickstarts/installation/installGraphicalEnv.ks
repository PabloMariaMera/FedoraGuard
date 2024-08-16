%post --log=/installationlog.txt

exec 3>/tmp/graphical-feedback
echo -e "0\n# Starting installGraphicalEnv..." >&3

system_release=$(cat /etc/system-release)

if [[ $system_release == *"Fedora"* ]]; then
    echo -e "10\n# Sistema operativo detectado: Fedora..." >&3
    echo -e "20\n# Actualizando paquetes desde Internet, puede tardar unos minutos..." >&3
    dnf upgrade -y
    echo -e "50\n# Instalando paquetes de servidor gráfico desde Internet, tardará varios minutos..." >&3
    dnf group install -y "Fedora Workstation"
    systemctl set-default graphical.target
    systemctl enable gdm
# Comprueba si el contenido indica que es Red Hat
elif [[ $system_release == *"Red Hat"* ]]; then
    echo -e "10\n# Sistema operativo detectado: Red Hat..." >&3
    echo -e "20\n# Instalando paquetes de servidor gráfico, puede tardar varios minutos..." >&3
    dnf group install -y "graphical-server-environment"
    systemctl set-default graphical.target
else
    echo "Sistema operativo no soportado: $system_release"
fi

dnf install -y policycoreutils-python-utils

echo -e "100\n# Kickstart installGraphicalEnv finalizado." >&3
exec 3>&-

%end
