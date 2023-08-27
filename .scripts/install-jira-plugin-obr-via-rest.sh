#!/usr/bin/env bash
optspec=":hv-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                file)
                    PLUGIN_FILE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${PLUGIN_FILE}'" >&2;
                    ;;
                file=*)

                    val=${OPTARG#*=}
                    opt=${OPTARG%=$PLUGIN_FILE}
                    echo "Parsing option: '--${opt}', value: '${PLUGIN_FILE}'" >&2
                    ;;

                server-url)
                    SERVER_URL="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${SERVER_URL}'" >&2;
                    ;;

                server-url=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$SERVER_URL}
                    echo "Parsing option: '--${opt}', value: '${SERVER_URL}'" >&2
                    ;;

                username)
                    USERNAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: '${USERNAME}'" >&2;
                    ;;
                username=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$USERNAME}
                    echo "Parsing option: '--${opt}', value: '${USERNAME}'" >&2
                    ;;

                password)
                    PASSWORD="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    echo "Parsing option: '--${OPTARG}', value: xxxxxxx (hidden)" >&2;
                    ;;
                password=*)
                    val=${OPTARG#*=}
                    opt=${OPTARG%=$PASSWORD}
                    echo "Parsing option: '--${opt}', value: xxxxxxx (hidden)" >&2
                    ;;

                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                    fi
                    ;;
            esac;;
        h)
            echo "usage: $0 [-v] [--file[=]<value>]" >&2
            exit 2
            ;;
        v)
            echo "Parsing option: '-${optchar}'" >&2
            ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
            fi
            ;;
    esac
done

UPM_TOKEN=$(curl -I --user $USERNAME:$PASSWORD -H 'Accept: application/vnd.atl.plugins.installed+json' $SERVER_URL'/rest/plugins/1.0/?os_authType=basic' 2>/dev/null | grep 'upm-token' | cut -d " " -f 2 | tr -d '\r')

PLUGIN_INSTALL_TASK_ENDPOINT=$(curl --silent --user ${USERNAME}:${PASSWORD} -H 'Accept: application/json' --url "${SERVER_URL}/rest/plugins/1.0/?token=${UPM_TOKEN}" -F plugin=@${PLUGIN_FILE} | jq --raw-output '.links.self')

PLUGIN_INSTALL_STATUS=$(curl --silent --user ${USERNAME}:${PASSWORD} -H 'Accept: application/json' --url "${SERVER_URL}${PLUGIN_INSTALL_TASK_ENDPOINT}?token=${UPM_TOKEN}" | jq --raw-output '.status.done')

echo "Installing..."
while [[ "$PLUGIN_INSTALL_STATUS" != "true" ]]; do
  echo "Still installing..."
  sleep 3;
done
echo "...Installed"