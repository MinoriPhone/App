#import "StoryViewController.h"
#import "Route.h"
#import "Link.h"
#import "Node.h"
#import "MediaItem.h"
#import "Image.h"
#import "Video.h"
#import "Text.h"
#import "History.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"

@implementation StoryViewController

@synthesize background, indicatorView, historyMenu, historyTable, documentsDir, moviePlayer, imageView, message, locationManager, story, startLinks, currentLink, history, timer, timerStarted, debug;

CGRect historyMenuFrame;
CGPoint touchedFrom;
NSInteger currentQueueIndex;
CLLocation *currentLocation;
NSInteger locationCheck;
BOOL started;
BOOL ended;
BOOL showingQueue;
BOOL debugMode = NO;

- (id)initWithStory:(Story *)newStory folder:(NSString *)folder
{
    self = [super init];
    self.story = newStory;
    self.documentsDir = folder;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // If the app is not running in debug mode, hide the debug label, else, set variable needed for debugging
    if (!debugMode) {
        debug.hidden = YES;
    } else {
        locationCheck = 0;
    }
    
    // Define variables needed to detect the start and end of the story
    started = NO;
    ended = NO;
    
    // Define the variable needed to detect if currently showing any media files
    showingQueue = NO;
    
    // Define the frame to reset the history menu to the old position
    historyMenuFrame = historyMenu.frame;
    
    // Initialize the History object
    history = [[History alloc] init];
    
    // Loop through each route and save the starting point of the route
    startLinks = [[NSMutableArray alloc] initWithCapacity:story.routes.count];
    for (Route *route in story.routes) {
        [startLinks addObject:route.start];
    }
    
    // Initialize the locationManager to optain the GPS location
    locationManager = [[CLLocationManager alloc] init];
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = 10;
    locationManager.delegate = self;
    
    // Check whether it is possible to obtain the GPS location. If not possible, show an alert
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"GPS cannot be used" message:@"Check your preferences of location services is enabled for iStory" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        alert.tag = 999;
        [alert show];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // When the story is started, unzip the iStory zip file corresponding to the started story and copy all media files
    [self performSelectorInBackground:@selector(unzipStory) withObject:nil];
    
    // Start updating the GPS location
    [locationManager startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // If the app is closed while playing a movie, first stop the movie before closing
    if (moviePlayer != nil) {
        [moviePlayer stop];
        moviePlayer = nil;
    }
    
    // If the app is closed while playing a story, first stop updating the GPS location before closing
    if (locationManager != nil) {
        [locationManager stopUpdatingLocation];
        locationManager = nil;
    }
    
    // If the app is closed while the timer was set, first invalidate the timer before closing
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

/*
 * Unzip the iStory zip file corresponding to the started story and copy all media files
 */
- (void)unzipStory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Define the path to the iStory zip file corresponding to the started story
    NSString *filePath = [documentsDir stringByAppendingPathComponent:story.zipFilename];
    
    // Unzip the iStory zip file corresponding to the started story
    ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:filePath mode:ZipFileModeUnzip];
    
    // Loop through all the files in the iStory zip file corresponding to the started story
    NSArray *infos = [unzipFile listFileInZipInfos];
    for (FileInZipInfo *info in infos) {
        if (info.name.length > 0) {
            // Check if the file is not the XML formatted story file
            if (![[info.name substringToIndex:1] isEqualToString:@"_"] &&
                ![[info.name substringFromIndex:info.name.length-1] isEqualToString:@"/"] &&
                ![[info.name substringFromIndex:info.name.length-3] isEqualToString:@"xml"]) {
                [unzipFile locateFileInZip:info.name];
            
                // Read the file data
                ZipReadStream *read = [unzipFile readCurrentFileInZip];
                NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
                int bytesRead = [read readDataWithBuffer:data];
                
                // Write the file data to a new file (create a copy of the file)
                if (bytesRead > 0) {
                    if (![fileManager fileExistsAtPath:story.dir isDirectory:nil])
                        [fileManager createDirectoryAtPath:story.dir withIntermediateDirectories:YES attributes:nil error:NULL];
                    
                    NSString *linkPath = [story.dir stringByAppendingPathComponent:[info.name stringByDeletingLastPathComponent]];
                    
                    if (![fileManager fileExistsAtPath:linkPath isDirectory:nil])
                        [fileManager createDirectoryAtPath:linkPath withIntermediateDirectories:YES attributes:nil error:NULL];
                    
                    NSString *filePath = [linkPath stringByAppendingPathComponent:[info.name lastPathComponent]];
                    
                    [data writeToFile:filePath atomically:YES];
                }
                
                // Close the file
                [read finishedReading];
            }
        }
    }
    
    // Close the iStory zip file corresponding to the started story
    [unzipFile close];
}

