//
//  XMLParser.h
//  iStory
//
//  Created by Gido Manders on 07-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Story;
@class Route;
@class Link;
@class Node;

@interface XMLParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentElementValue;
    Story *story;
    Route *currentRoute;
    NSMutableArray *currentLinks;
    Node *currentNode;
    NSNumberFormatter *numberFormatter;
    
}

@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Route *currentRoute;
@property (nonatomic, retain) NSMutableArray *currentLinks;
@property (nonatomic, retain) Node *currentNode;
@property (nonatomic, retain) NSNumberFormatter *numberFormatter;

- (XMLParser *) initXMLParser;

@end
