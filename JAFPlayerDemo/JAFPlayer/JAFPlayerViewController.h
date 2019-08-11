//
//  ZFNoramlViewController.h
//  ZFPlayer
//
//  Created by Jamfer on 2019/8/11.
//  Copyright © 2019年 Jamfer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JAFPlayerViewController : UIViewController
+(JAFPlayerViewController*)playerWithVideoUrl:(NSString*)url SourceImageView:(UIImageView*)sourceView;
-(void)showFromViewController:(UIViewController*)vc;
@end

