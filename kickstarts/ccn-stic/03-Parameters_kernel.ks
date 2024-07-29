%post --log=/root/logs/03-Parameters_kernel.ks
#!/bin/bash
tiempo=$( date +"%d-%b-%y-%H:%M:%S" )
echo "-----------------------------------"
echo "--APLICANDO PARÁMETROS DEL KERNEL--"
echo "-----------------------------------"
echo -e "\n"
echo " EL SCRIPT GUARDARÁ UNA COPIA DE LOS ARCHIVOS ORGINALES POR SI SE DESEARA RESTAURAR CONFIGURACIONES ANTERIORES EN:"
echo " /etc/sysctl.conf.bak_$tiempo"
echo "/etc/sysctl.d_$tiempo/"
echo " NO DETENGA EL SCRIPT, NI HAGA NADA HASTA QUE FINALICE"
echo " EN CASO DE DETENCIÓN DEL SCRIPT; VUELVA A EJECUTARLO ANTES DE REINICIAR, HASTA QUE FINALICE EL PROCESO CORRECTAMENTE"
#####################################################################
mkdir /etc/sysctl.d_$tiempo
cp -r /etc/sysctl.d/* /etc/sysctl.d_$tiempo
cp /etc/sysctl.conf /etc/sysctl.conf.bak_$tiempo
rm -f /etc/sysctl.conf


sudo sysctl -w net.ipv4.conf.all.send_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.send_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.secure_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.secure_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.all.log_martians=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.conf.default.log_martians=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 >>/etc/sysctl.conf
sudo sysctl -w net.ipv4.tcp_syncookies=1 >>/etc/sysctl.conf
sudo sysctl -w fs.suid_dumpable=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_source_route=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_redirects=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_ra=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.all.accept_ra=0 >>/etc/sysctl.conf
sudo sysctl -w net.ipv6.conf.default.accept_redirects=0 >>/etc/sysctl.conf
##############################ADICIONALES####################
cat >> /etc/sysctl.conf << EOF
# PARÁMETROS REVISABLES
# ----------------------
# Deshabilitar ping
#net.ipv4.icmp_echo_ignore_all = 1
###
# Paquetes entre interfaces (desactivar si el equipo no actúa como router)
#net.ipv4.ip_forward = 0
###
# Habilitar reverse path filtering
#net.ipv4.conf.all.rp_filter = 1
#net.ipv4.conf.default.rp_filter = 1
###
#Deshabilitar vulnerabilidad de marca de tiempo en TCP
#net.ipv4.tcp_timestamps = 0
###
#Bloqueo de ipv6
#net.ipv6.conf.all.disable_ipv6 = 1
#net.ipv6.conf.default.disable_ipv6 = 1
###
# Modificar el tamaño de las colas de espera de TCP
###
#net.ipv4.tcp_max_syn_backlog = 1280
EOF
echo  " >>>>>>>>EL PROCESO A FINALIZADO<<<<<<<< "

%end
