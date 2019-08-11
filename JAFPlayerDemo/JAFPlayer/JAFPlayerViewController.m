//
//  JAFPlayerViewController.m
//  ZFPlayer
//
//  Created by Jamfer on 2019/8/11.
//  Copyright © 2019年 Jamfer. All rights reserved.
//

#import "JAFPlayerViewController.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import <ZFPlayer/ZFPlayerControlView.h>
#import "UIImageView+ZFCache.h"
#import "ZFUtilities.h"
#import "JAFPlayerCacheManager.h"
#import <AFNetworking/AFNetworking.h>
#import "SDProgress/SDTransparentPieProgressView.h"

#define iPhoneX_DEVICE      (ScreenHeight==812.0?YES:NO)
#define SafeBottom          (iPhoneX_DEVICE?34:0)
#define SafeTop             (iPhoneX_DEVICE?24:0)
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

typedef NS_ENUM(NSInteger, ConverDownloadTag) {
    ConverDownloadEnd,
    ConverDownloadIng
};

@interface JAFPlayerViewController (){
    
    NSURLSessionDownloadTask *_downloadTask;
    
}

@property (nonatomic, strong) UIImageView* sourceView;
@property (nonatomic, strong) UIImage* placeHolderImage;
@property (nonatomic, assign) CGPoint startLocation;
@property (nonatomic, assign) CGRect startFrame;
@property (nonatomic, strong) SDTransparentPieProgressView* progressView;

@property (nonatomic, strong) UIView* backColorView;
@property (nonatomic, strong) UIView* playContentView;
@property (nonatomic, strong) ZFPlayerController *player;
@property (nonatomic, strong) UIImageView *containerView;
@property (nonatomic, strong) ZFPlayerControlView *controlView;
@property (nonatomic, strong) UIButton* playBtn;
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, assign) BOOL noPlayToolHiddenStatu;
@property (nonatomic, strong) UIButton *proCloseBtn;//视频stop后显示的关闭按钮
@property (nonatomic, strong) NSArray <NSURL *>*assetURLs;

@property (nonatomic, copy) NSString* sourceUrl;
@property (nonatomic, strong) NSURL* videoUrl;

/* 转为下载路径的标识，NO代表可以转为下载路径 */
@property (nonatomic, assign) ConverDownloadTag converDownloadTag;

@end

@implementation JAFPlayerViewController

#pragma mark - init

+(JAFPlayerViewController*)playerWithVideoUrl:(NSString*)videoUrl SourceImageView:(UIImageView*)sourceView{
    return [[JAFPlayerViewController alloc] initWithVideoUrl:videoUrl SourceImageView:sourceView];
}

