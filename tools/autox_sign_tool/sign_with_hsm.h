#ifndef _SIGN_WITH_HSM
#define _SIGN_WITH_HSM

#include <stdint.h>
#include <stddef.h>

int32_t sign_with_hsm(const char *file_to_sign,
                      const char *ca_cert,
                      const char *ssl_cert,
                      const char *ssl_key,
                      const char *url,
                      const char *signature_name);
int32_t sign_with_hsm_file_buffer(const char *file_to_sign,
                                  const char *ca_cert,
                                  const char *ssl_cert,
                                  const char *ssl_key,
                                  const char *url,
                                  uint8_t *o_buffer,
                                  size_t *o_len);
int32_t sign_with_hsm_buffer(const char *ca_cert,
                             const char *ssl_cert,
                             const char *ssl_key,
                             const char *url,
                             uint8_t *i_buffer,
                             size_t i_len,
                             uint8_t *o_buffer,
                             size_t *o_len);

#endif /* _SIGN_WITH_HSM */