import configparser

class ConfigManager:
    def __init__(self, config_file):
        self.config_file = config_file
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
    
    def save_config(self):
        """Save the current configuration to the file."""
        with open(self.config_file, 'w') as configfile:
            self.config.write(configfile)

    def modify_hostname(self, new_hostname):
        """Modify the hostname in the [General] section."""
        self.config['General']['hostname'] = new_hostname 

    def modify_root_password(self, new_root_password):
        """Modify the root password in the [General] section."""
        self.config['General']['root_password'] = new_root_password

    def modify_keyboard(self, new_keyboard):
        """Modify the keyboard setting in the [Language] section."""
        self.config['Language']['keyboard'] = new_keyboard

    def modify_os_language(self, new_os_language):
        """Modify the os_language setting in the [Language] section."""
        self.config['Language']['os_language'] = new_os_language

    def modify_grub_password(self, new_grub_password):
        """Modify the grub password in the [CCNguides] section."""
        self.config['CCNguides']['grub_password'] = new_grub_password
    
    def modify_banner(self, new_banner):
        """Modify the banner in the [CCNguides] section."""
        self.config['CCNguides']['banner'] = new_banner

    def modify_install_clamav(self, new_install_clamav):
        """Modify the install_clamav setting in the [CCNguides] section."""
        self.config['CCNguides']['install_clamav'] = new_install_clamav

    def modify_install_cockpit(self, new_install_cockpit):
        """Modify the install_cockpit setting in the [CCNguides] section."""
        self.config['CCNguides']['install_cockpit'] = new_install_cockpit

    def modify_allow_usb(self, new_allow_usb):
        """Modify the allow_usb setting in the [CCNguides] section."""
        self.config['CCNguides']['allow_usb'] = new_allow_usb

    def modify_allow_root(self, new_allow_root):
        """Modify the allow_root setting in the [CCNguides] section."""
        self.config['CCNguides']['allow_root'] = new_allow_root

    def modify_fedora28(self, new_fedora28_link):
        """Modify the fedora28 download link in the [OperatingSystem] section."""
        self.config['OperatingSystem']['fedora28'] = new_fedora28_link

    def modify_fedora34(self, new_fedora34_link):
        """Modify the fedora34 download link in the [OperatingSystem] section."""
        self.config['OperatingSystem']['fedora34'] = new_fedora34_link

    def modify_packages(self, new_packages):
        """Modify the packages in the [Packages] section."""
        self.config['Packages']['names'] = ', '.join(new_packages)

    def modify_files(self, new_files):
        """Modify the files in the [Files] section."""
        for key, value in new_files.items():
            self.config['Files'][key] = value
    
    def modify_scripts(self, new_scripts):
        """Modify the scripts in the [Scripts] section."""
        for key, value in new_scripts.items():
            self.config['Scripts'][key] = value
