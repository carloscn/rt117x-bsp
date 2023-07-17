
#include <stdio.h>
#include "sign_with_hsm.h"

#define LOG_INFO printf("[HSM_TOOL] "); printf

static void print_usage()
{
    LOG_INFO("Usage:\n\n");
    printf("./sign_hsm.elf \"https://dev.xxxxx.tech/v1/signServer/cms/sign\" \\"); printf("\n");
    printf("               \"ca.cert\"          \\"); printf("\n");
    printf("               \"sign_server.crt\"  \\"); printf("\n");
    printf("               \"sign_server.key\"  \\"); printf("\n");
    printf("               \"hello.txt\"        \\"); printf("\n");
    printf("               \"sign.out\""); printf("\n");
    LOG_INFO("Exit!\n");
}

int32_t main(int args, char *argv[])
{
    int32_t ret = 0;

    if (args < 7) {
        LOG_INFO("input parameter invalid!\n");
        print_usage();
        ret = -1;
        goto finish;
    }

    for (size_t i = 0; i < args; i ++) {
        if (NULL == argv[i]) {
            LOG_INFO("input parameter invalid!\n");
            print_usage();
            ret = -1;
            goto finish;
        }
    }

    const char *file_to_sign    = argv[5];
    const char *ca_cert         = argv[2];
    const char *ssl_cert        = argv[3];
    const char *ssl_key         = argv[4];
    const char *url             = argv[1];
    const char *signature_name  = argv[6];

    LOG_INFO("Sign Request:\n\n");
    LOG_INFO("> file_to_sign      : %s\n",  file_to_sign);
    LOG_INFO("> ca_cert           : %s\n",  ca_cert);
    LOG_INFO("> ssl_cert          : %s\n",  ssl_cert);
    LOG_INFO("> ssl_key           : %s\n",  ssl_key);
    LOG_INFO("> url               : %s\n",  url);
    LOG_INFO("> signature_name    : %s\n",  signature_name);
    LOG_INFO("\n");

    ret = sign_with_hsm(file_to_sign,
                        ca_cert,
                        ssl_cert,
                        ssl_key,
                        url,
                        signature_name);
    if (ret != 0) {
        LOG_INFO("sign error!\n");
        goto finish;
    }

    LOG_INFO("HSM sign finished!\n");

finish:
    return ret;
}