.PHONY: clean distclean

gen-ram-itcm-signed:
	@bash ./gen_boot_image.sh ./images/app.s19 4

qspi: ivt_image_nopadding.bin
	@echo "Write the app to QSPI Flash"
	@bash ./burn_boot_image.sh /dev/ttyACM0 ./ivt_image_nopadding.bin

ivt_image_nopadding.bin: gen-xip
	@echo "auto call make gen"

gen-xip:
	@bash ./gen_boot_image.sh ./images/app.s19 0

gen-ram-itcm:
	@bash ./gen_boot_image.sh ./images/app.s19 1

gen-ram-sdram:
	@bash ./gen_boot_image.sh ./images/app.s19 2

srk: ca_private_pkcs1.pem ca_cert.pem index.txt serial
	bash gen_srks.sh

ca_private_pkcs1.pem: ca
	ls ca_private_pkcs1.pem

ca_cert.pem: ca
	ls ca_cert.pem

ca:
	bash gen_ca_cert.sh

index.txt:
	touch index.txt
	echo "unique_subject = no" > index.txt.attr

serial:
	echo "12345678" > serial

hash: srk1_ca.cert.pem srk2_ca.cert.pem srk3_ca.cert.pem srk4_ca.cert.pem
	bash gen_hash.sh
	hd SRK_1_2_3_4_table.bin
	hd SRK_1_2_3_4_fuse.bin

key:
	tar -xvf keys.tar.gz

srk1_ca.cert.pem: srk
	ls srk1_ca.cert.pem

srk2_ca.cert.pem: srk
	ls srk2_ca.cert.pem

srk3_ca.cert.pem: srk
	ls srk3_ca.cert.pem

srk4_ca.cert.pem: srk
	ls srk4_ca.cert.pem

distclean:
	make clean

clean:
	@rm -rf *.bin *.dat *.log
	@echo "clean all output!"
	@rm -rf *.der *.pem *.txt *.attr *.old serial *.bin
	@rm -rf keys input.csf