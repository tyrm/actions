#!/bin/bash

# config
commands=(".*" "__test__")

# colors
fbold=$(tput bold)
fnormal=$(tput sgr0)
fred='\033[0;31m'

# check_requirements: Checks if the required dependencies are installed.
check_requirements() {
    commands=("rsync" "git")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${fred}${fbold}Error: $cmd is not installed. Please install $cmd to use this script."
            exit 1
        fi
    done
}

# cleanup: Cleans up temporary files or directories created during the script execution.
cleanup() {
    # Clean up temporary files or directories.
    if [[ -d "$TMPDIR" ]]; then
        echo "Cleaning up temporary directory: $TMPDIR"
#        rm -rf "$TMPDIR"
    fi
}

# usage: Prints the usage information and exits with an error.
usage() {
    echo -e "${fbold}Usage:${fnormal} $0 <action> <version>"
    echo -e "\taction: GitHub action to clone (e.g., 'actions/checkout')"
    echo -e "\tversion: the version to clone"
    exit 1
}

#########
# Start #
#########

# make sure we have everything we need
check_requirements

# print usage if wrong number of arguments
if [ "$#" -ne 2 ]; then
    usage
fi

# split first argument at /
if [[ "$1" != */* ]]; then
    echo -e "${fred}${fbold}Error:${fnormal} Invalid action format. Please use 'owner/repo' format."
    echo 
    usage
fi

# trap cleanup function on EXIT signal
trap cleanup EXIT

# assign arguments to variables
OWNER=$(echo "$1" | cut -d'/' -f1)
ACTION=$(echo "$1" | cut -d'/' -f2)
VERSION=$2
echo "Cloning ${ACTIO}N version ${VERSION}"

# make tmp directory
TMPDIR=$(mktemp -d)
#TMPDIR=.
echo "Using temporary directory: ${TMPDIR}"

# clone the specified version of the action into the tmp directory
echo "Cloning ${ACTION} into temp..."
git clone --branch "${VERSION}" --depth 1 "https://github.com/${OWNER}/${ACTION}.git" "${TMPDIR}/repo"
if [ $? -ne 0 ]; then
    echo -e "${fred}${fbold}Error:${fnormal} Failed to clone ${ACTION} at version ${VERSION}"
    exit 1
fi
#echo "Successfully cloned $ACTION at version $VERSION into $TMPDIR"

# move the cloned repo to the action directory
if [[ -d "${ACTION}" ]]; then
    rm -rf "${ACTION}/*"
else
    mkdir ${ACTION}
fi

# Copy data to repo
rsync -av --exclude='.*' "${TMPDIR}/repo/" "${ACTION}/"
