//
//  IbusCloudRealNameCommonTool.h
//  ibusCloudBusCodeBase
//
//  Created by GJY on 2019/4/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface IbusCloudRealNameCommonTool : NSObject

/** 获取当前bundle的图片 */
+ (UIImage *)imageWithName:(NSString *)imageName;

/** 根据颜色生成图片 */
+ (UIImage *)imageWithColor:(UIColor*)color;

/**
 *将图片缩放到指定的CGSize大小
 * UIImage image 原始的图片
 * CGSize size 要缩放到的大小
 */
+ (UIImage*)image:(UIImage *)image scaleToSize:(CGSize)size;

/** 放大并裁剪多余部分，类似UIImageView的UIViewContentModeScaleAspectFill模式 */
+ (UIImage*)scaleAspectFillImage:(UIImage *)image scaleToSize:(CGSize)size;

/**
 *从图片中按指定的位置大小截取图片的一部分
 * UIImage image 原始的图片
 * CGRect rect 要截取的区域
 */
+ (UIImage *)imageFromImage:(UIImage *)image inRect:(CGRect)rect;

/** 图片旋转 */
+ (UIImage*)rotateImage:(UIImage *)image rotate:(CGFloat)rotate;

/**
 *  压缩图片
 *
 *  @param image       被压缩图片
 *  @param maxFileSize 压缩后尺寸
 *
 */
+ (UIImage *)compressImage:(UIImage *)image toSize:(CGSize)imageSize toMaxFileSize:(NSInteger)maxFileSize;

#pragma mark - /** 找到window的底部根视图 */
+ (UIViewController *)getRootViewController;

/*
 *
 图片转base64
@param image 要转的图片
 *
 */

+ (NSString *)base64StringWithImage:(UIImage *)image;

/*
 *
 加签的方法
 @param dict 加签的数据源
 *
 */
+ (NSString *)getSignWithDict:(NSDictionary *)dict key: (NSString *)key;

/*
 *
 字典转字符串的方法（不删掉空格）
 @param dict  转字符串的数据源
 *
 */
+ (NSString *)convertToJsonData:(id )dict;

/*
 *
 字典转字符串的方法（删掉空格）
 @param dict  转字符串的数据源
 *
 */
+ (NSString *)convertToJsonForNoBlackData:(id )dict;

/*
 *
 json串转字典的方法
 @param str  json串
 *
 */
+ (NSDictionary *)convertToDict:(NSString *)str;

/*
 *
 签名时的加密方法
 @param secret  加密的secret
 @param content 加密的m内容
 *
 */
+ (NSString *)hmacSHA256WithSecret:(NSString *)secret content:(NSString *)content;

/*
 *
 AES对二进制加密方法
 @param data 需要加密的二进制数据
 @param key  加密所需的key
 *
 */

+ (NSData *)encryptDataWithData:(NSData *)data Key:(NSString *)key;

/*
 *
 AES对二进制解密方法
 @param data 需要解密密的二进制数据
 @param key  解密所需的key
 *
 */

+ (NSData *)decryptDataWithData:(NSData *)data andKey:(NSString *)key;

/*
 *
 AES对字符串加密方法
 @param string 需要加密的字符串
 @param key  加密所需的key
 *
 */

+ (NSString *)encryptStringWithString:(NSString *)string andKey:(NSString *)key;

/*
 *
 AES对字符串解密方法
 @param data 需要解密密的字符串
 @param key  解密所需的key
 *
 */

+ (NSString *)decryptStringWithString:(NSString *)string andKey:(NSString *)key;

/*
 *
 base64的encode
 @params input 需要转的字符串
 *
 */
+ (NSString*)encodeBase64String:(NSString *)input;
/*
 *
 base64的decode
 @params input 需要转的字符串
 *
 */
+ (NSString*)decodeBase64String:(NSString *)input;
/*
 *
 base64的encode
 @params input 需要转的data
 *
 */
+ (NSString*)encodeBase64Data:(NSData *)data;

/*
 *
 base64的decode
 @params input 需要转的data
 *
 */
+ (NSString*)decodeBase64Data:(NSData *)data;

/*
 *
 AES加密
 @params string 需要加密的字符串
 *
 */
+ (NSString*)neu_encryptAESData:(NSString*)string;
/*
 *
 AES加密
 @params string 需要解密的字符串
 *
 */
+ (NSString*)neu_decryptAESData:(NSString*)string;
@end

NS_ASSUME_NONNULL_END
