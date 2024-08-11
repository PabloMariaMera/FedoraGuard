#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import tkinter as tk
from tkinter import ttk, filedialog
import subprocess
import threading
import configparser
from tkinter import simpledialog
from modifyConfig import ConfigManager

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

        self.config = ConfigManager("config.ini")

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
        operating_systems = self.config.config["OperatingSystem"]
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
        ttk.Button(self.root, text="Ficheros", command=self.show_files_submenu).pack(pady=5)
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

        # Entry field for grub password
        ttk.Label(self.root, text="Contraseña de grub", font=("Arial", 11)).pack()
        self.grub_password_entry = ttk.Entry(self.root)
        self.grub_password_entry.pack(pady=5)
        self.grub_password_entry.insert(0, self.config.get_grub_password())

        # Entry field for banner
        ttk.Label(self.root, text="Banner", font=("Arial", 11)).pack()
        self.banner_entry = tk.Text(self.root, height=5, width=30)
        self.banner_entry.pack(pady=5)
        self.banner_entry.insert(tk.END, self.config.get_banner())

        # Checkbutton for install_clamav
        self.install_clamav_var = tk.BooleanVar()
        self.install_clamav_checkbutton = ttk.Checkbutton(self.root, text="Instalar ClamAV", variable=self.install_clamav_var)
        self.install_clamav_checkbutton.pack(pady=5)
        if self.config.get_install_clamav() == "yes":
            self.install_clamav_var.set(True)
        else:
            self.install_clamav_var.set(False)

        # Checkbutton for install_cockpit
        self.install_cockpit_var = tk.BooleanVar()
        self.install_cockpit_checkbutton = ttk.Checkbutton(self.root, text="Instalar Cockpit", variable=self.install_cockpit_var)
        self.install_cockpit_checkbutton.pack(pady=5)
        if self.config.get_install_cockpit() == "yes":
            self.install_cockpit_var.set(True)
        else:
            self.install_cockpit_var.set(False)

        # Checkbutton for allow_usb
        self.allow_usb_var = tk.BooleanVar()
        self.allow_usb_checkbutton = ttk.Checkbutton(self.root, text="Permitir USB", variable=self.allow_usb_var)
        self.allow_usb_checkbutton.pack(pady=5)
        if self.config.get_allow_usb() == "yes":
            self.allow_usb_var.set(True)
        else:
            self.allow_usb_var.set(False)

        # Checkbutton for allow_root
        self.allow_root_var = tk.BooleanVar()
        self.allow_root_checkbutton = ttk.Checkbutton(self.root, text="Permitir Root", variable=self.allow_root_var)
        self.allow_root_checkbutton.pack(pady=5)
        if self.config.get_allow_root() == "yes":
            self.allow_root_var.set(True)
        else:
            self.allow_root_var.set(False)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)
    def show_root_password_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Contraseña root", font=("Arial", 14)).pack(pady=10)

        # Entry field for root password
        self.root_password_entry = ttk.Entry(self.root)
        self.root_password_entry.pack(pady=10)
        # Set the initial value of the root password entry field to asterisks
        self.root_password_entry.insert(0, self.config.get_root_password())
        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def open_new_tab(self, event):
        self.modify_user()

    def add_newuser(self):
        # Open a dialog to enter a new element
        new_element = simpledialog.askstring("Añadir Elemento", "Introduce un nuevo elemento")

        # Add the new element to the listbox
        if new_element:
            self.users_listbox.insert(tk.END, new_element)

    def delete_user(self):
        # Get the selected element from the listbox
        try:
            selected_element = self.users_listbox.get(self.users_listbox.curselection())
        except tk.TclError:
            selected_element = None

        # Delete the selected element from the listbox
        if selected_element:
            self.users_listbox.delete(self.users_listbox.curselection())

    def modify_user(self):
        # Get the selected element from the listbox
        try:
            selected_element = self.users_listbox.get(self.users_listbox.curselection())
        except tk.TclError:
            selected_element = None

        if selected_element:
            # Open a dialog to modify the selected element
            modified_element = simpledialog.askstring("Modificar Elemento", "Introduce los nuevos valores separados por comas (password,uid,gid,description,home)", initialvalue=self.config.get_user_by_name(self.users_listbox.get(self.users_listbox.curselection())))

            # Update the selected element with the modified values
            if modified_element:
                # Save the modified values in a separate variable
                password, gid, uid, description, home = modified_element.split(",")
                # TODO: Do something with the modified values
    
    def show_users_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Usuarios", font=("Arial", 14)).pack(pady=10)

        # Listbox to display the elements
        self.users_listbox = tk.Listbox(self.root)
        self.users_listbox.pack(pady=10)
        # Add the users to the listbox
        for user in self.config.get_users():
            self.users_listbox.insert(tk.END, user)

        # Double click event handler for opening a new tab
        self.users_listbox.bind("<Double-Button-1>", self.open_new_tab)

        # Button to add a new element
        ttk.Button(self.root, text="Añadir Elemento", command=self.add_newuser).pack(pady=5)

        # Button to delete the selected element
        ttk.Button(self.root, text="Borrar Elemento", command=self.delete_user).pack(pady=5)
        # Button to modify the selected element
        ttk.Button(self.root, text="Modificar Elemento", command=self.modify_user).pack(pady=5)
        
        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def add_package(self):
        # Open a dialog to enter a new element
        new_element = simpledialog.askstring("Añadir Elemento", "Introduce un nuevo elemento")

        # Add the new element to the listbox
        if new_element:
            self.packages_listbox.insert(tk.END, new_element)

    def delete_package(self):
        # Get the selected element from the listbox
        try:
            selected_element = self.packages_listbox.get(self.packages_listbox.curselection())
        except tk.TclError:
            selected_element = None

        # Delete the selected element from the listbox
        if selected_element:
            self.packages_listbox.delete(self.packages_listbox.curselection())

    def show_packages_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Paquetes", font=("Arial", 14)).pack(pady=10)

        # Listbox to display the elements
        self.packages_listbox = tk.Listbox(self.root)
        self.packages_listbox.pack(pady=10)

        # Add the packages to the listbox
        for package in self.config.get_packages():
            self.packages_listbox.insert(tk.END, package)

        # Button to add a new element
        ttk.Button(self.root, text="Añadir Elemento", command=self.add_package).pack(pady=5)

        # Button to delete the selected element
        ttk.Button(self.root, text="Borrar Elemento", command=self.delete_package).pack(pady=5)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def add_script(self):
        # Open a dialog to enter a new element
        new_element = simpledialog.askstring("Añadir Elemento", "Introduce un nuevo elemento")

        # Add the new element to the listbox
        if new_element:
            self.scripts_listbox.insert(tk.END, new_element)

    def delete_script(self):
        # Get the selected element from the listbox
        try:
            selected_element = self.scripts_listbox.get(self.scripts_listbox.curselection())
        except tk.TclError:
            selected_element = None

        # Delete the selected element from the listbox
        if selected_element:
            self.scripts_listbox.delete(self.scripts_listbox.curselection())

    def show_scripts_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Scripts", font=("Arial", 14)).pack(pady=10)

        # Listbox to display the elements
        self.scripts_listbox = tk.Listbox(self.root)
        self.scripts_listbox.pack(pady=10)

        # Button to add a new element
        ttk.Button(self.root, text="Añadir Elemento", command=self.add_script).pack(pady=5)

        # Button to delete the selected element
        ttk.Button(self.root, text="Borrar Elemento", command=self.delete_script).pack(pady=5)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def add_file(self):
        # Open a dialog to enter a new element
        new_element = simpledialog.askstring("Añadir Elemento", "Introduce un nuevo elemento")

        # Add the new element to the listbox
        if new_element:
            self.files_listbox.insert(tk.END, new_element)

    def delete_file(self):
        # Get the selected element from the listbox
        try:
            selected_element = self.files_listbox.get(self.files_listbox.curselection())
        except tk.TclError:
            selected_element = None

        # Delete the selected element from the listbox
        if selected_element:
            self.files_listbox.delete(self.files_listbox.curselection())

    def show_files_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de ficheros", font=("Arial", 14)).pack(pady=10)

        # Listbox to display the elements
        self.files_listbox = tk.Listbox(self.root)
        self.files_listbox.pack(pady=10)

        # Button to add a new element
        ttk.Button(self.root, text="Añadir Elemento", command=self.add_file).pack(pady=5)

        # Button to delete the selected element
        ttk.Button(self.root, text="Borrar Elemento", command=self.delete_file).pack(pady=5)

        # Button to return to the configuration menu
        ttk.Button(self.root, text="Volver", command=self.configuration_menu).pack(pady=5)

        # Update window size to fit content
        self.root.update_idletasks()
        self.root.geometry("")

    def language_to_keyboard(self, language):
        # Map the language to the corresponding keyboard layout
        language_to_keyboard = {
            "Español": "es",
            "Inglés": "us",
            "Francés": "fr",
            "Alemán": "de"
        }
        return language_to_keyboard[language]

    def language_to_os_language(self, language):
        # Map the language to the corresponding OS language
        language_to_os_language = {
            "Español": "es_ES",
            "Inglés": "en_US",
            "Francés": "fr_FR",
            "Alemán": "de_DE"
        }
        return language_to_os_language[language]

    def keyboard_to_language(self, keyboard):
        # Map the keyboard layout to the corresponding language
        keyboard_to_language = {
            "es": "Español",
            "us": "Inglés",
            "fr": "Francés",
            "de": "Alemán"
        }
        return keyboard_to_language[keyboard]
    
    def os_language_to_language(self, os_language):
        # Map the OS language to the corresponding language
        os_language_to_language = {
            "es_ES": "Español",
            "en_US": "Inglés",
            "fr_FR": "Francés",
            "de_DE": "Alemán"
        }
        return os_language_to_language[os_language]

    def show_language_submenu(self):
        # Clear any existing widgets, except the logo
        self.clear_frame()

        # Display the logo
        self.logo_label.pack(pady=10)

        # Label to show the submenu name
        ttk.Label(self.root, text="Configuración de Idioma", font=("Arial", 14)).pack(pady=10)

        commonLanguages = ['Español', 'Inglés', 'Francés', 'Alemán']

        # Entry field for keyboard password
        ttk.Label(self.root, text="Teclado", font=("Arial", 11)).pack(pady=10)
        keyboard_combobox = ttk.Combobox(self.root)
        keyboard_combobox['values'] = commonLanguages
        keyboard_combobox.pack(pady=10)
        # Set the initial value of the keyboard combobox
        keyboard_combobox.current(commonLanguages.index(self.keyboard_to_language(self.config.get_keyboard())))

        # Entry field for language
        ttk.Label(self.root, text="Idioma del SO", font=("Arial", 11)).pack(pady=10)
        language_combobox = ttk.Combobox(self.root)
        language_combobox['values'] = commonLanguages
        language_combobox.pack(pady=10)
        # Set the initial value of the language combobox
        language_combobox.current(commonLanguages.index(self.os_language_to_language(self.config.get_os_language())))

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
