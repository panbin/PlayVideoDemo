//
//  BTVideoPlayerKitViewController.h
//  PlayVideoDemo
//
//  Created by panbin on 13-12-5.
//  Copyright (c) 2013年 Handpay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTVideoButtons.h"
#import "BTVideoPlayerKit.h"

@interface BTVideoPlayerKitViewController : UIViewController {
    BOOL playWhenReady;
    BOOL scrubBuffering;
    BOOL showShareOptions;
}

@property (readwrite, strong) AVPlayer *videoPlayer;
@property (nonatomic, assign) id <BTVideoPlayerKitDelegate> delegate;
@property (nonatomic) BOOL allowPortraitFullscreen;
@property (nonatomic) BOOL showStaticEndTime;


- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen;

@end
