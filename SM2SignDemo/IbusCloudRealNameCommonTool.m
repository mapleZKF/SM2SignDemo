//
//  IbusCloudRealNameCommonTool.m
//  ibusCloudBusCodeBase
//
//  Created by GJY on 2019/4/4.
//

#import "IbusCloudRealNameCommonTool.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCrypto.h>
#import "RSA.h"
#import "NEUBase64.h"
#import "NSData+NEUAES.h"

#define Iv          @"sa6aUdPr78xmX4pK" //偏移量,可自行修改
#define KEY         @"sa6aUdPr78xmX4pK" //key，可自行修改
@implementation IbusCloudRealNameCommonTool

+ (UIImage *)imageWithName:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"ibusCloudRealName.bundle/%@", imageName]];
    
    return image;
}

+ (UIImage *)imageWithColor:(UIColor*)color
{
    
    CGRect rect=CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    
    CGContextFillRect(context, rect);
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return theImage;
}


/**
 *从图片中按指定的位置大小截取图片的一部分
 * UIImage image 原始的图片
 * CGRect rect 要截取的区域
 */
+(UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect{
    
    //将UIImage转换成CGImageRef
    CGImageRef sourceImageRef = [image CGImage];
    
    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    
    //将CGImageRef转换成UIImage
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    //返回剪裁后的图片
    return newImage;
}

/**
 *将图片缩放到指定的CGSize大小
 * UIImage image 原始的图片
 * CGSize size 要缩放到的大小
 */
+ (UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size{
    
    // 得到图片上下文，指定绘制范围
    UIGraphicsBeginImageContext(size);
    
    // 将图片按照指定大小绘制
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    // 从当前图片上下文中导出图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 当前图片上下文出栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

/** 放大并裁剪多余部分，类似UIImageView的UIViewContentModeScaleAspectFill模式 */
+ (UIImage*)scaleAspectFillImage:(UIImage *)image scaleToSize:(CGSize)size{
    
    CGFloat imgW = image.size.width;
    CGFloat imgH = image.size.height;
    CGFloat width = size.width / imgW * size.height;
    CGFloat height = 0;
    CGFloat x = 0;
    CGFloat y = 0;
    
    if (imgW / imgH > size.width / size.height) {
        
        width = size.height / imgH * imgW;
        height = size.height;
        x = (size.width - width) * 0.5;
    }else{
        
        width = size.width;
        height = width / imgW * imgH;
        y = (size.height - height) * 0.5;
    }
    
    // 得到图片上下文，指定绘制范围
    UIGraphicsBeginImageContext(size);
    
    // 将图片按照指定大小绘制
    [image drawInRect:CGRectMake(x, y, width, height)];
    
    // 从当前图片上下文中导出图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 当前图片上下文出栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}



/** 图片旋转 */
+ (UIImage*)rotateImage:(UIImage *)image rotate:(CGFloat)rotate
{
    
//    long double rotate = 0.0;
    float translateX = 0;
    float translateY = 0;
    rotate = M_PI_2;
    CGRect rect = CGRectMake(0, 0, image.size.height, image.size.width);
    translateX = 0;
    translateY = -rect.size.width;

    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformRotate(transform, -M_PI_2);
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, 0, -rect.size.width);
    
    // 将图片按照指定大小绘制
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    // 从当前图片上下文中导出图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 当前图片上下文出栈
    UIGraphicsEndImageContext();
    return scaledImage;
}


/**
 *  压缩图片
 *
 *  @param image       被压缩图片
 *  @param maxFileSize 压缩后尺寸
 *
 */
+ (UIImage *)compressImage:(UIImage *)image toSize:(CGSize)imageSize toMaxFileSize:(NSInteger)maxFileSize
{
    
    CGFloat scaleX = imageSize.width / image.size.width;
    CGFloat scaleY = imageSize.height / image.size.height;
    CGFloat scale = 1;
    
    if (scaleX > scaleY) {
        scale = scaleX;
    }else{
        scale = scaleY;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scale, image.size.height * scale));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat compression = 0.9f;
    CGFloat maxCompression = 0.1f;
    
    NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
    
    while ([imageData length] > maxFileSize && compression > maxCompression) {
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(image, compression);
    }
    
    UIImage *compressedImage = [UIImage imageWithData:imageData];
    return compressedImage;
}


#pragma mark - /** 找到window的底部根视图 */
+ (UIViewController *)getRootViewController {
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    if (window.windowLevel != UIWindowLevelNormal) {
        
        NSArray *windowArray = [[UIApplication sharedApplication] windows];
        for (UIWindow *tempWin in windowArray) {
            if (tempWin.windowLevel == UIWindowLevelNormal) {
                window = tempWin;
                break;
            }
        }
    }
    
    UIViewController *result = nil;
    id  nextResponder = nil;
    UIViewController *appRootVC=window.rootViewController;
    //    如果是present上来的appRootVC.presentedViewController 不为nil
    if (appRootVC.presentedViewController) {
        nextResponder = appRootVC.presentedViewController;
    }else{
        UIView *frontView = [[window subviews] objectAtIndex:0];
        nextResponder = [frontView nextResponder];
    }
    
    if ([nextResponder isKindOfClass:[UITabBarController class]]){
        UITabBarController * tabbar = (UITabBarController *)nextResponder;
        UINavigationController * nav = (UINavigationController *)tabbar.viewControllers[tabbar.selectedIndex];
        //        UINavigationController * nav = tabbar.selectedViewController ; 上下两种写法都行
        result=nav.childViewControllers.lastObject;
        
    }else if ([nextResponder isKindOfClass:[UINavigationController class]]){
        UIViewController * nav = (UIViewController *)nextResponder;
        result = nav.childViewControllers.lastObject;
    }else{
        result = nextResponder;
    }
    
    return (UIViewController *)result;
}
#pragma mark ========= 图片转base64 =========
+ (NSString *)base64StringWithImage:(UIImage *)image {
    NSData *data = UIImageJPEGRepresentation(image, 1.0);
    NSLog(@"图片大小: %.2f MB",data.length /1000.0 /1000.0);
    
    NSString *code = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSMutableString *mutStr = [NSMutableString stringWithString:code];
    //    NSRange range = {0, jsonString.length};
    
    //去掉字符串中的空格
    //    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    NSRange range3 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\r" withString:@"" options:NSLiteralSearch range:range3];
    return [mutStr copy];

}
#pragma mark ========= 加签方法 =========
+ (NSString *)getSignWithDict:(NSDictionary *)dict key: (NSString *)key {
    
    NSArray *keyArray = dict.allKeys;
    NSArray *sorKeyArray = [keyArray sortedArrayUsingComparator:^NSComparisonResult(NSString   * _Nonnull obj1, NSString   * _Nonnull obj2) {
        
        return [obj1 compare:obj2];
    }];
    
    NSMutableString *signStr = [NSMutableString string];
    NSString *signKey = [NSString string];
    for (int i = 0; i < sorKeyArray.count; i++) {
        
        NSString *signal = @"&";
        if (i == sorKeyArray.count - 1) {
            signal = @"";
        }
        NSString *key = sorKeyArray[i];
        if ([dict[key] isKindOfClass:[NSDictionary class]]) {
            
            NSString *encodeStr = [self encodeToPercentEscapeString:[self convertToJsonForNoBlackData:dict[key]]];
            [signStr appendFormat:@"%@=%@%@", key, encodeStr, signal];
        }else{
            NSString *encodeStr = [self encodeToPercentEscapeString:dict[key]];

            [signStr appendFormat:@"%@=%@%@", key, encodeStr, signal];
        }
        if ([key isEqualToString:@"token"]) {
            //截取token后16位
            NSString *value = dict[key];
            if (value.length > 16) {
                signKey = [value substringFromIndex:value.length - 16];
            }
        }
    }
    // 整体需要再encode一下
    signStr = [NSMutableString stringWithString:[self encodeToPercentEscapeString:signStr]];
    NSRange range1 = {0,signStr.length};
    [signStr replaceOccurrencesOfString:@"+" withString:@"%20" options:NSLiteralSearch range:range1];
    NSRange range2 = {0,signStr.length};
    [signStr replaceOccurrencesOfString:@"*" withString:@"%2A" options:NSLiteralSearch range:range2];
    NSRange range3 = {0,signStr.length};
    [signStr replaceOccurrencesOfString:@"%7E" withString:@"~" options:NSLiteralSearch range:range3];
    
    
    return [self hmacSHA256WithSecret:signKey content:signStr];

}
#pragma mark ========= 字典转字符串 =========
+ (NSString *)convertToJsonData:(id )dict {

    NSError *error;
    // NSJSONWritingSortedKeys这个枚举类型只适用iOS11所以我是使用下面写法解决的  不设置则输出的json字符串就是一整行,没有空格和换行。
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    NSString *jsonString;
    if (!jsonData) {
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
//    NSString *version = [UIDevice currentDevice].systemVersion;
//    if (version.doubleValue >= 11.0) {
//        NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
//        NSRange range = {0, jsonString.length};
//        //去掉字符串中的空格
//        [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
//        NSRange range2 = {0,mutStr.length};
//        //去掉字符串中的换行符
//        [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
//        NSRange range3 = {0,mutStr.length};
//        [mutStr replaceOccurrencesOfString:@"\r" withString:@"" options:NSLiteralSearch range:range3];
//        return mutStr;
//    }
    return jsonString;
}

+ (NSString *)convertToJsonForNoBlackData:(id )dict {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    NSString *jsonString;
    
    if (!jsonData) {
        
        NSLog(@"%@",error);
    }else{
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];
    NSRange range = {0, jsonString.length};
    
    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
    NSRange range2 = {0,mutStr.length};
    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];
    NSRange range3 = {0,mutStr.length};
    [mutStr replaceOccurrencesOfString:@"\r" withString:@"" options:NSLiteralSearch range:range3];
    
    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"#%-*+=_\\|~(＜＞$%^&*)_+ "];
    NSString * hmutStr = [[mutStr componentsSeparatedByCharactersInSet: doNotWant]componentsJoinedByString: @""];
    
    NSLog(@"humStr is %@",hmutStr);
    
    return hmutStr;
}

#pragma mark ========= 字符串转字典 =========
+ (NSDictionary *)convertToDict:(NSString *)str {
    
    if (![str isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSData *data =[str dataUsingEncoding:NSUTF8StringEncoding];
    id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    return jsonData;
}
#pragma mark ========= 签名时的加密方法 =========
+ (NSString *)hmacSHA256WithSecret:(NSString *)secret content:(NSString *)content {
    
//    const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
//    const char *cData = [content cStringUsingEncoding:NSUTF8StringEncoding];// 有可能有中文 所以用NSUTF8StringEncoding -> NSASCIIStringEncoding
//    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
//    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
//    NSData *HMACData = [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
//    const unsigned char *buffer = (const unsigned char *)[HMACData bytes];
//    NSMutableString *HMAC = [NSMutableString stringWithCapacity:HMACData.length * 2];
//    for (int i = 0; i < HMACData.length; ++i){
//        [HMAC appendFormat:@"%02x", buffer[i]];
//    }
//    return HMAC;
//    NSData *data = [content dataUsingEncoding:NSUTF8StringEncoding];
    const char *cKey = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [content cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
//    NSString *s= [self encodeBase64Data:hash];
    NSString* s = [self base64forData:hash];
    return s;
}
+ (NSString*)base64forData:(NSData *)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {  value |= (0xFF & input[j]);  }  }  NSInteger theIndex = (i / 3) * 4;  output[theIndex + 0] = table[(value >> 18) & 0x3F];
        output[theIndex + 1] = table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
}
/** rsa2签名 */
+ (NSString *)rsa2WithSecret:(NSString *)secret content:(NSString *)content {
    
    NSData *outData = [content dataUsingEncoding:NSUTF8StringEncoding];
    // test
    // sha256加密
    SecKeyRef key = [RSA addPrivateKey:secret];
    
    size_t signedHashBytesSize = SecKeyGetBlockSize(key);
    uint8_t* signedHashBytes = malloc(signedHashBytesSize);
    memset(signedHashBytes, 0x0, signedHashBytesSize);
    
    size_t hashBytesSize = CC_SHA256_DIGEST_LENGTH;
    uint8_t* hashBytes = malloc(hashBytesSize);
    if (!CC_SHA256([outData bytes], (CC_LONG)[outData length], hashBytes)) {
        return nil;
    }
    SecKeyRawSign(key,
                  kSecPaddingPKCS1SHA256,
                  hashBytes,
                  hashBytesSize,
                  signedHashBytes,
                  &signedHashBytesSize);
    NSData* signedHash = [NSData dataWithBytes:signedHashBytes length:(NSUInteger)signedHashBytesSize];
    if (hashBytes)
        free(hashBytes);
    if (signedHashBytes)
        free(signedHashBytes);
    NSString *signString = [signedHash base64EncodedStringWithOptions:NSUTF8StringEncoding];
    NSLog(@"%@",signString);
    
    return signString;
    
}



#pragma mark ========= 二进制加密 =========
+ (NSData *)encryptDataWithData:(NSData *)data Key:(NSString *)key{
    
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(key) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          NULL,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesEncrypted);
    
    if(cryptStatus == kCCSuccess){
        
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}
#pragma mark ========= 二进制解密 =========
+ (NSData *)decryptDataWithData:(NSData *)data andKey:(NSString *)key{
    
    char keyPtr[kCCKeySizeAES128 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyPtr, kCCBlockSizeAES128, NULL, [data bytes], dataLength, buffer, bufferSize, &numBytesDecrypted);
    
    if(cryptStatus == kCCSuccess)
    {
        
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}
#pragma mark ========= 字符串加密 =========
+ (NSString *)encryptStringWithString:(NSString *)string andKey:(NSString *)key{
    
    const char *cStr = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cStr length:[string length]];
    
    //对数据进行加密
    NSData *result = [self encryptDataWithData:data Key:key];
    
    //转换为2进制字符串
    if(result && result.length > 0)
    {
        
        Byte *datas = (Byte *)[result bytes];
        NSMutableString *outPut = [NSMutableString stringWithCapacity:result.length];
        for(int i = 0 ; i < result.length ; i++){
            
            [outPut appendFormat:@"%02x",datas[i]];
        }
        return outPut;
    }
    return nil;
}
#pragma mark ========= 字符串解密 =========
+ (NSString *)decryptStringWithString:(NSString *)string andKey:(NSString *)key{
    
    NSMutableData *data = [NSMutableData dataWithCapacity:string.length/2.0];
    unsigned char whole_bytes;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for(i = 0 ; i < [string length]/2 ; i++){
        
        byte_chars[0] = [string characterAtIndex:i * 2];
        byte_chars[1] = [string characterAtIndex:i * 2 + 1];
        whole_bytes = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_bytes length:1];
    }
    
    NSData *result = [self decryptDataWithData:data andKey:key];
    if(result && result.length > 0){
        
        return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    return nil;
}


//加密
+ (NSString *)encodeToPercentEscapeString:(NSString *)input
{
    
    NSString *outputStr = (__bridge NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, /* allocator */(__bridge CFStringRef)input,NULL, /* charactersToLeaveUnescaped */(CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8);
    return outputStr;
}

//解码
+ (NSString *)decodeFromPercentEscapeString:(NSString *)input
{
    NSMutableString *outputStr = [NSMutableString stringWithString:input];
    [outputStr replaceOccurrencesOfString:@"+"withString:@""options:NSLiteralSearch range:NSMakeRange(0,[outputStr length])];
    return[outputStr stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
}

#pragma mark - base64
+ (NSString*)encodeBase64String:(NSString * )input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    data = [NEUBase64 encodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
    
}

+ (NSString*)decodeBase64String:(NSString * )input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    data = [NEUBase64 decodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
}

+ (NSString*)encodeBase64Data:(NSData *)data {
    data = [NEUBase64 encodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
}

+ (NSString*)decodeBase64Data:(NSData *)data {
    data = [NEUBase64 decodeData:data];
    NSString *base64String = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return base64String;
}

#pragma mark - AES加密
//将string转成带密码的data
+(NSString*)neu_encryptAESData:(NSString*)string
{
    //将nsstring转化为nsdata
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    //使用密码对nsdata进行加密
    NSData *encryptedData = [data AES128EncryptWithKey:KEY gIv:Iv];
    //返回进行base64进行转码的加密字符串
    NSString *encryStr =[self encodeBase64Data:encryptedData];
    return encryStr;
}

#pragma mark - AES解密
//将带密码的data转成string
+(NSString*)neu_decryptAESData:(NSString *)string
{
    //base64解密
    NSData *decodeBase64Data=[NEUBase64 decodeString:string];
    //使用密码对data进行解密
    NSData *decryData = [decodeBase64Data AES128DecryptWithKey:KEY gIv:Iv];
    //将解了密码的nsdata转化为nsstring
    NSString *str = [[NSString alloc] initWithData:decryData encoding:NSUTF8StringEncoding];
    return str;
}


@end
