%post --log=/root/logs/12-USB_limitation.ks
#!/bin/bash

dnf install -y usbguard

#evitando usb 
echo "----------------------------------------------------------------"
echo "-- SE DENEGARÁ EL ACCESO A LOS DISPOSITIVOS DE ALMACENAMIENTO --"
echo "----------------------------------------------------------------"
echo -e "\n"


cat > /etc/usbguard/usbguard-daemon.conf << EOF
####REGLAS GUIA#####
# Ruta de reglas
RuleFile=/etc/usbguard/rules.conf

# Regla por defecto
#
ImplicitPolicyTarget=block

#
# Política de de dispositivos activa.
#
# Cómo tratar los dispositivos que ya están conectados cuando
# demonio se inicia:
# #
# * allow - autoriza cada dispositivo presente en el sistema
# * block: desautoriza todos los dispositivos presentes en el sistema
# * reject: elimina todos los dispositivos presentes en el sistema
# * keep - solo sincroniza el estado interno y mantiene el dispositivo
# * apply-policy - evalúa el conjunto de reglas para cada dispositivo
#
PresentDevicePolicy=apply-policy
PresentControllerPolicy=apply-policy

# Política de de dispositivos insertados
#
# Cómo tratar los dispositivos USB que ya están conectados
# con el demonio activo:
#
# * block: desautoriza todos los dispositivos presentes en el sistema
# * reject: elimina todos los dispositivos presentes en el sistema
# * apply-policy - evalúa el conjunto de reglas para cada dispositivo
#
InsertedDevicePolicy=apply-policy

###
RestoreControllerDeviceState=false
###
DeviceManagerBackend=uevent

#Usuarios permitidos para interfaz IPC
IPCAllowedUsers=root aCdCmN610
IPCAllowedGroups=wheel

###
IPCAccessControlFiles=/etc/usbguard/IPCAccessControl.d/

###Generación de reglas por puerto USB
DeviceRulesWithPort=false
###
AuditBackend=FileAudit
AuditFilePath=/var/log/usbguard/usbguard-audit.log
EOF
systemctl enable usbguard.service
systemctl restart usbguard.service
systemctl status usbguard.service
echo ">>>>El SCRIPT ha finalizado<<<<"

%end