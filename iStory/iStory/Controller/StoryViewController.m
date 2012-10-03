//
//  ViewController.m
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "StoryViewController.h"
#import "HistoryViewController.h"
#import "Story.h"
#import "Route.h"
#import "Link.h"
#import "Node.h"
#import "MediaItem.h"
#import "Image.h"
#import "Video.h"
#import "Message.h"
#import "History.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StoryViewController

@synthesize moviePlayer, imageView, message, locationManager, story, currentLink, currentQueueIndex, currentMediaItem, history, timer, historyButton, currentFilePath, timerStarted, started, counter, storyEnded;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = story.name;
    started = NO;
    counter = 0;
    storyEnded = NO;
    
    history = [[History alloc] init];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    [self performSelectorInBackground:@selector(unzipVideos) withObject:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (storyEnded)
        [self dismissModalViewControllerAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (moviePlayer != nil) {
        [moviePlayer stop];
        moviePlayer = nil;
    }
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        locationManager = nil;
    }
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)unzipVideos
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *mediaFilesDir = [documentsDir stringByAppendingPathComponent:story.name];
    
    NSString *filePath = [documentsDir stringByAppendingPathComponent:story.zipFilename];
    ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
    
    NSArray *infos = [unzipFile listFileInZipInfos];
    for (FileInZipInfo *info in infos) {
        if (info.name.length > 0) {
            if (![[info.name substringToIndex:1] isEqualToString:@"_"] &&
                ![[info.name substringFromIndex:info.name.length-1] isEqualToString:@"/"] &&
                ![[info.name substringFromIndex:info.name.length-3] isEqualToString:@"xml"]) {
                    [unzipFile locateFileInZip:info.name];
                    
                    ZipReadStream *read = [unzipFile readCurrentFileInZip];
                    NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
                    int bytesRead = [read readDataWithBuffer:data];
                    
                    if (bytesRead > 0) {
                        if (![fileManager fileExistsAtPath:mediaFilesDir isDirectory:nil])
                            [fileManager createDirectoryAtPath:mediaFilesDir withIntermediateDirectories:YES attributes:nil error:NULL];
                        
                        NSString *linkPath = [mediaFilesDir stringByAppendingPathComponent:[info.name stringByDeletingLastPathComponent]];
                        
                        if (![fileManager fileExistsAtPath:linkPath isDirectory:nil])
                            [fileManager createDirectoryAtPath:linkPath withIntermediateDirectories:YES attributes:nil error:NULL];
                        
                        NSString *filePath = [linkPath stringByAppendingPathComponent:[info.name lastPathComponent]];
                        
                        [data writeToFile:filePath atomically:YES];
                    }
                    
                    [read finishedReading];
            }
        }
    }
    [unzipFile close];
}

- (void)showLinkQueue
{
    if (currentQueueIndex == 0) {
        historyButton.enabled = NO;
    } else if (currentQueueIndex >= currentLink.queue.count) {
        [history.linkQueue addObject:currentLink];
        historyButton.enabled = YES;
        if (currentLink.next.count == 0) {
            [locationManager stopUpdatingLocation];
            [self endOfStory];
        }
        return;
    }
    
    currentMediaItem = [currentLink.queue objectAtIndex:currentQueueIndex];
    
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *mediaFilesDir = [documentsDir stringByAppendingPathComponent:story.name];
    NSString *linkDir = [mediaFilesDir stringByAppendingPathComponent:[currentLink.identifier stringValue]];
    currentFilePath = [linkDir stringByAppendingPathComponent:currentMediaItem.filename];
    
    timerStarted = [NSDate date];
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkFile) userInfo:nil repeats:YES];
}

- (void)checkFile
{
    if ([timerStarted timeIntervalSinceNow] < -30) {
        [timer invalidate];
        timer = nil;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Opening video took too long" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:currentFilePath]){
        [timer invalidate];
        timer = nil;
        if ([[currentLink.queue objectAtIndex:currentQueueIndex] isMemberOfClass:[Video class]])
            [self playMovie:currentFilePath];
        else if ([[currentLink.queue objectAtIndex:currentQueueIndex] isMemberOfClass:[Image class]])
            [self showImage:currentFilePath duration:currentMediaItem.duration];
        else if ([[currentLink.queue objectAtIndex:currentQueueIndex] isMemberOfClass:[Message class]])
            [self showMessage:currentFilePath duration:currentMediaItem.duration];
    }
}

- (void)playMovie:(NSString *)path
{
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    moviePlayer.view.frame = CGRectMake(0, 0, 1024, 704);
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = YES;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
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

- (void)showImage:(NSString *)path duration:(NSInteger)duration
{
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    [self.view addSubview:imageView];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideImage) userInfo:nil repeats:NO];
}

- (void)hideImage
{
    [timer invalidate];
    timer = nil;
    [imageView removeFromSuperview];
    currentQueueIndex++;
    [self showLinkQueue];
}

- (void)showMessage:(NSString *)path duration:(NSInteger)duration
{
    message = [[UIWebView alloc] initWithFrame:self.view.frame];
    [message loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    message.delegate = self;
    [self.view addSubview:message];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideMessage) userInfo:nil repeats:NO];
}

- (void)hideMessage
{
    [timer invalidate];
    timer = nil;
    [message removeFromSuperview];
    currentQueueIndex++;
    [self showLinkQueue];
}

- (void)endOfStory
{
    storyEnded = YES;
    HistoryViewController *historyViewController = [[HistoryViewController alloc] init];
    historyViewController.history = history;
    historyViewController.storyName = story.name;
    historyViewController.view.backgroundColor = [UIColor blueColor];
    [self addChildViewController:historyViewController];
    [self.view addSubview:historyViewController.view];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)currentLocation fromLocation:(CLLocation *)oldLocation
{
    counter++;
    if (started) {
        for (Link *link in currentLink.next) {
            CLLocationDistance distance = [link.to.location distanceFromLocation:currentLocation];
            self.title = [NSString stringWithFormat:@"%d: %f", counter, distance];
            if (distance < [link.to.radius floatValue]) {
                currentQueueIndex = 0;
                currentLink = link;
                [self showLinkQueue];
            }
        }
    } else {
        CLLocationDistance nearest = 0;
        Route *nearestRoute = nil;
        for (Route *route in story.routes) {
            CLLocationDistance distance = [route.start.to.location distanceFromLocation:currentLocation];
            if (nearestRoute == nil || distance < nearest) {
                nearestRoute = route;
                nearest = distance;
            }
        }
        self.title = [NSString stringWithFormat:@"%d: %f", counter, nearest];
        if ([nearestRoute.start.to.location distanceFromLocation:currentLocation] < [nearestRoute.start.to.radius floatValue]) {
            currentQueueIndex = 0;
            currentLink = nearestRoute.start;
            started = YES;
            [self showLinkQueue];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showHistory"]) {
        [segue.destinationViewController setValue:history forKey:@"history"];
        [segue.destinationViewController setValue:story.name forKey:@"storyName"];
    }
}

@end
