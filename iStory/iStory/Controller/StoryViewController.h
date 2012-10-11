//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>

@class Location, Story, Link, Node, History, MediaItem;

@interface StoryViewController : UIViewController <CLLocationManagerDelegate, UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *background;
@property (nonatomic, retain) IBOutlet UIView *indicatorView;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIWebView *message;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Link *currentLink;
@property NSInteger currentQueueIndex;
@property (nonatomic, retain) MediaItem *currentMediaItem;
@property (nonatomic, retain) History *history;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) IBOutlet UIView *historyMenu;
@property (nonatomic, retain) IBOutlet UITableView *historyTable;
@property (nonatomic, retain) NSString *currentFilePath;
@property (nonatomic, retain) NSDate *timerStarted;
@property BOOL started;
@property BOOL ended;
@property BOOL storyUnzipped;
@property BOOL showingQueue;

- (id)initWithStory:(Story *)newStory;
- (void)unzipStory;
- (void)showLinkQueue;
- (void)checkFile;
- (void)playMovie:(NSString *)filename;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
- (void)showImage:(NSString *)path duration:(NSInteger)duration;
- (void)hideImage;
- (void)showMessage:(NSString *)path duration:(NSInteger)duration;
- (void)hideMessage;
- (void)checkLocation;
- (void)animateHistoryView:(BOOL)show;

@end
