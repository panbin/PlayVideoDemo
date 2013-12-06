//
//  ViewController.m
//  PlayVideoDemo
//
//  Created by panbin on 13-12-5.
//  Copyright (c) 2013年 Handpay. All rights reserved.
//

#import "ViewController.h"
#import "BTVideoPlayerKitViewController.h"

@interface ViewController ()

@property (nonatomic, retain) BTVideoPlayerKitViewController *playerController;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor blueColor];
    
    _playerController = [[BTVideoPlayerKitViewController alloc] init];
    _playerController.view.frame = CGRectMake(0, 0, 320, 200);
    [self.view addSubview:_playerController.view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    NSURL *url = [NSURL URLWithString:@"http://ignhdvod-f.akamaihd.net/i/assets.ign.com/videos/zencoder/,416/d4ff0368b5e4a24aee0dab7703d4123a-110000,640/d4ff0368b5e4a24aee0dab7703d4123a-500000,640/d4ff0368b5e4a24aee0dab7703d4123a-1000000,960/d4ff0368b5e4a24aee0dab7703d4123a-2500000,1280/d4ff0368b5e4a24aee0dab7703d4123a-3000000,-1354660143-w.mp4.csmil/master.m3u8"];
    
    NSURL *url = [NSURL URLWithString:@"http://images.xiaowoba.com/my.mp4"];
    
//    NSURL *url = [NSURL URLWithString:@"http://dev.mopietek.net:8080/mp4/320480flv.3gp"];
    
//    NSURL *url = [NSURL URLWithString:@"http://v.youku.com/player/getRealM3U8/vid/XMzU5NDE3NTYw/type/video.m3u8"];
    
    
    [_playerController playVideoWithTitle:@"Title" URL:url videoID:nil shareURL:nil isStreaming:NO playInFullScreen:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
