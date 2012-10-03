//
//  HistoryViewController.h
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class History, Link;

@interface HistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIWebViewDelegate>

@property (nonatomic, retain) NSString *storyName;
@property (nonatomic, retain) History *history;
@property (nonatomic, retain) IBOutlet UIScrollView *rightScrollView;

- (void)setScrollViewContent:(Link *)link;
- (void)addMovie:(NSString *)path;
- (void)addImage:(NSString *)path;
- (void)addMessage:(NSString *)path;
- (IBAction)hideHistory:(id)sender;

@end
