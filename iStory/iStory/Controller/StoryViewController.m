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

@synthesize moviePlayer, imageView, message, locationManager, story, currentLink, currentQueueIndex, currentMediaItem, history, timer, historyMenu, historyTable, currentFilePath, timerStarted, started, counter, storyUnzipped, showingQueue;

CGRect historyMenuFrame;
CGPoint touchedFrom;

- (id)initWithStory:(Story *)newStory
{
    self = [super init];
    self.story = newStory;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = story.name;
    started = NO;
    counter = 0;
    storyUnzipped = NO;
    showingQueue = NO;
    historyMenuFrame = historyMenu.frame;
    
    history = [[History alloc] init];
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    locationManager.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!storyUnzipped)
        [self performSelectorInBackground:@selector(unzipStory) withObject:nil];
    
    [locationManager startUpdatingLocation];
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

- (void)unzipStory
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
    
    storyUnzipped = YES;
}

- (void)showLinkQueue
{
    if (currentQueueIndex == 0) {
        showingQueue = YES;
    } else if (currentQueueIndex >= currentLink.queue.count) {
        [history.linkQueue addObject:currentLink];
        [historyTable reloadData];
        if (currentLink.next.count == 0) {
            [locationManager stopUpdatingLocation];
        } else {
            [self checkLocation];
        }
        showingQueue = NO;
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
    moviePlayer.view.frame = self.view.frame;
    moviePlayer.shouldAutoplay = YES;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = YES;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    //moviePlayer.controlStyle = MPMovieControlStyleNone;
    [self.view addSubview:moviePlayer.view];
    
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
    if (imageView.frame.size.width > self.view.frame.size.width || imageView.frame.size.height > self.view.frame.size.height) {
        if (((self.view.frame.size.width/imageView.frame.size.width)*imageView.frame.size.height) < self.view.frame.size.height) {
            imageView.frame = CGRectMake(0, 0, self.view.frame.size.width, ((self.view.frame.size.width/imageView.frame.size.width)*imageView.frame.size.height));
        } else {
            imageView.frame = CGRectMake(0, 0, ((self.view.frame.size.height/imageView.frame.size.height)*imageView.frame.size.width), self.view.frame.size.height);
        }
    }
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

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)currentLocation fromLocation:(CLLocation *)oldLocation
{
    counter++;
    if (!showingQueue) {
        if (started) {
            [self checkLocation];
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
}

- (void)checkLocation
{
    for (Link *link in currentLink.next) {
        CLLocationDistance distance = [link.to.location distanceFromLocation:locationManager.location];
        self.title = [NSString stringWithFormat:@"%d: %f", counter, distance];
        if (distance < [link.to.radius floatValue]) {
            currentQueueIndex = 0;
            currentLink = link;
            [self showLinkQueue];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return history.linkQueue.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    //[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = UITextAlignmentRight;
    cell.textLabel.text = [[history.linkQueue objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self animateHistoryView:NO];
    currentLink = [history.linkQueue objectAtIndex:indexPath.row];
    currentQueueIndex = 0;
    [self showLinkQueue];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        touchedFrom = [touch locationInView:self.view];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        if (location.x > touchedFrom.x && location.x-touchedFrom.x < historyMenu.frame.size.width)
            historyMenu.frame = CGRectMake(-historyMenu.frame.size.width+(location.x-touchedFrom.x), 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
        else if (location.x < touchedFrom.x && touchedFrom.x-location.x < historyMenu.frame.size.width)
            historyMenu.frame = CGRectMake(-(touchedFrom.x-location.x), 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
        else
            historyMenu.frame = historyMenuFrame;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        if (location.x > touchedFrom.x && location.x-touchedFrom.x > historyMenu.frame.size.width/2) {
            [self animateHistoryView:YES];
        } else if (location.x < touchedFrom.x && touchedFrom.x-location.x > historyMenu.frame.size.width/2) {
            [self animateHistoryView:NO];
        } else {
            historyMenu.frame = historyMenuFrame;
        }
    }
}

- (void)animateHistoryView:(BOOL)show
{
     historyMenu.frame = CGRectMake(show ? 0 : -historyMenu.frame.size.width, 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
     historyMenuFrame = historyMenu.frame;
    
}

@end
