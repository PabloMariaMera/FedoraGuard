%post --log=/root/logs/02-User_root_and_without_password.ks
#!/bin/bash
echo "-----------------------------------------------"
echo "-- SE CONFIGURA LA CONTRASEÑA SEGURA DE ROOT --"
echo "-----------------------------------------------"
echo

echo
/usr/bin/chage -m 2 -M 45 -W 10 root

sleep 2
#La siguiente línea debe estar en la línea 13
echo "root" | passwd --stdin root;

echo

/usr/bin/chage -l root


echo
echo "--------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS CON UID 0 --"
echo "--------------------------------------------"
echo
echo

UiD=$(cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root)

if [[ -z $UiD ]]; then

	echo "No se detectan usuarios con UID 0."

else

	echo "Se detectan los siguientes usuarios con UID 0:"
	echo
	cat /etc/passwd |cut -d":" -f1,3 | grep -w 0|cut -d":" -f1|grep -v root

fi

echo
echo "-------------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS SIN CONTRASEÑA --"
echo "-------------------------------------------------"
echo

echo 

Sinpass=$(cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1)

if [[ -z $Sinpass ]]; then
	
	echo "No se detectan usuarios sin contraseña."

else

	echo "Se detectan los siguientes usuarios sin contraseña:"

	cat /etc/shadow |cut -d":" -f-2 | grep ":$" |cut -d":" -f1

fi

echo

echo "----------------------------------------------------------------"
echo "-- SE PROCEDE A BUSCAR USUARIOS/GRUPOS SUDOERS SIN CONTRASEÑA --"
echo "----------------------------------------------------------------"
echo

echo

Nopass=$(cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD")

if [[ -z $Nopass ]]; then

	echo "No se detectan usuarios sin contraseña en sudoers."

else

	echo "Se detectan usuarios/grupos sin contraseña en sudoers:"
	echo

	cat /etc/sudoers|grep -v "^#" |grep -i "NOPASSWD"

fi

%end