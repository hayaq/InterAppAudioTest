#import "AppDelegate.h"
#import "ViewController.h"

@implementation AppDelegate{
}


- (BOOL)application:(UIApplication*)application
			openURL:(NSURL*)url
  sourceApplication:(NSString*)sourceApplication
		 annotation:(id)annotation{
	//NSDictionary *args = [self parseQueryString:[url query]];
	NSLog(@"%@",url);
	//NSLog(@"%@",args);
	/*NSString *freq = [args objectForKey:@"freq"];
	if( freq ){
		[_viewController setWaveFrequency:[freq doubleValue]];
		return YES;
	}*/
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application{
}

- (void)applicationDidEnterBackground:(UIApplication *)application{
}

- (void)applicationWillEnterForeground:(UIApplication *)application{
	
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [dict setObject:val forKey:key];
    }
    return dict;
}

@end
