//
//  StartViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

@interface StartViewController : UITableViewController {
    NSMutableArray *stories;
}

@property (nonatomic, retain) NSMutableArray *stories;

- (void)parse:(NSData *)data;

@end
