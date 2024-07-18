#!/usr/bin/env bash

############################################################################
# Auto install Prometheus Node Exporter on Linux
# Tested on Debian9+(Amd64 and Aaarch64), Ubuntu20+(Amd64), Trisquel9+(Amd64)
# Copyright (c) 2024 MisterTowelie Released under the GNUv3 License.
# https://github.com/MisterTowelie/Prometheus-node-exporter
############################################################################

############################################################################
#   VERSION HISTORY   ######################################################
############################################################################
# v1.0.0
# - Initial version.
############################################################################

# Troubleshooting
# set -e -u -x

# Define Colors
readonly RED="\033[0;31m"
readonly GREEN="\033[0;32m"
readonly YELLOW="\033[0;33m"
readonly BOLD="\033[1m"
readonly NORM="\033[0m"
readonly INFO="${BOLD}${GREEN}[INFO]:$NORM"
readonly ERROR="${BOLD}${RED}[ERROR]:$NORM"
readonly WARNING="${BOLD}${YELLOW}[WARNING]:$NORM"

# Root only
[[ $EUID -ne 0 ]] && echo -e "$WARNING This script must be run as root!" && exit 1

# Detected architecture, platform
if [[ "$(uname)" != 'Linux' ]]; then
  echo -e "$ERROR This operating system is not supported."
  exit 1
fi
case $(uname -m) in
  'i386' | 'i686')
    MACHINE_ARCH='linux-386'
    echo -e "$INFO Detected i386(i686) architecture."
    ;;
  'amd64' | 'x86_64')
    MACHINE_ARCH='linux-amd64'
    echo -e "$INFO Detected Amd64 architecture."
    ;;
  'armv5tel')
    MACHINE_ARCH='linux-armv5'
    echo -e "$INFO Detected ARMv5tel architecture."
    ;;
  'armv6l')
    MACHINE_ARCH='linux-armv6'
    grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE_ARCH='linux-armv5'
    echo -e "$INFO Detected ARMv6 architecture."
    ;;
  'armv7' | 'armv7l')
    MACHINE_ARCH='linux-armv7'
    echo -e "$INFO Detected ARMv7 architecture."
    ;;
  'armv8' | 'aarch64')
    MACHINE_ARCH='linux-arm64'
    echo -e "$INFO Detected ARMv8 architecture."
    ;;
  'mips')
    MACHINE_ARCH='linux-mips'
    echo -e "$INFO Detected Mips architecture."
    ;;
  'mipsle')
    MACHINE_ARCH='linux-mipsle'
    echo -e "$INFO Detected Mipsle architecture."
    ;;
  'mips64')
    MACHINE_ARCH='linux-mips64'
    lscpu | grep -q "Little Endian" && MACHINE_ARCH='linux-mips64le'
    echo -e "$INFO Detected Mips64 architecture."
    ;;
  'mips64le')
    MACHINE_ARCH='linux-mips64le'
    echo -e "$INFO Detected Mips64le architecture."
    ;;
  'ppc64')
    MACHINE_ARCH='linux-ppc64'
    echo -e "$INFO Detected Ppc64 architecture."
    ;;
  'ppc64le')
    MACHINE_ARCH='linux-ppc64le'
    echo -e "$INFO Detected Ppc64le architecture."
    ;;
  'riscv64')
    MACHINE_ARCH='linux-riscv64'
    echo -e "$INFO Detected Riscv64 architecture."
    ;;
  's390x')
    MACHINE_ARCH='linux-s390x'
    echo -e "$INFO Detected s390x architecture."
    ;;
  *) 
    echo -e "$ERROR This is unsupported platform, sorry."
    exit 1
    ;;
esac
if [[ ! -f '/etc/os-release' ]]; then
  echo -e "$ERROR Don't use outdated Linux distributions."
  exit 1
