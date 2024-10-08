#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import configparser
import os
import subprocess
import shutil
import sys
import time
import re
import argparse
from modifyKickstarts import *

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"### Error ejecutando el comando: {command}\n{result.stderr}")
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
        print(f"### Error ejecutando el comando: {command}")
        sys.exit(1)

def download_iso(url, output):
    if os.path.isfile(output):
        print(f"--- ISO {output} ya existe en original_iso. Omitiendo descarga.")
    else:
        print(f"--- Descargando ISO desde {url}...")
        run_command_real_time(f"wget --progress=bar:force {url} -O {output}")

def extract_iso(iso_path, extract_to):
    if os.path.exists(extract_to):
        print(f"--- El directorio {extract_to} ya existe. Omitiendo extracción.")
        os.chmod(extract_to, 0o777)  # Ensure the directory is writable
    else:
        print(f"--- Extrayendo ISO {iso_path} a {extract_to}...")
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
    print(f"--- Validando ficheros kickstart...")
    for root, dirs, files in os.walk(kickstart_path):
        for file in files:
            if file != ".gitkeep":  # Exclude .gitkeep file
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
                    print(f"### La validación de kickstarts falló para {file_path}: {e.output}")
                    sys.exit(1)

def add_kickstart_folder(extract_to, kickstart_folder):
    # Validate the kickstart files before adding them
    validate_kickstart(kickstart_folder)

    print(f"--- Añadiendo carpeta de kickstarts {kickstart_folder} a {extract_to}...")
    dest_path = os.path.join(extract_to, "kickstarts")
    if os.path.exists(dest_path):
        shutil.rmtree(dest_path)  # Remove any existing kickstarts folder

    shutil.copytree(kickstart_folder, dest_path)

def modify_boot_config(extract_to, volume_label, os_name, os_version):
    print(f"--- Modificando configuración de arranque en {extract_to}...")
    
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
    print(f"--- Creando nueva ISO {output_iso} de {extract_to}...")
    run_command(f"cd {extract_to} && genisoimage -joliet-long -o {output_iso} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V '{volume_label}' .")

def implantmd5(output_iso):
    print(f"--- Implantando suma de verificación MD5...")
    run_command(f"implantisomd5 {output_iso}")

def get_volume_label(iso_path):
    command = f"isoinfo -d -i {iso_path} | grep 'Volume id'"
    output = run_command(command)
    match = re.search(r"Volume id:\s*(\S+)", output)
    return match.group(1) if match else "UNKNOWN"

def parse_arguments():
    parser = argparse.ArgumentParser(description="Generar ISO personalizada")
    parser.add_argument("distribucion", choices=["fedora", "rhel"], help="Elige distribución: fedora or rhel")
    parser.add_argument("--version", choices=["28", "34"], help="Versión de Fedora: 28 or 34")
    parser.add_argument("--iso", help="Especificar la ruta a ISO de RHEL")
    return parser.parse_args()

def script_and_files_to_kickstart(kickstart_folder, scripts_folder, files_folder, config):
    print(f"--- Pasando scripts y ficheros a kickstarts...")
    dest_scripts_path = os.path.join(kickstart_folder, "custom_scripts")
    dest_files_path = os.path.join(kickstart_folder, "custom_files")

    if os.path.exists(dest_scripts_path):
        for root, dirs, files in os.walk(dest_scripts_path):
            for file in files:
                if file != ".gitkeep":  # Exclude .gitkeep file
                    os.remove(os.path.join(root, file))  # Remove files inside scripts folder
    if os.path.exists(dest_files_path):
        for root, dirs, files in os.walk(dest_files_path):
            for file in files:
                if file != ".gitkeep":  # Exclude .gitkeep file
                    os.remove(os.path.join(root, file))  # Remove files inside files folder

    modifyScripts(scripts_folder, dest_scripts_path, config)
    modifyFiles(files_folder, dest_files_path, config)

def add_files_folder(extract_to, files_folder):
    print(f"--- Añadiendo la carpeta {files_folder} a {extract_to}...")
    dest_path = os.path.join(extract_to, "files")
    if os.path.exists(dest_path):
        shutil.rmtree(dest_path)  # Remove any existing files folder

    shutil.copytree(files_folder, dest_path)

def main():

    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Directories for original and custom ISOs
    original_iso_dir = os.path.join(os.getcwd(), "original_iso")
    custom_iso_dir = os.path.join(os.getcwd(), "custom_iso")
    
    # Ensure directories exist
    os.makedirs(original_iso_dir, exist_ok=True)
    os.makedirs(custom_iso_dir, exist_ok=True)

    # Read the configuration file
    config = configparser.ConfigParser()
    config.read("../Common/config.ini")

    # Extract Fedora versions from the configuration file
    fedora_versions = {}
    if "OperatingSystem" in config.sections():
        for key, value in config["OperatingSystem"].items():
            if key.startswith("fedora"):
                version = key.replace("fedora", "")
                fedora_versions[version] = value

    args = parse_arguments()

    if args.distribucion == "fedora":
        if args.version:
            version = args.version
        else:
            print("### Por favor, especifica la versión de Fedora usando la opción --version")
            return
        iso_url = fedora_versions.get(version)
        if not iso_url:
            print(f"### Versión de Fedora inválida: {fedora_versions}")
            return

        downloaded_iso = os.path.join(original_iso_dir, f"Fedora-Server-dvd-x86_64-{version}.iso")
        download_iso(iso_url, downloaded_iso)

    elif args.distribucion == "rhel":
        if args.iso:
            iso_path = args.iso
        else:
            print("### Por favor, especifica la ruta de la ISO de RHEL ISO usando la opción --iso")
            return
        if not os.path.isfile(iso_path):
            print("## ISO de RHEL no encontrada")
            return

        downloaded_iso = iso_path
        rhel_version_match = re.search(r"rhel-(\d+\.\d+)-x86_64-dvd\.iso", os.path.basename(downloaded_iso))
        version = rhel_version_match.group(1) if rhel_version_match else "unknown"

    else:
        print("### Opción inválida.")
        return

    kickstart_folder = "kickstarts"
    files_folder = "add_files"
    scripts_folder = "add_scripts"
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    output_iso = os.path.join(custom_iso_dir, f"{args.distribucion}-{version}-FedoraGuard-{timestamp}.iso")
    extract_to = os.path.join(custom_iso_dir, f"extracted_iso_{os.path.basename(downloaded_iso).split('.')[0]}")
    volume_label = "FedoraGuard"

    extract_iso(downloaded_iso, extract_to)
    modify_kickstarts(kickstart_folder, config)
    script_and_files_to_kickstart(kickstart_folder, scripts_folder, files_folder, config)
    add_kickstart_folder(extract_to, kickstart_folder)
    add_files_folder(extract_to, files_folder)
    modify_boot_config(extract_to, volume_label, args.distribucion, version)
    create_iso(extract_to, output_iso, volume_label)
    implantmd5(output_iso)
    
    print(f"--- ISO personalizada creada: {output_iso}")

if __name__ == "__main__":
    main()

