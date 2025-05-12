#!/bin/bash
cd /home/container
sleep 1
# Make internal Docker IP address available to processes.
export INTERNAL_IP=`ip route get 1 | awk '{print $NF;exit}'`

GAME_DIR="/home/container/game/csgo"

METAMOD_DIR="${GAME_DIR}/addons/metamod"
METAMOD_VERSION_FILE="${GAME_DIR}/addons/metamod/.VERSION"
METAMOD_BASE_URL="https://www.metamodsource.net/mmsdrop/2.0/"
METAMOD_LATEST_URL=$(curl -s "$METAMOD_BASE_URL" | grep -oP 'mmsource-[\d\.]+-git\d+-linux\.tar\.gz' | sort -V | tail -n1)
METAMOD_LATEST_VERSION=$(echo "$METAMOD_LATEST_URL" | grep -oP 'git\K[0-9]+')

SWIFTLY_DIR="${GAME_DIR}/addons/swiftly"
SWIFTLY_VERSION_FILE="${GAME_DIR}/addons/swiftly/.VERSION"

# Update Source Server
if [ ! -z ${SRCDS_APPID} ]; then
    if [ ${SRCDS_STOP_UPDATE} -eq 0 ]; then
        STEAMCMD=""
        echo "Starting SteamCMD for AppID: ${SRCDS_APPID}"
        if [ ! -z ${SRCDS_BETAID} ]; then
            if [ ! -z ${SRCDS_BETAPASS} ]; then
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    echo "SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${SRCDS_APPID}"
                    echo "THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended."
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} validate +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    else
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} -betapassword ${SRCDS_BETAPASS} +quit"
                    fi
                fi
            else
                if [ ${SRCDS_VALIDATE} -eq 1 ]; then
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                    else             
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} validate +quit"
                    fi
                else
                    if [ ! -z ${SRCDS_LOGIN} ]; then
                        STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    else 
                        STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} -beta ${SRCDS_BETAID} +quit"
                    fi
                fi
            fi
        else
            if [ ${SRCDS_VALIDATE} -eq 1 ]; then
            echo "SteamCMD Validate Flag Enabled! Triggered install validation for AppID: ${SRCDS_APPID}"
            echo "THIS MAY WIPE CUSTOM CONFIGURATIONS! Please stop the server if this was not intended."
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} validate +quit"
                fi
            else
                if [ ! -z ${SRCDS_LOGIN} ]; then
                    STEAMCMD="./steamcmd/steamcmd.sh +login ${SRCDS_LOGIN} ${SRCDS_LOGIN_PASS} +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                else
                    STEAMCMD="./steamcmd/steamcmd.sh +login anonymous +force_install_dir /home/container +app_update ${SRCDS_APPID} +quit"
                fi
            fi
        fi

        # echo "SteamCMD Launch: ${STEAMCMD}"
        eval ${STEAMCMD}
        # Issue #44 - We can't symlink this, causes "File not found" errors. As a mitigation, copy over the updated binary on start.
        cp -f ./steamcmd/linux32/steamclient.so ./.steam/sdk32/steamclient.so
        cp -f ./steamcmd/linux64/steamclient.so ./.steam/sdk64/steamclient.so
    fi
fi

sleep 1
# MetaMod installation and update
if [ "${METAMOD_STOP_UPDATE:-0}" -eq 0 ]; then  
    if [ ! -f ${METAMOD_VERSION_FILE} ]; then
        echo "[INFO] MetaMod not found, downloading..."
        curl -sSL "${METAMOD_BASE_URL}${METAMOD_LATEST_URL}" -o metamod.tar.gz
        tar -xzf metamod.tar.gz -C "${GAME_DIR}"
        echo "${METAMOD_LATEST_VERSION}" > ${METAMOD_VERSION_FILE}
        rm -rf metamod.tar.gz
    else
        echo "[INFO] MetaMod already installed, checking for updates..."
        CURRENT_VERSION=$(cat ${METAMOD_VERSION_FILE})
        if [ "$CURRENT_VERSION" != "$METAMOD_LATEST_VERSION" ]; then
            echo "[INFO] Newer version Metamod available: $SWIFTLY_VERSION (current: $CURRENT_VERSION)"
            rm -rf ${METAMOD_DIR}
            curl -sSL "${METAMOD_BASE_URL}${METAMOD_LATEST_URL}" -o metamod.tar.gz
            tar -xzf metamod.tar.gz -C "${GAME_DIR}/"
            echo "${METAMOD_LATEST_VERSION}" > ${METAMOD_VERSION_FILE}
            rm -rf metamod.tar.gz
        else
            echo "[INFO] MetaMod is up to date (version $CURRENT_VERSION)."
        fi
    fi
