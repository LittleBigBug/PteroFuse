#!/bin/bash
# steamcmd Base Installation Script
#
# Server Files: /mnt/server

##
#
# Variables
# STEAM_USER, STEAM_PASS, STEAM_AUTH - Steam user setup. If a user has 2fa enabled it will most likely fail due to timeout. Leave blank for anon install.
# WINDOWS_INSTALL - if it's a windows server you want to install set to 1
# SRCDS_APPID - steam app id found here - https://developer.valvesoftware.com/wiki/Dedicated_Servers_List
# SRCDS_BETAID - beta id
# SRCDS_BETAPASS - beta password
# EXTRA_FLAGS - when a server has extra flags for things like beta installs or updates.
#
##

LAYERS_DIR="/mnt/server-layers"

STEAMCMD_DIR="${LAYERS_DIR}/_server-bases/steamcmd"
BASE_SERVER_DIR="${LAYERS_DIR}/_server-bases/source-${SRCDS_APPID}"

if [ -n "${SRCDS_BETAID}" ]; then
  BASE_SERVER_DIR+="-beta${SRCDS_BETAID}"
fi

mkdir -p "${STEAMCMD_DIR}"
mkdir -p "${BASE_SERVER_DIR}"

## just in case someone removed the defaults.
if [ "${STEAM_USER}" == "" ]; then
    echo -e "steam user is not set.\n"
    echo -e "Using anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

# download & install SteamCMD if absent
if [ -z "$( ls -A ${STEAMCMD_DIR} )" ]; then
   curl -sSL -o /tmp/steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
   tar -xzvf /tmp/steamcmd.tar.gz -C "${STEAMCMD_DIR}"
fi

# fix SteamCMD disk write error when this folder is missing
mkdir -p "${BASE_SERVER_DIR}/steamapps"

# SteamCMD fails otherwise for some reason, even running as root.
# This is changed at the end of the install process anyways.
# chown -R root:root "${BASE_SERVER_DIR}"
export HOME="${BASE_SERVER_DIR}"

# install or validate/update game server base
cd "${STEAMCMD_DIR}" || exit 1

chmod +x steamcmd.sh

# shellcheck disable=SC2046
# shellcheck disable=SC2086
./steamcmd.sh +force_install_dir "${BASE_SERVER_DIR}" +login "${STEAM_USER}" "${STEAM_PASS}" "${STEAM_AUTH}" \
  $( [[ "${WINDOWS_INSTALL}" == "1" ]] && printf %s '+@sSteamCmdForcePlatformType windows' ) \
  +app_update "${SRCDS_APPID}" ${EXTRA_FLAGS} \
  $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) \
  $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) \
  validate +quit

# copy over steam libraries
SDK32_DIR="${BASE_SERVER_DIR}/.steam/sdk32"
SDK64_DIR="${BASE_SERVER_DIR}/.steam/sdk64"

mkdir -p "${SDK32_DIR}"
mkdir -p "${SDK64_DIR}"
cp -v linux32/steamclient.so "${SDK32_DIR}/steamclient.so"
cp -v linux64/steamclient.so "${SDK64_DIR}/steamclient.so"

# other layers are populated during server startups