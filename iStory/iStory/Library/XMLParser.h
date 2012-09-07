//
//  XMLParser.h
//  iStory
//
//  Created by Gido Manders on 07-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Story;

@interface XMLParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentElementValue;
    Story *story;
    NSMutableArray *stories;
}

@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) NSMutableArray *stories;

- (XMLParser *) initXMLParser;

@end
