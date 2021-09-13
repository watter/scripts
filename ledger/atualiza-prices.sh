#!/bin/bash
OUTFILE=${1:-prices.db}
AK="COINAPI-ACCESS-KEY"

COINS="USD ADA BNB BTC ETH VRA XRP"
ASSETBASE="BRL"
for i in $COINS; do 
    curl -k -s  https://rest.coinapi.io/v1/exchangerate/${i}/${ASSETBASE}   --request GET --header "X-CoinAPI-Key: ${AK}" | \
	jq  -j '"P ", .time , " ",  .asset_id_base, " ", .asset_id_quote, " ",  .rate ' | sed 's/T/ /; s/\.\([0-9]\)*Z//; s@-@/@;s@-@/@' | tee -a  ${OUTFILE}
    echo  | tee -a ${OUTFILE}
done
