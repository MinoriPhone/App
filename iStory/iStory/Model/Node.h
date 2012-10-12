#import <CoreLocation/CoreLocation.h>

@interface Node : NSObject

@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *radius;
@property (nonatomic, retain) CLLocation *location;

@end