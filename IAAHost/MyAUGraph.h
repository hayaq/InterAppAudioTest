#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface MyAUGraph : NSObject
-(UIImage*)remoteAudioAppIcon;
-(NSURL*)remoteAudioAppURL;
-(void)start;
-(void)stop;
@end
