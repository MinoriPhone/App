@interface MediaItem : NSObject

@property (nonatomic, retain) NSNumber *shortcut;
@property (nonatomic, retain) NSString *filename;
@property NSInteger duration;
@property (nonatomic, retain) NSData *data;
@property MediaItemType type;

- (id)initWithType:(MediaItemType)theType;

@end