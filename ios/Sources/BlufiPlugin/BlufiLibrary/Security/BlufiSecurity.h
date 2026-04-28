#ifndef BlufiSecurity_h
#define BlufiSecurity_h

//
//  BlufiSecurity.h
//  EspBlufi
//
//  Created by AE on 2020/6/9.
//  Copyright © 2020 espressif. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>
#import "BlufiDH.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlufiSecurity : NSObject

+ (NSInteger)crc:(NSInteger)crc data:(NSData *)data;

+ (NSInteger)crc:(NSInteger)crc buf:(Byte *)buf length:(NSInteger)length;

+ (NSData *)md5:(NSData *)data;

+ (NSData *)sha256:(NSData *)data;

+ (NSData *)aesEncrypt:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

+ (NSData *)aesDecrypt:(NSData *)data key:(NSData *)key iv:(NSData *)iv;

+ (CCCryptorRef)createAESCTRCryptor:(CCOperation)op key:(NSData *)key iv:(NSData *)iv;

+ (NSData *)cryptorUpdate:(CCCryptorRef)cryptor data:(NSData *)data;

+ (BlufiDH *)dhGenerateKeys;

+ (BlufiDH *)dhGenerateKeys3072;

@end

NS_ASSUME_NONNULL_END

#endif
