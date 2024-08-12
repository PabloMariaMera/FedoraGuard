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
    
    def reload_config(self):
        """Reload the configuration from the file."""
        self.config.read(self.config_file)

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
        self.config['Packages']['names'] = ','.join(new_packages)

    def modify_files(self, new_files):
        """Modify the files in the [Files] section."""
        self.config['Files'] = {}
        for i in new_files:
            self.config['Files'][i.split('.')[0]] = i
    
    def modify_scripts(self, new_scripts):
        """Modify the scripts in the [Scripts] section."""
        self.config['Scripts'] = {}
        for i in new_scripts:
            self.config['Scripts'][i.split('.')[0]] = i

    def modify_user(self, new_user):
        """Modify the user in the [User] section."""
        self.config['Users'][new_user] = ",,,,"

    def modify_user_delete(self, user):
        """Delete the user in the [User] section."""
        del self.config['Users'][user]

    def modify_user_parameters(self, user, parameters):
        """Modify the user in the [User] section."""
        self.config['Users'][user] = parameters

    def get_hostname(self):
        """Get the hostname from the [General] section."""
        return self.config['General']['hostname']

    def get_root_password(self):
        """Get the root password from the [General] section."""
        return self.config['General']['root_password']

    def get_keyboard(self):
        """Get the keyboard setting from the [Language] section."""
        return self.config['Language']['keyboard']

    def get_os_language(self):
        """Get the os_language setting from the [Language] section."""
        return self.config['Language']['os_language']

    def get_grub_password(self):
        """Get the grub password from the [CCNguides] section."""
        return self.config['CCNguides']['grub_password']

    def get_banner(self):
        """Get the banner from the [CCNguides] section."""
        return self.config['CCNguides']['banner']

    def get_install_clamav(self):
        """Get the install_clamav setting from the [CCNguides] section."""
        return self.config['CCNguides']['install_clamav']

    def get_install_cockpit(self):
        """Get the install_cockpit setting from the [CCNguides] section."""
        return self.config['CCNguides']['install_cockpit']

    def get_allow_usb(self):
        """Get the allow_usb setting from the [CCNguides] section."""
        return self.config['CCNguides']['allow_usb']

    def get_allow_root(self):
        """Get the allow_root setting from the [CCNguides] section."""
        return self.config['CCNguides']['allow_root']

    def get_fedora28(self):
        """Get the fedora28 download link from the [OperatingSystem] section."""
        return self.config['OperatingSystem']['fedora28']

    def get_fedora34(self):
        """Get the fedora34 download link from the [OperatingSystem] section."""
        return self.config['OperatingSystem']['fedora34']

    def get_packages(self):
        """Get the packages from the [Packages] section."""
        return self.config['Packages']['names'].split(',')

    def get_files(self):
        """Get the files from the [Files] section."""
        return list(self.config['Files'].values())

    def get_scripts(self):
        """Get the scripts from the [Scripts] section."""
        return list(self.config['Scripts'].values())

    def get_users(self):
        """Get the user from the [Users] section."""
        return dict(self.config['Users'])

    def get_user_by_name(self, username):
        """Get the user by name from the [Users] section."""
        return self.config['Users'][username]
