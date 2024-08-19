%post --log=/root/logs/11-Orphan_packages.ks
#!/bin/bash
echo "---------------------------------"
echo "--ELIMINANDO PAQUETES HUÉRFANOS--"
echo "---------------------------------"
dnf install -y yum-utils
dnf -y autoremove
dnf -y clean all
dnf -y remove `package-cleanup --orphans`
dnf -y remove `package-cleanup --leaves | grep -v cracklib-dicts | grep -v libsss_sudo`
%end