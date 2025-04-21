#!/bin/bash

set -e

source "$(dirname "$0")/check_prereqs.sh"
source "$(dirname "$0")/generate_keys.sh"

# Install gum if not present
if ! command -v gum &>/dev/null; then
  echo "[+] Installing gum for enhanced prompts..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
  sudo apt update
  sudo apt install gum -y
fi

# Prompt helpers
ask() { if command -v gum &>/dev/null; then gum input --placeholder="$1"; else read -rp "$1: " val && echo "$val"; fi; }
ask_secret() { if command -v gum &>/dev/null; then gum input --password --placeholder="$1"; else read -rsp "$1: " val && echo; echo "$val"; fi; }
ask_select() { if command -v gum &>/dev/null; then gum choose "$@"; else read -rp "Choose one of: $* > " val && echo "$val"; fi; }

STRAPI_PARENT=$(ask "Enter folder to create your Strapi project in (leave empty for current dir)")
STRAPI_PARENT=${STRAPI_PARENT:-.}
mkdir -p "$STRAPI_PARENT"

STRAPI_PROJECT=$(ask "Enter Strapi project folder name (e.g. my-strapi, or '.' for current dir)")
if [[ -z "$STRAPI_PROJECT" || "$STRAPI_PROJECT" == "." ]]; then
  TARGET_DIR="$STRAPI_PARENT"
  INSTALL_TARGET="."
else
  TARGET_DIR="$STRAPI_PARENT/$STRAPI_PROJECT"
  INSTALL_TARGET="$STRAPI_PROJECT"
fi

if [ -d "$TARGET_DIR" ] && [ "$(ls -A "$TARGET_DIR")" ]; then
  CONFIRM=$(ask_select "Erase existing contents in $TARGET_DIR?" "Yes" "No")
  if [[ "$CONFIRM" != "Yes" ]]; then echo "Aborting setup."; exit 1; fi
  rm -rf "$TARGET_DIR" && mkdir -p "$TARGET_DIR"
fi

VALID_DB_TYPES=(sqlite postgres mysql mariadb)
echo "Choose a database type: ${VALID_DB_TYPES[*]}"
while true; do
  DB_TYPE=$(ask "Database")
  if [[ " ${VALID_DB_TYPES[*]} " =~ " $DB_TYPE " ]]; then break; else echo "Invalid option"; fi
done

if [[ "$DB_TYPE" != "sqlite" ]]; then
  DB_NAME=$(ask "Database name")
  DB_USER=$(ask "Database user")
  DB_PASS=$(ask_secret "Database password")
fi

STRAPI_PORT=$(ask "Port to run Strapi on (default 3131)")
STRAPI_PORT=${STRAPI_PORT:-3131}
USE_SESSION=$(ask_select "Use session-based auth instead of JWT?" "Yes" "No")
USE_TS=$(ask_select "Use TypeScript?" "Yes" "No")

apt update
install_if_missing ufw nodejs curl

if [[ "$DB_TYPE" == "postgres" ]]; then
  install_if_missing postgresql
  cd /tmp
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS $DB_NAME;"
  sudo -u postgres psql -c "DROP ROLE IF EXISTS $DB_USER;"
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
fi

if [[ "$DB_TYPE" == "mysql" || "$DB_TYPE" == "mariadb" ]]; then
  install_if_missing mariadb-server
  mysql -u root -e "DROP DATABASE IF EXISTS $DB_NAME;"
  mysql -u root -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
  mysql -u root -e "CREATE DATABASE $DB_NAME;"
  mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
  mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
  mysql -u root -e "FLUSH PRIVILEGES;"
fi

cd "$TARGET_DIR"
npm init -y
npm install strapi@latest --save

JWT_SECRET=$(generate_key key)
KEY1=$(generate_key key)
KEY2=$(generate_key key)
APP_KEYS="[\"$KEY1\", \"$KEY2\"]"
API_SALT=$(generate_key salt)

{
  echo "DATABASE_CLIENT=$DB_TYPE"
  [[ "$DB_TYPE" != "sqlite" ]] && {
    echo "DATABASE_NAME=$DB_NAME"
    echo "DATABASE_USERNAME=$DB_USER"
    echo "DATABASE_PASSWORD=$DB_PASS"
    echo "DATABASE_HOST=127.0.0.1"
    echo "DATABASE_PORT=5432"
    echo "DATABASE_SSL=false"
  }
  echo "JWT_SECRET=$JWT_SECRET"
} > .env

mkdir -p ./config/env/production
for EXT in js ts; do
cat <<EOFCONFIG > ./config/server.$EXT
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', $STRAPI_PORT),
  app: {
    keys: $APP_KEYS,
  },
});
EOFCONFIG

cat <<EOFADMIN > ./config/admin.$EXT
module.exports = ({ env }) => ({
  apiToken: {
    salt: '$API_SALT',
  },
});
EOFADMIN

cat <<EOFPROD > ./config/env/production/server.$EXT
module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('PORT', $STRAPI_PORT),
  app: {
    keys: $APP_KEYS,
  },
});
EOFPROD

if [[ "$USE_SESSION" == "Yes" ]]; then
cat <<EOFMW > ./config/middlewares.$EXT
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
EOFMW
fi
done

ufw allow "$STRAPI_PORT"/tcp
ufw reload || true

echo "Installing dependencies and starting Strapi..."
npm install
npm run develop
