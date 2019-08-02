//
//  SM2SignMessage.m
//  WXQRCode
//
//  Created by Better on 2018/7/3.
//  Copyright © 2018年 Weconex. All rights reserved.
//

#import "SM2SignMessage.h"
#import "sm2Sign.h"

#define sm2_K @"6CB28D99385C175C94F94E934817663FC176D925DD72B727260DBAAE1FB2F96F"

@interface SM2SignMessage (){
    unsigned int _outlen;
    unsigned char _result[256];
}

@property (nonatomic, copy, readwrite) NSString *resultRS;

@end

@implementation SM2SignMessage

- (sm2SignStatus)sM2Sign
{
    if (!self.skString) return sm2SignError_skEmpty;
    
    if (!self.IDString) return sm2SignError_IDEmpty;
    
    if (!self.Message) return sm2SignError_MessageEmpty;
    
    
    const char *sk = [self.skString UTF8String];
    const char *ID = [self.IDString UTF8String];
    const char *M  = [self.Message UTF8String];
    
    const char *k  =  (self.k) ? [self.k UTF8String] : [sm2_K UTF8String];
    NSString  *px = [self.pubString substringToIndex:64];
    
    NSString  *py = [self.pubString substringFromIndex:64];
    char *ret = sm2_sign(sk,[px cStringUsingEncoding:NSUTF8StringEncoding],[py cStringUsingEncoding:NSUTF8StringEncoding], ID, M, k);
   
    NSString *result = [NSString stringWithFormat:@"%s",ret];
    
    if (![result isEqualToString:@"fail"]) {
        
        self.resultRS = result;
        return sm2Sign_Success;
    }
    return sm2SignFail;
}
- (NSInteger )checkSign{
    NSString *str = @"1234567890";
    
    NSString *uid = @"vcard@ibuscloud.com";

    
    NSString *pub = @"3429AE135F0B3F49532572064DE1BBE365511C56D6669A526F70A93EAF8A5384B14AE028C575D30AF3AB015DD0D35EF17C522B0D07D300DA77010BED9525DB1A";
    NSString *pri = @"92B76BD2A46CE80804E1910D7680536475A053F5ED4F408123ED8086412CD211";
    NSString  *px = [pub substringToIndex:64];
    
    NSString  *py = [pub substringFromIndex:64];
 NSInteger i = JZYT_sm2_verify(nil,
                    "",
                    [px cStringUsingEncoding:NSUTF8StringEncoding],
                    [py cStringUsingEncoding:NSUTF8StringEncoding],
                               [uid cStringUsingEncoding:NSUTF8StringEncoding], [str cStringUsingEncoding:NSUTF8StringEncoding], _result,_outlen);
    return i;
}
@end
