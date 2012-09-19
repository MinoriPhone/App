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
#import "MediaItem.h"
#import "Image.h"
#import "Video.h"
#import "Message.h"
#import "History.h"

@implementation StoryViewController

@synthesize moviePlayer, locationManager, story, currentLink, currentQueueIndex, history, timer, historyButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    
    history = [[History alloc] init];
    
    // Play video on load
    currentLink = [[story.routes objectAtIndex:0] valueForKey:@"start"];
    [self showLinkQueue];
    
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

- (void)showLinkQueue
{
    if (currentQueueIndex >= currentLink.queue.count) {
        // start checking next position
        [history.linkQueue addObject:currentLink];
        historyButton.enabled = YES;
        return;
    }
    
    MediaItem *object = [currentLink.queue objectAtIndex:currentQueueIndex];
    
    if ([object isKindOfClass:[Video class]])
        [self playMovie:object.filename];
    else if ([object isKindOfClass:[Image class]])
        [self showImage:object.filename duration:object.duration];
    else if ([object isKindOfClass:[Message class]])
        [self showMessage:object.filename duration:object.duration];
}

- (void)playMovie:(NSString *)filename
{
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
    
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    moviePlayer.view.frame = CGRectMake(0, 0, 1024, 704);
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = NO;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeNone;
    //moviePlayer.controlStyle = MPMovieControlStyleNone;
    [self.view addSubview:moviePlayer.view];
    [moviePlayer play];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification
{
    NSNumber *reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    
    if([reason intValue] == MPMovieFinishReasonPlaybackEnded && moviePlayer.playbackState != MPMoviePlaybackStateStopped) {
        [moviePlayer.view removeFromSuperview];
        currentQueueIndex++;
        [self showLinkQueue];
    }
}

- (void)showImage:(NSString *)filename duration:(NSInteger)duration
{
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]];
    [self.view addSubview:imageView];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideImage) userInfo:nil repeats:NO];
}

- (void)hideImage
{
    [imageView removeFromSuperview];
    currentQueueIndex++;
    [self showLinkQueue];
}

- (void)showMessage:(NSString *)filename duration:(NSInteger)duration
{
    message = [[UITextView alloc] initWithFrame:self.view.frame];
    message.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filename ofType:nil] encoding:NSUTF8StringEncoding error:nil];
    [self.view addSubview:message];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideMessage) userInfo:nil repeats:NO];
}

- (void)hideMessage
{
    [message removeFromSuperview];
    currentQueueIndex++;
    [self showLinkQueue];
}

- (CLLocationDistance)calculateDistance:(Node *)node
{
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[node.latitude doubleValue] longitude:[node.longitude doubleValue]];
    
    CLLocationDistance distance = [location distanceFromLocation:locationManager.location];
    
    return distance;
}

- (void)checkStart
{
    CLLocationDistance nearest = 0;
    Route *nearestRoute = nil;
    for (Route *route in story.routes) {
        CLLocationDistance distance = [self calculateDistance:route.start.to];
        if (nearestRoute == nil || distance < nearest) {
            nearestRoute = route;
            nearest = distance;
            Log(@"Locatie(%@, %@) dichterbij (afstand %f)", route.start.to.longitude, route.start.to.latitude, distance);
        } else {
            Log(@"Locatie(%@, %@) niet dichterbij (afstand %f)", route.start.to.longitude, route.start.to.latitude, distance);
        }
    }
    if ([self calculateDistance:nearestRoute.start.to] < [nearestRoute.start.to.radius floatValue]) {
        [timer invalidate];
        currentLink = nearestRoute.start;
        [self showLinkQueue];
    } else {
        Log(@"Locatie(%@, %@) niet binnen bereik", nearestRoute.start.to.longitude, nearestRoute.start.to.latitude);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showHistory"]) {
        [segue.destinationViewController setValue:history forKey:@"history"];
    }
        
}

@end
