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
@property (nonatomic, strong) NSArray<KTVHCDataCacheItem *> *allCacheItems;
+(id)shareManager;
-(NSURL*)proxyUrl:(NSString*)urlString;
-(void)removeAllCache;
/* 单位为bit */
-(long long)getCacheSizeLength;
@end
