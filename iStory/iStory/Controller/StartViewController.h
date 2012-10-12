@class StoryViewController, History;

@interface StartViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray *stories;
@property (nonatomic, retain) StoryViewController *storyViewController;
@property (nonatomic, retain) NSString *documentsDir;

- (void)readZippedFiles;
- (void)getStoryImages;
- (void)parse:(NSData *)data zipFilename:(NSString *)zipFilename;
- (IBAction)buttonPressed:(id)sender;

@end