-(id)initWithVideoUrl:(NSString*)videoUrl SourceImageView:(UIImageView*)sourceView{
    self = [super init];
    if(self){
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        if([videoUrl containsString:@"http"]){
            if([[JAFPlayerCacheManager shareManager] fetchVideoCachePathByHTTPUrl:videoUrl]){
                //文件下载类型缓存下的本地路径
                self.videoUrl = [NSURL URLWithString:[[JAFPlayerCacheManager shareManager] fetchVideoCachePathByHTTPUrl:videoUrl]];
            }else{
                //流媒体播放地址 或 待下载的文件类型播放地址
                self.videoUrl = [[JAFPlayerCacheManager shareManager] proxyUrl:videoUrl];
            }
        }else{
            //本地路径播放地址
            if([videoUrl containsString:@"file://"]){
                self.videoUrl = [NSURL URLWithString:videoUrl];
            }else{
                if([[videoUrl substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"/"]){
                    self.videoUrl = [NSURL URLWithString:[@"file://" stringByAppendingString:videoUrl]];
                }else{
                    self.videoUrl = [NSURL URLWithString:[@"file:///" stringByAppendingString:videoUrl]];
                }
            }
        }
        self.sourceUrl = videoUrl;
        self.sourceView = sourceView;
        self.placeHolderImage = sourceView.image;
        self.converDownloadTag = ConverDownloadEnd;
    }
    return self;
}

-(void)showFromViewController:(UIViewController*)vc{
    [vc presentViewController:self animated:NO completion:nil];
}

#pragma mark - implementation

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self buildPalyerUI];
    
    //kvo add failBtn
    [self.controlView.failBtn addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)dealloc{
    [self.controlView.failBtn removeObserver:self forKeyPath:@"hidden"];
    if(_downloadTask) [_downloadTask cancel];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player.viewControllerDisappear = NO;
    
    [self viewShowAnimated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.player.viewControllerDisappear = YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGFloat x = 0;
    CGFloat y = 64+SafeTop;
    CGFloat w = ScreenWidth;
    CGFloat h = ScreenHeight-SafeBottom-49-64-SafeTop;
    self.containerView.frame = CGRectMake(x, y, w, h);
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.player.isFullScreen) {
        return UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden {
    /// 如果只是支持iOS9+ 那直接return NO即可，这里为了适配iOS8
    return self.player.isStatusBarHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (BOOL)shouldAutorotate {
    return self.player.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (self.player.isFullScreen) {
        return UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - observerNoti

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"hidden"] && object == self.controlView.failBtn){
        BOOL hiddenValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if(hiddenValue == NO){
            //进入下载的方式
            [self downloadVideoFile];
        }
    }
}

#pragma mark - BuildPlayer

-(void)buildPalyerUI{
    [self.view addSubview:self.backColorView];
    [self.view addSubview:self.playContentView];
    
    [self.playContentView addSubview:self.containerView];
    [self.playContentView addSubview:self.playBtn];
    [self.controlView.portraitControlView.topToolView addSubview:self.closeBtn];
    [self.playContentView addSubview:self.proCloseBtn];
    
    ZFAVPlayerManager *playerManager = [[ZFAVPlayerManager alloc] init];
    /// 播放器相关
    self.player = [ZFPlayerController playerWithPlayerManager:playerManager containerView:self.containerView];
    self.player.controlView = self.controlView;
    /// 设置退到后台继续播放
    self.player.pauseWhenAppResignActive = NO;
    
    @weakify(self)
    self.player.orientationWillChange = ^(ZFPlayerController * _Nonnull player, BOOL isFullScreen) {
        @strongify(self)
        [self setNeedsStatusBarAppearanceUpdate];
    };
    
    // 播放完成
    self.player.playerDidToEnd = ^(id  _Nonnull asset) {
        @strongify(self)
        [self.player stop];
        self.noPlayToolHiddenStatu = NO;
    };
    
    self.player.assetURLs = self.assetURLs;
    [self.controlView showTitle:@"" coverImage:[UIImage new] fullScreenMode:ZFFullScreenModeAutomatic];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.controlView addGestureRecognizer:pan];
    
    UIPanGestureRecognizer *pan_content = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.playContentView addGestureRecognizer:pan_content];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.controlView.backgroundColor = [UIColor clearColor];
    
}
/* 将当前播放路径转化为本地路径,检测到缓存时调用该方法 */
-(void)resetVideoPathToLocalPath:(NSString*)localPath{
    self.progressView.hidden = YES;
    self.noPlayToolHiddenStatu = YES;
    self.sourceUrl = localPath;
    self.videoUrl = [NSURL URLWithString:localPath];
    self.assetURLs = @[self.videoUrl];
    self.player.assetURLs = self.assetURLs;
    [self.player playTheIndex:0];
}

#pragma mark - Animation

-(void)viewShowAnimated{
    
    if(!self.sourceView){
        [UIView animateWithDuration:.3 animations:^{
            self.backColorView.alpha = 1.0;
            self.playContentView.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self.player playTheIndex:0];
        }];
        
        return;
    }
    
    CGRect sourceRect;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [self.sourceView.superview convertRect:self.sourceView.frame toCoordinateSpace:self.view];
    } else {
        sourceRect = [self.sourceView.superview convertRect:self.sourceView.frame toView:self.view];
    }
    
    CGRect endRect;
    endRect.origin.x = 0;
    endRect.size.width = ScreenWidth;
    endRect.size.height = ScreenWidth*(self.sourceView.frame.size.height/self.sourceView.frame.size.width);
    endRect.origin.y = (ScreenHeight-endRect.size.height)/2.0;
    
    UIImageView* tempSourceView = [[UIImageView alloc] initWithFrame:sourceRect];
    tempSourceView.image = self.sourceView.image;
    tempSourceView.clipsToBounds = self.sourceView.clipsToBounds;
    tempSourceView.layer.cornerRadius = self.sourceView.layer.cornerRadius;
    tempSourceView.contentMode = self.sourceView.contentMode;
    [self.view addSubview:tempSourceView];
    
    [UIView animateWithDuration:.3 animations:^{
        self.backColorView.alpha = 1.0;
        tempSourceView.frame = endRect;
        self.sourceView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [tempSourceView removeFromSuperview];
        self.playContentView.alpha = 1.0f;
        [self.player playTheIndex:0];
    }];
}

