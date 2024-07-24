#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512

# Clear the Master Boot Record
zerombr

cdrom

# Use graphical install
graphical
firstboot --disable

# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_US.UTF-8

# Root password
rootpw --plaintext password

user --name=tbd --password=tbd --gecos="tbd"

# System timezone
timezone America/New_York --isUtc

%packages
@standard
%end

%post
echo "Post installation script" >> /hola.txt
%end
