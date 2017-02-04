#!/bin/bash
# Initializes environment and starts
# the docker sensor

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Dialog status code
DIALOG_OK=0
DIALOG_CANCEL=1
DIALOG_HELP=2
DIALOG_EXTRA=3
DIALOG_ITEM_HELP=4
DIALOG_ESC=255

DIALOG_HEIGTH=12
DIALOG_WIDTH=50

# Check if script is beeing sourced
if [ "$0" != "$BASH_SOURCE" ]; then
  SOURCED=1
  WORKDIR=$(dirname $BASH_SOURCE)
else
  SOURCED=0;
  WORKDIR=$(dirname $0)
fi

ENV_FILE="${WORKDIR}/.env"
ENV_SAVE_VARS="SNIFF_IFACE|API_DST"
ENV_BRO="${WORKDIR}/site/env.bro"

API_DST_REGEX="^(([^:/?#]+):)?(//([^:/?#]*)?(:([0-9]+)))/([^/]+)/([^/]+)"
API_DST_DEFAULT="http://localhost:9200/pdml2flow/flow/"

if [ -e "${ENV_FILE}" ]; then source "${ENV_FILE}"; fi

# Read sniffing interface

IFACES=$(ip -o link show up | awk -v SNIFF_IFACE="${SNIFF_IFACE}" '
  BEGIN { i=0 }
  { 
    i++;
    iface=substr($2, 1, length($2)-1);
    if (iface == SNIFF_IFACE)
      first_line = iface" "iface;
    else
      lines = lines" "iface" "iface;
  }
  END { print i, first_line, lines}
')

result=""
while [ -z "$result" ]; do
  exec 3>&1
  result=$(dialog \
    --help-button \
    --backtitle "$0" \
    --menu "Select sniffing interface:" \
    "${DIALOG_HEIGHT}" "${DIALOG_WIDTH}" ${IFACES} \
    2>&1 1>&3
  );
  exitcode=$?;
  exec 3>&-;
  # Act on it
  case $exitcode in
    $DIALOG_OK) ;;
    $DIALOG_CANCEL) exit ;;
    $DIALOG_HELP)
      clear;
      cat << EOF
Help:
  1. Go to the preferred interface using UP & DOWN
  2. Hit ENTER
Note:
  - Your selection will be remembered in the .env file
  - Next time you start this script the previously selected 
    interface will be the default selection.
Press [ENTER] to continue
EOF
    read
    result=""
    ;;
    $DIALOG_EXTRA) echo "Extra button pressed." ;;
    $DIALOG_ITEM_HELP) echo "Item-help button pressed." ;;
    $DIALOG_ESC) exit ;;
  esac
  [ -z "$result" ] && (
    clear
    echo "Please select an interface. Press [ENTER] to continue"
    read
  )
done

export SNIFF_IFACE=$result

# Read api dst

[[ ! "$API_DST" ]] && API_DST=${API_DST_DEFAULT};

result=""
while [ -z "$result" ]; do
  exec 3>&1
  result=$(dialog \
    --help-button \
    --backtitle "$0" \
    --inputbox "Elasticsearch-API destination:" \
    "${DIALOG_HEIGHT}" "${DIALOG_WIDTH}" ${API_DST} \
    2>&1 1>&3
  );
  exitcode=$?;
  exec 3>&-;
  # Act on it
  case $exitcode in
    $DIALOG_OK) ;;
    $DIALOG_CANCEL) exit ;;
    $DIALOG_HELP)
      clear;
      cat << EOF
Help:
  1. Enter Elasticsearch API destination in the form: http(s)://server.com:1258/index/type
  2. Hit ENTER
Note:
Press [ENTER] to continue
EOF
    read
    result=""
    ;;
    $DIALOG_EXTRA) echo "Extra button pressed." ;;
    $DIALOG_ITEM_HELP) echo "Item-help button pressed." ;;
    $DIALOG_ESC) exit ;;
  esac
  [[ ! $result =~ $API_DST_REGEX ]] && (
    clear
    echo "Invalid URI, validation regex: ${API_DST_REGEX}. Press [ENTER] to continue"
    read
  )
done

export API_DST=$result

[[ $result =~ $API_DST_REGEX ]]
export ES_HOST=${BASH_REMATCH[4]}
export ES_PORT=${BASH_REMATCH[6]}
export ES_INDEX=${BASH_REMATCH[7]}
export ES_TYPE=${BASH_REMATCH[8]}

# Save environment
env | grep -E -e "$ENV_SAVE_VARS" > "${ENV_FILE}"

# Start docker
[[ "$SOURCED" == "0" ]] && sudo -E docker-compose up --build
