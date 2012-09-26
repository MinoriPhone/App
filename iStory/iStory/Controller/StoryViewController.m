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
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StoryViewController

@synthesize moviePlayer, imageView, message, locationManager, story, currentLink, currentQueueIndex, history, timer, historyButton, currentVideoFilePath, timerStarted;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
    
    history = [[History alloc] init];
    
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
    [self performSelectorInBackground:@selector(unzipVideos) withObject:nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkStart) userInfo:nil repeats:YES];
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
                ([[info.name substringFromIndex:info.name.length-3] isEqualToString:@"avi"] ||
                 [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"m4v"] ||
                 [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"mov"] ||
                 [[info.name substringFromIndex:info.name.length-3] isEqualToString:@"mp4"])) {
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
        timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkPosition) userInfo:nil repeats:YES];
        return;
    }
    
    MediaItem *object = [currentLink.queue objectAtIndex:currentQueueIndex];
    
    if ([object isKindOfClass:[Video class]]) {
        NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *mediaFilesDir = [documentsDir stringByAppendingPathComponent:story.name];
        NSString *linkDir = [mediaFilesDir stringByAppendingPathComponent:[currentLink.identifier stringValue]];
        currentVideoFilePath = [linkDir stringByAppendingPathComponent:object.filename];
        
        timerStarted = [NSDate date];
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkFile) userInfo:nil repeats:YES];
    } else {
        [self readFileForMediaItem:object];
        
        if ([object isKindOfClass:[Image class]]) {
            [self showImage:object.data duration:object.duration];
        } else if ([object isKindOfClass:[Message class]]) {
            [self showMessage:object.data duration:object.duration];
        }
    }
}

- (void)checkFile
{
    if ([timerStarted timeIntervalSinceNow] < -30) {
        [timer invalidate];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Opening video took too long" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:currentVideoFilePath]){
        [timer invalidate];
        [self playMovie:currentVideoFilePath];
    }
}

- (void)readFileForMediaItem:(MediaItem *)mediaItem
{
    NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    if (mediaItem.data == nil){
        NSString *filePath = [documentsDir stringByAppendingPathComponent:story.zipFilename];
        ZipFile *unzipFile= [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
        [unzipFile locateFileInZip:mediaItem.filename];
        FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];
        
        ZipReadStream *read= [unzipFile readCurrentFileInZip];
        NSMutableData *data= [[NSMutableData alloc] initWithLength:info.length];
        int bytesRead= [read readDataWithBuffer:data];
        
        if (bytesRead > 0) {
            mediaItem.data = data;
        }
        
        [read finishedReading];
        [unzipFile close];
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
    moviePlayer.controlStyle = MPMovieControlStyleNone;
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

- (void)showImage:(NSData *)data duration:(NSInteger)duration
{
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:data]];
    [self.view addSubview:imageView];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideImage) userInfo:nil repeats:NO];
}

- (void)hideImage
{
    [imageView removeFromSuperview];
    currentQueueIndex++;
    [self showLinkQueue];
}

- (void)showMessage:(NSData *)data duration:(NSInteger)duration
{
    message = [[UITextView alloc] initWithFrame:self.view.frame];
    message.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
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
        }
    }
    if ([self calculateDistance:nearestRoute.start.to] < [nearestRoute.start.to.radius floatValue]) {
        [timer invalidate];
        currentLink = nearestRoute.start;
        [self showLinkQueue];
    }
}

- (void)checkPosition
{
    CLLocationDistance nearest = 0;
    Link *nearestLink = nil;
    for (Link *link in currentLink.next) {
        CLLocationDistance distance = [self calculateDistance:link.to];
        if (nearestLink == nil || distance < nearest) {
            nearestLink = link;
            nearest = distance;
        }
    }
    if ([self calculateDistance:nearestLink.to] < [nearestLink.to.radius floatValue]) {
        [timer invalidate];
        currentLink = nearestLink;
        [self showLinkQueue];
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
