#!/bin/bash

function e_header()  { echo -e "\n\033[1m$*\033[0m"; }
function e_success() { echo -e " \033[1;32m✔\033[0m  $*"; }
function e_error()   { echo -e " \033[1;31m✖\033[0m  $*"; }
function e_arrow()   { echo -e " \033[1;34m➜\033[0m  $*"; }

function symlink() {
    local dir_to_create
    dir_to_create=$(dirname "${2}")
    if [ ! -d "$dir_to_create" ]; then
        e_arrow "directory $dir_to_create does not exist, let's create it"
        mkdir -p "$dir_to_create"
    fi
    if [ -h "$2" ]; then
        e_arrow "the symlink already exists, skipping"
        return 0
    fi
    ln -s "$1" "$2"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.." || { echo "not able to switch to the oxideshop directory"; exit 1; }
oxideshop_path=$(pwd)
for module in project-modules/*
do
    module_source_directory="$oxideshop_path/$module"
    module_directory_only=$(basename "$module")
    e_header "Working on $module_directory_only"

    cd "$module_source_directory" || { echo "not able to cd into $module"; exit 1; }

    module_target_directory=$(composer config extra.oxideshop.target-directory)
    if [[ "$module_target_directory" == "" ]]; then
        e_error "Please add an extra.oxideshop.target-directory config to the composer.json"
        continue
    fi
    full_module_target_directory="$oxideshop_path/source/modules/$module_target_directory"

    e_arrow "symlinking $module to $module_target_directory"
    symlink "../../../project-modules/$module_directory_only" "$full_module_target_directory"
    if [[ -L "$full_module_target_directory" && -d "$full_module_target_directory" ]]
    then
        e_success "symlinking done"
    else
        e_error "symlink not created"
    fi

    e_arrow "checking module configuration for $module_directory_only ..."
    if grep -q "path: $module_target_directory$" "$oxideshop_path/var/configuration/shops/1.yaml"; then
        e_success "already configured"
    else
        e_arrow "not configured yet"
        if [ -f /.dockerenv ]; then
            e_arrow "installing $module_directory_only ..."
            "$oxideshop_path/vendor/bin/oe-console" oe:module:install-configuration "$oxideshop_path/source/modules/$module_target_directory"
            e_success "module configuration done"
        else
            e_arrow "ATTENTION! You need to install this module by running this command in the app container: \n\t" \
                "vendor/bin/oe-console oe:module:install-configuration source/modules/$module_target_directory"
        fi
    fi

    e_arrow "adding module testing lib configuration for ${module_target_directory} ..."
    sed 's#<modulepath>#${module_target_directory}#' -i ${oxideshop_path}\test_config.yml
done
