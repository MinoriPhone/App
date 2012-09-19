//
//  HistoryViewController.h
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class History, Link;

@interface HistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, retain) History *history;
@property (nonatomic, retain) IBOutlet UIScrollView *rightScrollView;

- (void)setScrollViewContent:(Link *)link;
- (void)addMovie:(NSString *)filename;
- (void)addImage:(NSString *)filename;
- (void)addMessage:(NSString *)filename;
- (IBAction)hideHistory:(id)sender;

@end
