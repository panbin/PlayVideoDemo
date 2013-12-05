//
//  BTVideoPlayerKitViewController.m
//  PlayVideoDemo
//
//  Created by panbin on 13-12-5.
//  Copyright (c) 2013年 Handpay. All rights reserved.
//

#import "BTVideoPlayerKitViewController.h"
#import "FullScreenViewController.h"

NSString * const kVideoPlayerVideoChangedNotification = @"VideoPlayerVideoChangedNotification";
NSString * const kVideoPlayerWillHideControlsNotification = @"VideoPlayerWillHideControlsNotitication";
NSString * const kVideoPlayerWillShowControlsNotification = @"VideoPlayerWillShowControlsNotification";
NSString * const kTrackEventVideoStart = @"Video Start";
NSString * const kTrackEventVideoLiveStart = @"Video Live Start";
NSString * const kTrackEventVideoComplete = @"Video Complete";

@interface BTVideoPlayerKitViewController ()<UIGestureRecognizerDelegate>

@property (readwrite, strong) BTVideoButtons *videoButtons;
@property (readwrite) BOOL restoreVideoPlayStateAfterScrubbing;
@property (readwrite, strong) NSDictionary *currentVideoInfo;
@property (readwrite) BOOL fullScreenModeToggled;
@property (nonatomic) BOOL isAlwaysFullscreen;
@property (nonatomic, readwrite) BOOL isPlaying;
@property (nonatomic, strong) FullScreenViewController *fullscreenViewController;
@property (nonatomic) CGRect previousBounds;
@property (readwrite, strong) id scrubberTimeObserver;
@property (readwrite, strong) id playClockTimeObserver;
@property (readwrite) BOOL seekToZeroBeforePlay;
@property (readwrite) BOOL rotationIsLocked;
@property (readwrite) BOOL playerIsBuffering;


//@property (nonatomic, assign) UIViewController *containingViewController;

@end

@implementation BTVideoPlayerKitViewController

#pragma mark -
#pragma mark Button Clicked

- (void)playPauseHandler
{
    if (_seekToZeroBeforePlay) {
        _seekToZeroBeforePlay = NO;
        [_videoPlayer seekToTime:kCMTimeZero];
    }
    
    if ([self isPlaying]) {
        [_videoPlayer pause];
    } else {
        [self playVideo];
        [[_videoButtons activityIndicator] stopAnimating];
    }
    
    [self syncPlayPauseButtons];
    [self showControls];
}




- (void)fullScreenButtonHandler
{
    [self showControls];
    
    if (self.fullScreenModeToggled) {
        [self minimizeVideo];
    } else {
        [self launchFullScreen];
    }
}


-(void)scrubbingDidBegin
{
    if ([self isPlaying]) {
        [_videoPlayer pause];
        [self syncPlayPauseButtons];
        self.restoreVideoPlayStateAfterScrubbing = YES;
        [self showControls];
    }
}

