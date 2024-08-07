import os

folder_path = "../GenerateISO/kickstarts/ccn-stic"
output_file = "./script.sh"

# Obtener una lista de todos los archivos en la carpeta con extensión .ks
files = [file for file in os.listdir(folder_path) if file.endswith(".ks")]

# Abrir el archivo de salida en modo de escritura
with open(output_file, "w") as output:
    # Iterar sobre cada archivo
    for file in files:
        file_path = os.path.join(folder_path, file)
        # Abrir cada archivo en modo de lectura
        with open(file_path, "r") as input_file:
            # Leer el contenido del archivo
            contents = input_file.readlines()
            # Eliminar las secciones que comienzan con %post y terminan con %end
            modified_contents = []
            for line in contents:
                if "%post" not in line and "%end" not in line:
                    modified_contents.append(line)
            # Eliminar las líneas que contienen #!/bin/bash
            modified_contents = [line for line in modified_contents if "#!/bin/bash" not in line]
            # Escribir el contenido modificado en el archivo de salida
            output.write(f"# Archivo: {file}\n")
            output.writelines(modified_contents)
