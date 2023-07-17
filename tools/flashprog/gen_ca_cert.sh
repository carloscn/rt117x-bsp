
CA_PRIVATE_KEY="ca_private"
CA_PUBLIC_KEY="ca_public"
CA_CERT="ca_cert"

ca_generate() {
    ca_subj_req=/CN=CA1_sha256_2048_65537_v3_ca/
    ca_key_type=rsa:2048

    rm -rf key_pass.txt
    echo "123456" > key_pass.txt
    # 1. gen ca private key (pem) + ca cert (pem) PKCS#1
    openssl req -newkey ${ca_key_type} -passout file:./key_pass.txt \
                   -subj ${ca_subj_req} \
                   -x509 -extensions v3_ca \
                   -keyout temp.pem \
                   -out ${CA_CERT}.pem \
                   -days 3650 -config "openssl.cnf"
    if [ $? -ge 1 ]; then
       exit 2
    fi

    echo key_pass.txt > key_pass_1.txt
    # 2.Generate CA key in PKCS #8 format - both PEM and DER
    openssl pkcs8 -passin file:"./key_pass.txt" -passout file:"./key_pass_1.txt" \
                  -topk8 -inform PEM -outform DER -v2 des3 \
                  -in temp.pem \
                  -out ${CA_PRIVATE_KEY}.der
    if [ $? -ge 1 ]; then
       exit 2
    fi
    cp -r temp.pem ${CA_PRIVATE_KEY}_pkcs1.pem
    openssl pkcs8 -passin file:./key_pass.txt -passout file:./key_pass_1.txt \
                  -topk8 -inform PEM -outform PEM -v2 des3 \
                  -in temp.pem \
                  -out ${CA_PRIVATE_KEY}.pem
    if [ $? -ge 1 ]; then
       exit 2
    fi

    # 3. Convert CA Certificate to DER format
    openssl x509 -inform PEM -outform DER -in ${CA_CERT}.pem -out ${CA_CERT}.der
    if [ $? -ge 1 ]; then
       exit 2
    fi

    rm -rf temp.pem
}

ca_generate
ls -al
echo "CA cert done!"