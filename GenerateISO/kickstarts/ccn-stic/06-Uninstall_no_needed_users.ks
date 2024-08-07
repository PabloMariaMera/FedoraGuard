%post --log=/root/logs/06-Uninstall_no_needed_users.ks
#!/bin/bash
echo "---------------------------------------"
echo "--DESINSTALANDO USUARIOS INNECESARIOS--"
echo "---------------------------------------"

cat /etc/shells|grep -q "/sbin/shutdown"

	if ! [[ $? = 0 ]]; then
	
		echo "/sbin/shutdown" >> /etc/shells
	fi

cat /etc/shells|grep -q "/sbin/halt"

	if ! [[ $? = 0 ]]; then
	
		echo "/sbin/halt" >> /etc/shells
	fi
	
########################################
#userdel -r netdump
#userdel -r sync
#userdel -r rpc
#userdel -r dbus
#userdel -r gopher
#userdel -r ftp #si desinstalamos el ftp
groupdel games
groupdel floppy
userdel games
#userdel -r lp
#userdel -r uucp
#userdel -r pcap
#userdel -r haldaemon
#userdel -r sshd #si desinstalamos el ssh
#userdel -r mail
#userdel -r chrony
#userdel -r geoclue
#chsh -s /bin/bash root

########################################
chsh -s /sbin/shutdown shutdown
chsh -s /sbin/halt halt
### disable login root  change from /bin/bash to /bin/false
#usermod -s /bin/false root
usermod -s /bin/false nobody
%end