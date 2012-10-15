#import "StoryViewController.h"
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

@synthesize background, indicatorView, historyMenu, historyTable, documentsDir, moviePlayer, imageView, message, locationManager, story, startLinks, currentLink, currentQueueIndex, history, timer, timerStarted, started, ended, showingQueue;

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
    documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    started = NO;
    ended = NO;
    showingQueue = NO;
    historyMenuFrame = historyMenu.frame;
    
    history = [[History alloc] init];
    
    startLinks = [[NSMutableArray alloc] initWithCapacity:story.routes.count];
    for (Route *route in story.routes) {
        [startLinks addObject:route.start];
    }
    
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
                        if (![fileManager fileExistsAtPath:story.dir isDirectory:nil])
                            [fileManager createDirectoryAtPath:story.dir withIntermediateDirectories:YES attributes:nil error:NULL];
                        
                        NSString *linkPath = [story.dir stringByAppendingPathComponent:[info.name stringByDeletingLastPathComponent]];
                        
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

- (MediaItem *)currentMediaItem
{
    return [currentLink.queue objectAtIndex:currentQueueIndex];
}

- (NSString *)currentFilePath
{
    if (currentLink.shortcut == nil || [[currentLink.shortcut stringValue] isEqualToString:@""])
        return [[story.dir stringByAppendingPathComponent:[currentLink.identifier stringValue]] stringByAppendingPathComponent:self.currentMediaItem.filename];
    else
        return [[story.dir stringByAppendingPathComponent:[currentLink.shortcut stringValue]] stringByAppendingPathComponent:self.currentMediaItem.filename];
}

- (void)showLinkQueue
{
    if (currentQueueIndex == 0) {
        started = YES;
        showingQueue = YES;
        background.hidden = YES;
    }
    
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
    if ([fileManager fileExistsAtPath:self.currentFilePath]){
        [timer invalidate];
        timer = nil;
        switch (self.currentMediaItem.type) {
            case VideoType:
                [self playMovie:self.currentFilePath];
                break;
            case ImageType:
                [self showImage:self.currentFilePath duration:self.currentMediaItem.duration];
                break;
            case MessageType:
                [self showMessage:self.currentFilePath duration:self.currentMediaItem.duration];
                break;
        }
    }
}

- (void)playMovie:(NSString *)path
{
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    [moviePlayer prepareToPlay];
    moviePlayer.view.frame = self.view.frame;
    moviePlayer.shouldAutoplay = YES;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = YES;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    indicatorView.hidden = YES;
    [self.view addSubview:moviePlayer.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification
{
    if((MPMovieFinishReason)[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] == MPMovieFinishReasonPlaybackEnded && moviePlayer.playbackState != MPMoviePlaybackStateStopped) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [moviePlayer.view removeFromSuperview];
        moviePlayer = nil;
        [self nextQueueItem];
    }
}

- (void)showImage:(NSString *)path duration:(NSInteger)duration
{
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    if (imageView.frame.size.width > self.view.frame.size.width || imageView.frame.size.height > self.view.frame.size.height) {
        if (((self.view.frame.size.width/imageView.frame.size.width)*imageView.frame.size.height) <= self.view.frame.size.height) {
            NSInteger height = (self.view.frame.size.width/imageView.frame.size.width)*imageView.frame.size.height;
            imageView.frame = CGRectMake(0, ((self.view.frame.size.height-height)/2), self.view.frame.size.width, height);
        } else {
            NSInteger width = (self.view.frame.size.height/imageView.frame.size.height)*imageView.frame.size.width;
            imageView.frame = CGRectMake(((self.view.frame.size.width-width)/2), 0, width, self.view.frame.size.height);
        }
    } else {
        imageView.frame = CGRectMake(((self.view.frame.size.width-imageView.frame.size.width)/2), ((self.view.frame.size.height-imageView.frame.size.height)/2), imageView.frame.size.width, imageView.frame.size.height);
    }
    indicatorView.hidden = YES;
    [self.view addSubview:imageView];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideImage) userInfo:nil repeats:NO];
}

- (void)hideImage
{
    [timer invalidate];
    timer = nil;
    [imageView removeFromSuperview];
    [self nextQueueItem];
}

- (void)showMessage:(NSString *)path duration:(NSInteger)duration
{
    message = [[UIWebView alloc] initWithFrame:self.view.frame];
    [message loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    message.delegate = self;
    indicatorView.hidden = YES;
    [self.view addSubview:message];
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideMessage) userInfo:nil repeats:NO];
}

- (void)hideMessage
{
    [timer invalidate];
    timer = nil;
    [message removeFromSuperview];
    [self nextQueueItem];
}

- (void)nextQueueItem
{
    indicatorView.hidden = NO;
    currentQueueIndex++;
    
    if (currentQueueIndex >= currentLink.queue.count) {
        currentQueueIndex = 0;
        
        if (!ended) {
            [history.linkQueue addObject:currentLink];
            [historyTable reloadData];
            if (currentLink.next.count == 0) {
                ended = YES;
                [locationManager stopUpdatingLocation];
            } else {
                [self checkLocation];
            }
        }
        
        showingQueue = NO;
        indicatorView.hidden = YES;
        background.hidden = NO;
        return;
    } else {
        [self showLinkQueue];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)currentLocation fromLocation:(CLLocation *)oldLocation
{
    if (!showingQueue) {
        [self checkLocation];
    }
}

- (void)checkLocation
{
    CLLocationDistance nearest = 0;
    Link *nearestLink = nil;
    for (Link *link in started ? currentLink.next : startLinks) {
        CLLocationDistance distance = [link.to.location distanceFromLocation:locationManager.location];
        if (distance < [link.to.radius floatValue]) {
            if (nearestLink == nil || distance < nearest) {
                nearestLink = link;
                nearest = distance;
            }
        }
    }
    if (nearestLink != nil) {
        indicatorView.hidden = NO;
        currentLink = nearestLink;
        [self showLinkQueue];
    }
}

- (void)animateHistoryView:(BOOL)show
{
    historyMenu.frame = CGRectMake(show ? 0 : -historyMenu.frame.size.width, 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
    historyMenuFrame = historyMenu.frame;
    
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
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self nextQueueItem];
}

@end