#!/bin/sh

out_name="ca_cert_chains.crt"

if [[ "$1" = "" || "$2" = ""  ]]; then
        echo "certSignVerify.sh  CAfiles certfile "
        exit 0;
fi

touch ${out_name}
count=$#
tmp=1
for i in "$@"; do
        if [  "$tmp" -eq  "$count" ] ; then
                break;
        fi
        cat $i >> ${out_name}
        tmp=$[$tmp +1]
done

openssl verify -CAfile ${out_name} -verbose $(eval echo "\$$#")
if [ $? -ge 1 ]; then
    echo "verify CAfile with signer certs failed!"
    exit 2
fi
cp -rf ${out_name} ./keys
