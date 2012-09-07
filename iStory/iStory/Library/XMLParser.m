//
//  XMLParser.m
//  iStory
//
//  Created by Gido Manders on 07-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "XMLParser.h"
#import "Story.h"

@implementation XMLParser
@synthesize story, stories;

- (XMLParser *) initXMLParser {
    self = [super init];
    stories = [[NSMutableArray alloc] init];
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"story"]) {
        story = [[Story alloc] init];
        //user.att = [[attributeDict objectForKey:@"<att name>"] ...];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentElementValue) {
        // init the ad hoc string with the value
        currentElementValue = [[NSMutableString alloc] initWithString:string];
    } else {
        // append value to the ad hoc string
        [currentElementValue appendString:string];
    }
}  

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"stories"]) {
        // We reached the end of the XML document
        return;
    }
    
    if ([elementName isEqualToString:@"story"]) {
        [stories addObject:story];
        story = nil;
    } else {
        // The parser hit one of the element values
        [story setValue:currentElementValue forKey:elementName];
    }
    
    currentElementValue = nil;
}

@end
