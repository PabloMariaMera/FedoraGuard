#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, filedialog
from PIL import Image, ImageTk
import subprocess
import threading
import configparser

class App:
    def __init__(self, root):
        self.root = root
        self.root.title("FedoraGuard")

        # Load the logo once
        self.logo = tk.PhotoImage(file="./logo/logo256.png")  # Cambia esta ruta a tu logo
        
        # Load the icon
        self.icon = tk.PhotoImage(file="./logo/logo256.png")  # Cambia esta ruta a tu icono

        # Set the window icon
        self.root.iconphoto(True, self.icon)

        # Create the logo label once
        self.logo_label = tk.Label(root, image=self.logo)

        # Create a style for ttk widgets
        self.style = ttk.Style()
        self.style.configure("TButton", font=("Arial", 12), padding=5)
        self.style.configure("TLabel", font=("Arial", 12))
        self.style.configure("TCombobox", font=("Arial", 12))

        # Set padding for all sides
        self.root.configure(padx=50, pady=40)

        self.config = configparser.ConfigParser()
        self.config.read("config.ini")

        # Create main menu buttons
        self.main_menu()

    def main_menu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Create buttons for the main menu
        ttk.Button(self.root, text="Generar Imagen", command=self.generate_image_menu).pack(pady=5)
        ttk.Button(self.root, text="Configuración", command=self.configuration_menu).pack(pady=5)
        ttk.Button(self.root, text="Salir", command=self.root.quit).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def generate_image_menu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Create a frame to hold the OS selector and attach file button side by side
        self.options_frame = tk.Frame(self.root)
        self.options_frame.pack(pady=10, fill=tk.X)  # Fill the width of the window

        # Dropdown for OS selection
        operating_systems = self.config["OperatingSystem"]
        os_list = list(operating_systems.keys())
        formatted_os_list = [f"Fedora {os.split('fedora')[1]}" for os in os_list]
        self.os_selector = ttk.Combobox(self.options_frame, values=formatted_os_list)
        self.os_selector.set("Selecciona Fedora")
        self.os_selector.pack(side=tk.LEFT, padx=(10, 5))  # Space between the dropdown and the separator
        
        # Bind the selection event to update the file label
        self.os_selector.bind("<<ComboboxSelected>>", self.update_file_label)

        # Vertical separator
        self.separator = tk.Label(self.options_frame, text="|", font=("Arial", 14))
        self.separator.pack(side=tk.LEFT, padx=5)

        # Button to attach a file
        self.attach_file_button = ttk.Button(self.options_frame, text="Adjuntar Fichero", command=self.attach_file)
        self.attach_file_button.pack(side=tk.LEFT, padx=(5, 10))  # Space between the separator and the button

        # Label to show the selected file
        self.selected_file_label = ttk.Label(self.root, text="Ningún fichero seleccionado")
        self.selected_file_label.pack(pady=(5, 10))  # Space below the label

        # Button to generate image
        ttk.Button(self.root, text="Generar Imagen", command=lambda: self.generate_image(self.selected_file_label.cget("text"))).pack(pady=5)

        # Button to return to the main menu
        ttk.Button(self.root, text="Volver", command=self.main_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def update_file_label(self, event):
        # Update the selected file label with the current option from the combobox
        selected_os = self.os_selector.get()
        self.selected_file_label.config(text=f"Sistema Operativo seleccionado: {selected_os}")


    def attach_file(self):
        # Open a file dialog to select a file
        filename = filedialog.askopenfilename(title="Seleccionar fichero")
        self.selected_file_label.config(text=filename if filename else "Ningún fichero seleccionado")

    def generate_image(self, selected_file):
        # Create and open a new window to display the output
        output_window = tk.Toplevel(self.root)
        output_window.title("Salida de Generación de Imagen")
        output_window.geometry("600x400")
        
        # Add a Text widget to show the output
        self.output_text = tk.Text(output_window, wrap=tk.WORD, state=tk.NORMAL)
        self.output_text.pack(expand=True, fill=tk.BOTH)
        
        # Start the script execution in a separate thread
        threading.Thread(target=self.run_script, args=(output_window,selected_file)).start()

    def run_script(self, window, selected_file):
        # Run the external script and capture output
        if "Fedora" in selected_file:
                option1 = "fedora"
                option2 = "--version"
                if "28" in selected_file:
                    option3 = "28"
                elif "34" in selected_file:
                    option3 = "34"
        else:
            option1 = "rhel"
            option2 = "--iso"
            option3 = selected_file
        process = subprocess.Popen(["python3", "-u", "./generateISO.py", option1, option2, option3], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Read the output and update the Text widget in the new window
        for line in iter(process.stdout.readline, ''):
            self.output_text.insert(tk.END, line)
            self.output_text.yview(tk.END)
        
        # Wait for the process to complete and capture stderr
        stdout_output, stderr_output = process.communicate()
        
        # Append any error messages
        if stderr_output:
            self.output_text.insert(tk.END, stderr_output)
            self.output_text.yview(tk.END)
        
        self.output_text.insert(tk.END, "\n\n--- Proceso completado, puede cerrar esta ventana. ---")
        self.output_text.yview(tk.END)

        # Close the new window once the script is done
        #window.after(1000, window.destroy)

    def configuration_menu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Create buttons for each configuration submenu
        ttk.Button(self.root, text="Bastionado", command=self.show_bastionado_submenu).pack(pady=5)
        ttk.Button(self.root, text="Contraseña root", command=self.show_root_password_submenu).pack(pady=5)
        ttk.Button(self.root, text="Usuarios", command=self.show_users_submenu).pack(pady=5)
        ttk.Button(self.root, text="Paquetes", command=self.show_packages_submenu).pack(pady=5)
        ttk.Button(self.root, text="Scripts", command=self.show_scripts_submenu).pack(pady=5)
        ttk.Button(self.root, text="Idioma", command=self.show_language_submenu).pack(pady=5)

        # Button to apply the configuration
        ttk.Button(self.root, text="Aplicar Configuración", command=self.apply_configuration).pack(pady=5)

        # Button to return to the main menu
        ttk.Button(self.root, text="Volver", command=self.main_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_bastionado_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Bastionado", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Bastionado.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_root_password_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Contraseña root", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Contraseña root.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_users_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Usuarios", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Usuarios.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_packages_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Paquetes", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Paquetes.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_scripts_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Scripts", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Scripts.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def show_language_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Idioma", font=("Arial", 14)).pack(pady=10)

        # Placeholder content for the submenu
        ttk.Label(self.root, text="Aquí va la configuración de Idioma.").pack(pady=10)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def apply_configuration(self):
        # Placeholder function for applying configuration
        print("Aplicando configuración")

    def clear_frame(self):
        # Destroy all widgets in the root window except the logo
        for widget in self.root.winfo_children():
            if widget != self.logo_label:
                widget.destroy()


if __name__ == "__main__":
    root = tk.Tk()
    app = App(root)
    root.mainloop()
