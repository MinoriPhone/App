@class Story, Route, Link, Node, MediaItem;

@interface XMLParser : NSObject <NSXMLParserDelegate> {
    NSMutableString *currentElementValue;
    Story *story;
    Route *currentRoute;
    NSMutableArray *currentLinks;
    Node *currentNode;
    NSMutableArray *currentQueue;
    MediaItem *currentMediaItem;
    NSNumberFormatter *numberFormatter;
}

@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) Route *currentRoute;
@property (nonatomic, retain) NSMutableArray *currentLinks;
@property (nonatomic, retain) Node *currentNode;
@property (nonatomic, retain) NSMutableArray *currentQueue;
@property (nonatomic, retain) MediaItem *currentMediaItem;
@property (nonatomic, retain) NSNumberFormatter *numberFormatter;

- (XMLParser *) initXMLParser;

@end