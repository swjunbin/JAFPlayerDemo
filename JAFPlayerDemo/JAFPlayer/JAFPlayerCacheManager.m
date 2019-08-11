//
//  JAFPlayerCacheManager.m
//  JAFPlayerDemo
//
//  Created by SuperPanda_Jamfer on 2019/8/11.
//  Copyright © 2019 SuperPanda_Jamfer. All rights reserved.
//

#import "JAFPlayerCacheManager.h"

@interface JAFPlayerCacheManager()
@end

@implementation JAFPlayerCacheManager
+(id)shareManager{
    static JAFPlayerCacheManager* _manager = nil;
    static dispatch_once_t _onceToken;
    
    if(!_manager){
        dispatch_once(&_onceToken, ^{
            _manager = [[super allocWithZone:nil] init];
            [_manager setupHTTPCache];
        });
    }
    return _manager;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [JAFPlayerCacheManager shareManager];
}

- (id)copyWithZone:(NSZone *)zone {
    return [JAFPlayerCacheManager shareManager];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [JAFPlayerCacheManager shareManager];
}

- (void)setupHTTPCache
{
    [KTVHTTPCache logSetConsoleLogEnable:YES];
    NSError *error = nil;
    [KTVHTTPCache proxyStart:&error];
    if (error) {
        NSLog(@"Proxy Start Failure, %@", error);
    } else {
        NSLog(@"Proxy Start Success");
    }
    [KTVHTTPCache encodeSetURLConverter:^NSURL *(NSURL *URL) {
        NSLog(@"URL Filter reviced URL : %@", URL);
        return URL;
    }];
    [KTVHTTPCache downloadSetUnacceptableContentTypeDisposer:^BOOL(NSURL *URL, NSString *contentType) {
        NSLog(@"Unsupport Content-Type Filter reviced URL : %@, %@", URL, contentType);
        return NO;
    }];
}

-(NSURL*)proxyUrl:(NSString*)urlString{
    NSString *URLString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURL *URL = [KTVHTTPCache proxyURLWithOriginalURL:[NSURL URLWithString:URLString]];
    return URL;
}

-(void)removeAllCache{
    [KTVHTTPCache cacheDeleteAllCaches];
}

-(long long)getCacheSizeLength{
    long long sizelength = 0;
    for(KTVHCDataCacheItem* item in self.allCacheItems){
        for(KTVHCDataCacheItemZone* zone in item.zones){
            sizelength += zone.length;
        }
    }
    return sizelength;
}

#pragma mark - setter&&getter
-(NSArray<KTVHCDataCacheItem *> *)allCacheItems{
    return [KTVHTTPCache cacheAllCacheItems];
}
@end
