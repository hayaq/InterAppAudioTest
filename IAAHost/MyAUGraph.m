#import "MyAUGraph.h"
#import "IAAudioGenerator.h"
#import <AVFoundation/AVFoundation.h>

static AudioComponentDescription ACDescMake(OSType,OSType,OSType);

@implementation MyAUGraph{
	AUGraph _graph;
	AudioUnit _remoteAU;
	AudioComponent _remoteComponent;
}

-(id)init{
	self = [super init];
	AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setCategory:AVAudioSessionCategoryPlayback
			 withOptions:AVAudioSessionCategoryOptionMixWithOthers error:Nil];
	[session setActive:YES error:nil];
	[self setupRemoteAudioUnit];
	return self;
}

- (void)dealloc
{
	if( _graph ){
		AUGraphUninitialize(_graph);
		AUGraphClose(_graph);
	}
}

-(void)start{
	if( !_graph ){ return; }
	AUGraphStart(_graph);
}

-(void)stop{
	if( !_graph ){ return; }
	AUGraphStop(_graph);
}

-(UIImage*)remoteAudioAppIcon{
	if( !_remoteComponent ){ return nil; }
	return AudioComponentGetIcon(_remoteComponent,120);
}

-(NSURL*)remoteAudioAppURL{
	NSURL *url = NULL;
	UInt32 urlSize = sizeof(url);
	AudioUnitGetProperty(_remoteAU,
						 kAudioUnitProperty_PeerURL,
						 kAudioUnitScope_Global,
						 0, &url, &urlSize);
	return url;
}

#define AU_CHECK() if(result){ NSLog(@"AUError@%d %08X\n",__LINE__,(uint32_t)result); return; }

-(void)setupRemoteAudioUnit
{
	if( _graph ){ return; }
	
	_remoteComponent = [IAAudioGenerator findComponent];
	if( !_remoteComponent ){ return; }
	
	OSStatus result = NewAUGraph(&_graph);
	
	// output unit
	AudioComponentDescription outDesc = ACDescMake(kAudioUnitType_Output,
												kAudioUnitSubType_RemoteIO,
												kAudioUnitManufacturer_Apple);
	
	AudioComponentDescription mixDesc = ACDescMake(kAudioUnitType_Mixer,
												kAudioUnitSubType_MultiChannelMixer,
												kAudioUnitManufacturer_Apple);
	
	AUNode outNode = 0;
	AUNode mixNode = 0;
	AUNode inNode = 0;
	
	result = AUGraphAddNode(_graph, &outDesc, &outNode);
	AU_CHECK();
	
	result = AUGraphAddNode(_graph, &mixDesc, &mixNode);
	AU_CHECK();
	
	result = AUGraphConnectNodeInput(_graph, mixNode, 0, outNode, 0);
	AU_CHECK();
	
	AudioComponentDescription inDesc;
	AudioComponentGetDescription(_remoteComponent, &inDesc);
	
	AUGraphAddNode(_graph, &inDesc, &inNode);
	result = AUGraphConnectNodeInput(_graph, inNode, 0, mixNode, 0);
	AU_CHECK();
	
	result = AUGraphOpen(_graph);
	AU_CHECK();
	
	AudioStreamBasicDescription fmt = [IAAudioGenerator streamDescription];
	
	AUGraphNodeInfo(_graph, inNode, &inDesc, &_remoteAU);
	AU_CHECK();
	result = AudioUnitSetProperty(_remoteAU,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Output,
								  0, &fmt, sizeof(fmt));
	AU_CHECK();
	
	AudioUnit mixUnit = NULL;
	AUGraphNodeInfo(_graph, mixNode, &mixDesc, &mixUnit);
	AU_CHECK();
	result = AudioUnitSetProperty(mixUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Output,
								  0, &fmt, sizeof(fmt));
	result = AudioUnitSetProperty(mixUnit,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input,
								  0, &fmt, sizeof(fmt));
	AU_CHECK();
	
	result = AUGraphInitialize(_graph);
	AU_CHECK();
}

@end

static AudioComponentDescription ACDescMake(OSType type,OSType subtype, OSType mnfc){
	AudioComponentDescription desc;
	memset(&desc, 0, sizeof(AudioComponentDescription));
	desc.componentType = type;
	desc.componentSubType = subtype;
	desc.componentManufacturer = mnfc;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	return desc;
}

