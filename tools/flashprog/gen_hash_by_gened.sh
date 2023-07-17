./tools/srktool -h 4 -t "SRK_1_2_3_4_table.bin" -e "SRK_1_2_3_4_fuse.bin" -d sha256 -f 1 \
                   -c "./keys/SRK1_sha256_2048_65537_v3_ca_crt.pem,./keys/SRK2_sha256_2048_65537_v3_ca_crt.pem,./keys/SRK3_sha256_2048_65537_v3_ca_crt.pem,./keys/SRK4_sha256_2048_65537_v3_ca_crt.pem"

sha256sum SRK_1_2_3_4_table.bin
sha256sum SRK_1_2_3_4_fuse.bin