/*
 * Get the Media item that needs to be shown
 *
 * @return MediaItem The Media item
 */
- (MediaItem *)currentMediaItem
{
    return [currentLink.queue objectAtIndex:currentQueueIndex];
}

/*
 * Get the file path of the Media item that needs to be shown
 *
 * @return NSString The path to the file
 */
- (NSString *)currentFilePath
{
    if (self.currentMediaItem.shortcut == nil || [[self.currentMediaItem.shortcut stringValue] isEqualToString:@""])
        return [[story.dir stringByAppendingPathComponent:[currentLink.identifier stringValue]] stringByAppendingPathComponent:self.currentMediaItem.filename];
    else
        return [[story.dir stringByAppendingPathComponent:[self.currentMediaItem.shortcut stringValue]] stringByAppendingPathComponent:self.currentMediaItem.filename];
}

/*
 * Start the queue of the current position the platform to show the Media items
 * If a history item is tabbed, the queue for the tabbed history item will be started
 */
- (void)showLinkQueue
{
    // Check if it is the first Media item to be shown and set the variables to prevent this application from starting another queue while the current queue is not finished yet
    if (currentQueueIndex == 0) {
        started = YES;
        showingQueue = YES;
        background.hidden = YES;
    }
    
    // Start the timer to check if the file of the Media item is already unzipped
    timerStarted = [NSDate date];
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkFile) userInfo:nil repeats:YES];
}

/*
 * Check if the file of the Media item that needs to be shown is already unzipped
 * Stop checking when 30 seconds elapsed since checking started
 */
- (void)checkFile
{
    // Check if 30 seconds elapsed since checking started
    if ([timerStarted timeIntervalSinceNow] < -30) {
        // Invalidate the timer to prevent checking again
        [timer invalidate];
        timer = nil;
        
        // Show an alert message to let the user know that the file of the Media item was not unzipped in time
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Opening video took too long" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }
    
    // Check if the file of the Media item is unzipped
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:self.currentFilePath]){
        // Invalidate the timer to prevent checking again
        [timer invalidate];
        timer = nil;
        
        // Show the Media item
        switch (self.currentMediaItem.type) {
            case VideoType:
                [self playMovie:self.currentFilePath];
                break;
            case ImageType:
                [self showImage:self.currentFilePath duration:self.currentMediaItem.duration];
                break;
            case TextType:
                [self showMessage:self.currentFilePath duration:self.currentMediaItem.duration];
                break;
        }
    }
}

/*
 * Play a Media item that is type of Video
 */
- (void)playMovie:(NSString *)path
{
    // Initialize the movie player
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    [moviePlayer prepareToPlay];
    moviePlayer.view.frame = self.view.frame;
    moviePlayer.shouldAutoplay = YES;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = YES; // Always show a Video in fullscreen modus
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    moviePlayer.controlStyle = MPMovieControlStyleNone; // Do not show any controls
    indicatorView.hidden = YES;
    
    // Show the movie player
    [self.view addSubview:moviePlayer.view];
    
    // Initialize a notification to detect when the end of the Video is reached
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateChanged:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}

