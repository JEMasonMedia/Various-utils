# Various-utils

A collection of useful utility scripts for setting up and maintaining local development environments, servers, or test VMs.

## Included Tools

---

### `install_web_stack.sh`

Installs a modern web server stack on Debian 12:

- **Nginx**
- **MariaDB**
- **PHP 8.3** via the Sury repository
- Common PHP extensions: FPM, MySQL, mbstring, curl, zip, gd, etc.

#### Usage

\`\`\`bash
chmod +x install_web_stack.sh
sudo ./install_web_stack.sh
\`\`\`

After running, your system will be ready to host PHP-based apps using Nginx and MariaDB.

---

### `setup_smf_wdp.sh`

This script automates the installation and setup of:

- **Simple Machines Forum (SMF)** under \`/smf\`
- **WordPress** under \`/wdp\`
- Fresh MariaDB databases for each

Each time it runs, it performs a clean install — dropping any previous database or files.

#### Features

- Automatically downloads and installs SMF and WordPress
- Drops and recreates their databases and users
- Configures WordPress (\`wp-config.php\`)
- Leaves \`install.php\` for SMF so you can complete setup manually

#### Usage

\`\`\`bash
chmod +x setup_smf_wdp.sh
sudo ./setup_smf_wdp.sh
\`\`\`

Afterward, visit in your browser:

- \`http://<your-server-ip>/wdp\` — WordPress setup
- \`http://<your-server-ip>/smf/install.php\` — SMF installer

**Important:** After completing SMF installation, remove the installer for security:

\`\`\`bash
sudo rm /var/www/html/smf/install.php
\`\`\`

---

### `install_node_lts.sh`

Installs the latest **LTS** version of Node.js on Debian using the official NodeSource repository.

#### Usage

\`\`\`bash
chmod +x install_node_lts.sh
sudo ./install_node_lts.sh
\`\`\`

After installation, you will have:

- \`node\` (LTS version)
- \`npm\` (Node.js package manager)

To install a global process manager like PM2 (optional):

\`\`\`bash
npm install -g pm2
\`\`\`

---

## Coming Soon

Additional utilities will be added here to automate:

- File management
- Backup and deployment tasks
- CMS/app auto-installers
- Security and optimization helpers
