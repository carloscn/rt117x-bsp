openssl cms -sign \
            -md sha256 \
            -signer ./keys/IMG1_1_sha256_2048_65537_v3_usr_crt.pem \
            -inkey ./keys/IMG1_1_sha256_2048_65537_v3_usr_key.pem \
            -outform der \
            -nodetach \
            -out signed_cmd_data_0.bin \
            -in to_be_signed_0.bin \
            -noattr

echo "sign finish!"

openssl cms -verify \
            -CAfile ./keys/tmpca.cer \
            -inform der \
            -in signed_cmd_data_0.bin
