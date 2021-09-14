#!/bin/bash
set +x
SERVER='http://gitlab.my-installation'
API='projects'
NUMPAGS=$(curl -s -I --header "PRIVATE-TOKEN: $PRIVATETOKEN"  "$SERVER/api/v4/${API}?per_page=100&page=1"  | grep X-Total-Pages | grep -oP '\d+')
TMPFILE=$(mktemp)

for i in $(seq  1 $NUMPAGS); do
    curl -s --header "PRIVATE-TOKEN: $PRIVATETOKEN" -X GET \
	 "$SERVER/api/v4/${API}?per_page=100&page=$i" | jq -c '.[]|{name_with_namespace}' >> $TMPFILE;
done ;
cat $TMPFILE  | grep gcgit | cut -f 2 -d / | cut -f 1 -d \" | sort | nl
rm $TMPFILE
