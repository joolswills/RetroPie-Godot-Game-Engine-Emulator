#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

# Scriptmodule variables ############################

rp_module_id="godot-engine"
rp_module_desc="Godot - Game Engine (https://godotengine.org/)"
rp_module_help="Godot games extensions: .pck .zip."
rp_module_help+="\n\nCopy your Godot games to:\n'$romdir/godot-engine'."
rp_module_help+="\n\nAuthor: hiulit (https://github.com/hiulit)."
rp_module_help+="\n\nCredits: https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator#credits"
rp_module_help+="\n\nLicense: https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator#license"
rp_module_licence="MIT https://raw.githubusercontent.com/hiulit/RetroPie-Godot-Game-Engine-Emulator/master/LICENSE"
rp_module_section="opt"
rp_module_flags="x86 aarch64 rpi1 rpi2 rpi3 rpi4"


# Global variables ##################################

SCRIPT_VERSION="1.3.0"
GODOT_VERSIONS=(
    "2.1.6"
    "3.0.6"
    "3.1.2"
    "3.2.3"
)
GODOT_ONLY_RPI_4_VERSIONS=(
    "3.1.2"
    "3.2.3" 
)
SUPPORTED_PLATFORMS=(
    "x86"
    "aarch64"
    "rpi1"
    "rpi2"
    "rpi3"
    "rpi4"
)
FRT_KEYBOARD=""


# Configuration flags ###############################

FRT_FLAG=0
GLES2_FLAG=0

# Configuration dialog variables ####################

readonly DIALOG_OK=0
readonly DIALOG_CANCEL=1
readonly DIALOG_EXTRA=3
readonly DIALOG_ESC=255


# Configuration dialog functions ####################

function _main_config_dialog() {
    local options=()
    local option_1_enabled_disabled
    local option_2_enabled_disabled
    local menu_text
    local cmd
    local choice

    if [[ "$FRT_FLAG" -eq 0 ]]; then
        option_1_enabled_disabled="Disabled"
    elif [[ "$FRT_FLAG" -eq 1 ]]; then
        option_1_enabled_disabled="Enabled"
    fi

    if [[ "$GLES2_FLAG" -eq 0 ]]; then
        option_2_enabled_disabled="Disabled"
    elif [[ "$GLES2_FLAG" -eq 1 ]]; then
        option_2_enabled_disabled="Enabled"
    fi

    options=(
        1 "Use a GPIO/Virtual keyboard ("$option_1_enabled_disabled")"
        2 "Force GLES2 video driver ("$option_2_enabled_disabled")"
    )
    cmd=(dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "" \
            --ok-label "OK" \
            --cancel-label "Exit" \
            --menu "Choose an option." \
            15 60 15)
    choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        if [[ -n "$choice" ]]; then
            case "$choice" in
                1)
                    _gpio_virtual_keyboard_dialog
                    ;;
                2)
                    _force_gles2_dialog
                    ;;
            esac
        else
            # If there is no choice that means the user selected "Exit".
            exit 0
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        exit 0
    fi
}


