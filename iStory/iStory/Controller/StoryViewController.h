//
//  ViewController.h
//  iStory
//
//  Created by Gido Manders on 06-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface StoryViewController : UIViewController {
    MPMoviePlayerController *moviePlayer;
}

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;

- (void)playMovie:(NSString *)filename;

@end
