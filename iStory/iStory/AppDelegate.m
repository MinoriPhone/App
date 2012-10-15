#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window, startViewController, navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    application.idleTimerDisabled = YES;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.startViewController = [[StartViewController alloc] initWithNibName:@"StartViewController" bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.startViewController];
    self.navigationController.navigationBarHidden = YES;
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end