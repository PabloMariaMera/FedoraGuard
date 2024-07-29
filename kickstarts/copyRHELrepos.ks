%post --nochroot --log=/mnt/sysimage/installationlognochroot.txt
if [[ $(cat /mnt/sysimage/etc/system-release) == *"Red Hat"* ]]; then

echo "Sistema operativo detectado: Red Hat"
echo "Configurando repositorios en local..."

# Copy repos to /opt/repositorios
mkdir /mnt/sysimage/opt/repositorios
cp -r /run/install/repo/AppStream  /mnt/sysimage/opt/repositorios
cp -r /run/install/repo/BaseOS  /mnt/sysimage/opt/repositorios

cat << EOT > /mnt/sysimage/etc/yum.repos.d/redhat.repo
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

fi
%end