function _gpio_virtual_keyboard_dialog() {
    dialog \
        --backtitle "Godot - Game Engine Configuration" \
        --title "" \
        --yesno "Would you like to you use a GPIO/Virtual keyboard?" 10 60 2>&1 >/dev/tty
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        local i=1
        local options=()
        local cmd
        local choice

        while IFS= read -r line; do
            line="$(echo "$line" | sed -e 's/^"//' -e 's/"$//')" # Remove leading and trailing double quotes.
            options+=("$i" "$line")
            ((i++))
        done < <(cat "/proc/bus/input/devices" | grep "N: Name" | cut -d= -f2)

        cmd=(dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "" \
            --ok-label "OK" \
            --cancel-label "Back" \
            --menu "Choose an option." \
            15 60 15)

        choice="$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)"

        if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
            if [[ -n "$choice" ]]; then
                configure_godot-engine "use_frt" 1 "${options[choice*2-1]}"

                dialog \
                    --backtitle "Godot - Game Engine Configuration" \
                    --title "" \
                    --ok-label "OK" \
                    --msgbox "The GPIO/Virtual keyboard has been set." 8 60 2>&1 >/dev/tty

                _main_config_dialog
            else
                # If there is no choice that means the user selected "Back".
                _main_config_dialog
            fi
        elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
            _main_config_dialog
        elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
            _main_config_dialog
        fi
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        configure_godot-engine "use_frt" 0

        dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "" \
            --ok-label "OK" \
            --msgbox "The GPIO/Virtual keyboard has been unset." 8 60 2>&1 >/dev/tty

        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


function _force_gles2_dialog() {
    dialog \
        --backtitle "Godot - Game Engine Configuration" \
        --title "" \
        --yesno "Would you like to force Godot to use the GLES2 video driver?" 10 65 2>&1 >/dev/tty
    local return_value="$?"

    if [[ "$return_value" -eq "$DIALOG_OK" ]]; then
        configure_godot-engine "force_gles2" 1


        dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "" \
            --ok-label "OK" \
            --msgbox "GLES2 video renderer has been set." 8 60 2>&1 >/dev/tty

        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_CANCEL" ]]; then
        configure_godot-engine "force_gles2" 0

        dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "" \
            --ok-label "OK" \
            --msgbox "GLES2 video renderer has been unset." 8 60 2>&1 >/dev/tty

        _main_config_dialog
    elif [[ "$return_value" -eq "$DIALOG_ESC" ]]; then
        _main_config_dialog
    fi
}


# Helper functions ##################################

function _download_file() {
    echo "> Downloading '$file'..."
    echo
    # Download the file and rename it.
    curl -LJ "$url/$file" -o "$md_build/$file"
    if [[ "$?" -eq 0 ]]; then
        chmod +x "$md_build/$file"
        echo
        echo "'$file' downloaded successfully!"
        echo
    else
        echo
        echo "Something went wrong when dowloading '$file'."
        echo
    fi
}


# Scriptmodule functions ############################

function sources_godot-engine() {
    local url="https://github.com/hiulit/RetroPie-Godot-Game-Engine-Emulator/releases/download/v${SCRIPT_VERSION}"
    local platform
    local file

    # Check if the platform is supported.
    if isPlatform "x86"; then
        platform="x11_32"
    elif isPlatform "aarch64"; then
        platform="arm64"
    elif isPlatform "rpi1"; then
        platform="pi1"
    elif isPlatform "rpi2" || isPlatform "rpi3"; then
        platform="pi2"
    elif isPlatform "rpi4"; then
        platform="pi4"
    fi

    # Throw an error if the platform is not supported.
    if [[ -z "$platform" ]]; then
        echo
        echo "ERROR: Can't install 'Godot - Game Engine'. Your device is not currently supported." >&2
        echo
        echo "The supported platforms/architectures are:"
        for supported_platform in "${SUPPORTED_PLATFORMS[@]}"; do
            echo "- $supported_platform"
        done
        echo
        exit 1
    fi

    echo
    echo "Target platform: '$platform'."
    echo

    # Download all the versions of the Godot binaries for the current the platform.
    for version in "${GODOT_VERSIONS[@]}"; do
        if [[ "$platform" == "x11_32" ]]; then
            file="godot_${version}_${platform}.bin"
            _download_file
        elif [[ "$platform" == "arm64" ]]; then
            file="frt_${version}_${platform}.bin"
            _download_file
        elif [[ "$platform" == "pi1" ]]; then
            file="frt_${version}_${platform}.bin"
            _download_file
        elif [[ "$platform" == "pi2" ]]; then
            file="frt_${version}_${platform}.bin"
            _download_file
        elif [[ "$platform" == "pi4" ]]; then
            file="frt_${version}_${platform}.bin"
            _download_file

            # Only download specific verisons of the Godot binaries for the Raspberry Pi 4.
            local godot_rpi4_version
            for godot_rpi4_version in "${GODOT_ONLY_RPI_4_VERSIONS[@]}"; do
                if [[ "$version" == "$godot_rpi4_version" ]]; then
                    file="godot_${version}_${platform}.bin"
                    _download_file
                fi
            done
        fi
    done
}


function install_godot-engine() {
    if [[ -d "$md_build" ]]; then
        md_ret_files=($(ls "$md_build"))
    else
        echo
        echo "ERROR: Can't install 'godot-engine'." >&2
        echo
        echo "There must have been a problem downloading the sources."
        echo
        exit 1
    fi
}

# Parameters:
# - use_frt [flag, gpio/virtual keyboard]
# - force_gles2 [flag]
function configure_godot-engine() {
    mkRomDir "godot-engine"

    local bin_file
    local bin_file_prefix
    local bin_file_tmp
    local bin_files=()
    local bin_files_tmp=()
    local default
    local id
    local index
    local platform
    local version

    # Check if there are parameters.
    if [[ -n "$1" ]]; then
        if [[ "$1" == "use_frt" ]]; then
            FRT_FLAG="$2"
            FRT_KEYBOARD="$3"
        elif [[ "$1" == "force_gles2" ]]; then
            GLES2_FLAG="$2"
        fi
    fi

    if [[ -d "$md_inst" ]]; then
        # Get all the files in the installation folder.
        bin_files_tmp=($(ls "$md_inst"))

        # Remove the extra "retropie.pkg" file
        # and create the final array with the needed files.
        for bin_file_tmp in "${bin_files_tmp[@]}"; do
            if [[ "$bin_file_tmp" != "retropie.pkg" ]]; then
                bin_files+=("$bin_file_tmp")
            fi
        done
    else
        echo
        echo "ERROR: Can't configure 'godot-engine'." >&2
        echo
        echo "There must have been a problem installing the binaries."
        echo
        exit 1
    fi

    if isPlatform "x86"; then
        platform="x11_32"
        id="x86"
    elif isPlatform "aarch64"; then
        platform="arm64"
        id="frt-arm64"
    elif isPlatform "rpi1"; then
        platform="pi1"
        id="frt-rpi0-1"
    elif isPlatform "rpi2" || isPlatform "rpi3"; then
        platform="pi2"
        id="frt-rpi2-3"
    elif isPlatform "rpi4"; then
        platform="pi4"
        id="frt-rpi4"
    fi

    # Remove the file that contains all the configurations for the different Godot "emulators".
    # It will be created from scratch when adding the emulators in the "addEmulator" functions below.
    [[ -f "/opt/retropie/configs/godot-engine/emulators.cfg" ]] && rm "/opt/retropie/configs/godot-engine/emulators.cfg"

    for index in "${!bin_files[@]}"; do
        default=0
        [[ "$index" -eq "${#bin_files[@]}-1" ]] && default=1 # Default to the last item in 'bin_files'.
        
        # Get the version from the file name.
        version="${bin_files[$index]}"
        # Cut between "_".
        version="$(echo $version | cut -d'_' -f 2)"

        # Set the correct id for the specific (not FRT) Raspberry Pi 4 Godot binaries.
        if [[ "$platform" == "pi4" ]]; then
            # Get the first word before the first underscore.
            # In this case, either 'frt' or 'godot'.
            bin_file_prefix="$(echo "${bin_files[$index]}" | cut -d'_' -f 1)"

            if [[ "$bin_file_prefix" == "godot" ]]; then
                # Remove the first word before the dash.
                # In this case, 'frt', just leaving 'rpi4'.
                id="$(echo "$id" | cut -d'-' -f 2)"
            fi
        fi

        if [[ "$platform" == "x11_32" ]]; then
            addEmulator "$default" "$md_id-$version-$id" "godot-engine" "$md_inst/${bin_files[$index]} --main-pack %ROM%"
        else
            if [[ "$FRT_FLAG" -eq 1 && "$GLES2_FLAG" -eq 1 ]]; then
                addEmulator "$default" "$md_id-$version-$id" "godot-engine" "FRT_KEYBOARD_ID='$FRT_KEYBOARD' $md_inst/${bin_files[$index]} --main-pack %ROM% --video-driver GLES2"
            elif [[ "$FRT_FLAG" -eq 1 && "$GLES2_FLAG" -eq 0 ]]; then
                addEmulator "$default" "$md_id-$version-$id" "godot-engine" "FRT_KEYBOARD_ID='$FRT_KEYBOARD' $md_inst/${bin_files[$index]} --main-pack %ROM%"
            elif [[ "$FRT_FLAG" -eq 0 && "$GLES2_FLAG" -eq 1 ]]; then
                addEmulator "$default" "$md_id-$version-$id" "godot-engine" "$md_inst/${bin_files[$index]} --main-pack %ROM% --video-driver GLES2"
            else
                addEmulator "$default" "$md_id-$version-$id" "godot-engine" "$md_inst/${bin_files[$index]} --main-pack %ROM%"
            fi
        fi
    done

    addSystem "godot-engine" "Godot" ".pck .zip"
}

function gui_godot-engine() {
    if isPlatform "x86"; then
        dialog \
            --backtitle "Godot - Game Engine Configuration" \
            --title "Info" \
            --ok-label "OK" \
            --msgbox "There are no configuration options for the 'x86' platform.\n\nConfiguration options are only available for single-board computers, such as the Raspberry Pi." \
            10 65 2>&1 >/dev/tty
    else
        local emulators_config_file="/opt/retropie/configs/godot-engine/emulators.cfg"

        if grep "FRT_KEYBOARD_ID" "$emulators_config_file" > /dev/null; then
            FRT_FLAG=1
            # Get the first line of the file.
            line="$(sed -n 1p "$emulators_config_file")"
            # Get the string between single quotes.
            FRT_KEYBOARD="$(echo "$line" | cut -d"'" -f 2)"
        fi

        if grep "GLES2" "$emulators_config_file" > /dev/null; then
            GLES2_FLAG=1
        fi

        _main_config_dialog
    fi
}
