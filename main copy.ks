#
# Installation source
#
cdrom

#
# Clear the Master Boot Record
#
zerombr

#
# Graphical or text installation
#
graphical
#text

#
# Keyboard
#
keyboard --vckeymap=es --xlayouts='es'

#
# Language
#
lang en_US.UTF-8

#
# Root password
#
rootpw --plaintext root

#
# Users
#
user --name=user --password=user --gecos="user"

#
# Timezone
#
timezone UTC

#
# Packages
#
%packages
@standard
%end

#
# Network
#
network --bootproto=dhcp --hostname=XXXXX

%include /run/install/repo/kickstarts/installation/graphical-progress.ks

#
# Scripts
#
%include /run/install/repo/kickstarts/installation/copyRHELrepos.ks
%include /run/install/repo/kickstarts/installation/installGraphicalEnv.ks

#
# CCN-STIC guides
#
%include /run/install/repo/kickstarts/ccn-stic/01-Password_grub.ks
%include /run/install/repo/kickstarts/ccn-stic/02-User_root_and_without_password.ks
%include /run/install/repo/kickstarts/ccn-stic/03-Parameters_kernel.ks
%include /run/install/repo/kickstarts/ccn-stic/04-Parameters_SSH.ks
%include /run/install/repo/kickstarts/ccn-stic/05-Handling_register_activity.ks
%include /run/install/repo/kickstarts/ccn-stic/06-Uninstall_no_needed_users.ks
%include /run/install/repo/kickstarts/ccn-stic/07-Failed_attempts.ks
%include /run/install/repo/kickstarts/ccn-stic/08-Limits_permissions_passExpiration.ks
%include /run/install/repo/kickstarts/ccn-stic/09-Parameters_gnome.ks
%include /run/install/repo/kickstarts/ccn-stic/10-Unnecessary_items_efi.ks
%include /run/install/repo/kickstarts/ccn-stic/11-Orphan_packages.ks
%include /run/install/repo/kickstarts/ccn-stic/12-USB_limitation.ks
%include /run/install/repo/kickstarts/ccn-stic/13-Antivirus_install.ks

#
# Copy files
#

#
# Scripts
#