-(void)scrubberIsScrolling
{
    CMTime playerDuration = [self playerItemDuration];
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(duration * _videoButtons.videoScrubber.value);
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoButtons.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
        
        if (!self.showStaticEndTime) {
            [_videoButtons.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
        } else {
            [_videoButtons.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
        }
        [_videoPlayer seekToTime:CMTimeMakeWithSeconds((float) currentTime, NSEC_PER_SEC)];
    }
}


-(void)scrubbingDidEnd
{
    if (self.restoreVideoPlayStateAfterScrubbing) {
        self.restoreVideoPlayStateAfterScrubbing = NO;
        scrubBuffering = YES;
    }
    [[_videoButtons activityIndicator] startAnimating];
    
    [self showControls];
}

- (void)videoTapHandler
{
    if (_videoButtons.playerControlBar.alpha) {
        [self hideControlsAnimated:YES];
    } else {
        [self showControls];
    }
}

- (void)pinchGesture:(id)sender
{
    if([(UIPinchGestureRecognizer *)sender state] == UIGestureRecognizerStateEnded) {
        [self fullScreenButtonHandler];
    }
}

- (void)loadView {
    [super loadView];
    
    _currentVideoInfo = [[NSDictionary alloc] init];
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    _videoButtons = [[BTVideoButtons alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    _videoButtons.backgroundColor = [UIColor redColor];
    [self.view addSubview:_videoButtons];
    
    
    [_videoButtons.playPauseButton addTarget:self action:@selector(playPauseHandler) forControlEvents:UIControlEventTouchUpInside];
    
    [_videoButtons.fullScreenButton addTarget:self action:@selector(fullScreenButtonHandler) forControlEvents:UIControlEventTouchUpInside];
    
    [_videoButtons.videoScrubber addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_videoButtons.videoScrubber addTarget:self action:@selector(scrubberIsScrolling) forControlEvents:UIControlEventValueChanged];
    [_videoButtons.videoScrubber addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    
    UITapGestureRecognizer *playerTouchedGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoTapHandler)];
    playerTouchedGesture.delegate = self;
    [_videoButtons addGestureRecognizer:playerTouchedGesture];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
    [pinchRecognizer setDelegate:self];
    [self.view addGestureRecognizer:pinchRecognizer];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.fullScreenModeToggled) {
        BOOL isHidingPlayerControls = self.videoButtons.playerControlBar.alpha == 0;
        [[UIApplication sharedApplication] setStatusBarHidden:isHidingPlayerControls withAnimation:UIStatusBarAnimationNone];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

#pragma makr -
#pragma mark Play Videos

- (void)playVideoWithTitle:(NSString *)title URL:(NSURL *)url videoID:(NSString *)videoID shareURL:(NSURL *)shareURL isStreaming:(BOOL)streaming playInFullScreen:(BOOL)playInFullScreen
{
    [self.videoPlayer pause];
    
    [[_videoButtons activityIndicator] startAnimating];
    // Reset the buffer bar back to 0
    [self.videoButtons.progressView setProgress:0 animated:NO];
    [self showControls];
    
    NSString *vidID = videoID ?: @"";
    _currentVideoInfo = @{ @"title": title ?: @"", @"videoID": vidID, @"isStreaming": @(streaming), @"shareURL": shareURL ?: url};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerVideoChangedNotification
                                                        object:self
                                                      userInfo:_currentVideoInfo];
    if ([self.delegate respondsToSelector:@selector(trackEvent:videoID:title:)]) {
        if (streaming) {
            [self.delegate trackEvent:kTrackEventVideoLiveStart videoID:vidID title:title];
        } else {
            [self.delegate trackEvent:kTrackEventVideoStart videoID:vidID title:title];
        }
    }
    
    [_videoButtons.currentPositionLabel setText:@""];
    [_videoButtons.timeLeftLabel setText:@""];
    _videoButtons.videoScrubber.value = 0;
    
    [_videoButtons setTitle:title];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
                                     MPMediaItemPropertyTitle: title,
     }];
    
    [self setURL:url];
    
    [self syncPlayPauseButtons];
    
    if (playInFullScreen) {
        self.isAlwaysFullscreen = YES;
        [self launchFullScreen];
    }
}


- (void)setURL:(NSURL *)url
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
    
    [playerItem addObserver:self
                 forKeyPath:@"status"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackBufferEmpty"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"playbackLikelyToKeepUp"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [playerItem addObserver:self
                 forKeyPath:@"loadedTimeRanges"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    if (!self.videoPlayer) {
        _videoPlayer = [AVPlayer playerWithPlayerItem:playerItem];
        _videoPlayer.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        
        if ([_videoPlayer respondsToSelector:@selector(setAllowsExternalPlayback:)]) { // iOS 6 API
            [_videoPlayer setAllowsExternalPlayback:YES];
        }
        
        [_videoButtons setPlayer:_videoPlayer];
    } else {
        [self removeObserversFromVideoPlayerItem];
        [self.videoPlayer replaceCurrentItemWithPlayerItem:playerItem];
    }
    
    // iOS 5
    [_videoPlayer addObserver:self forKeyPath:@"airPlayVideoActive" options:NSKeyValueObservingOptionNew context:nil];
    
    // iOS 6
    [_videoPlayer addObserver:self
                   forKeyPath:@"externalPlaybackActive"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.videoPlayer.currentItem];
}


