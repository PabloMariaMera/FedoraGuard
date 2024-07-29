%post --log=/root/logs/07-failed_attempts.ks
#!/bin/bash
echo "--------------------------------------------"
echo "--BLOQUEO DE CUENTAS POR INTENTOS FALLIDOS--"
echo "--------------------------------------------"
echo -e "\n"
echo " ANTES DE COMENZAR SE CREARÁ UN BACKUP DE LA CARPETA PAM.D EN EL DIRECTORIO /etc/pam.d_backup[fecha/hora]"
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE EL SCRIPT FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
mkdir /etc/pam.d_bakup_$tiempo
cp -r /etc/pam.d/* /etc/pam.d_bakup_$tiempo
cat >/etc/pam.d/password-auth <<EOF
#######################################
#PARÁMETROS GUIA CCN-STIC  SYSTEM-AUTH#
#######################################

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=8 even_deny_root unlock_time=0
auth        sufficient    pam_unix.so try_first_pass nullok
auth        [default=die] pam_faillock.so authfail audit deny=8 even_deny_root unlock_time=0
auth        required      pam_deny.so

account     required      pam_faillock.so
account     required      pam_unix.so

password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    requisite     pam_pwhistory.so debug use_authtok remember=20 retry=3
password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so

EOF
cat >/etc/pam.d/system-auth <<EOF
########################################
#PARÁMETROS GUIA CCN-STIC PASSWORD-AUTH#
########################################

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=8 even_deny_root unlock_time=0
auth        sufficient    pam_unix.so try_first_pass nullok
auth        [default=die] pam_faillock.so authfail audit deny=8 even_deny_root unlock_time=0
auth        required      pam_deny.so

account     required      pam_faillock.so
account     required      pam_unix.so
password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
password    requisite     pam_pwhistory.so debug use_authtok remember=20 retry=3
password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
EOF
##para desbloquear un usuario sudo faillock --user <user> --reset
##para ver bloqueos sudo faillock
echo  " >>>>>>>>EL PROCESO A FINALIZADO CORRECTAMENTE<<<<<<<<"
%end