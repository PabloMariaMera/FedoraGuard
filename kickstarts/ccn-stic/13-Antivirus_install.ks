%post --log=/root/logs/13-Antivirus_install.ks
#!/bin/bash
echo "---------------------------------"
echo "--Instalando antivirus ClamAV--"
echo "---------------------------------"
dnf install -y clamav clamav-data clamav-devel clamav-filesystem clamav-update clamd
dnf -y autoremove
dnf -y clean all

%end