- (void)removeObserversFromVideoPlayerItem
{
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.videoPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_videoPlayer removeObserver:self forKeyPath:@"externalPlaybackActive"];
    [_videoPlayer removeObserver:self forKeyPath:@"airPlayVideoActive"];
}


- (void)syncPlayPauseButtons
{
    if ([self isPlaying]) {
        [_videoButtons.playPauseButton setImage:[UIImage imageNamed:@"pause-button"] forState:UIControlStateNormal];
    } else {
        [_videoButtons.playPauseButton setImage:[UIImage imageNamed:@"play-button"] forState:UIControlStateNormal];
    }
}

- (BOOL)isPlaying
{
    return [_videoPlayer rate] != 0.0;
}

- (void)showControls
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillShowControlsNotification
                                                        object:self
                                                      userInfo:nil];
    [UIView animateWithDuration:0.4 animations:^{
        self.videoButtons.playerControlBar.alpha = 1.0;
        self.videoButtons.titleLabel.alpha = 1.0;
    } completion:nil];
    
    if (self.fullScreenModeToggled) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                withAnimation:UIStatusBarAnimationFade];
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideControlsAnimated:) object:@YES];
    
    if ([self isPlaying]) {
        //[self performSelector:@selector(hideControlsAnimated:) withObject:@YES afterDelay:4.0];
    }
}


- (void)launchFullScreen
{
    if (!self.fullScreenModeToggled) {
        self.fullScreenModeToggled = YES;
        
        if (!self.isAlwaysFullscreen) {
            [self hideControlsAnimated:YES];
        }
        
        [self syncFullScreenButton:[[UIApplication sharedApplication] statusBarOrientation]];
        
        if (!self.fullscreenViewController) {
            self.fullscreenViewController = [[FullScreenViewController alloc] init];
            self.fullscreenViewController.allowPortraitFullscreen = self.allowPortraitFullscreen;
        }
        
        [_videoButtons setFullscreen:YES];
        [self.fullscreenViewController.view addSubview:self.videoButtons];
        
        
//        if (self.topView) {
//            [self.topView removeFromSuperview];
//            [self.fullscreenViewController.view addSubview:self.topView];
//        }
        
        if (self.isAlwaysFullscreen) {
            self.videoButtons.alpha = 0.0;
        } else {
            self.previousBounds = self.videoButtons.frame;
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationCurveLinear
                             animations:^{
                                 [self.videoButtons setCenter:CGPointMake( self.videoButtons.superview.bounds.size.width / 2, ( self.videoButtons.superview.bounds.size.height / 2))];
                                 self.videoButtons.bounds = self.videoButtons.superview.bounds;
                             }
                             completion:nil];
        }
        
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.fullscreenViewController animated:YES completion:^{
            if (self.isAlwaysFullscreen) {
                self.videoButtons.frame = CGRectMake(self.videoButtons.superview.bounds.size.width / 2, self.videoButtons.superview.bounds.size.height / 2, 0, 0);
                self.previousBounds = CGRectMake(self.videoButtons.superview.bounds.size.width / 2, self.videoButtons.superview.bounds.size.height / 2, 0, 0);
                [self.videoButtons setCenter:CGPointMake( self.videoButtons.superview.bounds.size.width / 2, self.videoButtons.superview.bounds.size.height / 2)];
                [UIView animateWithDuration:0.25f
                                      delay:0.0f
                                    options:UIViewAnimationOptionCurveLinear
                                 animations:^{
                                     self.videoButtons.alpha = 1.0;
                                 }
                                 completion:nil];
                
                self.videoButtons.frame = self.videoButtons.superview.bounds;
            }
            
//            if (self.topView) {
//                self.topView.frame = CGRectMake(0, 0, self.videoButtons.frame.size.width, self.topView.frame.size.height);
//            }
            
            if ([self.delegate respondsToSelector:@selector(setFullScreenToggled:)]) {
                [self.delegate setFullScreenToggled:self.fullScreenModeToggled];
            }
        }];
    }
}

