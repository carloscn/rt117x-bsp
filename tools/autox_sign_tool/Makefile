.PHONY: clean

SOURCE = $(wildcard *.c)
TARGET = sign_hsm.elf
LD =

$(TARGET):
	$(CC) -o $@ $(SOURCE) $(LD)

clean:
	$(RM) -rf ${TARGET} *.o

distclean:
	make clean
	$(RM) -rf *.key *.crt *.csr *.txt *.bin *.cert *.out

keys:
	curl -sk https://dev.ca.autox.tech/ejbca/publicweb/webdist/certdist\?cmd\=cachain\&caid\=-238079556\&format\=pem -o ca.cert
	tar -xvf certs.tar.gz

sign: ${TARGET}
	echo "hello" > hello.txt
	./${TARGET} "https://dev.xsec-gateway.autox.tech/v1/signServer/cms/sign" \
	            "ca.cert" \
	            "sign_server.crt" \
	            "sign_server.key" \
	            "hello.txt" \
	            "sign.out"

