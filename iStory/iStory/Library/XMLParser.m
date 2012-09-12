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

@implementation XMLParser
@synthesize story, currentLinks, currentNode, currentRoute;

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
        return;
    }
    if ([elementName isEqualToString:@"routes"]) {
        story.routes = [[NSMutableArray alloc] init];
    }
    
    if ([elementName isEqualToString:@"route"]) {
        currentRoute = [[Route alloc] init];
    }
    
    if ([elementName isEqualToString:@"link"] || [elementName isEqualToString:@"route.link"]) {
        if(currentLinks == nil)
            currentLinks = [[NSMutableArray alloc] init];
        [currentLinks addObject:[[Link alloc] init]];
    }
    
    if ([elementName isEqualToString:@"from"] || [elementName isEqualToString:@"to"]) {
        currentNode = [[Node alloc] init];
    }
    
    if([elementName isEqualToString:@"links"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:[[NSMutableArray alloc] init] forKey:@"next"];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentElementValue) {
        
        // currentStringValue is an NSMutableString instance variable
        
        currentElementValue = [[NSMutableString alloc] initWithCapacity:50];
        
    }
    
    [currentElementValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    if ([elementName isEqualToString:@"story"]) {
        return;
    }
    
    if ([elementName isEqualToString:@"story.name"]) {
        story.name = currentElementValue;
        currentElementValue = nil;
        return;
    }
    
    if ([elementName isEqualToString:@"route.name"]) {
        currentRoute.name = currentElementValue;
        currentElementValue = nil;
        return;
    }
    
    if ([elementName isEqualToString:@"route"]) {
        [story.routes addObject:currentRoute];
        currentRoute = nil;
        return;
    }
    
    if ([elementName isEqualToString:@"route.link"]) {
        currentRoute.start = [currentLinks objectAtIndex:currentLinks.count-1];
        return;
    }
    
    if([elementName isEqualToString:@"longitude"])
    {
        currentNode.longitude = [numberFormatter numberFromString:currentElementValue];
        return;
    }
    
    if([elementName isEqualToString:@"latitude"])
    {
        currentNode.latitude = [numberFormatter numberFromString:currentElementValue];
        return;
    }
    
    if ([elementName isEqualToString:@"link"]) {
        [[[currentLinks objectAtIndex:currentLinks.count-2] valueForKey:@"next"] addObject:[currentLinks objectAtIndex:currentLinks.count-1]];
        [currentLinks removeLastObject];
        return;
    }
    
    if ([elementName isEqualToString:@"from"] || [elementName isEqualToString:@"to"]) {
        [[currentLinks objectAtIndex:currentLinks.count-1] setValue:currentNode forKey:elementName];
        currentNode = nil;
        return;
    }
    currentElementValue = nil;
    
}

@end
