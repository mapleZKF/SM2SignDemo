//
//  sm2Sign.c
//  SM2
//
//  Created by Better on 2018/6/29.
//  Copyright © 2018年 Better. All rights reserved.
//

#include "sm2Sign.h"


#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "e_os.h"

# include <openssl/bn.h>
# include <openssl/ec.h>
# include <openssl/evp.h>
# include <openssl/rand.h>
# include <openssl/engine.h>
# include <openssl/sm2.h>
# include "sm2_lcl.h"
# include  <ec_lcl.h>
/* 素数p */
#define sm2group_p  "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF"
/* 系数a */
#define sm2group_a  "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC"
/* 系数b */
#define sm2group_b  "28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93"
/* 阶n */
#define sm2group_n  "FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFF7203DF6B21C6052B53BBF40939D54123"
/* 坐标Gx */
#define sm2group_Gx "32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7"
/* 坐标Gy */
#define sm2group_Gy "BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0"


RAND_METHOD fake_rand;
const RAND_METHOD *old_rand;

static const char *rnd_number = NULL;


static int fbytes(unsigned char *buf, int num)
{
    int ret = 0;
    BIGNUM *bn = NULL;
    
    if (!BN_hex2bn(&bn, rnd_number)) {
        goto end;
    }
    if (BN_num_bytes(bn) > num) {
        goto end;
    }
    memset(buf, 0, num);
    if (!BN_bn2bin(bn, buf + num - BN_num_bytes(bn))) {
        goto end;
    }
    ret = 1;
end:
    BN_free(bn);
    return ret;
}

#pragma mark - new ec_group
EC_GROUP *new_ec_group(int is_prime_field,
                       const char *p_hex, const char *a_hex, const char *b_hex,
                       const char *x_hex, const char *y_hex, const char *n_hex, const char *h_hex)
{
    int ok = 0;
    EC_GROUP *group = NULL;
    BN_CTX *ctx = NULL;
    BIGNUM *p = NULL;
    BIGNUM *a = NULL;
    BIGNUM *b = NULL;
    BIGNUM *x = NULL;
    BIGNUM *y = NULL;
    BIGNUM *n = NULL;
    BIGNUM *h = NULL;
    EC_POINT *G = NULL;
    point_conversion_form_t form = SM2_DEFAULT_POINT_CONVERSION_FORM;
    int flag = 0;
    
    if (!(ctx = BN_CTX_new())) {
        goto end;
    }
    
    if (!BN_hex2bn(&p, p_hex) ||
        !BN_hex2bn(&a, a_hex) ||
        !BN_hex2bn(&b, b_hex) ||
        !BN_hex2bn(&x, x_hex) ||
        !BN_hex2bn(&y, y_hex) ||
        !BN_hex2bn(&n, n_hex) ||
        !BN_hex2bn(&h, h_hex)) {
        goto end;
    }
    
    if (is_prime_field) {
        if (!(group = EC_GROUP_new_curve_GFp(p, a, b, ctx))) {
            goto end;
        }
        if (!(G = EC_POINT_new(group))) {
            goto end;
        }
        if (!EC_POINT_set_affine_coordinates_GFp(group, G, x, y, ctx)) {
            goto end;
        }
    } else {
        if (!(group = EC_GROUP_new_curve_GF2m(p, a, b, ctx))) {
            goto end;
        }
        if (!(G = EC_POINT_new(group))) {
            goto end;
        }
        if (!EC_POINT_set_affine_coordinates_GF2m(group, G, x, y, ctx)) {
            goto end;
        }
    }
    
    if (!EC_GROUP_set_generator(group, G, n, h)) {
        goto end;
    }
    
    EC_GROUP_set_asn1_flag(group, flag);
    EC_GROUP_set_point_conversion_form(group, form);
    
    ok = 1;
end:
    BN_CTX_free(ctx);
    BN_free(p);
    BN_free(a);
    BN_free(b);
    BN_free(x);
    BN_free(y);
    BN_free(n);
    BN_free(h);
    EC_POINT_free(G);
    if (!ok && group) {
        ERR_print_errors_fp(stderr);
        EC_GROUP_free(group);
        group = NULL;
    }
    
    return group;
}

