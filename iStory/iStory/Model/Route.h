@class Link;

@interface Route : NSObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) Link *start;

@end