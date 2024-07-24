#!/usr/bin/env python3

import os
import subprocess
import shutil
import sys
import time
import re

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running command: {command}\n{result.stderr}")
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
        print(f"Error running command: {command}")
        sys.exit(1)

def download_iso(url, output):
    if os.path.isfile(output):
        print(f"ISO {output} already exists in original_iso. Skipping download.")
    else:
        print(f"Downloading ISO from {url}...")
        run_command_real_time(f"wget --progress=bar:force {url} -O {output}")

def extract_iso(iso_path, extract_to):
    if os.path.exists(extract_to):
        print(f"Directory {extract_to} already exists. Skipping extraction.")
    else:
        print(f"Extracting ISO {iso_path} to {extract_to}...")
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

def add_kickstart(extract_to, kickstart_path):
    print(f"Adding Kickstart file {kickstart_path} to {extract_to}...")
    dest_path = os.path.join(extract_to, "ks.cfg")
    os.chmod(extract_to, 0o777)  # Ensure the directory is writable
    for root, dirs, files in os.walk(extract_to):
        for dir in dirs:
            os.chmod(os.path.join(root, dir), 0o777)
        for file in files:
            os.chmod(os.path.join(root, file), 0o666)
    shutil.copy(kickstart_path, dest_path)

def modify_boot_config(extract_to, volume_label, os_name, os_version):
    print(f"Modifying boot configuration in {extract_to}...")
    
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
        file.write(f"    APPEND initrd=initrd.img rd.live.check=0 inst.stage2=hd:LABEL={volume_label} inst.ks=cdrom:/ks.cfg\n")

def create_iso(extract_to, output_iso, volume_label):
    print(f"Creating new ISO {output_iso} from {extract_to}...")
    run_command(f"cd {extract_to} && genisoimage -joliet-long -o {output_iso} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V '{volume_label}' .")

def implantmd5(output_iso):
    print(f"Implanting MD5 checksum...")
    run_command(f"implantisomd5 {output_iso}")

def get_volume_label(iso_path):
    command = f"isoinfo -d -i {iso_path} | grep 'Volume id'"
    output = run_command(command)
    match = re.search(r"Volume id:\s*(\S+)", output)
    return match.group(1) if match else "UNKNOWN"

def clean_temp_directory(directory):
    if os.path.exists(directory):
        shutil.rmtree(directory)

def main():
    # Directories for original and custom ISOs
    original_iso_dir = os.path.join(os.getcwd(), "original_iso")
    custom_iso_dir = os.path.join(os.getcwd(), "custom_iso")
    
    # Ensure directories exist
    os.makedirs(original_iso_dir, exist_ok=True)
    os.makedirs(custom_iso_dir, exist_ok=True)

    fedora_versions = {
        "28": "https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/28/Server/x86_64/iso/Fedora-Server-dvd-x86_64-28-1.1.iso",
        "34": "https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/34/Server/x86_64/iso/Fedora-Server-dvd-x86_64-34-1.2.iso"
 
    }

    print("Select distribution:")
    print("1. Fedora")
    print("2. Red Hat Enterprise Linux (RHEL)")
    choice = input("Enter your choice (1 or 2): ").strip()
    
    kickstart_path = "kickstarts/test.ks"
    # kickstart_path = input("Enter the path to your Kickstart file: ").strip()
    # if not os.path.isfile(kickstart_path):
    #     print("Kickstart file not found")
    #     return

    if choice == "1":
        print("Select Fedora version:")
        print("1. Fedora 28")
        print("2. Fedora 34")
        version_choice = input("Enter your choice (1 or 2): ").strip()
        
        if version_choice == "1":
            iso_url = fedora_versions["28"]
            fedora_version = "28"
        elif version_choice == "2":
            iso_url = fedora_versions["34"]
            fedora_version = "34"
        else:
            print("Invalid choice")
            return

        downloaded_iso = os.path.join(original_iso_dir, f"Fedora-Server-dvd-x86_64-{fedora_version}.iso")
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        output_iso = os.path.join(custom_iso_dir, f"Fedora-Server-dvd-x86_64-{fedora_version}-FedoraGuard-{timestamp}.iso")
        extract_to = os.path.join(custom_iso_dir, f"extracted_iso_{os.path.basename(downloaded_iso).split('.')[0]}")
        volume_label = "FedoraGuard"

        download_iso(iso_url, downloaded_iso)
        extract_iso(downloaded_iso, extract_to)
        add_kickstart(extract_to, kickstart_path)
        modify_boot_config(extract_to, volume_label, "Fedora", fedora_version)
        create_iso(extract_to, output_iso, volume_label)
        implantmd5(output_iso)

        print(f"Custom ISO created successfully: {output_iso}")

    elif choice == "2":
        iso_path = input("Enter the path to your RHEL ISO: ").strip()
        if not os.path.isfile(iso_path):
            print("RHEL ISO file not found")
            return
        
        downloaded_iso = iso_path
        rhel_version_match = re.search(r"rhel-(\d+\.\d+)-x86_64-dvd\.iso", os.path.basename(downloaded_iso))
        rhel_version = rhel_version_match.group(1) if rhel_version_match else "unknown"
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        output_iso = os.path.join(custom_iso_dir, f"RHEL-{rhel_version}-FedoraGuard-{timestamp}.iso")
        extract_to = os.path.join(custom_iso_dir, f"extracted_iso_{os.path.basename(downloaded_iso).split('.')[0]}")
        volume_label = "FedoraGuard"

        extract_iso(downloaded_iso, extract_to)
        add_kickstart(extract_to, kickstart_path)
        modify_boot_config(extract_to, volume_label, "Red Hat", rhel_version)
        create_iso(extract_to, output_iso, volume_label)
        implantmd5(output_iso)

        print(f"Custom ISO created successfully: {output_iso}")

    else:
        print("Invalid choice")
        return

if __name__ == "__main__":
    main()