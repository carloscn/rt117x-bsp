#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <sys/stat.h>

#define LOG_INFO printf("[HSM_LIB] "); printf
#define LINE_MAX_BUFFER_SIZE 255

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

#define DUMP_WIDTH 16
static void bio_dump(const char *s, int len)
{
    char buf[160+1] = {0};
    char tmp[20] = {0};
    unsigned char ch;
    int32_t i, j, rows;

#ifdef TRUNCATE
    int32_t trunc = 0;
    for(; (len > 0) && ((s[len-1] == ' ') || (s[len-1] == '\0')); len--)
        trunc++;
#endif

    rows = (len / DUMP_WIDTH);
    if ((rows * DUMP_WIDTH) < len)
        rows ++;
    for (i = 0; i < rows; i ++) {
        /* start with empty string */
        buf[0] = '\0';
        sprintf(tmp, "%04x - ", i * DUMP_WIDTH);
        strcpy(buf, tmp);
        for (j = 0; j < DUMP_WIDTH; j ++) {
            if (((i * DUMP_WIDTH) + j) >= len) {
                strcat(buf,"   ");
            } else {
                ch = ((unsigned char)*(s + i * DUMP_WIDTH + j)) & 0xff;
                sprintf(tmp, "%02x%c" , ch, j == 7 ? '-':' ');
                strcat(buf, tmp);
            }
        }
        strcat(buf, "  ");
        for(j = 0;j < DUMP_WIDTH;j ++) {
            if (((i * DUMP_WIDTH) + j) >= len)
                break;
            ch = ((unsigned char)*(s + i * DUMP_WIDTH + j)) & 0xff;
            sprintf(tmp, "%c", ((ch >= ' ')&&(ch <= '~')) ? ch : '.');
            strcat(buf, tmp);
        }
        strcat(buf, "\n");
        printf("%s", buf);
    }
#ifdef TRUNCATE
    if (trunc > 0) {
        sprintf(buf,"%04x - <SPACES/NULS>\n",len+trunc);
        printf("%s", buf);
    }
#endif
}

static void print_array(uint8_t *buffer, size_t len, char* msg)
{
    printf("\n");
    printf("%s: the len is %zu\n", msg, len);
    bio_dump((const char *)buffer, len);
    printf("\n");
}

int32_t sign_with_hsm(const char *file_to_sign,
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

int32_t sign_with_hsm_file_buffer(const char *file_to_sign,
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

    ret = sign_with_hsm(file_to_sign,
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

int32_t sign_with_hsm_buffer(const char *ca_cert,
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

    ret = sign_with_hsm_file_buffer(in_name,
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
