#!/bin/bash

# Author: slmckenzie
# Date Created: 2025-08-09
# File Name: vivado_project_create.sh

# Description: This script creates a vivado project with the file structure
#              for storing in a repo in github or gitlab.

dir=""
proj_name=""
do_docs=""
remove=""

# Function to display help menu
help_menu() {
    echo ""
    echo "Usage: ./vivado_project_create.sh [-d|--dir] <directory> [-n|--name] <project name> [--docs] [--rm]"
    echo ""
    echo "directory: Folder where the project is to be created."
    echo "project name: Name of the project to be created."
    echo "(optional)'--docs': Creates a document folder in the firmware folder."
    echo "(optional)'--rm': Will remove project folder if it exist already."
    echo ""
}

# Function to ensure directory path ends with /
ensure_trailing_slash() {
    local path="$1"
    if [[ "$path" == */ ]]; then
        echo "$path"   # Already has trailing slash
    else
        echo "$path/"  # Add trailing slash
    fi
}

if [ $# -eq 0 ]; then
    # No command line arguments were given. Exit immediatly.
    echo "No command line arguments given. Please view help menu with '-h' or '--help'"
    exit 1
# elif [ $# -le 4 ]; then
#     # Incorrect number of command line arguments were given. Show help menu and Exit immediatly.
#     help_menu #call help menu
#     exit 2
else
    # Quick help check
    for arg in "$@"; do
        [ "$arg" = "-h" ] || [ "$arg" = "--help" ] && {
            help_menu
            exit 2
        }
    done

    # Parse arguments
    i=1
    while [ $i -le $# ]; do
        case ${!i} in
            "-d" | "--dir")
                i=$((i+1))
                dir=${!i};;
            "-n" | "--name")
                i=$((i+1))
                proj_name=${!i};;      
            "--docs")
                do_docs="true";;
            "--rm")
                remove="true";;
        esac
        i=$((i+1))
    done
fi

passed=2
# Check if directory is populated.
if [ -z "$dir" ]; then
    echo "Directory not specified."
    ((--passed))
else
    # Ensure directory has trailing slash
    dir=$(ensure_trailing_slash "$dir")
fi

# Check if project name is populated.
if [ -z "$proj_name" ]; then
    echo "Project name not specified."
    ((--passed))
fi

if [ $passed -ne 2 ]; then
    echo "Please use '-h' or '--help' for help menu."
    exit 3
fi

# Display the directory and project name
echo "Directory is: ${dir}"
echo "Project name is: ${proj_name}"

# Check if the directory + project name already exists.
if [ -d "${dir}${proj_name}" ]; then

    # If the remove flag has been asserted remove the directory
    if [ "$remove" ]; then
        rm -rf "${dir}${proj_name}"
    else
        # Let use know the directory already exist and will immediatly exit.
        echo "Project directory already exists."
        exit 4
    fi
fi

# Create the parent directory with the child directories underneth it.
mkdir -p "${dir}${proj_name}"/"firmware"/{"BD","HDL","Constraints"} "${dir}${proj_name}"/"scripts"

# Check if the documents child directory needs to be created
if [ "$do_docs" ]; then
    mkdir -p "${dir}${proj_name}"/"firmware/Documents"
fi

echo "Finished creating project folder."