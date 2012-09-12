//
//  ViewController.m
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "StoryViewController.h"
#import "Story.h"
#import "Route.h"
#import "Link.h"
#import "Node.h"

@implementation StoryViewController

@synthesize moviePlayer, locationManager, story, timer;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    
    // Play video on load
    [self playMovie:@"movie" ofType:@"mp4"];
    
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
    //timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkStart) userInfo:nil repeats:YES];
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

- (void)playMovie:(NSString *)filename ofType:(NSString *)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    
    // Set moviePlayer settings
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    moviePlayer.view.frame = CGRectMake(0, 0, 1024, 704);
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = NO;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeNone;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.view.userInteractionEnabled = NO;

    // Add movieplayer playbackstate listener
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    [self.view addSubview:moviePlayer.view];
    [moviePlayer play];
}

- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification
{
    // Get stop reason for movie
    NSNumber *reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    // Call action when movie playbackstate is done (so NOT stopped!!)
    if([reason intValue] == MPMovieFinishReasonPlaybackEnded && moviePlayer.playbackState != MPMoviePlaybackStateStopped) {
        
        // Add movie to history (viewed media)
        
    }
}

- (CLLocationDistance)calculateDistance:(Node *)node
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[node.latitude doubleValue] longitude:[node.longitude doubleValue]];
    
    CLLocationDistance distance = [location distanceFromLocation:locationManager.location];
    
    return distance;
}

- (void)checkStart
{
    CLLocationDistance nearbiest = 0;
    Route *nearbiestRoute = nil;
    for (Route *route in story.routes) {
        CLLocationDistance distance = [self calculateDistance:route.start.to];
        if (nearbiestRoute == nil || distance < nearbiest) {
            nearbiestRoute = route;
            nearbiest = distance;
            Log(@"Locatie(%@, %@) dichterbij (afstand %f)", route.start.to.longitude, route.start.to.latitude, distance);
        } else {
            Log(@"Locatie(%@, %@) niet dichterbij (afstand %f)", route.start.to.longitude, route.start.to.latitude, distance);
        }
    }
    if ([self calculateDistance:nearbiestRoute.start.to] < [nearbiestRoute.start.to.radius floatValue]) {
        [timer invalidate];
        [self playMovie:[[nearbiestRoute.start.files objectAtIndex:0] valueForKey:@"filename"] ofType:[[nearbiestRoute.start.files objectAtIndex:0] valueForKey:@"ofType"]];
    } else {
        Log(@"Locatie(%@, %@) niet binnen bereik", nearbiestRoute.start.to.longitude, nearbiestRoute.start.to.latitude);
    }
}

@end