/*
 * Detect if the Video shown reached the end and start the next queue item
 * If the Video is stopped because of an error, show an alert to let the user know an error occurred
 */
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification
{
    // Check if the Video stopped because of an error
    if((MPMovieFinishReason)[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] == MPMovieFinishReasonPlaybackError) {
        // Show an alert message to let the user know an error occurred
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"An error occured while playing video" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    } else if (moviePlayer.playbackState != MPMoviePlaybackStateStopped) {
        // If the Video reached the end, remove the notification and the movie player
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [moviePlayer.view removeFromSuperview];
        moviePlayer = nil;
        
        // Start the next queue item
        [self nextQueueItem];
    }
}

/*
 * Show a media item that is type of an Image
 *
 * @param path The path to the Media item file
 * @param duration The number of seconds the Media item needs to be shown
 */
- (void)showImage:(NSString *)path duration:(NSInteger)duration
{
    // Initialize a view containing the Media item file
    imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    
    // Center the Media item in the middle screen
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
    
    // Add the view containing the Media item to the screen
    [self.view addSubview:imageView];
    
    // Start a timer to hide the Media item and start the next queue item after the given number of seconds
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideImage) userInfo:nil repeats:NO];
}

/*
 * Hide the Media item that is type of an Image and start the next queue item
 */
- (void)hideImage
{
    // Invalidate the timer
    [timer invalidate];
    timer = nil;
    
    // Remove the Media item from the screen
    [imageView removeFromSuperview];
    
    // Start next queue item
    [self nextQueueItem];
}

/*
 * Show a Media item that is type of a Message
 *
 * @param path The path to the Media item file
 * @param duration The number of seconds the Media item needs to be shown
 */
- (void)showMessage:(NSString *)path duration:(NSInteger)duration
{
    // Initialize a view containing the Media item file
    message = [[UIWebView alloc] initWithFrame:self.view.frame];
    [message loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    message.delegate = self;
    indicatorView.hidden = YES;
    
    // Add the Media item to the screen
    [self.view addSubview:message];
    
    // Start a timer to hide the Media item and start the next queue item after the given number of seconds
    timer = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(hideMessage) userInfo:nil repeats:NO];
}

/*
 * Hide the Media item that is type of a Message and start the next queue item
 */
- (void)hideMessage
{
    // Invalidate the timer
    [timer invalidate];
    timer = nil;
    
    // Remove the Media item from the screen
    [message removeFromSuperview];
    
    // Start the next queue item
    [self nextQueueItem];
}

/*
 * Start the next queue item if there is any Media item left in the current queue
 */
- (void)nextQueueItem
{
    indicatorView.hidden = NO;
    currentQueueIndex++;
    
    // Check if there is any Media item left in the current queue
    if (currentQueueIndex >= currentLink.queue.count) {
        currentQueueIndex = 0;
        
        // Check if the end of the story is not reached yet
        if (!ended) {
            // Add the current queue to the History object
            if (![history.linkQueue containsObject:currentLink]) {
                [history.linkQueue addObject:currentLink];
                [historyTable reloadData];
            }
            
            // Check if the end of the story is reached
            if (currentLink.next.count == 0) {
                ended = YES;
                [locationManager stopUpdatingLocation];
            } else {
                // Check the GPS location again
                [self checkLocation];
            }
        }
        
        // Set the variables to (again) make it possible to start another queue
        showingQueue = NO;
        indicatorView.hidden = YES;
        background.hidden = NO;
    } else {
        // Show next queue item
        [self showLinkQueue];
    }
}

/*
 * This method is called when the GPS location is different from the previous location (which means that the user moved the platform)
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if([newLocation.timestamp timeIntervalSinceNow] > -15) {
        currentLocation = newLocation;
    }
    
    // Check if it is possible to show a queue
    if (!showingQueue){
        // Check if the platform is within the radius of any of the next locations
        [self checkLocation];
    }
}

/*
 * Check if the platform is within the radius of any of the next locations.
 * If true, start the queue of the nearest location.
 * If the story is started but no queue is shown yet, next locations are start locations of all the routes.
 */
