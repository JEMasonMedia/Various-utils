#!/bin/bash

# Makes all .sh files in the current directory executable

echo "Making all .sh scripts in $(pwd) executable..."
chmod +x ./*.sh
echo "Done."
