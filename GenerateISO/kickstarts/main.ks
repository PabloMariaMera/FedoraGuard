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
lang es_ES

#
# Root password
#
rootpw --iscrypted $6$r/QiN952i6VMQHlC$yKeFRA77RI95A0Qawr3X2YLwlUPLMB2pm/hzi6LNN3MbPAwiJncxW41ppHEzVqWbEEV3A1kqwoxbhfry/7vS80

#
# Users
#
user --name=user --password=$6$KhbAiyWzbfuVHxQS$ichNhV2HncLC9xzuuaKxoYbortw1ZeDGA4Sqf7LwnEXvb0yhIrNUVtl.Jq6wodefNnnBRaFDh8hjc0fDuYBKE. --iscrypted 

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
network --bootproto=dhcp --hostname=FedoraGuard

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
%include /run/install/repo/kickstarts/ccn-stic/14-Configure_cockpit.ks

#
# Copy files
#
%post
mkdir /files/
%end
%include /run/install/repo/kickstarts/custom_files/custom_files.ks

#
# Custom scripts
#
%include /run/install/repo/kickstarts/custom_scripts/custom_scripts.ks
