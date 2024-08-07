#!/usr/bin/env python3

import configparser
#import crypt
import shacrypt512
import os
import subprocess
import shutil
import sys
import time
import re
import argparse

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"### Error running command: {command}\n{result.stderr}")
        sys.exit(1)
    return result.stdout

def run_command_real_time(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    while True:
        output = process.stdout.read(1)
        if output == b'' and process.poll() is not None:
            break
        if output:
            sys.stdout.write(output.decode())
            sys.stdout.flush()
    rc = process.poll()
    if rc != 0:
        print(f"### Error running command: {command}")
        sys.exit(1)

def download_iso(url, output):
    if os.path.isfile(output):
        print(f"--- ISO {output} already exists in original_iso. Skipping download.")
    else:
        print(f"--- Downloading ISO from {url}...")
        run_command_real_time(f"wget --progress=bar:force {url} -O {output}")

def extract_iso(iso_path, extract_to):
    if os.path.exists(extract_to):
        print(f"--- Directory {extract_to} already exists. Skipping extraction.")
        os.chmod(extract_to, 0o777)  # Ensure the directory is writable
    else:
        print(f"--- Extracting ISO {iso_path} to {extract_to}...")
        os.makedirs(extract_to, exist_ok=True)
        os.chmod(extract_to, 0o777)  # Ensure the directory is writable
        mount_point = os.path.join(os.getcwd(), "mnt/fuse_iso_mount")
        os.makedirs(mount_point, exist_ok=True)
        os.chmod(mount_point, 0o777)  # Ensure the directory is writable
        run_command(f"fusermount -u {mount_point} || true")  # Ensure any previous mount is unmounted
        run_command(f"fuseiso {iso_path} {mount_point}")
        run_command(f"rsync -av {mount_point}/ {extract_to}/")
        run_command(f"fusermount -u {mount_point}")
        shutil.rmtree(mount_point)  # Remove the mount directory after use
        # Ensure mnt directory is also removed
        parent_mount_dir = os.path.dirname(mount_point)
        if os.path.exists(parent_mount_dir):
            shutil.rmtree(parent_mount_dir)
    
    os.chmod(extract_to, 0o777)  # Ensure the directory is writable
    for root, dirs, files in os.walk(extract_to):
        for dir in dirs:
            os.chmod(os.path.join(root, dir), 0o777)
        for file in files:
            os.chmod(os.path.join(root, file), 0o666)

def validate_kickstart(kickstart_path):
    # Ensure the kickstart files are in UTF-8 encoding
    print(f"--- Validating kickstart files...")
    for root, dirs, files in os.walk(kickstart_path):
        for file in files:
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)

            # Validate each kickstart file using ksvalidator
            try:
                run_command(f"ksvalidator {file_path}")
                #print(f"Kickstart file {file_path} is valid.")
            except subprocess.CalledProcessError as e:
                print(f"### Kickstart validation failed for {file_path}: {e.output}")
                sys.exit(1)

def add_kickstart_folder(extract_to, kickstart_folder):
    # Validate the kickstart files before adding them
    validate_kickstart(kickstart_folder)

    print(f"--- Adding Kickstart folder {kickstart_folder} to {extract_to}...")
    dest_path = os.path.join(extract_to, "kickstarts")
    if os.path.exists(dest_path):
        shutil.rmtree(dest_path)  # Remove any existing kickstarts folder

    shutil.copytree(kickstart_folder, dest_path)

def modify_boot_config(extract_to, volume_label, os_name, os_version):
    print(f"--- Modifying boot configuration in {extract_to}...")
    
    # Define paths for the original and copy of isolinux.cfg
    config_path = os.path.join(extract_to, "isolinux", "isolinux.cfg")
    copy_config_path = os.path.join(extract_to, "isolinux", "isolinux.cfg.copy")

    if not os.path.exists(copy_config_path):
        # Create a copy of the original configuration file
        shutil.copy(config_path, copy_config_path)
    else:
        shutil.copy(copy_config_path, config_path)

    # Append new configuration to the copy
    with open(config_path, "a") as file:
        file.write(f"DEFAULT install\n")
        file.write(f"LABEL install\n")
        file.write(f"    MENU LABEL INSTALL FedoraGuard {os_name} {os_version}\n")
        file.write(f"    KERNEL vmlinuz\n")
        file.write(f"    APPEND initrd=initrd.img rd.live.check=0 inst.stage2=hd:LABEL={volume_label} inst.ks=cdrom:/kickstarts/main.ks\n")

def create_iso(extract_to, output_iso, volume_label):
    print(f"--- Creating new ISO {output_iso} from {extract_to}...")
    run_command(f"cd {extract_to} && genisoimage -joliet-long -o {output_iso} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V '{volume_label}' .")