-(void)dismissAnimated{
    self.noPlayToolHiddenStatu = YES;
    if(self.player){
        [self.player stop];
    }
    if(!self.sourceView){
        [UIView animateWithDuration:.3 animations:^{
            self.backColorView.alpha = 0.0f;
            self.playContentView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
        return;
    }
    
    CGRect sourceRect;
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0 && systemVersion < 9.0) {
        sourceRect = [self.sourceView.superview convertRect:self.sourceView.frame toCoordinateSpace:self.view];
    } else {
        sourceRect = [self.sourceView.superview convertRect:self.sourceView.frame toView:self.view];
    }
    self.noPlayToolHiddenStatu = YES;
    if(self.player){
        [self.player stop];
    }
    [UIView animateWithDuration:.3 animations:^{
        self.backColorView.alpha = 0.0f;
        self.containerView.frame = sourceRect;
        if(!self.progressView.hidden)self.progressView.center = CGPointMake(sourceRect.size.width/2.0, sourceRect.size.height/2.0);
    } completion:^(BOOL finished) {
        self.sourceView.alpha = 1.0f;
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

-(void)showCancellationAnimation{
    CGFloat x = 0;
    CGFloat y = 64+SafeTop;
    CGFloat w = ScreenWidth;
    CGFloat h = ScreenHeight-SafeBottom-49-64-SafeTop;
    CGRect endRect = CGRectMake(x, y, w, h);
    
    [UIView animateWithDuration:.3 animations:^{
        self.containerView.frame = endRect;
        if(!self.progressView.hidden)self.progressView.center = CGPointMake(endRect.size.width/2.0, endRect.size.height/2.0);
        self.backColorView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        if(self.player.currentPlayerManager.playState == ZFPlayerPlayStatePlayStopped){
            self.noPlayToolHiddenStatu = NO;
        }
        if(self.converDownloadTag == ConverDownloadIng){
            self.proCloseBtn.hidden = NO;
            self.playBtn.hidden = YES;
        }
    }];
    
}

#pragma mark - setter && getter

-(void)setNoPlayToolHiddenStatu:(BOOL)noPlayToolHiddenStatu{
    _noPlayToolHiddenStatu = noPlayToolHiddenStatu;
    self.proCloseBtn.hidden = _noPlayToolHiddenStatu;
    self.playBtn.hidden = _noPlayToolHiddenStatu;
}

#pragma mark - Action

-(void)dismissSelf{
    [self dismissAnimated];
}

-(void)playeAction{
    self.noPlayToolHiddenStatu = YES;
    [self.player playTheIndex:0];
    [self.controlView showTitle:@"" coverImage:[UIImage new] fullScreenMode:ZFFullScreenModeAutomatic];
}

-(void)didPan:(UIPanGestureRecognizer*)pan{
    
    if(self.player.isFullScreen){
        return;
    }
    
    CGPoint point = [pan translationInView:self.view];
    CGPoint location = [pan locationInView:self.playContentView];
    CGPoint velocity = [pan velocityInView:self.view];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
            _startLocation = location;
            self.startFrame = self.containerView.frame;
            self.noPlayToolHiddenStatu = YES;
            break;
        case UIGestureRecognizerStateChanged: {
            double percent = 1 - fabs(point.y) / self.view.frame.size.height;
            double s = MAX(percent, 0.3);
            
            CGFloat width = self.startFrame.size.width * s;
            CGFloat height = self.startFrame.size.height * s;
            
            CGFloat rateX = (_startLocation.x - self.startFrame.origin.x) / self.startFrame.size.width;
            CGFloat x = location.x - width * rateX;
            
            CGFloat rateY = (_startLocation.y - self.startFrame.origin.y) / self.startFrame.size.height;
            CGFloat y = location.y - height * rateY;
            
            self.containerView.frame = CGRectMake(x, y, width, height);
            if(!self.progressView.hidden)self.progressView.center = CGPointMake(width/2.0, height/2.0);
            
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:percent];
            self.backColorView.alpha = percent;
        }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (fabs(point.y) > 100 || fabs(velocity.y) > 500) {
                [self dismissSelf];
            } else {
                [self showCancellationAnimation];
            }
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Download

-(void)downloadVideoFile{
    if(self.converDownloadTag == ConverDownloadIng || _downloadTask){
        return;
    }
    self.converDownloadTag = ConverDownloadIng;
    [self.player stop];
    self.proCloseBtn.hidden = NO;
    self.playBtn.hidden = YES;
    self.progressView.hidden = NO;
    
    NSURL *URL = [NSURL URLWithString:self.sourceUrl];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    _downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
        });
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *videoPath = [JAFPlayerCacheManager shareManager].localVideoPath;
        NSString *path = [videoPath stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        //设置下载完成操作
        dispatch_async(dispatch_get_main_queue(), ^{
            self.converDownloadTag = ConverDownloadEnd;
            [self resetVideoPathToLocalPath:filePath.absoluteString];
        });
    }];
    [_downloadTask resume];
}


#pragma mark - lazyload

-(UIView *)backColorView{
    if(!_backColorView){
        _backColorView = [[UIView alloc] initWithFrame:self.view.bounds];
        _backColorView.backgroundColor = [UIColor blackColor];
        _backColorView.alpha = 0.0f;
    }
    return _backColorView;
}

-(UIView *)playContentView{
    if(!_playContentView){
        _playContentView = [[UIView alloc] initWithFrame:self.view.bounds];
        _playContentView.backgroundColor = [UIColor clearColor];
        _playContentView.alpha = 0.0f;
    }
    return _playContentView;
}

- (ZFPlayerControlView *)controlView {
    if (!_controlView) {
        _controlView = [ZFPlayerControlView new];
        _controlView.fastViewAnimated = YES;
        _controlView.autoHiddenTimeInterval = 4;
        _controlView.autoFadeTimeInterval = 0.25;
        _controlView.prepareShowLoading = YES;
        _controlView.bottomPgrogress.bufferTrackTintColor = [UIColor clearColor];
        _controlView.bottomPgrogress.minimumTrackTintColor = [UIColor clearColor];
        _controlView.effectViewShow = NO;
    }
    return _controlView;
}

- (UIImageView *)containerView {
    if (!_containerView) {
        _containerView = [UIImageView new];
        _containerView.contentMode = UIViewContentModeScaleAspectFit;
        _containerView.clipsToBounds = YES;
        _containerView.image = self.placeHolderImage;
    }
    return _containerView;
}

- (NSArray<NSURL *> *)assetURLs {
    if (!_assetURLs) {
            _assetURLs = @[self.videoUrl];
    }
    return _assetURLs;
}

-(UIButton *)closeBtn{
    if(!_closeBtn){
        _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeBtn.frame = CGRectMake(5, 5, 30, 30);
        [_closeBtn setBackgroundImage:[UIImage imageNamed:@"JAFPlayerClose.png"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

-(UIButton *)proCloseBtn{
    if(!_proCloseBtn){
        _proCloseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _proCloseBtn.frame = CGRectMake(5, 64+SafeTop+5, 30, 30);
        [_proCloseBtn setBackgroundImage:[UIImage imageNamed:@"JAFPlayerClose.png"] forState:UIControlStateNormal];
        [_proCloseBtn addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
        _proCloseBtn.hidden = YES;
    }
    return _proCloseBtn;
}

-(UIButton *)playBtn{
    if(!_playBtn){
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _playBtn.frame = CGRectMake(0, 0, 44, 44);
        _playBtn.center = CGPointMake(ScreenWidth/2.0, ScreenHeight/2.0);
        [_playBtn setImage:[UIImage imageNamed:@"JAFPlayerPlay"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playeAction) forControlEvents:UIControlEventTouchUpInside];
        _playBtn.hidden = YES;
    }
    return _playBtn;
}

-(SDTransparentPieProgressView *)progressView{
    if(!_progressView){
        _progressView = [SDTransparentPieProgressView progressView];
        _progressView.frame = CGRectMake(self.containerView.frame.size.width/2.0-30, self.containerView.frame.size.height/2.0-30, 60, 60);
        _progressView.progress = 0.0f;
        [self.containerView addSubview:_progressView];
        _progressView.hidden = YES;
    }
    return _progressView;
}

@end
