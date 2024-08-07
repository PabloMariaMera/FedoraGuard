%post --nochroot --log=/mnt/sysimage/installationlognochroot.txt
if [[ $(cat /mnt/sysimage/etc/system-release) == *"Red Hat"* ]]; then

exec 3>/mnt/sysimage/tmp/graphical-feedback
echo -e "0\n# Starting copyRHELrepos..." >&3

echo -e "20\n# Configurando repositorios en local..." >&3
echo "Configurando repositorios en local..."

# Copy repos to /opt/repositorios
mkdir /mnt/sysimage/opt/repositorios
cp -r /run/install/repo/AppStream  /mnt/sysimage/opt/repositorios
cp -r /run/install/repo/BaseOS  /mnt/sysimage/opt/repositorios

cat << EOT > /mnt/sysimage/etc/yum.repos.d/local.repo
[BaseOS]
name=BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///opt/repositorios/BaseOS/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[AppStream]
name=AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///opt/repositorios/AppStream/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOT

echo -e "100\n# Repositorio local configurado." >&3
exec 3>&-
fi
%end

%post --log=/mnt/sysimage/installationlognochroot.txt
if [[ $(cat /etc/system-release) == *"Red Hat"* ]]; then
exec 3>/tmp/graphical-feedback
echo -e "0\n# Configurar EPEL..." >&3

echo -e "80\n# Configurando repositorio remoto EPEL..." >&3
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm

echo -e "100\n# Kickstart copyRHELrepos finalizado." >&3
exec 3>&-
fi
%end
