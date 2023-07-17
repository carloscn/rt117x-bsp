# !/bin/bash

# example :
# ./gen_git_code.sh /home/haochenwei/work/cst-origin/cst-3.3.2 /home/haochenwei/work/imx-cst

cst_origin_root=$1
cst_modify_root=$2

echo "origin root : $1"
echo "modify root : $2"

cp -rf ${cst_modify_root}/code/cst/code/back_end-ssl/hdr/autox_sign_with_hsm.h `pwd`
if [ $? -ge 1 ]; then
    exit 2
fi

cp -rf ${cst_modify_root}/code/cst/code/back_end-ssl/src/autox_sign_with_hsm.c `pwd`
if [ $? -ge 1 ]; then
    exit 2
fi

diff -Nu ${cst_origin_root}/code/cst/code/back_end-ssl/src/adapt_layer_openssl.c \
         ${cst_modify_root}/code/cst/code/back_end-ssl/src/adapt_layer_openssl.c \
         > `pwd`/adapt_layer_openssl.c.patch
if [ $? -ne 0 ]; then
    echo "[INFO] adapt_layer_openssl.c.patch is generated."
else
    echo "[ERR] adapt_layer_openssl.c.patch generated failed."
    exit -1
fi

diff -Nu ${cst_origin_root}/code/cst/code/back_end-ssl/src/objects.mk \
         ${cst_modify_root}/code/cst/code/back_end-ssl/src/objects.mk \
         > `pwd`/objects.mk.patch
if [ $? -ne 0 ]; then
    echo "[INFO] objects.mk.patch is generated."
else
    echo "[ERR] objects.mk.patch failed."
    exit -1
fi

echo "[INFO] done!"
ls -al *