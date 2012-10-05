//
//  StartViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class StoryViewController, History;

@interface StartViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray *stories;
@property (nonatomic, retain) StoryViewController *storyViewController;

- (void)readZippedFiles;
- (void)getStoryImages;
- (void)parse:(NSData *)data zipFilename:(NSString *)zipFilename;
- (IBAction)buttonPressed:(id)sender;
- (void)storyEnded:(History *)history;

@end
