#!/bin/bash

set -eo pipefail # don't set 'u' as we need to explicityly test for undefined vars

CONFIG_DIR="../etc"
DEFAULT_MODE="RCC"
MNC_LENGTH=${MNC_LENGTH:-${#MNC}}

# look up configuration template to use
MODE=${MODE:-${DEFAULT_MODE}}
case "${MODE^^}" in
    UE) TEMPLATE=${CONFIG_DIR}/rru.tdd.band40.conf.template;;
    *)   echo "Unkown mode '${MODE}'."; exit 1;;
esac

# grep variable names (format: ${VAR}) from template to be rendered
VARS=$(grep -oP '\$\{\K[a-zA-Z0-9_]+' ${TEMPLATE} | sort | uniq | xargs)

# create sed expressions for substituting each occurrence of ${VAR}
# with the value of the environment variable "VAR"
EXPRESSIONS=""
for v in ${VARS}; do
    if [[ "${!v}x" == "x" ]]; then
        echo "Error: Environment variable '${v}' is not set." \
             "Config file '$(basename $TEMPLATE)' requires all of $VARS."
        exit 1
    fi
    EXPRESSIONS="${EXPRESSIONS} -e s|\\\${${v}}|${!v}|g"
done

# render template and write to ue.conf
sed ${EXPRESSIONS} ${TEMPLATE} > ${CONFIG_DIR}/ue.conf

exec "$@"