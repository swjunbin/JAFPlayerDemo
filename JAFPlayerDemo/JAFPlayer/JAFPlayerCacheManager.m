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
static JAFPlayerCacheManager* _manager = nil;
static dispatch_once_t _onceToken;
+(JAFPlayerCacheManager*)shareManager{
    
    if(!_manager){
        dispatch_once(&_onceToken, ^{
            _manager = [[super allocWithZone:nil] init];
            [_manager setupHTTPCache];
        });
    }
    return _manager;
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
    [self removeFileCache];
}

-(void)removeFileCache{
    NSError *error=nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray<NSString*>* allVideoNames = [fileManager contentsOfDirectoryAtPath:self.localVideoPath error:&error];
    if(error) return;
    
    for(NSString* videoName in allVideoNames){
        NSString* videoPath = [self.localVideoPath stringByAppendingPathComponent:videoName];
        [fileManager removeItemAtPath:videoPath error:nil];
    }
}

-(long long)getCacheSizeLength{
    long long sizelength = 0;
    for(KTVHCDataCacheItem* item in self.allCacheItems){
        for(KTVHCDataCacheItemZone* zone in item.zones){
            sizelength += zone.length;
        }
    }
    sizelength += [self getFileVideoCacheSize];
    return sizelength;
}

-(long long)getFileVideoCacheSize{
    long long cacheSize = 0;
    NSError *error=nil;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSArray<NSString*>* allVideoNames = [fileManager contentsOfDirectoryAtPath:self.localVideoPath error:&error];
    if(error) return cacheSize;
    
    for(NSString* videoName in allVideoNames){
        NSString* videoPath = [self.localVideoPath stringByAppendingPathComponent:videoName];
        NSDictionary* dic = [fileManager attributesOfItemAtPath:videoPath error:nil];
        cacheSize += [dic[NSFileSize] longLongValue];
    }
    return cacheSize;
}

-(NSString*)fetchVideoCachePathByHTTPUrl:(NSString*)httpUrl{
    NSError *error=nil;
    NSArray<NSString*>* allVideoNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localVideoPath error:&error];
    if(error){
        return nil;
    }
    NSString* httpVideoName = [[NSURL URLWithString:httpUrl] lastPathComponent];
    for(NSString* videoName in allVideoNames){
        if([videoName isEqualToString:httpVideoName]){
            return [@"file://" stringByAppendingString:[self.localVideoPath stringByAppendingPathComponent:videoName]];
        }
    }
    return nil;
}

#pragma mark - setter&&getter
-(NSArray<KTVHCDataCacheItem *> *)allCacheItems{
    return [KTVHTTPCache cacheAllCacheItems];
}

-(NSString *)localVideoPath{
    NSString* path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"JAFVideoCache"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}
@end
