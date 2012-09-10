//
//  ViewController.m
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "StoryViewController.h"
#import "Story.h"

@implementation StoryViewController

@synthesize moviePlayer, locationManager, story;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
//    [self playMovie:@"movie"];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    self.title = story.name;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
//    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkLocation) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (moviePlayer != nil)
        [moviePlayer stop];
    if (locationManager != nil)
        [locationManager stopUpdatingLocation];
    [timer invalidate];
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

- (BOOL)inRange
{
//    CLLocation *location = [[CLLocation alloc] initWithLatitude:[node.latitude doubleValue] longitude:[node.longitude doubleValue]];
//    
//    CLLocationDistance distance = [location distanceFromLocation:locationManager.location];
//    
//    return distance <= [node.radius floatValue];
}

- (void)checkLocation
{
    if ([self inRange]) {
        [timer invalidate];
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"In range" message:@"You are now in range of a node" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//        [alert show];
    }
}

@end
