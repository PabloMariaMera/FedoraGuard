%post --log=/root/logs/01-Password_grub.ks
#!/bin/bash

echo "--------------------------------"
echo "--APLICANDO CONTRASEÑA DE GRUB--"
echo "--------------------------------"
var=$(echo -e 'micontrasenagrub\nmicontrasenagrub' | grub2-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}' | cut -d' ' -f7)
echo $var
echo set superusers="root">>/etc/grub.d/40_custom
echo password_pbkdf2 root $var >>/etc/grub.d/40_custom
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
chmod 600 /boot/grub2/grub.cfg
chmod 600 /boot/efi/EFI/redhat/grub.cfg
chmod 600 /boot/efi/EFI/fedora/grub.cfg

%end