static int change_rand(const char *hex)
{
    if (!(old_rand = RAND_get_rand_method())) {
        return 0;
    }
    
    fake_rand.seed        = old_rand->seed;
    fake_rand.cleanup    = old_rand->cleanup;
    fake_rand.add        = old_rand->add;
    fake_rand.status    = old_rand->status;
    fake_rand.bytes        = fbytes;
    fake_rand.pseudorand    = old_rand->bytes;
    
    if (!RAND_set_rand_method(&fake_rand)) {
        return 0;
    }
    
    rnd_number = hex;
    return 1;
}

static int restore_rand(void)
{
    rnd_number = NULL;
    if (!RAND_set_rand_method(old_rand))
        return 0;
    else    return 1;
}

// group 是必选参数
// 附 prive_key_hex 可生成完整的 EC_KEY
// 附 xP 和 yP 可生成缺失 priv_key 的 EC_KEY
EC_KEY *
new_ec_key(const EC_GROUP *group,
           const char *priv_key_hex,
           const char *xP,
           const char *yP)
{
    int ok = 0;
    EC_KEY *ec_key = NULL;
    BIGNUM *d = NULL;
    BIGNUM *x = NULL;
    BIGNUM *y = NULL;
    
    OPENSSL_assert(group);
    OPENSSL_assert(xP);
    OPENSSL_assert(yP);
    
    if (!(ec_key = EC_KEY_new())) {
        goto end;
    }
    if (!EC_KEY_set_group(ec_key, group)) {
        goto end;
    }
    
    if (priv_key_hex) {
        if (!BN_hex2bn(&d, priv_key_hex)) {
            goto end;
        }
        if (!EC_KEY_set_private_key(ec_key, d)) {
            goto end;
        }
    }
    
    if (xP && yP) {
        if (!BN_hex2bn(&x, xP)) {
            goto end;
        }
        if (!BN_hex2bn(&y, yP)) {
            goto end;
        }
        if (!EC_KEY_set_public_key_affine_coordinates(ec_key, x, y)) {
            goto end;
        }
    }
    
    /*
     if (id) {
     if (!SM2_set_id(ec_key, id, id_md)) {
     goto end;
     }
     }
     */
    
    ok = 1;
end:
    if (d) BN_free(d);
    if (x) BN_free(x);
    if (y) BN_free(y);
    if (!ok && ec_key) {
        ERR_print_errors_fp(stderr);
        EC_KEY_free(ec_key);
        ec_key = NULL;
    }
    return ec_key;
}

