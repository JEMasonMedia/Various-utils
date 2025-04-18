#!/bin/bash

# Generates a key or salt for use in Strapi
# Usage: generate_key key   -> single hex string
#        generate_key salt  -> base64 token

generate_key() {
  case "$1" in
    key)
      echo "$(openssl rand -hex 32)"
      ;;
    salt)
      echo "$(openssl rand -base64 16)"
      ;;
    *)
      echo "Usage: generate_key key|salt"
      return 1
      ;;
  esac
}
