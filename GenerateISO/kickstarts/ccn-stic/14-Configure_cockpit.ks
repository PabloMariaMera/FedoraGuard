%post --log=/root/logs/14-Configure_cockpit.ks

dnf -y install cockpit
systemctl enable --now cockpit.socket
firewall-cmd --permanent --add-port=9090/tcp
firewall-offline-cmd --add-port=9090/tcp
%end

