cdrom

# Clear the Master Boot Record
zerombr

# Use graphical install
text
firstboot --disable

# Keyboard layouts
keyboard --vckeymap=es --xlayouts='es'

# System language
lang en_US.UTF-8

# Root password
rootpw --plaintext tbd

user --name=tbd --password=tbd --gecos="tbd"

# System timezone
timezone UTC

%packages
@standard
%end

network --bootproto=dhcp

%include /run/install/repo/kickstarts/copyRHELrepos.ks
%include /run/install/repo/kickstarts/installGraphicalEnv.ks
