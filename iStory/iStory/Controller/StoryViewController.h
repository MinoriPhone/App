#import <MediaPlayer/MediaPlayer.h>
#import <CoreLocation/CoreLocation.h>

@class Location, Story, Link, Node, History, MediaItem;

@interface StoryViewController : UIViewController <CLLocationManagerDelegate, UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) IBOutlet UIImageView *background;
@property (nonatomic, retain) IBOutlet UIView *indicatorView;
@property (nonatomic, retain) IBOutlet UIView *historyMenu;
@property (nonatomic, retain) IBOutlet UITableView *historyTable;
@property (nonatomic, retain) IBOutlet UILabel *debug;
@property (nonatomic, retain) NSString *documentsDir;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIWebView *message;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) NSTimer *locationUpdateTimer;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) NSMutableArray *startLinks;
@property (nonatomic, retain) Link *currentLink;
@property (nonatomic, retain) History *history;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSDate *timerStarted;

- (id)initWithStory:(Story *)newStory folder:(NSString *)folder;
- (void)unzipStory;
- (MediaItem *)currentMediaItem;
- (NSString *)currentFilePath;
- (void)showLinkQueue;
- (void)checkFile;
- (void)playMovie:(NSString *)filename;
- (void)moviePlayerPlaybackStateChanged:(NSNotification *)notification;
- (void)showImage:(NSString *)path duration:(NSInteger)duration;
- (void)hideImage;
- (void)showMessage:(NSString *)path duration:(NSInteger)duration;
- (void)hideMessage;
- (void)nextQueueItem;
- (void)checkLocation;
- (void)animateHistoryView:(BOOL)show;

@end