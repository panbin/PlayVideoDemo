//
//  BTVideoPlayerKit.h
//  PlayVideoDemo
//
//  Created by panbin on 13-12-5.
//  Copyright (c) 2013年 Handpay. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kVideoPlayerVideoChangedNotification;
extern NSString * const kVideoPlayerWillHideControlsNotification;
extern NSString * const kVideoPlayerWillShowControlsNotification;
extern NSString * const kTrackEventVideoStart;
extern NSString * const kTrackEventVideoLiveStart;
extern NSString * const kTrackEventVideoComplete;

@protocol BTVideoPlayerKitDelegate <NSObject>

@optional
@property (nonatomic) BOOL fullScreenToggled;
- (void)trackEvent:(NSString *)event videoID:(NSString *)videoID title:(NSString *)title;

@end

@protocol BTVideoPlayerKit <NSObject>

@property (readonly, strong) NSDictionary *currentVideoInfo;
@property (nonatomic, assign) id <BTVideoPlayerKitDelegate> delegate;
@property (readonly) BOOL fullScreenModeToggled;
@property (nonatomic) BOOL showStaticEndTime;
@property (nonatomic) BOOL allowPortraitFullscreen;

@property (nonatomic, readonly) BOOL isPlaying;

- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen;
- (void)showCannotFetchStreamError;

- (void)launchFullScreen;
- (void)minimizeVideo;
- (void)playPauseHandler;

@end
