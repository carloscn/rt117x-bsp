
CA_PRIVATE_KEY="ca_private"
CA_PUBLIC_KEY="ca_public"
CA_CERT="ca_cert"

num_srk=4

srk_generate() {

   i=1
   while [ $i -le ${num_srk} ]
   do
      SRK_NUM=${i}
      SRK_PRIVATE_KEY="srk${SRK_NUM}_private"
      SRK_PUBLIC_KEY="srk${SRK_NUM}_public"
      SRK_CERT_BY_CA="srk${SRK_NUM}_ca.cert"
      # 1. Generate SRK key (PEM)
      echo "123456" > key_pass.txt
      openssl genrsa -des3 -passout file:./key_pass.txt -f4 \
                     -out ./temp_srk.pem 2048
      if [ $? -ge 1 ]; then
         exit 2
      fi

      # 2. Generate SRK certificate signing request
      srk_subj_req=/CN=SRK${SRK_NUM}_sha256_256_65537_v3_usr/
      openssl req -new -batch -passin file:./key_pass.txt \
                       -subj ${srk_subj_req} \
                       -key ./temp_srk.pem \
                       -out ./temp_srk_req.pem
      if [ $? -ge 1 ]; then
         exit 2
      fi

      # 3. Generate SRK certificate signing request
      openssl req -new -batch -passin file:./key_pass.txt \
                       -subj ${srk_subj_req} \
                       -key ./temp_srk.pem \
                       -out ./temp_srk_req.pem
      if [ $? -ge 1 ]; then
         exit 2
      fi
      echo "Gen SRK CSR finish!"

      # 4. Generate SRK certificate (signed by a CA cert)
      openssl ca -batch -passin file:./key_pass.txt \
                 -md sha256 -outdir ./ \
                 -in ./temp_srk_req.pem \
                 -cert ${CA_CERT}.pem \
                 -keyfile ${CA_PRIVATE_KEY}_pkcs1.pem \
                 -extfile "v3_usr.cnf" \
                 -out ${SRK_CERT_BY_CA}.pem \
                 -days 3650 \
                 -config "openssl.cnf"
      if [ $? -ge 1 ]; then
         exit 2
      fi
      echo "signed CSR by CA cert and private key!"

      # Convert SRK Certificate to DER format
      openssl x509 -inform PEM -outform DER \
                   -in ${SRK_CERT_BY_CA}.pem \
                   -out ${SRK_CERT_BY_CA}.der
      if [ $? -ge 1 ]; then
         exit 2
      fi
      echo "Converted SRK Certificate to DER format!"

      echo key_pass.txt > key_pass_1.txt
      # Generate SRK key in PKCS #8 format - both PEM and DER
      openssl pkcs8 -passin file:./key_pass.txt \
                    -passout file:./key_pass_1.txt \
                    -topk8 -inform PEM -outform DER -v2 des3 \
                    -in temp_srk.pem \
                    -out ${SRK_PRIVATE_KEY}.der
      if [ $? -ge 1 ]; then
         exit 2
      fi

      openssl pkcs8 -passin file:./key_pass.txt \
                    -passout file:./key_pass_1.txt \
                    -topk8 -inform PEM -outform PEM -v2 des3 \
                    -in temp_srk.pem \
                    -out ${SRK_PRIVATE_KEY}.pem
      if [ $? -ge 1 ]; then
         exit 2
      fi
      echo "Generate SRK key in PKCS #8 format - both PEM and DER!"
      cp -r temp_srk.pem ${SRK_PRIVATE_KEY}_pkcs1.pem
      rm ./temp_srk.pem ./temp_srk_req.pem
      i=$((i+1))
   done
}

srk_generate
echo "done!"