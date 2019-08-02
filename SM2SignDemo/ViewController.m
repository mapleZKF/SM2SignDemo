//
//  ViewController.m
//  SM2SignDemo
//
//  Created by Better on 2018/7/13.
//  Copyright © 2018年 Better. All rights reserved.
//

#import "ViewController.h"
#import "SM2SignMessage.h"
#import "IbusCloudRealNameCommonTool.h"
#import "UICKeyChainStore.h"
#import "SAMKeyChain/SAMKeychain.h"
@interface ViewController ()
@property (nonatomic, copy) NSString *signStr;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //SM2椭圆曲线公钥密码算法 第2部分:数字签名算法
    //示例1:Fp -256提供的参数
    SM2SignMessage *sm2Sign = [[SM2SignMessage alloc] init];
    
    sm2Sign.skString = [self HexStringWithData:[self base64Decode:@"krdr0qRs6AgE4ZENdoBTZHWgU/XtT0CBI+2AhkEs0hE="]];

    sm2Sign.IDString = @"vcard@ibuscloud.com";
    
    sm2Sign.Message = @"1234567890";
    NSLog(@"%@",[self ret32bitString]);
    sm2Sign.k = [self ret32bitString];
    NSString *pub = @"NCmuE18LP0lTJXIGTeG742VRHFbWZppSb3CpPq+KU4SxSuAoxXXTCvOrAV3Q017xfFIrDQfTANp3AQvtlSXbGg==";
    sm2Sign.pubString = [self HexStringWithData:[self base64Decode:pub]];
    //加签方法
    [sm2Sign sM2Sign];
    // 我这里是把加签后的R、S合并到一起了，前32位是R、后32位是S
    NSLog(@"加签成功:%@",sm2Sign.resultRS);
    self.signStr = sm2Sign.resultRS;
    [UICKeyChainStore setDefaultService:@"com.ibus.com"];
    [UICKeyChainStore setString:self.signStr forKey:@"sign"];
    [SAMKeychain setPassword:self.signStr forService:@"ibusCloud" account:@"sign"];
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(100, 100, 100, 100)];
    [btn setBackgroundColor:[UIColor redColor]];
    [btn addTarget:self action:@selector(yanqian) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}
- (void)yanqian {
    
//     SM2SignMessage *sm2Sign = [[SM2SignMessage alloc] init];
//    NSLog(@"%ld",(long)[sm2Sign checkSign]);

//    NSLog(@"%@",[UICKeyChainStore stringForKey:@"sign"]);

    
    [SAMKeychain deletePasswordForService:@"com.ibus.com" account:@"sign"];
    NSLog(@"%@",[SAMKeychain passwordForService:@"ibusCloud" account:@"sign"]);
    
}
- (NSString *)transBase64WithString: (NSString *)str{
    //1、先转换成二进制数据
    NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
    //2、对二进制数据进行base64编码，完成后返回字符串
    return [data base64EncodedStringWithOptions:0];
}
//普通字符串转换为十六进制的。

- (NSString *)hexStringFromString:(NSString *)string{
    NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
    Byte *bytes = (Byte *)[myD bytes];
    //下面是Byte 转换为16进制。
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}
-(NSString *)HexStringWithData:(NSData *)data{
    Byte *bytes = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length]==1){
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        }
        else{
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
        }
    }
    hexStr = [hexStr uppercaseString];
    return hexStr;
}
// Base64 2 Data
- (NSData*) base64Decode:(NSString *)string
{
    unsigned long ixtext, lentext;
    unsigned char ch, inbuf[4], outbuf[4];
    short i, ixinbuf;
    Boolean flignore, flendtext = false;
    const unsigned char *tempcstring;
    NSMutableData *theData;
    
    if (string == nil) {
        return [NSData data];
    }
    
    ixtext = 0;
    
    tempcstring = (const unsigned char *)[string UTF8String];
    
    lentext = [string length];
    
    theData = [NSMutableData dataWithCapacity: lentext];
    
    ixinbuf = 0;
    
    while (true) {
        if (ixtext >= lentext){
            break;
        }
        
        ch = tempcstring [ixtext++];
        
        flignore = false;
        
        if ((ch >= 'A') && (ch <= 'Z')) {
            ch = ch - 'A';
        } else if ((ch >= 'a') && (ch <= 'z')) {
            ch = ch - 'a' + 26;
        } else if ((ch >= '0') && (ch <= '9')) {
            ch = ch - '0' + 52;
        } else if (ch == '+') {
            ch = 62;
        } else if (ch == '=') {
            flendtext = true;
        } else if (ch == '/') {
            ch = 63;
        } else {
            flignore = true;
        }
        
        if (!flignore) {
            short ctcharsinbuf = 3;
            Boolean flbreak = false;
            
            if (flendtext) {
                if (ixinbuf == 0) {
                    break;
                }
                
                if ((ixinbuf == 1) || (ixinbuf == 2)) {
                    ctcharsinbuf = 1;
                } else {
                    ctcharsinbuf = 2;
                }
                
                ixinbuf = 3;
                
                flbreak = true;
            }
            
            inbuf [ixinbuf++] = ch;
            
            if (ixinbuf == 4) {
                ixinbuf = 0;
                
                outbuf[0] = (inbuf[0] << 2) | ((inbuf[1] & 0x30) >> 4);
                outbuf[1] = ((inbuf[1] & 0x0F) << 4) | ((inbuf[2] & 0x3C) >> 2);
                outbuf[2] = ((inbuf[2] & 0x03) << 6) | (inbuf[3] & 0x3F);
                
                for (i = 0; i < ctcharsinbuf; i++) {
                    [theData appendBytes: &outbuf[i] length: 1];
                }
            }
            
            if (flbreak) {
                break;
            }
        }
    }
    
    return theData;
}
#pragma mark ========= 获取随机数 =========
- (NSString *)ret32bitString{
    
    NSString *randString = @"";
    for(int i=0;i<16;i++)
    {
        int num = arc4random()%0xFFFF;
        NSString *str = [NSString stringWithFormat:@"%02x", num];
        randString = [NSString stringWithFormat:@"%@%@",randString,str] ;
    }
    
    return randString;
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