- (void)minimizeVideo
{
    if (self.fullScreenModeToggled) {
        self.fullScreenModeToggled = NO;
        [self.videoButtons setFullscreen:NO];
        [self hideControlsAnimated:NO];
        [self syncFullScreenButton:self.interfaceOrientation];
        
//        if (self.topView) {
//            [self.containingViewController.view addSubview:self.topView];
//        }
        
        if (self.isAlwaysFullscreen) {
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.videoButtons.frame = self.previousBounds;
                             }
                             completion:^(BOOL success){
                                 
                                 if (showShareOptions) {
                                     [self presentShareOptions];
                                 }
                                 
                                 [self.videoButtons removeFromSuperview];
                             }];
        } else {
            [UIView animateWithDuration:0.45f
                                  delay:0.0f
                                options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.videoButtons.frame = self.previousBounds;
                             }
                             completion:^(BOOL success){
                                 if (showShareOptions) {
                                     [self presentShareOptions];
                                 }
                             }];
            
            [self.videoButtons removeFromSuperview];
            //[self.containingViewController.view addSubview:self.videoButtons];
        }
        
        
        [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:self.isAlwaysFullscreen completion:^{
            
            if (!self.isAlwaysFullscreen) {
                [self showControls];
            }
            [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                    withAnimation:UIStatusBarAnimationFade];
            
            if ([self.delegate respondsToSelector:@selector(setFullScreenToggled:)]) {
                [self.delegate setFullScreenToggled:self.fullScreenModeToggled];
            }
        }];
    }
}

- (void)presentShareOptions
{
    showShareOptions = NO;
}

- (void)hideControlsAnimated:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kVideoPlayerWillHideControlsNotification
                                                        object:self
                                                      userInfo:nil];
    if (animated) {
        [UIView animateWithDuration:0.4 animations:^{
            self.videoButtons.playerControlBar.alpha = 0;
            self.videoButtons.titleLabel.alpha = 0;
        } completion:nil];
        
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationFade];
        }
        
    } else {
        self.videoButtons.playerControlBar.alpha = 0;
        self.videoButtons.titleLabel.alpha = 0;
        if (self.fullScreenModeToggled) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                    withAnimation:UIStatusBarAnimationNone];
        }
    }
}


- (void)syncFullScreenButton:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (_fullScreenModeToggled) {
        [_videoButtons.fullScreenButton setImage:[UIImage imageNamed:@"minimize-button"] forState:UIControlStateNormal];
    } else {
        [_videoButtons.fullScreenButton setImage:[UIImage imageNamed:@"fullscreen-button"] forState:UIControlStateNormal];
    }
}


-(void)removePlayerTimeObservers
{
    if (_scrubberTimeObserver) {
        [_videoPlayer removeTimeObserver:_scrubberTimeObserver];
        _scrubberTimeObserver = nil;
    }
    
    if (_playClockTimeObserver) {
        [_videoPlayer removeTimeObserver:_playClockTimeObserver];
        _playClockTimeObserver = nil;
    }
}

- (void)playVideo
{
    if (self.view.superview) {
        self.playerIsBuffering = NO;
        scrubBuffering = NO;
        playWhenReady = NO;
        // Configuration is done, ready to start.
        [self.videoPlayer play];
        [self updatePlaybackProgress];
    }
}

- (void)updatePlaybackProgress
{
    [self syncPlayPauseButtons];
    [self showControls];
    
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (CMTIME_IS_INDEFINITE(playerDuration) || duration <= 0) {
        [_videoButtons.videoScrubber setHidden:YES];
        [_videoButtons.progressView setHidden:YES];
        [self syncPlayClock];
        return;
    }
    
    [_videoButtons.videoScrubber setHidden:NO];
    [_videoButtons.progressView setHidden:NO];
    
    CGFloat width = CGRectGetWidth([_videoButtons.videoScrubber bounds]);
    interval = 0.5f * duration / width;
    __weak BTVideoPlayerKitViewController *vpvc = self;
    _scrubberTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                       queue:NULL
                                                                  usingBlock:^(CMTime time) {
                                                                      [vpvc syncScrubber];
                                                                  }];
    
    // Update the play clock every second
    _playClockTimeObserver = [_videoPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, NSEC_PER_SEC)
                                                                        queue:NULL
                                                                   usingBlock:^(CMTime time) {
                                                                       [vpvc syncPlayClock];
                                                                   }];
    
}


- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self syncPlayPauseButtons];
    _seekToZeroBeforePlay = YES;
    if ([self.delegate respondsToSelector:@selector(trackEvent:videoID:title:)]) {
        [self.delegate trackEvent:kTrackEventVideoComplete videoID:[_currentVideoInfo objectForKey:@"videoID"] title:[_currentVideoInfo objectForKey:@"title"]];
    }
    
    [self minimizeVideo];
}

- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        _videoButtons.videoScrubber.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [_videoButtons.videoScrubber minimumValue];
        float maxValue = [_videoButtons.videoScrubber maximumValue];
        double time = CMTimeGetSeconds([_videoPlayer currentTime]);
        
        [_videoButtons.videoScrubber setValue:(maxValue - minValue) * time / duration + minValue];
    }
}

- (void)syncPlayClock
{
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        return;
    }
    
    if (CMTIME_IS_INDEFINITE(playerDuration)) {
        [_videoButtons.currentPositionLabel setText:@"LIVE"];
        [_videoButtons.timeLeftLabel setText:@""];
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        double currentTime = floor(CMTimeGetSeconds([_videoPlayer currentTime]));
        double timeLeft = floor(duration - currentTime);
        
        if (currentTime <= 0) {
            currentTime = 0;
            timeLeft = floor(duration);
        }
        
        [_videoButtons.currentPositionLabel setText:[NSString stringWithFormat:@"%@ ", [self stringFormattedTimeFromSeconds:&currentTime]]];
        if (!self.showStaticEndTime) {
            [_videoButtons.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&timeLeft]]];
        } else {
            [_videoButtons.timeLeftLabel setText:[NSString stringWithFormat:@"%@", [self stringFormattedTimeFromSeconds:&duration]]];
        }
	}
}

- (CMTime)playerItemDuration
{
    if (_videoPlayer.status == AVPlayerItemStatusReadyToPlay) {
        return([_videoPlayer.currentItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (NSString *)stringFormattedTimeFromSeconds:(double *)seconds
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:*seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [formatter setDateFormat:@"HH:mm:ss"];
    return [formatter stringFromDate:date];
}


#pragma makr -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:self.videoButtons.playerControlBar]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Wait for the video player status to change to ready before initializing video player controls
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == _videoPlayer
        && ([keyPath isEqualToString:@"externalPlaybackActive"] || [keyPath isEqualToString:@"airPlayVideoActive"])) {
        BOOL externalPlaybackActive = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        [[_videoButtons airplayIsActiveView] setHidden:!externalPlaybackActive];
        return;
    }
    
    if (object != [_videoPlayer currentItem]) {
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusReadyToPlay:
                playWhenReady = YES;
                break;
            case AVPlayerStatusFailed:
                // TODO:
                [self removeObserversFromVideoPlayerItem];
                [self removePlayerTimeObservers];
                self.videoPlayer = nil;
                NSLog(@"failed");
                break;
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"] && _videoPlayer.currentItem.playbackBufferEmpty) {
        self.playerIsBuffering = YES;
        [[_videoButtons activityIndicator] startAnimating];
        [self syncPlayPauseButtons];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"] && _videoPlayer.currentItem.playbackLikelyToKeepUp) {
        if (![self isPlaying] && (playWhenReady || self.playerIsBuffering || scrubBuffering)) {
            [self playVideo];
        }
        [[_videoButtons activityIndicator] stopAnimating];
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        float durationTime = CMTimeGetSeconds([[self.videoPlayer currentItem] duration]);
        float bufferTime = [self availableDuration];
        [self.videoButtons.progressView setProgress:bufferTime/durationTime animated:YES];
    }
    
    return;
}

- (float)availableDuration
{
    NSArray *loadedTimeRanges = [[self.videoPlayer currentItem] loadedTimeRanges];
    
    // Check to see if the timerange is not an empty array, fix for when video goes on airplay
    // and video doesn't include any time ranges
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self removeObserversFromVideoPlayerItem];
    [self removePlayerTimeObservers];
    
    [self.videoPlayer pause];
    [self.videoButtons.layer removeFromSuperlayer];
    self.videoPlayer = nil;
    [_videoButtons release];
    [super dealloc];
}

@end
