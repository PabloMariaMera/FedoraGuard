%post --log=/root/logs/14-Configure_cockpit.ks

dnf -y install cockpit
systemctl enable cockpit

%end

