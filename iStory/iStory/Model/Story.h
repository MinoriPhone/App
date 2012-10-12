@interface Story : NSObject

@property (nonatomic, retain) NSString *zipFilename;
@property (nonatomic, retain) NSString *dir;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *image;
@property (nonatomic, retain) NSMutableArray *routes;

@end