#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
#import crypt
import shacrypt512

def modifyHostname(mainks_path, hostname):
    with open(mainks_path, 'r') as file:
        content = file.read()

    if not hostname:
        hostname = "FedoraGuard"

    content = re.sub(r"network --bootproto=dhcp --hostname=\S+", f"network --bootproto=dhcp --hostname={hostname}", content)
    
    with open(mainks_path, 'w') as file:
        file.write(content)

def modifyRootpassword(mainks_path, ccnguides_path, root_password):
    with open(mainks_path, 'r') as file:
        content = file.read()
    
    if not root_password:
        root_password = "FedoraGuard"

    #crypt_password = crypt.crypt(root_password)
    crypt_password = shacrypt512.shacrypt(root_password.encode('utf-8'))
    content = re.sub(r"rootpw --iscrypted \S+", f"rootpw --iscrypted {crypt_password}", content)
    
    with open(mainks_path, 'w') as file:
        file.write(content)
    
    root_password_ks = ccnguides_path+"/02-User_root_and_without_password.ks"
    
    with open(root_password_ks, 'r') as file:
        content = file.readlines()

    line = 'echo "'+root_password+'" | passwd --stdin root;\n'
    content[12] = line
    
    with open(root_password_ks, 'w') as file:
        file.writelines(content)
    
def modifyPackages(mainks_path, packages):
    with open(mainks_path, 'r') as file:
        content = file.read()

    if packages:
        packages = packages.split(",")
        aditional_packages = ""
        for i in packages:
            aditional_packages = aditional_packages+f"{i}\n"
        content = re.sub(r"%packages\s+.*?%end", f"%packages\n@standard\n{aditional_packages}%end", content, flags=re.DOTALL)

    else:
        content = re.sub(r"%packages\s+.*?%end", f"%packages\n@standard\n%end", content, flags=re.DOTALL)

    with open(mainks_path, 'w') as file:
        file.write(content)

def modifyLanguage(mainks_path, os_language):
    if os_language:
        with open(mainks_path, 'r') as file:
            content = file.read()
        
        content = re.sub(r"lang \S+", f"lang {os_language}", content)
        
        with open(mainks_path, 'w') as file:
            file.write(content)

def modifyKeyboard(mainks_path, keyboard):
    if keyboard:
        with open(mainks_path, 'r') as file:
            content = file.read()

        content = re.sub(r"keyboard --vckeymap=\S+ --xlayouts='\S+'", f"keyboard --vckeymap={keyboard} --xlayouts='{keyboard}'", content)

        with open(mainks_path, 'w') as file:
            file.write(content)

def modifyUsers(mainks_path, users):

        with open(mainks_path, 'r') as file:
            content = file.readlines()
        
        content = [line for line in content if not line.strip().startswith("user --name")]

        if users:
            newlines = []
            for user in users:
                userksline = "user "
                userksline = userksline + "--name=" + user[0] + " "
                options = user[1].split(",")
                if options[0] != "":
                    userksline = userksline + "--password=" + shacrypt512.shacrypt(options[0].encode('utf-8')) + " --iscrypted "
                if options[1] != "":
                    userksline = userksline + "--uid=" + options[1] + " "
                if options[2] != "":
                    userksline = userksline + "--gid=" + options[2] + " "
                if options[3] != "":
                    userksline = userksline + "--gecos=" + options[3] + " "
                if options[4] != "":
                    userksline = userksline + "--homedir=" + options[4] + " "

                newlines.append(userksline)
            
            for i in newlines:
                userksline = i + "\n"

            # Buscar la posición de "# Users\n" en el contenido
            posicion_users = None
            for i, linea in enumerate(content):
                if linea.strip() == '# Users':
                    posicion_users = i + 2  # Insertar después de esta línea
                    break
            
            if posicion_users is not None:
                # Insertar la cadena en la posición encontrada
                for i in newlines:
                    content.insert(posicion_users, i + '\n')
                
        with open(mainks_path, 'w') as file:
            file.writelines(content)

def modifyGrubPassword(ccnguides_path, grub_password):
    grub_password_ks = ccnguides_path+"/01-Password_grub.ks"
    with open(grub_password_ks, 'r') as file:
        content = file.readlines()

    if not grub_password:
        grub_password = "FedoraGuard"

    line = "var=$(echo -e '"+grub_password+"\\n"+grub_password+"' | grub2-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}' | cut -d' ' -f7)\n"
    content[7]  = line
    
    with open(grub_password_ks, 'w') as file:
        file.writelines(content)

def modifyBanner(ccnguides_path, banner):
    banner_ks = ccnguides_path+"/09-Parameters_gnome.ks"
    with open(banner_ks, 'r') as file:
        content = file.readlines()

    if not banner:
        banner = "This is a private system. Unauthorized access is prohibited."

    for i, line in enumerate(content):
        if line.strip().startswith("BANN="):
            content[i] = 'BANN="'+banner+'"\n'
    
    with open(banner_ks, 'w') as file:
        file.writelines(content)