- (void)checkLocation
{
    CLLocationDistance nearest = CLLocationDistanceMax;
    Link *nearestLink = nil;
    
    // Loop through all the next locations
    for (Link *link in started ? currentLink.next : startLinks) {
        // Calculate the distance between the platform and the location
        CLLocationDistance distance = [link.to.location distanceFromLocation:currentLocation];
        float radius = [link.to.radius floatValue];
        
        // Check if the GPS signal is very bad. If true, increase the radius of the location
        if (currentLocation.horizontalAccuracy > 20 && radius < 20)
            radius = (radius*1.5) > 20 ? 20 : (radius*1.5);
        
        // Check if the platform is within the radius of the location
        if (distance < radius && distance > 0) {
            if (nearestLink == nil || distance < nearest) {
                nearestLink = link;
                nearest = distance;
            }
        }
        if (distance < nearest && distance > 0)
            nearest = distance;
    }
    
    // If the app is running in debug mode, update the debug label
    if (debugMode) {
        locationCheck++;
        debug.text = [NSString stringWithFormat:@"%d: %f", locationCheck, nearest];
    }
    
    // If the platform is within the radius of any location, start the queue of the nearest location
    if (nearestLink != nil) {
        indicatorView.hidden = NO;
        currentLink = nearestLink;
        [self showLinkQueue];
    }
}

/*
 * Show or hide the History view
 *
 * @param show A boolean defining if the History view needs to be shown or hidden
 */
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
    
    // Set cell text style settings
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = UITextAlignmentRight;
    
    // Add the name of the history item to the cell
    cell.textLabel.text = [[history.linkQueue objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Hide the History view
    [self animateHistoryView:NO];
    
    // Show the tabbed History item
    currentLink = [history.linkQueue objectAtIndex:indexPath.row];
    [self showLinkQueue];
}

/*
 * Detect where the screen is touched before swiped to position the History view
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Check if it is possible to show the History view
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        touchedFrom = [touch locationInView:self.view];
    }
}

/*
 * If the user touches the screen and moves his finger, the History view will be shown
 * The position of the History view depends on the amount of pixels the finger is moved
 */
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Check if it is possible to show the History view
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        
        // Check if the finger is moved to the right
        if (location.x > touchedFrom.x && location.x-touchedFrom.x < historyMenu.frame.size.width)
            historyMenu.frame = CGRectMake(-historyMenu.frame.size.width+(location.x-touchedFrom.x), 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
        // Check if the finger is moved to the left
        else if (location.x < touchedFrom.x && touchedFrom.x-location.x < historyMenu.frame.size.width)
            historyMenu.frame = CGRectMake(-(touchedFrom.x-location.x), 0, historyMenu.frame.size.width, historyMenu.frame.size.height);
    }
}

/*
 * If the user touches the screen, moves his finger and releases his finger from the screen, the History view will be shown or hidden
 * depending on the amount of pixels the finger is moved on the screen
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Check if it is possible to show the History view
    if (!showingQueue && history.linkQueue.count > 0) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.view];
        
        // If the finger is moved enough pixels to the right to show the History view, animate showing the History view
        if (location.x > touchedFrom.x && location.x-touchedFrom.x > historyMenu.frame.size.width/2)
            [self animateHistoryView:YES];
        // If the finger is moved enough pixels to the left to hide the History view, animate hiding the History view
        else if (location.x < touchedFrom.x && touchedFrom.x-location.x > historyMenu.frame.size.width/2)
            [self animateHistoryView:NO];
        // Else, reset the position of the History view
        else
            historyMenu.frame = historyMenuFrame;
    }
}

/*
 * This method is called when a button is tabbed in the alert popup
 */
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Check if the alert is shown because it is not possible to obtain the GPS location
    if (alertView.tag == 999) {
        // Close the whole app
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(terminate)]) {
            [[UIApplication sharedApplication] performSelector:@selector(terminate)];
        } else {
            kill(getpid(), SIGINT);
        }
    } else {
        // If there was an error showing a Media item, start the next queue item
        [self nextQueueItem];
    }
}

@end