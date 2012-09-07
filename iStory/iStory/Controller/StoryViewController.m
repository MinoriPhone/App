//
//  ViewController.m
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "StoryViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation StoryViewController

@synthesize moviePlayer;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self playMovie:@"movie"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [moviePlayer stop];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)playMovie:(NSString *)filename
{
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mp4"];
    
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    moviePlayer.view.frame = CGRectMake(0, 0, 1024, 704);
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    moviePlayer.fullscreen = YES;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeNone;
    [self.view addSubview:moviePlayer.view];
    [moviePlayer play];
}

@end
