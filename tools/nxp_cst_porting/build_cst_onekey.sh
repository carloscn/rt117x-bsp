# !/bin/bash

if [ ! -f "openssl-1.1.1t.tar.gz" ]; then
    wget https://www.openssl.org/source/openssl-1.1.1t.tar.gz --no-check-certificate
    if [ $? -ge 1 ]; then
        exit 2
    fi
fi

if [ ! -d "openssl" ]; then
    tar -xvf openssl-1.1.1t.tar.gz
    if [ $? -ge 1 ]; then
        exit 2
    fi

    mv openssl-1.1.1t openssl
    if [ $? -ge 1 ]; then
        exit 2
    fi

    OSTYPE=linux64 make openssl -j16
    if [ $? -ge 1 ]; then
        exit 2
    fi
fi

cd cst

#bash -c "export OS_TYPE=linux64 make os_bin"
OSTYPE=linux64 make os_bin
if [ $? -ge 1 ]; then
    exit 2
fi

echo "build cst finish! you can get it in ./release/linux64/bin"
ls -al release/linux64/bin/*