def modifyClamAV(mainks_path, install_clamav):
    with open(mainks_path, 'r') as file:
        content = file.readlines()

    for i, line in enumerate(content):
        if "13-Antivirus_install.ks" in line:
            if install_clamav == "no":
                content[i] = "#" + line.lstrip("#")
            else:
                content[i] = line.lstrip("#")
            break
    
    with open(mainks_path, 'w') as file:
        file.writelines(content)
    
def modifyCockpit(mainks_path, install_cockpit):
    with open(mainks_path, 'r') as file:
        content = file.readlines()

    for i, line in enumerate(content):
        if "14-Configure_cockpit.ks" in line:
            if install_cockpit == "no":
                content[i] = "#" + line.lstrip("#")
            else:
                content[i] = line.lstrip("#")
            break
    
    with open(mainks_path, 'w') as file:
        file.writelines(content)

def modifyAllowUSB(mainks_path, allow_usb):
    with open(mainks_path, 'r') as file:
        content = file.readlines()

    for i, line in enumerate(content):
        if "12-USB_limitation.ks" in line:
            if allow_usb == "yes":
                content[i] = "#" + line.lstrip("#")
            else:
                content[i] = line.lstrip("#")
            break
    
    with open(mainks_path, 'w') as file:
        file.writelines(content)

def modifyAllowRoot(ccnguides_path, allow_root):
    allow_root_ks = ccnguides_path+"/06-Uninstall_no_needed_users.ks"
    with open(allow_root_ks, 'r') as file:
        content = file.readlines()

    for i, line in enumerate(content):
        if "usermod -s /bin/false root" in line:
            if allow_root == "yes":
                content[i] = "#" + line.lstrip("#")
            else:
                content[i] = line.lstrip("#")
            break
    
    with open(allow_root_ks, 'w') as file:
        file.writelines(content)

def modifyCCNguides(mainks_path, ccnguides_path, ccnguides):
    modifyGrubPassword(ccnguides_path, ccnguides["grub_password"])
    modifyBanner(ccnguides_path, ccnguides["banner"])
    modifyClamAV(mainks_path, ccnguides["install_clamav"])
    modifyCockpit(mainks_path, ccnguides["install_cockpit"])
    modifyAllowUSB(mainks_path, ccnguides["allow_usb"])
    modifyAllowRoot(ccnguides_path, ccnguides["allow_root"])

def modifyScripts(scripts_folder, dest_scripts_path, config):
    if config["Scripts"]:
        path_list = []
        for name, path in config["Scripts"].items():
            if path in os.listdir(scripts_folder):
                createScriptsKickstart(name, path, scripts_folder, dest_scripts_path)
                path_list.append(name+".ks")
            else:
                print(f"Script {path} not found in {scripts_folder}")
                exit(1)
        addToCustomScriptsKs(path_list, dest_scripts_path)
    else:
        with open(os.path.join(dest_scripts_path, "custom_scripts.ks"), 'w') as file:
            file.write("%post\necho 'No custom scripts added.'\n%end\n")

def modifyFiles(files_folder, dest_files_path, config):
    if config["Files"]:
        path_list = []
        for name, path in config["Files"].items():
            if path in os.listdir(files_folder):
                createFilesKickstart(name, path, dest_files_path)
                path_list.append(name+".ks")
            else:
                print(f"File {path} not found in {files_folder}")
                exit(1)
        addToCustomFilesKs(path_list, dest_files_path)
    else:
        with open(os.path.join(dest_files_path, "custom_files.ks"), 'w') as file:
            file.write("%post\necho 'No custom files added.'\n%end\n")
    exit()
def createScriptsKickstart(name, path, scripts_folder, dest_scripts_path):
    with open(os.path.join(scripts_folder, path), 'r') as file:
        script_content = file.read()
    with open(os.path.join(dest_scripts_path, name+".ks"), 'w') as file:
        file.write('%post\n'+script_content+'\n%end\n')
    
def createFilesKickstart(name, path, dest_files_path):
    with open(os.path.join(dest_files_path, name+".ks"), 'w') as file:
        file.write('%post --nochroot\ncp /run/install/repo/files/'+path+' /mnt/sysimage/files/\n%end\n')

def addToCustomScriptsKs(path_list, dest_scripts_path):
    with open(os.path.join(dest_scripts_path, "custom_scripts.ks"), 'w') as file:
        for path in path_list:
            file.write("%include /run/install/repo/kickstarts/custom_scripts/"+path+"\n")

def addToCustomFilesKs(path_list, dest_files_path):
    with open(os.path.join(dest_files_path, "custom_files.ks"), 'w') as file:
        for path in path_list:
            file.write("%include /run/install/repo/kickstarts/custom_files/"+path+"\n")
