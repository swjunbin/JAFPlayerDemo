//
//  JAFPlayerCacheManager.h
//  JAFPlayerDemo
//
//  Created by SuperPanda_Jamfer on 2019/8/11.
//  Copyright © 2019 SuperPanda_Jamfer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KTVHTTPCache/KTVHTTPCache.h>

@interface JAFPlayerCacheManager : NSObject
//非流媒体缓存地址
@property (nonatomic, copy) NSString* localVideoPath;
//流媒体缓存，地址在document
@property (nonatomic, strong) NSArray<KTVHCDataCacheItem *> *allCacheItems;

+(JAFPlayerCacheManager*)shareManager;

/**
 *清除所有缓存;
 */
-(void)removeAllCache;
/**
 *单位为bit;
 *iOS计算单位以1000进制而非1024;
 *获取时尽量在子线程调用;
 */
-(long long)getCacheSizeLength;

/**
 *流媒体类视频的缓存操作;
 *@param urlString 流媒体地址,解析方法调用本地服务器自动缓存跟踪并且转换;
 */
-(NSURL*)proxyUrl:(NSString*)urlString;

/**
 *通过URL检索Document/JAFVideoCache下是否有命名相同的视频文件;
 *@param httpUrl 视频文件Http地址;
 */
-(NSString*)fetchVideoCachePathByHTTPUrl:(NSString*)httpUrl;
@end
