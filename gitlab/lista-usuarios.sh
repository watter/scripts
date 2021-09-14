#!/bin/bash
set +x

SERVER='http://gitlab.my-installation'

LAST=$(curl -s --no-buffer -G --header "PRIVATE-TOKEN: ${PRIVATETOKEN}" "${SERVER}/api/v4/users?per_page=1&sort=desc" | grep \"id\": | cut -f 2 -d : | cut -f 1 -d , )

for i in `seq $LAST -1 1 `; do  \
    curl -s -G --header "PRIVATE-TOKEN: ${PRIVATETOKEN}" ${SERVER}/api/v4/users/${i} | \
    jq -c ' { username, name } ' | grep -v '"name":null' ;
done | sort | nl
