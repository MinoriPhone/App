//
//  XMLParser.m
//  iStory
//
//  Created by Gido Manders on 07-09-2012.
//  Copyright (c) 2012 HSS. All rights reserved.
//

#import "XMLParser.h"
#import "Story.h"
#import "Route.h"
#import "Link.h"
#import "Node.h"
#import "MediaItem.h"
#import "Video.h"
#import "Image.h"
#import "Message.h"

@implementation XMLParser
@synthesize story, currentLinks, currentNode, currentQueue, currentRoute;

- (XMLParser *) initXMLParser {
    self = [super init];
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    currentElementValue = nil;
    
    if ([elementName isEqualToString:@"story"]) {
        story = [[Story alloc] init];
    } else if ([elementName isEqualToString:@"routes"]) {
        story.routes = [[NSMutableArray alloc] init];
    } else if ([elementName isEqualToString:@"route"]) {
        currentRoute = [[Route alloc] init];
    } else if ([elementName isEqualToString:@"link"] || [elementName isEqualToString:@"route.link"]) {
        if(currentLinks == nil)
            currentLinks = [[NSMutableArray alloc] init];
        [currentLinks addObject:[[Link alloc] init]];
    } else if ([elementName isEqualToString:@"from"] || [elementName isEqualToString:@"to"]) {
        currentNode = [[Node alloc] init];
    } else if([elementName isEqualToString:@"links"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:[[NSMutableArray alloc] init] forKey:@"next"];
    } else if([elementName isEqualToString:@"queue"]) {
        currentQueue = [[NSMutableArray alloc] init];
    } else if([elementName isEqualToString:@"video"]) {
        currentMediaItem = [[Video alloc] init];
    } else if([elementName isEqualToString:@"image"]) {
        currentMediaItem = [[Image alloc] init];
    } else if([elementName isEqualToString:@"message"]) {
        currentMediaItem = [[Message alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentElementValue) {
        // currentStringValue is an NSMutableString instance variable
        currentElementValue = [[NSMutableString alloc] init];
    }
    
    [currentElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"story.name"]) {
        story.name = currentElementValue;
    } else if ([elementName isEqualToString:@"route.name"]) {
        currentRoute.name = currentElementValue;
    } else if ([elementName isEqualToString:@"route"]) {
        [story.routes addObject:currentRoute];
        currentRoute = nil;
    } else if ([elementName isEqualToString:@"route.link"]) {
        currentRoute.start = [currentLinks objectAtIndex:currentLinks.count-1];
    } else if([elementName isEqualToString:@"longitude"]) {
        currentNode.longitude = [numberFormatter numberFromString:currentElementValue];
    } else if([elementName isEqualToString:@"latitude"]) {
        currentNode.latitude = [numberFormatter numberFromString:currentElementValue];
    } else if ([elementName isEqualToString:@"link"]) {
        [[[currentLinks objectAtIndex:currentLinks.count-2] valueForKey:@"next"] addObject:[currentLinks objectAtIndex:currentLinks.count-1]];
        [currentLinks removeLastObject];
    } else if ([elementName isEqualToString:@"link.name"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:currentElementValue forKey:@"name"];
    } else if ([elementName isEqualToString:@"from"] || [elementName isEqualToString:@"to"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:currentNode forKey:elementName];
        currentNode = nil;
    } else if([elementName isEqualToString:@"queue"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:currentQueue forKey:@"queue"];
        currentQueue = nil;
    } else if([elementName isEqualToString:@"video"] || [elementName isEqualToString:@"image"] || [elementName isEqualToString:@"message"]) {
        [currentQueue addObject:currentMediaItem];
        currentMediaItem = nil;
    } else if([elementName isEqualToString:@"filename"]) {
        currentMediaItem.filename = currentElementValue;
    } else if([elementName isEqualToString:@"duration"]) {
        currentMediaItem.duration = [currentElementValue intValue];
    }
    
    currentElementValue = nil;
    return;
}

@end
