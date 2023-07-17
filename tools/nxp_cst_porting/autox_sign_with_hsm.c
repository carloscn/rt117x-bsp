#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>
#include "autox_sign_with_hsm.h"

#define LOG_INFO printf("[HSM_LIB] "); printf
#define LINE_MAX_BUFFER_SIZE 1024

static int32_t run_external_command(const char *cmd,
                                    char lines[][LINE_MAX_BUFFER_SIZE],
                                    size_t *line_num)
{
    int32_t ret = 0;
    FILE *fp = NULL;
    char path[LINE_MAX_BUFFER_SIZE];

    if (NULL == cmd) {
        LOG_INFO("input error!\n");
        ret = -1;
        goto finish;
    }

    fp = popen(cmd, "r");
    if (NULL == fp) {
        LOG_INFO("popen error!\n");
        ret = -1;
        goto finish;
    }

    LOG_INFO("Run : \n %s\n", cmd);

    if (lines != NULL) {
        size_t cnt = 0;
        while (fgets(path, sizeof(path), fp) != NULL) {
            strcpy(lines[cnt], path);
            cnt ++;
        }
        if (line_num != NULL) {
            *line_num = cnt;
        }
    }

finish:
    if (fp != NULL) {
        pclose(fp);
    }
    return ret;
}

static int32_t read_binary_all(const char *filename, uint8_t *buffer, size_t *o_len)
{
    int32_t ret = 0;
    struct stat info;
    FILE *fp = NULL;

    if (stat(filename, &info) != 0) {
        ret = -1;
        goto finish;
    }

    fp = fopen(filename, "rb");
    if (fp == NULL) {
        ret = -1;
        goto finish;
    }

    /* Try to read a single block of info.st_size bytes */
    size_t blocks_read = fread(buffer, info.st_size, 1, fp);
    if (blocks_read != 1) {
        ret = -1;
        goto finish;
    }

    *o_len = info.st_size;

finish:

    if (fp != NULL) fclose(fp);
    return ret;
}

static int32_t write_binary_all(const char *filename, uint8_t *buffer, size_t o_len)
{
    int32_t ret = 0;
    FILE *fp = NULL;

    fp = fopen(filename, "wb+");
    if (fp == NULL) {
        ret = -1;
        goto finish;
    }

    size_t blocks_write = fwrite(buffer, o_len, 1, fp);
    if (blocks_write != 1) {
        ret = -1;
        goto finish;
    }

finish:
    if (fp != NULL) fclose(fp);
    return ret;
}

int32_t autox_sign_with_hsm(const char *file_to_sign,
                            const char *ca_cert,
                            const char *ssl_cert,
                            const char *ssl_key,
                            const char *url,
                            const char *signature_name)
{
    int32_t ret = 0;

    if (NULL == file_to_sign ||
        NULL == ca_cert ||
        NULL == ssl_cert ||
        NULL == ssl_key ||
        NULL == url ||
        NULL == signature_name) {
        LOG_INFO("input invalid!\n");
        ret = -1;
        goto finish;
    }

    char cmd[2048] = {0};
    char output[100][LINE_MAX_BUFFER_SIZE];

    sprintf(cmd,
            "curl \"%s\" \\\n"
            "   --silent \\\n"
            "   --cacert \"%s\" \\\n"
            "   --request POST \\\n"
            "   --output \"%s\" \\\n"
            "   --header \"Content-Type: multipart/form-data\" \\\n"
            "   --cert %s \\\n"
            "   --key %s \\\n"
            "   --form \"file=@%s\" ",
            url,
            ca_cert,
            signature_name,
            ssl_cert,
            ssl_key,
            file_to_sign
    );

    size_t line_count = 0;
    ret = run_external_command(cmd, output, &line_count);
    if (ret != 0) {
        LOG_INFO("Call run cmd failed.\n cmd: %s\n", cmd);
        goto finish;
    }

    for (size_t i = 0; i < line_count; ++ i) {
        LOG_INFO("%s", output[i]);
    }

finish:
    return ret;
}

int32_t autox_sign_with_hsm_file_buffer(const char *file_to_sign,
                                        const char *ca_cert,
                                        const char *ssl_cert,
                                        const char *ssl_key,
                                        const char *url,
                                        uint8_t *o_buffer,
                                        size_t *o_len)
{
    int32_t ret = 0;
    const char *out_name = "temp_buffer.out";

    if (NULL == o_buffer ||
        NULL == o_len) {
        ret = -1;
        LOG_INFO("input invalid!\n");
        goto finish;
    }

    ret = autox_sign_with_hsm(file_to_sign,
                              ca_cert,
                              ssl_cert,
                              ssl_key,
                              url,
                              out_name);
    if (ret != 0) {
        LOG_INFO("call sign_with_hsm failed\n");
        goto finish;
    }

    ret = read_binary_all(out_name, o_buffer, o_len);
    if (ret != 0) {
        LOG_INFO("call read binary all failed\n");
        goto finish;
    }

    ret = remove(out_name);
    if (ret != 0) {
        LOG_INFO("call remove file %s failed\n", out_name);
        goto finish;
    }

finish:
    return ret;
}

int32_t autox_sign_with_hsm_buffer(const char *ca_cert,
                                   const char *ssl_cert,
                                   const char *ssl_key,
                                   const char *url,
                                   uint8_t *i_buffer,
                                   size_t i_len,
                                   uint8_t *o_buffer,
                                   size_t *o_len)
{
    int32_t ret = 0;
    const char *in_name = "temp_buffer_in.bin";

    if (NULL == i_buffer ||
        0 == i_len) {
        LOG_INFO("input invalid!\n");
        ret = -1;
        goto finish;
    }

    ret = write_binary_all(in_name, i_buffer, i_len);
    if (ret != 0) {
        LOG_INFO("write signature buffer failed\n");
        goto finish;
    }

    ret = autox_sign_with_hsm_file_buffer(in_name,
                                          ca_cert,
                                          ssl_cert,
                                          ssl_key,
                                          url,
                                          o_buffer,
                                          o_len);
    if (ret != 0) {
        LOG_INFO("call sign_with_hsm_file_buffer failed\n");
        goto finish;
    }

    ret = remove(in_name);
    if (ret != 0) {
        LOG_INFO("call remove temp failed\n");
        goto finish;
    }

finish:
    return ret;
}

int32_t autox_download_root_ca(const char *url,
                               const char *outname)
{
    int32_t ret = 0;
    char cmd[1024] = {0};

    if (NULL == url ||
        NULL == outname) {
        ret = -1;
        LOG_INFO("invalid input\n");
        goto finish;
    }

    sprintf(cmd,
            "curl \\\n"
            "   -sk \"%s\" \\\n"
            "   -o \"%s\" \n",
            url,
            outname
    );

    ret = run_external_command(cmd, NULL, NULL);
    if (ret != 0) {
        ret = -1;
        LOG_INFO("run_external_command %s failed!\n", cmd);
        goto finish;
    }

finish:
    return ret;
}