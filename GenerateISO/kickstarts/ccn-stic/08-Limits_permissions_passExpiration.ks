%post --log=/root/logs/08-Limits_permissions_passExpiration.ks
#!/bin/bash
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
#Evitando generacion de ficheros core
echo "----------------------------------------"
echo "--SUPRIMIENDO GENERACIÓN FICHEROS CORE--"
echo "----------------------------------------"
echo -e "\n"
echo " ANTES DE COMENZAR SE CREARÁ UN BACKUP DEL FICHERO "/etc/security/limits.conf" CON LA SIGUIENTE NOMENCLATURA "/etc/security/limits.conf_backup[fecha/hora]""
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE EL SCRIPT FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"

cp -r /etc/security/limits.conf /etc/security/limits.conf_bakup_$tiempo
cat /etc/security/limits.conf |grep -v "#" >/etc/security/limits.conf.R
cat >/etc/security/limits.conf <<EOF
#############################################
# Párámetros incluidos por la guía CCN-STIC #
#############################################

#<domain>      <type>  <item>         <value>
EOF
cat /etc/security/limits.conf.R >>/etc/security/limits.conf
var1=$(cat /etc/security/limits.conf |grep "soft    core")
if [ -z "$var1" ]
then
cat >>/etc/security/limits.conf <<EOF
*               soft    core            0
EOF
else
sed -i -e 's/.*soft    core.*/*               soft    core            0/' /etc/security/limits.conf

fi
var1=$(cat /etc/security/limits.conf |grep "hard    core")
if [ -z "$var1" ]
then
cat >>/etc/security/limits.conf <<EOF
*               hard    core            0
EOF
else
sed -i -e 's/.*hard    core.*/*               hard    core            0/' /etc/security/limits.conf
fi
rm -rf /etc/security/limits.conf.R

echo "*               soft   nofile    4096" >> /etc/security/limits.conf
echo "*               hard   nofile    65536" >> /etc/security/limits.conf
echo "*               soft   nproc     4096" >> /etc/security/limits.conf
echo "*               hard   nproc     4096" >> /etc/security/limits.conf
echo "*               soft   locks     4096" >> /etc/security/limits.conf
echo "*               hard   locks     4096" >> /etc/security/limits.conf
echo "*               soft   stack     10240" >> /etc/security/limits.conf
echo "*               hard   stack     32768" >> /etc/security/limits.conf
echo "*               soft   memlock   64" >> /etc/security/limits.conf
echo "*               hard   memlock   64" >> /etc/security/limits.conf
echo "*               hard   maxlogins 1" >> /etc/security/limits.conf
echo "# Límite soft 32GB, hard 64GB" >> /etc/security/limits.conf
echo "*               soft   fsize     33554432" >> /etc/security/limits.conf
echo "*               hard   fsize     67108864" >> /etc/security/limits.conf
echo "# Límites para root" >> /etc/security/limits.conf
echo "root            soft   nofile    4096" >> /etc/security/limits.conf
echo "root            hard   nofile    65536" >> /etc/security/limits.conf
echo "root            soft   nproc     4096" >> /etc/security/limits.conf
echo "root            hard   nproc     4096" >> /etc/security/limits.conf
echo "root            oft    stack     10240" >> /etc/security/limits.conf
echo "root            hard   stack     32768" >> /etc/security/limits.conf
echo "root            soft   fsize     33554432" >> /etc/security/limits.conf
#echo "*		hard 	rss		40000" >> /etc/security/limits.conf
echo "# FIN DE FICHERO" >>/etc/security/limits.conf
#Caducidad de las contraseñas y permisos a usuarios
echo "--------------------------------------------------------------"
echo "--FORZANDO CADUCIDAD EN LAS CONTRASEÑAS DE USUARIO (45 DÍAS)--"
echo "--------------------------------------------------------------"
echo -e "\n"
echo -e "\n"
sed -i -e 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS  45/' /etc/login.defs
sed -i -e 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS  2/' /etc/login.defs
sed -i -e 's/^PASS_WARN_AGE.*/PASS_WARN_AGE  10/' /etc/login.defs
var1=$(cat /etc/login.defs |grep "PASS_MIN_LEN")
if [ -z "$var1" ]
then
cat >>/etc/login.defs <<EOF
PASS_MIN_LEN  12
EOF
else
sed -i -e 's/^PASS_MIN_LEN.*/PASS_MIN_LEN  12/' /etc/login.defs
fi
var1=$(cat /etc/login.defs |grep "ENCRYPT_METHOD")
if [ -z "$var1" ]
then
cat >>/etc/login.defs <<EOF
ENCRYPT_METHOD  SHA512
EOF
else
sed -i -e 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD  SHA512/' /etc/login.defs
fi
sed -i -e 's/^UMASK.*/UMASK	027/' /etc/login.defs
cat /etc/login.defs |grep -v "#"|grep "PASS"


#######################################################################################
echo "---------------------------------------"
echo "--FORZANDO COMPLEJIDAD DE CONTRASEÑAS--"
echo "---------------------------------------"
echo -e "\n"

sed -i -e 's/minlen.*/minlen = 8/' /etc/security/pwquality.conf
sed -i -e 's/# minlen.*/minlen = 8/' /etc/security/pwquality.conf
sed -i -e 's/dcredit.*/dcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# dcredit.*/dcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/ucredit.*/ucredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# ucredit.*/ucredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/lcredit.*/lcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# lcredit.*/lcredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/ocredit.*/ocredit = 1/' /etc/security/pwquality.conf
sed -i -e 's/# ocredit.*/ocredit = 1/' /etc/security/pwquality.conf

#Sobre usuarios ya existentes

echo "------------------------------------------------------------"
echo "--MODIFICANDO CADUCIDAD CONTRASEÑAS USUARIOS YA EXISTENTES--"
echo "------------------------------------------------------------"
echo -e "\n"

echo "Los usuarios que se modificarán seran los siguientes:"
for LOGIN in `cut -d: -f1 /etc/passwd |grep -v "nobody"`
do
   USERID=`id -u $LOGIN `
 if [ $USERID -ge 1000 ]; then
	echo $LOGIN
      passwd -e $LOGIN
      /usr/bin/chage -m 2 -M 45 -W 10 $LOGIN
   fi
done

#Permisos en los directorios de los usuarios#
echo "-----------------------------------------------------"
echo "--MODIFICANDO PERMISOS DIRECTORIO /home DE USUARIOS--"
echo "-----------------------------------------------------"
echo -e "\n"

for USU in `cut -d: -f1 /etc/passwd |grep -v "nobody"`
do
   USERID=`id -u $USU `
 if [ $USERID -ge 1000 ]; then
	echo $USU
   /bin/chmod g-w /home/$USU
   /bin/chmod o-rwx /home/$USU
   fi
done

%end

