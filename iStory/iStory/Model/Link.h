@class Node;

@interface Link : NSObject

@property (nonatomic, retain) NSNumber *identifier;
@property (nonatomic, retain) NSNumber *shortcut;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Node *from;
@property (nonatomic, retain) Node *to;
@property (nonatomic, retain) NSMutableArray *next;
@property (nonatomic, retain) NSMutableArray *queue;

@end