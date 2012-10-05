//
//  HistoryViewController.m
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "HistoryViewController.h"
#import "History.h"
#import "Link.h"
#import "MediaItem.h"
#import "Image.h"
#import "Video.h"
#import "Message.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation HistoryViewController

@synthesize storyName, history, tableView, rightScrollView, storyEnded;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setScrollViewContent:[history.linkQueue objectAtIndex:0]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setScrollViewContent:(Link *)link
{
    for (UIView *subView in rightScrollView.subviews) {
        [subView removeFromSuperview];
    }
    
    for (MediaItem *object in link.queue) {
        NSString *documentsDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *mediaFilesDir = [documentsDir stringByAppendingPathComponent:storyName];
        NSString *currentMediaFileDir = [mediaFilesDir stringByAppendingPathComponent:[link.identifier stringValue]];
        NSString *filePath = [currentMediaFileDir stringByAppendingPathComponent:object.filename];
        if ([object isKindOfClass:[Video class]])
            [self addMovie:filePath];
        else if ([object isKindOfClass:[Image class]])
            [self addImage:filePath];
        else if ([object isKindOfClass:[Message class]])
            [self addMessage:filePath];
    }
}

- (void)addMovie:(NSString *)path
{
    MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    moviePlayer.view.frame = CGRectMake(10, rightScrollView.subviews.count*160, 218, 150);
    moviePlayer.shouldAutoplay = NO;
    moviePlayer.repeatMode = MPMovieRepeatModeNone;
    moviePlayer.fullscreen = NO;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.scalingMode = MPMovieScalingModeNone;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.view.userInteractionEnabled = NO;
    [rightScrollView addSubview:moviePlayer.view];
    rightScrollView.contentSize = CGSizeMake(rightScrollView.frame.size.width, rightScrollView.contentSize.height+160);
}

- (void)addImage:(NSString *)path
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:path]];
    [rightScrollView addSubview:imageView];
    rightScrollView.contentSize = CGSizeMake(rightScrollView.frame.size.width, rightScrollView.contentSize.height+160);
}

- (void)addMessage:(NSString *)path
{
    UIWebView *message = [[UIWebView alloc] initWithFrame:self.view.frame];
    [message loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
    message.delegate = self;
    [rightScrollView addSubview:message];
    rightScrollView.contentSize = CGSizeMake(rightScrollView.frame.size.width, rightScrollView.contentSize.height+160);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return history.linkQueue.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:identifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.textAlignment = UITextAlignmentRight;
    cell.textLabel.text = [[history.linkQueue objectAtIndex:indexPath.row] valueForKey:@"name"];
    
    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self setScrollViewContent:[history.linkQueue objectAtIndex:indexPath.row]];
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)hideHistory
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