fi
if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
    true
  elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
    true
  else
    echo -e "$ERROR Only Linux distributions using systemd are supported."
    exit 1
  fi
  if [[ "$(type -P apt)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'
    PACKAGE_MANAGEMENT_REMOVE='apt purge'
  elif [[ "$(type -P dnf)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='dnf -y install'
    PACKAGE_MANAGEMENT_REMOVE='dnf remove'
  elif [[ "$(type -P yum)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='yum -y install'
    PACKAGE_MANAGEMENT_REMOVE='yum remove'
  elif [[ "$(type -P zypper)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='zypper install -y --no-recommends'
    PACKAGE_MANAGEMENT_REMOVE='zypper remove'
  elif [[ "$(type -P pacman)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='pacman -Syy --noconfirm'
    PACKAGE_MANAGEMENT_REMOVE='pacman -Rsn'
    elif [[ "$(type -P emerge)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='emerge -qv'
    PACKAGE_MANAGEMENT_REMOVE='emerge -Cv'
    echo -e "$INFO PACKAGE_MANAGEMENT_INSTALL= $PACKAGE_MANAGEMENT_INSTALL"
    echo -e "$INFO PACKAGE_MANAGEMENT_REMOVE= $PACKAGE_MANAGEMENT_REMOVE"
  else
    echo -e "$ERROR The script does not support the package manager in this operating system."
    exit 1
  fi

# Dependencies
function set_Dependencies(){
  if [ -f /usr/bin/node_exporter ]; then
    NODE_EXPORTER_DIR="/usr/bin"
  else
    NODE_EXPORTER_DIR="/usr/local/bin"
  fi

  IS_NODE_EXPORTER="0"
  # IS_PATH_SERVICE="0"
  IS_CURL="0"
  readonly PATH_CURL="/usr/bin/curl"
  readonly NODE_EXPORTER_LATEST_URL="https://api.github.com/repos/prometheus/node_exporter/releases/latest"
  readonly PATH_NODE_EXPORTER="${NODE_EXPORTER_DIR}/node_exporter"
  readonly PATH_SERVICE="/etc/systemd/system/node_exporter.service"
  readonly SERVICE_USER="node_exporter"
  readonly NODE_EXPORTER_DIR
}

# Dependencies
function check_Dependencies(){
  
	if [ -f $PATH_NODE_EXPORTER ]; then
		STATUS_PATH_NODE_EXPORTER="$(echo -e "$GREEN OK$NORM")"
	else
		STATUS_PATH_NODE_EXPORTER="$(echo -e "$RED NA$NORM")"
		IS_NODE_EXPORTER="1"
	fi

  if [ -f $PATH_SERVICE ]; then
		STATUS_PATH_SERVICE="$(echo -e "$GREEN OK$NORM")"
    # IS_PATH_SERVICE="1"
	else
	  STATUS_PATH_SERVICE="$(echo -e "$RED NA$NORM")"
	fi

  if [ -f $PATH_CURL ]; then
	  STATUS_PATH_CURL="$(echo -e "$GREEN OK$NORM")"

	else
		STATUS_PATH_CURL="$(echo -e "$RED NA$NORM")"
		IS_CURL="1"
	fi
}

# Show Dependencies
function show_Dependencies(){
	echo ""
	echo "List of File Dependencies Needed"
	echo ""
	echo -e "$INFO $PATH_NODE_EXPORTER - $GREEN Status:$NORM $STATUS_PATH_NODE_EXPORTER"
  echo -e "$INFO $PATH_SERVICE - $GREEN Status:$NORM $STATUS_PATH_SERVICE"
	echo -e "$INFO $PATH_CURL - $GREEN Status:$NORM $STATUS_PATH_CURL"
	echo ""
	read -n1 -r -p "Press ENTER to continue...."
}

# Check new version Node Exporter
function check_update_Prometheus(){
  local PROMETHEUS_LOCAL_COMMIT
  local PROMETHEUS_REMOTE_COMMIT
  echo -e "$INFO Check update Node Exporter"
  PROMETHEUS_LOCAL_COMMIT="$("${NODE_EXPORTER_DIR}/node_exporter" --version | grep "version" | head -1 | cut -d : -f 3 | cut -d \) -f 1 | tr -d " ")"
  PROMETHEUS_REMOTE_COMMIT="$(curl -sL "$NODE_EXPORTER_LATEST_URL" | grep "target_commitish" | head -1 | cut -d \" -f 4 | tr -d " ")"
  if [ "$PROMETHEUS_LOCAL_COMMIT" != "$PROMETHEUS_REMOTE_COMMIT" ]; then
    echo -e "$INFO LOCAL_VERSION is not synced with REMOTE_VERSION, initiating update..."
  else
    echo -e "$INFO No new version available for Node Exporter."
    exit 1
  fi
}

# Download Node Exporter
function download_Prometheus() {
  NODE_EXPORTER_REMOTE_VERSION_DOWNLOAD="$(curl -sL "$NODE_EXPORTER_LATEST_URL" | grep "tag_name" | head -1 | cut -d \" -f 4 | tr -d "v")"
  NODE_EXPORTER_TAR="node_exporter-${NODE_EXPORTER_REMOTE_VERSION_DOWNLOAD}.${MACHINE_ARCH}.tar.gz"
  NODE_EXPORTER_DOWNLOAD_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_REMOTE_VERSION_DOWNLOAD}/${NODE_EXPORTER_TAR}"
  echo -e "$INFO Download Node Exporter"
  cd /tmp || exit 1
  if [ -f "${NODE_EXPORTER_TAR}" ]; then
    echo -e "$INFO Files:${NODE_EXPORTER_TAR}$GREEN [found]$NORM"
  else
    echo -e "$INFO Files:${NODE_EXPORTER_TAR}$RED [not found]$NORM, download now..."
    if ! $(type -P curl) --request GET -sLq --retry 5 --retry-delay 10 --retry-max-time 60 --url "${NODE_EXPORTER_DOWNLOAD_URL}" --output "$NODE_EXPORTER_TAR"; then
        echo -e "$ERROR Download ${NODE_EXPORTER_TAR} $RED [failed].$NORM"
        rm -Rf "$NODE_EXPORTER_TAR"
    fi
  fi
}

# Unpack archive
function unpack_App(){
  if ! tar xvfz "${NODE_EXPORTER_TAR}"; then
    echo -e "$ERROR An error occurred while unzipping the$RED${NODE_EXPORTER_TAR}$NORM"
    rm -Rf "$NODE_EXPORTER_TAR"
    echo -e "$ERROR $$NODE_EXPORTER_TAR"
    exit 1
  fi 
  cd node_exporter-"${NODE_EXPORTER_REMOTE_VERSION_DOWNLOAD}"."${MACHINE_ARCH}" || exit 1
}

# Make node_exporter user
function check_Users(){
  if grep -qs "^$SERVICE_USER:" /etc/passwd > /dev/null; then
    echo -e "$INFO User $SERVICE_USER - $GREEN [found]$NORM"
  else
    echo -e "$INFO User $SERVICE_USER - $RED [not found]$NORM/ Create User"
    adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" "$SERVICE_USER"
  fi
}

function create_Unit(){
  echo -e "$INFO Create Service Node Exporter..."
  cat > "/etc/systemd/system/node_exporter.service"<<-EOF
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$SERVICE_USER
Group=$SERVICE_USER
Type=simple
Restart=on-failure
ExecStart=$NODE_EXPORTER_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 /etc/systemd/system/node_exporter.service
}

# Copy utilitie to where they should be in the filesystem
# Assign ownership of the files above to prometheus user
function move_Prometheus(){
   cp -fv "node_exporter" "${NODE_EXPORTER_DIR}" &&
   chmod u+x "${NODE_EXPORTER_DIR}/node_exporter" &&
   chown "$SERVICE_USER":"$SERVICE_USER" $NODE_EXPORTER_DIR/node_exporter
}

# Installation cleanup
function cleanup_Install(){
  rm -rf /tmp/node_exporter*
}

# Start Node Exporter Service
function service_Prometheus(){
  local NODE_EXPORTER_CUSTOMIZE
  systemctl daemon-reload &&
  systemctl enable node_exporter &&
  systemctl start node_exporter
  NODE_EXPORTER_CUSTOMIZE="$(systemctl list-units | grep 'node_exporter' | awk -F ' ' '{print $1}')"
  if systemctl -q is-active "${NODE_EXPORTER_CUSTOMIZE:-node_exporter}"; then
      echo -e "$INFO Start the Node Exporter service."
      completion_Message
  else
      echo -e "$INFO Failed to start Node Exporter service."
      exit 1
  fi
}

# Display a completion message
function completion_Message() {
  echo ""
  echo -e "$INFO Node Exporter setup completed!"
}

# Install Dependencies
function install_Dependencies() {
  if [ "${IS_CURL}" == "1" ]; then
		echo -e "$INFO Installing required packages. Curl is required to use this installer."
		read -n1 -r -p "Press any key to install Curl and continue..."
    if ${PACKAGE_MANAGEMENT_INSTALL} curl; then
      echo -e "$INFO Curl is installed."
    else
      echo -e "$ERROR Installation of Curl failed, please check your network."
      exit 1
    fi
	fi
}

# Prometheus Server Update Block
function update_Prometheus(){
  check_update_Prometheus
  download_Prometheus
  unpack_App
  move_Prometheus
}

# Prometheus Server Install Block
function install_Prometheus(){
  download_Prometheus
  unpack_App
  check_Users
  move_Prometheus
  create_Unit
}

function main(){
  set_Dependencies
  check_Dependencies
  show_Dependencies
  install_Dependencies
  if [ "${IS_NODE_EXPORTER}" == "1" ]; then
    install_Prometheus
  else
    update_Prometheus
  fi
  service_Prometheus
  cleanup_Install
}

main