else
    echo "[INFO] MetaMod update disabled."
fi

sleep 1

# Swiftly installation and update
if [ "${SWIFTLY_STOP_UPDATE:-0}" -eq 0 ]; then

    if [ ! -f ${SWIFTLY_VERSION_FILE} ]; then
        echo "[INFO] Swiftly not found, downloading..."
        html=$(curl -sSL "https://github.com/swiftly-solution/swiftly/releases")
        SWIFTLY_VERSION=$(echo "$html" | grep -oP '/swiftly-solution/swiftly/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | sed 's|.*/tag/||')
        SWIFTLY_DOWNLOAD_URL="https://github.com/swiftly-solution/swiftly/releases/download/${SWIFTLY_VERSION}/Swiftly.Plugin.Linux.zip"
        
        curl -sSL "$SWIFTLY_DOWNLOAD_URL" -o swiftly.zip
        if unzip -t swiftly.zip; then
            echo "[INFO] Successfully downloaded Swiftly ${SWIFTLY_VERSION}. Extracting..."
            unzip -oq swiftly.zip -d "${GAME_DIR}"
            rm -f swiftly.zip
            echo "${SWIFTLY_VERSION}" > ${SWIFTLY_VERSION_FILE}
            echo "[INFO] Swiftly ${SWIFTLY_VERSION} installed successfully."
        else
            echo "[ERROR] Failed to download or unzip Swiftly. Please check the download URL."
            exit 1
        fi
    else
        echo "[INFO] Swiftly already installed, checking for updates..."
        CURRENT_VERSION=$(cat ${SWIFTLY_VERSION_FILE})
        html=$(curl -sSL "https://github.com/swiftly-solution/swiftly/releases")
        SWIFTLY_VERSION=$(echo "$html" | grep -oP '/swiftly-solution/swiftly/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+' | head -n1 | sed 's|.*/tag/||')
        current="${CURRENT_VERSION#v}"
        latest="${SWIFTLY_VERSION#v}"

        if [[ "$(printf '%s\n' "$current" "$latest" | sort -V | head -n1)" != "$latest" ]]; then
            echo "[INFO] Newer version Swiftly available: $SWIFTLY_VERSION (current: $CURRENT_VERSION)"
            SWIFTLY_DOWNLOAD_URL="https://github.com/swiftly-solution/swiftly/releases/download/${SWIFTLY_VERSION}/Swiftly.Plugin.Linux.zip"
                curl -sSL "$SWIFTLY_DOWNLOAD_URL" -o swiftly.zip
            if unzip -t swiftly.zip; then
                echo "[INFO] Successfully downloaded Swiftly ${SWIFTLY_VERSION}. Extracting..."
                unzip -oq swiftly.zip -d "${GAME_DIR}"
                rm -f swiftly.zip
                echo "${SWIFTLY_VERSION}" > ${SWIFTLY_VERSION_FILE}
                echo "[INFO] Swiftly ${SWIFTLY_VERSION} updated successfully."
            else
                echo "[ERROR] Failed to download or unzip Swiftly. Please check the download URL."
                exit 1
            fi
        else
            echo "[INFO] Swiftly is up-to-date (version: $CURRENT_VERSION)"
        fi
    fi
else
    echo "[INFO] Swiftly update disabled."
fi

sleep 1

# Edit /home/container/game/csgo/gameinfo.gi to add MetaMod path
GAMEINFO_FILE="/home/container/game/csgo/gameinfo.gi"
GAMEINFO_ENTRY="            Game    csgo/addons/metamod"
if [ -f "${GAMEINFO_FILE}" ]; then
    if grep -q "Game[[:blank:]]*csgo\/addons\/metamod" "$GAMEINFO_FILE"; then # match any whitespace
        echo "File gameinfo.gi already configured. No changes were made."
    else
        awk -v new_entry="$GAMEINFO_ENTRY" '
            BEGIN { found=0; }
            // {
                if (found) {
                    print new_entry;
                    found=0;
                }
                print;
            }
            /Game_LowViolence/ { found=1; }
        ' "$GAMEINFO_FILE" > "$GAMEINFO_FILE.tmp" && mv "$GAMEINFO_FILE.tmp" "$GAMEINFO_FILE"

        echo "The file ${GAMEINFO_FILE} has been configured for MetaMod successfully."
    fi
fi

# Replace Startup Variables
MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`
echo ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}


