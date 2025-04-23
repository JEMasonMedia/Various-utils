#!/bin/bash
set -e

source "$(dirname "$0")/check_prereqs.sh"
source "$(dirname "$0")/generate_keys.sh"

# Ensure gum is installed for better prompts
if ! command -v gum &>/dev/null; then
  echo "[+] Installing gum..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update && sudo apt install -y gum
fi

# Prompt user for install dir
INSTALL_DIR=$(gum input --placeholder "Enter install directory (default: ~/strapi)")
INSTALL_DIR=${INSTALL_DIR:-"$HOME/strapi"}

# Confirm deletion if exists
if [[ -d "$INSTALL_DIR" ]]; then
  if gum confirm "Delete existing directory at $INSTALL_DIR?"; then
    echo "[*] Cleaning old project files in $INSTALL_DIR..."
    sudo rm -rf "$INSTALL_DIR"
  else
    echo "Aborted."
    exit 1
  fi
fi

mkdir -p "$INSTALL_DIR"
cd /tmp

# Launch Strapi installer interactively
npx create-strapi-app@latest "$INSTALL_DIR" --no-run --use-npm
cd "$INSTALL_DIR"

# Detect project type (ts or js)
CONFIG_EXT="js"
[[ -f ./tsconfig.json ]] && CONFIG_EXT="ts"

# Extract DB and PORT from .env or config
DB_CLIENT=$(grep -i DATABASE_CLIENT .env | cut -d= -f2 | xargs)
STRAPI_PORT=$(grep -i '^PORT=' .env | cut -d= -f2 | grep -oE '[0-9]+' | head -n 1)
STRAPI_PORT=${STRAPI_PORT:-1337}

# Install and configure DB if needed
case "$DB_CLIENT" in
  postgres)
    install_if_missing postgresql
    DB_NAME=$(grep -i DATABASE_NAME .env | cut -d= -f2 | xargs)
    DB_USER=$(grep -i DATABASE_USERNAME .env | cut -d= -f2 | xargs)
    DB_PASS=$(grep -i DATABASE_PASSWORD .env | cut -d= -f2 | xargs)
    cd /tmp
    sudo -u postgres psql -tc "DROP DATABASE IF EXISTS $DB_NAME;"
    sudo -u postgres psql -tc "DROP ROLE IF EXISTS $DB_USER;"
    sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
    cd "$INSTALL_DIR"
    ;;
  mysql|mariadb)
    install_if_missing mariadb-server
    DB_NAME=$(grep -i DATABASE_NAME .env | cut -d= -f2 | xargs)
    DB_USER=$(grep -i DATABASE_USERNAME .env | cut -d= -f2 | xargs)
    DB_PASS=$(grep -i DATABASE_PASSWORD .env | cut -d= -f2 | xargs)
    sudo mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;"
    sudo mysql -u root -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
    sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
    sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
    ;;
esac

# Generate secrets
KEY1=$(generate_key key)
KEY2=$(generate_key key)
APP_KEYS="[\"$KEY1\", \"$KEY2\"]"
API_SALT=$(generate_key salt)

# Ensure JWT_SECRET is present in .env
if ! grep -q '^JWT_SECRET=' .env; then
  echo "JWT_SECRET=$(generate_key key)" >> .env
  echo "[+] Added JWT_SECRET to .env"
fi

# Create config files
mkdir -p ./config/env/production
for EXT in "$CONFIG_EXT"; do
  cat <<EOF > ./config/server.$EXT
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', $STRAPI_PORT),
  app: {
    keys: $APP_KEYS,
  },
});
EOF

  cat <<EOFADMIN > ./config/admin.$EXT
module.exports = ({ env }) => ({
  apiToken: {
    salt: '$API_SALT',
  },
  auth: {
    secret: env('JWT_SECRET'),
  },
});
EOFADMIN

  cat <<EOF > ./config/env/production/server.$EXT
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', $STRAPI_PORT),
  app: {
    keys: $APP_KEYS,
  },
});
EOF

  if gum confirm "Enable session-based authentication?"; then
    cat <<EOF > ./config/middlewares.$EXT
module.exports = [
  'strapi::errors',
  'strapi::security',
  'strapi::cors',
  'strapi::poweredBy',
  'strapi::logger',
  'strapi::query',
  'strapi::body',
  'strapi::session',
  'strapi::favicon',
  'strapi::public',
];
EOF
  fi

done

# Allow UFW port
sudo ufw allow "$STRAPI_PORT"/tcp || true

# Install and launch
npm install
npm run seed:example || true
npm run develop

