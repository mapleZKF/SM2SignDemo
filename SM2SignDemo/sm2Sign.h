//
//  sm2Sign.h
//  SM2
//
//  Created by Better on 2018/6/29.
//  Copyright © 2018年 Better. All rights reserved.
//

#ifndef sm2Sign_h
#define sm2Sign_h
#include <openssl/ec.h>

//char * sm2_sign( const char *sk, const char *xP, const char *yP,
//                const char *ID, const char *M,  const char *k,
//                int M_len);

char *sm2_sign(const char *priv_key_hex, /* 私钥 hexstring */
               const char *xP,
               const char *yP,
               const char *ID,  /* 身份 ID */
               const char *msg_for_sign, /* 待签名消息 */
               const char *rand_seed_k /* 随机数种子 */);
char *JZYT_sm2_verify(const EC_GROUP *group,
                    const char *sk, const char *xP, const char *yP,
                    const char *id,const char *M,unsigned char sig[256],unsigned int siglen);
#endif /* sm2Sign_h */