def implantmd5(output_iso):
    print(f"--- Implanting MD5 checksum...")
    run_command(f"implantisomd5 {output_iso}")

def get_volume_label(iso_path):
    command = f"isoinfo -d -i {iso_path} | grep 'Volume id'"
    output = run_command(command)
    match = re.search(r"Volume id:\s*(\S+)", output)
    return match.group(1) if match else "UNKNOWN"

def parse_arguments():
    parser = argparse.ArgumentParser(description="Generate custom ISO")
    parser.add_argument("distribution", choices=["fedora", "rhel"], help="Select distribution: fedora or rhel")
    parser.add_argument("--version", choices=["28", "34"], help="Specify Fedora version: 28 or 34")
    parser.add_argument("--iso", help="Specify the path to the RHEL ISO file")
    return parser.parse_args()

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
    
    with open(ccnguides_path+"/01-Password_grub.ks", 'r') as file:
        content = file.readlines()

    line = "var=$(echo -e '"+root_password+"\\n"+root_password+"' | grub2-mkpasswd-pbkdf2 | awk '/grub.pbkdf/{print$NF}' | cut -d' ' -f7)\n"
    content[6]  = line
    
    with open(ccnguides_path+"/01-Password_grub.ks", 'w') as file:
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

def modifyCCNguides(ccnguides_path, ccnguides):
    print("TODO: Modify CCNguides")

def modify_kickstarts(kickstart_folder, config):
    mainks_path = os.path.join(kickstart_folder, "main.ks")
    ccnguides_path = os.path.join(kickstart_folder, "ccn-stic")

    modifyHostname(mainks_path,config["General"]["hostname"])
    modifyRootpassword(mainks_path, ccnguides_path, config["General"]["root_password"])
    modifyPackages(mainks_path,config["Packages"]["names"])
    modifyLanguage(mainks_path,config["Language"]["os_language"])
    modifyKeyboard(mainks_path,config["Language"]["keyboard"])
    modifyUsers(mainks_path,config.items("Users"))
    modifyCCNguides(ccnguides_path, config["CCNguides"])

def main():

    # Directories for original and custom ISOs
    original_iso_dir = os.path.join(os.getcwd(), "original_iso")
    custom_iso_dir = os.path.join(os.getcwd(), "custom_iso")
    
    # Ensure directories exist
    os.makedirs(original_iso_dir, exist_ok=True)
    os.makedirs(custom_iso_dir, exist_ok=True)

    # Read the configuration file
    config = configparser.ConfigParser()
    config.read("config.ini")

    # Extract Fedora versions from the configuration file
    fedora_versions = {}
    if "OperatingSystem" in config.sections():
        for key, value in config["OperatingSystem"].items():
            if key.startswith("fedora"):
                version = key.replace("fedora", "")
                fedora_versions[version] = value

    args = parse_arguments()

    if args.distribution == "fedora":
        if args.version:
            version = args.version
        else:
            print("### Please specify the Fedora version using the --version option")
            return
        iso_url = fedora_versions.get(version)
        if not iso_url:
            print(f"### Invalid Fedora version: {fedora_versions}")
            return

        downloaded_iso = os.path.join(original_iso_dir, f"Fedora-Server-dvd-x86_64-{version}.iso")
        download_iso(iso_url, downloaded_iso)

    elif args.distribution == "rhel":
        if args.iso:
            iso_path = args.iso
        else:
            print("### Please specify the path to the RHEL ISO file using the --iso option")
            return
        if not os.path.isfile(iso_path):
            print("## #RHEL ISO file not found")
            return

        downloaded_iso = iso_path
        rhel_version_match = re.search(r"rhel-(\d+\.\d+)-x86_64-dvd\.iso", os.path.basename(downloaded_iso))
        version = rhel_version_match.group(1) if rhel_version_match else "unknown"

    else:
        print("### Invalid choice")
        return

    kickstart_folder = "kickstarts"
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    output_iso = os.path.join(custom_iso_dir, f"{args.distribution}-{version}-FedoraGuard-{timestamp}.iso")
    extract_to = os.path.join(custom_iso_dir, f"extracted_iso_{os.path.basename(downloaded_iso).split('.')[0]}")
    volume_label = "FedoraGuard"

    extract_iso(downloaded_iso, extract_to)
    modify_kickstarts(kickstart_folder, config)
    add_kickstart_folder(extract_to, kickstart_folder)
    modify_boot_config(extract_to, volume_label, args.distribution, version)
    create_iso(extract_to, output_iso, volume_label)
    implantmd5(output_iso)
    
    print(f"--- Custom ISO created successfully: {output_iso}")


if __name__ == "__main__":
    main()

