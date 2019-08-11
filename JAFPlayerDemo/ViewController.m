//
//  ViewController.m
//  JAFPlayerDemo
//
//  Created by SuperPanda_Jamfer on 2019/8/10.
//  Copyright © 2019 SuperPanda_Jamfer. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

#import <KSPhotoBrowser/KSPhotoBrowser.h>

#import "JAFPlayer/JAFPlayerViewController.h"

#import "MediaViewController.h"

#import "JAFPlayer/JAFPlayerCacheManager.h"

@interface ViewController ()
@property (nonatomic, strong) UIImageView* imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 200)];
    iv.backgroundColor = [UIColor grayColor];
    iv.userInteractionEnabled = YES;
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(touchTap)];
    tap.numberOfTouchesRequired = 1;
    [iv addGestureRecognizer:tap];
    [self.view addSubview:iv];
    
    self.imageView = iv;
    iv.image = [UIImage imageNamed:@"test.jpg"];
    
    UIImage* newImage = [self getVideoThumbnailWithUrl:[NSURL URLWithString:@"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4"] second:1];
    iv.frame = CGRectMake(20, 100, 200, 200*(newImage.size.height/newImage.size.width));
    iv.image = newImage;
}

-(void)touchTap{
    
//    KSPhotoItem* item = [KSPhotoItem itemWithSourceView:self.imageView image:self.imageView.image];
//    KSPhotoBrowser* brow = [KSPhotoBrowser browserWithPhotoItems:@[item] selectedIndex:0];
//    brow.dismissalStyle = KSPhotoBrowserInteractiveDismissalStyleScale;
//    brow.backgroundStyle = KSPhotoBrowserBackgroundStyleBlack;
//    [brow showFromViewController:self];
//    return;
    
    //NSString* url = @"https://vodsoumffti.vod.126.net/vodsoumffti/8OFMJoHV_2524060764_hd.mp4";
    //NSString* url = @"http://aliuwmp3.changba.com/userdata/video/45F6BD5E445E4C029C33DC5901307461.mp4";
    NSString* url = @"https://mtest.getech.cn/hebe/app/oss/pull/52699997accc2046999e15a26ce58d24.mp4";
    JAFPlayerViewController* vc = [JAFPlayerViewController playerWithVideoUrl:url SourceImageView:self.imageView];
    [vc showFromViewController:self];
    
//    NSString *URLString = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
//    NSURL *URL = [KTVHTTPCache proxyURLWithOriginalURL:[NSURL URLWithString:URLString]];
//    NSLog(@"看看:\n==============\n%@\n=====================\n%@",url,URL.absoluteString);
//    MediaViewController *vc = [[MediaViewController alloc] initWithURLString:URL.absoluteString];
//    [self presentViewController:vc animated:YES completion:nil];
}

#define k_THUMBNAIL_IMG_WIDTH  100//缩略图及cell大小
#define k_FPS 1//一秒想取多少帧

- (UIImage*)getVideoThumbnailWithUrl:(NSURL*)videoUrl second:(CGFloat)second
{
    if (!videoUrl)
    {
        return nil;
    }
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:videoUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    BOOL getThumbnail = YES;
    if (getThumbnail)
    {
        CGFloat width = [UIScreen mainScreen].scale * k_THUMBNAIL_IMG_WIDTH;
        imageGenerator.maximumSize =  CGSizeMake(width, width);
    }
    NSError *error = nil;
    CMTime time = CMTimeMake(second,k_FPS);
    CMTime actucalTime;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
    if (error) {
    }
    CMTimeShow(actucalTime);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}
@end
