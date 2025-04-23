# Various Utilities for VPS and Development Setup

This repository contains a growing collection of shell utilities designed to streamline the setup of development and production environments—particularly when working with VPS deployments or rebuilding systems after breaking changes.

These scripts automate everything from package installation to Strapi project initialization, FTP configuration, SSH access, and more. The goal is to provide a reliable and repeatable toolset that minimizes human error and accelerates setup time.

## Table of Contents

- [check_prereqs.sh](#check_prereqssh)
- [generate_keys.sh](#generate_keyssh)
- [gUpload.sh](#guploadsh)
- [install_node_lts.sh](#install_node_ltssh)
- [install_web_stack.sh](#install_web_stacksh)
- [make_executable.sh](#make_executablesh)
- [setup_ftp.sh](#setup_ftpsh)
- [setup_smf_wdp.sh](#setup_smf_wdpsh)
- [setup_strapi.sh](#setup_strapish)

---

### check_prereqs.sh
Checks for required system packages (Node.js, PostgreSQL, curl, ufw, etc.) and installs them if missing. Ensures your environment is ready for other scripts.

**Usage:**  
```bash
./check_prereqs.sh
```

---

### generate_keys.sh
Generates secure random strings suitable for use in JWT secrets, session keys, or salts.

**Usage:**  
```bash
source generate_keys.sh
generate_key key
```

---

### gUpload.sh
Stages, commits, and pushes changes to a Git repository. Prompts for a commit message and confirms changes before pushing.

**Usage:**  
```bash
./gUpload.sh
```

---

### install_node_lts.sh
Installs the LTS version of Node.js using Nodesource's distribution, suitable for general web development use.

**Usage:**  
```bash
./install_node_lts.sh
```

---

### install_web_stack.sh
Sets up a basic web stack including Nginx, UFW rules, Node.js, and optionally SSL tooling.

**Usage:**  
```bash
./install_web_stack.sh
```

---

### make_executable.sh
Makes all `.sh` files in the current directory executable, ensuring they can be run directly from the shell.

**Usage:**  
```bash
./make_executable.sh
```

---

### setup_ftp.sh
Configures and installs a basic FTP server using vsftpd. Useful for setting up file transfers on a VPS.

**Usage:**  
```bash
./setup_ftp.sh
```

---

### setup_smf_wdp.sh
Initializes and configures SMF (Simple Machines Forum) for development or deployment. May include dependencies and basic config.

**Usage:**  
```bash
./setup_smf_wdp.sh
```

---

### setup_strapi.sh
Full Strapi CMS setup utility. Allows for interactive installation, database provisioning, environment configuration, and launching the development server.

**Usage:**  
```bash
./setup_strapi.sh
```

---
