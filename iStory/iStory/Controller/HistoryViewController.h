//
//  HistoryViewController.h
//  iStory
//
//  Created by Gido Manders on 13-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@class History;

@interface HistoryViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, retain) History *history;
@property (nonatomic, retain) IBOutlet UIScrollView *rightScrollView;

@end