char *
sm2_sign_hex(const char *priv_key_hex, /* 私钥 hexstring */
             const char *ID,  /* 身份 ID */
             const char *msg_hex_for_sign, /* 待签名消息 */
             const char *rand_seed_k /* 随机数种子 */){
    long msg_len;
    unsigned char *msg_bytes = OPENSSL_hexstr2buf(msg_hex_for_sign, &msg_len);
    const EC_GROUP *group;
    // Create EC_GROUP with params in header
    group = new_ec_group(1, sm2group_p, sm2group_a, sm2group_b, sm2group_Gx, sm2group_Gy, sm2group_n, "1");
    
    EC_KEY *ec_key = NULL;
    
    // EVP digest operators
    const EVP_MD *id_md = EVP_sm3();
    const EVP_MD *msg_md = EVP_sm3();
    
    int type = NID_undef;
    // result of digest
    unsigned char dgst[32];
    size_t dgstlen;
    // result of signature
    unsigned char sig[256];
    unsigned int siglen;
    const unsigned char *psig;
    ECDSA_SIG *sm2sig = NULL;
    const BIGNUM *sig_r;
    const BIGNUM *sig_s;
    char *sm2sigR = NULL;
    char *sm2sigS = NULL;
    static char ret[200];
    
    change_rand(rand_seed_k);
    
    int i = 0;
    
    // create EC_KEY with EC_GROUP and private key
    if (!(ec_key = new_ec_key(group, priv_key_hex, NULL, NULL))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    EC_KEY_print_fp(stdout, ec_key, 4);
    
    // digest
    dgstlen = sizeof(dgst);
    if (!SM2_compute_message_digest(id_md, msg_md,
                                    msg_bytes,
                                    (size_t)msg_len, ID, strlen(ID),
                                    dgst, &dgstlen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    
    // print digest
//    printf("id=%s\n", ID);
    printf("digest:");
    for (i = 0; i < dgstlen; i++) { printf("%02x", dgst[i]); }
    printf("\n");
    
    
    // sign
    siglen = sizeof(sig);
    if (!SM2_sign(type, dgst, (int)dgstlen, sig, &siglen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    psig = sig;
    if (!(sm2sig = d2i_ECDSA_SIG(NULL, &psig, siglen))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    
    ECDSA_SIG_get0(sm2sig, &sig_r, &sig_s);

    
    sm2sigR = BN_bn2hex(sig_r);
    sm2sigS = BN_bn2hex(sig_s);
    
    strcpy(ret, sm2sigR);
    strcat(ret, sm2sigS);
    
end:
    restore_rand();
    free (msg_bytes);
    if (ec_key) EC_KEY_free(ec_key);
    if (sm2sig) ECDSA_SIG_free(sm2sig);
    if (sm2sigR) OPENSSL_free(sm2sigR);
    if (sm2sigS) OPENSSL_free(sm2sigS);
    return ret;
}

char *sm2_sign(const char *priv_key_hex, /* 私钥 hexstring */
         const char *xP,
         const char *yP,
         const char *ID,  /* 身份 ID */
         const char *msg_for_sign, /* 待签名消息 */
         const char *rand_seed_k /* 随机数种子 */)
{
    const EC_GROUP *group;
    // Create EC_GROUP with params in header
    group = new_ec_group(1, sm2group_p, sm2group_a, sm2group_b, sm2group_Gx, sm2group_Gy, sm2group_n, "1");

    EC_KEY *ec_key = NULL;
    
    // EVP digest operators
    const EVP_MD *id_md = EVP_sm3();
    const EVP_MD *msg_md = EVP_sm3();
    
    int type = NID_undef;
    // result of digest
    unsigned char dgst[32];
    size_t dgstlen;
    // result of signature
    unsigned char sig[256];
    unsigned int siglen;
    const unsigned char *psig;
    ECDSA_SIG *sm2sig = NULL;
    const BIGNUM *sig_r;
    const BIGNUM *sig_s;
    char *sm2sigR = NULL;
    char *sm2sigS = NULL;
    static char ret[200];
    
    change_rand(rand_seed_k);
    
    int i = 0;
    
    // create EC_KEY with EC_GROUP and private key
    if (!(ec_key = new_ec_key(group, priv_key_hex, xP, yP))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
//    EC_KEY_print_fp(stdout, ec_key, 4);
  
    dgstlen = sizeof(dgst);
    
    // digest
    dgstlen = sizeof(dgst);
    if (!SM2_compute_message_digest(id_md, msg_md,
                                    (const unsigned char *)msg_for_sign,
                                    strlen(msg_for_sign), ID, strlen(ID),
                                    dgst, &dgstlen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    // print digest
    printf("id=%s\n", ID);
    printf("digest:");
    for (i = 0; i < dgstlen; i++) { printf("%02x", dgst[i]); }
    printf("\n");

    
    // sign
    siglen = sizeof(sig);
    if (!SM2_sign(type, dgst, (int)dgstlen, sig, &siglen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    psig = sig;
    if (!(sm2sig = d2i_ECDSA_SIG(NULL, &psig, siglen))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto end;
    }
    
    
    ECDSA_SIG_get0(sm2sig, &sig_r, &sig_s);
    
    sm2sigR = BN_bn2hex(sig_r);
    sm2sigS = BN_bn2hex(sig_s);
    
    strcpy(ret, sm2sigR);
    strcat(ret, sm2sigS);

end:
    restore_rand();
    if (ec_key) EC_KEY_free(ec_key);
    if (sm2sig) ECDSA_SIG_free(sm2sig);
    if (sm2sigR) OPENSSL_free(sm2sigR);
    if (sm2sigS) OPENSSL_free(sm2sigS);
    return ret;
}
char *JZYT_sm2_verify(const EC_GROUP *group,
                    const char *sk, const char *xP, const char *yP,
                    const char *id,const char *M,unsigned char sig[256],unsigned int siglen)
{
    int ret = 0;
//    int verbose = VERBOSE;
    const EVP_MD *id_md = EVP_sm3();
    const EVP_MD *msg_md = EVP_sm3();
    int type = NID_undef;
    unsigned char dgst[EVP_MAX_MD_SIZE];
    size_t dgstlen;
    const unsigned char *p;
    EC_KEY *ec_key = NULL;
    EC_KEY *pubkey = NULL;
    ECDSA_SIG *sm2sig = NULL;
    BIGNUM *rr = NULL;
    BIGNUM *ss = NULL;
    const BIGNUM *sig_r;
    const BIGNUM *sig_s;
    group = new_ec_group(1, sm2group_p, sm2group_a, sm2group_b, sm2group_Gx, sm2group_Gy, sm2group_n, "1");
    if (!(ec_key = new_ec_key(group, NULL, xP, yP))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        
    }
    
//    if (verbose > 1) {
//        EC_KEY_print_fp(stdout, ec_key, 4);
//    }
    
    dgstlen = sizeof(dgst);
    
    if (!SM2_compute_id_digest(id_md, id, strlen(id), dgst, &dgstlen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto err;
    }
    
//
//    if (verbose > 1) {
//        int j;
//        printf("id=%s\n", id);
//        printf("zid(xx):");
//        for (j = 0; j < dgstlen; j++) { printf("%02x", dgst[j]); } printf("\n");
//    }
    
    //    if (!hexequbin(Z, dgst, dgstlen)) {
    //        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
    //        goto err;
    //    }
    
    dgstlen = sizeof(dgst);
    if (!SM2_compute_message_digest(id_md, msg_md,
                                    (const unsigned char *)M, strlen(M), id, strlen(id),
                                    dgst, &dgstlen, ec_key)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        
    }
    printf("dgst = ");
    for (int i = 0; i<dgstlen; i++)
    {
        if (i %4 ==0)
        {
            printf(" ");
        }
        printf("%02x", dgst[i]);
        
    }
    printf("\n");
    
    /* verify */
    if (!(pubkey = new_ec_key(group, NULL, xP, yP))) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto err;
    }
    
    if (1 != SM2_verify(type, dgst, dgstlen, sig, siglen, pubkey)) {
        fprintf(stderr, "error: %s %d\n", __FUNCTION__, __LINE__);
        goto err;
    }
    
    ret = 1;
err:
    restore_rand();
    
    if (pubkey) EC_KEY_free(pubkey);
    if (sm2sig) ECDSA_SIG_free(sm2sig);
    if (rr) BN_free(rr);
    if (ss) BN_free(ss);
    return ret;
}

int JZYT_sm2_dgst(const EC_GROUP *group,
                  const char *sk, const char *xP, const char *yP,
                  const char *id, const char *Z,
                  const char *M, const char *e,
                  const char *k, const char *r, const char *s)
{
//    int verbose = VERBOSE;
    const EVP_MD *id_md = EVP_sm3();
    const EVP_MD *msg_md = EVP_sm3();
    unsigned char dgst[EVP_MAX_MD_SIZE];
    size_t dgstlen;
    EC_KEY *ec_key = NULL;
    
    change_rand(k);
    
    
err:
    restore_rand();
    
    return 1;
}
