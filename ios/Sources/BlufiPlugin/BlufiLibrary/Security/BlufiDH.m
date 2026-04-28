//
//  BlufiDH.m
//  EspBlufi
//
//  Created by AE on 2020/6/10.
//  Copyright © 2020 espressif. All rights reserved.
//

#import "BlufiDH.h"

@implementation BlufiDH

- (instancetype)initWithP:(NSData *)p G:(NSData *)g PublicKey:(NSData *)publicKey PrivateKey:(NSData *)privateKey DH:(nonnull DH *)dh keySize:(NSInteger)keySize {
    self = [super init];
    if (self) {
        _p = p;
        _g = g;
        _publicKey = publicKey;
        _privateKey = privateKey;
        _dh = dh;
        _keySize = keySize;
    }
    return self;
}

- (NSData *)generateSecret:(NSData *)srcPublicKey {
    if (!_dh) {
        NSLog(@"BlufiDH: DH is nil");
        return nil;
    }
    NSInteger keySize = _keySize > 0 ? _keySize : 128;
    Byte *shareKey = malloc(keySize);
    BIGNUM *pubKey = BN_bin2bn(srcPublicKey.bytes, (int)srcPublicKey.length, NULL);
    int ret = 0;
    while (!ret) {
        ret = DH_compute_key(shareKey, pubKey, _dh);
    }
    BN_free(pubKey);

    int offset = 0;
    for (int i = 0; i < keySize; i++) {
        if (shareKey[i] == 0) {
            offset++;
        } else {
            break;
        }
    }

    NSData *result;
    if (offset == 0) {
        result = [NSData dataWithBytes:shareKey length:keySize];
    } else {
        result = [NSData dataWithBytes:shareKey + offset length:keySize - offset];
    }
    free(shareKey);
    return result;
}

- (void)releaseDH {
    if (_dh) {
        DH_free(_dh);
        _dh = nil;
    }
}

@end
