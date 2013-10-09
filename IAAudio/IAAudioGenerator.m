#import "IAAudioGenerator.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>

typedef struct WaveData{
	double frequency;
	double samplignRate;
	double phase;
	uint64_t count;
}WaveData;

void AudioUnitPropertyChanged(void *inRefCon, AudioUnit inUnit,
							  AudioUnitPropertyID inID, AudioUnitScope inScope,
							  AudioUnitElement inElement);

OSStatus renderCallback(void *inRefCon,
						AudioUnitRenderActionFlags 	*ioActionFlags,
						const AudioTimeStamp 		*inTimeStamp,
						UInt32 						inBusNumber,
						UInt32 						inNumberFrames,
						AudioBufferList 			*ioData);


@implementation IAAudioGenerator{
	AudioUnit _remoteIOUnit;
	WaveData  _outputWave;
	NSString *_iaaName;
	AudioComponentDescription _iaaDesc;
}

+(NSString*)iaaName{
	return @"IAAudioTest";
}

+(AudioComponentDescription)iaaDescription{
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_RemoteGenerator;
	desc.componentSubType = 'aaaa';
	desc.componentManufacturer = 'qqqq';
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	return desc;
}

+(AudioComponent)findComponent{
	NSString *iaaName = [IAAudioGenerator iaaName];
	AudioComponentDescription searchDesc = [IAAudioGenerator iaaDescription];
	AudioComponentDescription foundDesc = { 0, 0, 0, 0, 0 };
	AudioComponent foundComp = NULL;
	AudioComponent comp = NULL;
	while( (comp=AudioComponentFindNext(comp,&searchDesc)) ){
		AudioComponentDescription desc;
		if( AudioComponentGetDescription(comp, &desc)!=noErr){
			continue;
		}
		if( desc.componentType != kAudioUnitType_RemoteGenerator ){
			continue;
		}
		CFStringRef cmpName = NULL;
		AudioComponentCopyName(comp,&cmpName);
		if( [iaaName isEqual:(__bridge NSString*)(cmpName)] ){
			foundComp = comp;
			foundDesc = desc;
			CFRelease(cmpName);
			break;
		}
		CFRelease(cmpName);
	}
	return foundComp;
}

+(AudioStreamBasicDescription)streamDescription{
	AudioStreamBasicDescription fmt;
	fmt.mSampleRate = [[AVAudioSession sharedInstance] sampleRate];
	fmt.mFormatID = kAudioFormatLinearPCM;
	fmt.mFormatFlags = kAudioFormatFlagIsPacked|kAudioFormatFlagIsSignedInteger;
	fmt.mBytesPerPacket = 2;
	fmt.mFramesPerPacket = 1;
	fmt.mBytesPerFrame = 2;
	fmt.mChannelsPerFrame = 1;
	fmt.mBitsPerChannel = 2 * 8;
	return fmt;
}

-(id)init{
	self = [super init];
	_outputWave.samplignRate = [[AVAudioSession sharedInstance] sampleRate];
	_outputWave.phase = 0.0;
	_outputWave.count = 0;
	_outputWave.frequency = 400.0;
	_iaaName = [IAAudioGenerator iaaName];
	_iaaDesc = [IAAudioGenerator iaaDescription];
	[self initGeneratorAudioUnit];
	return self;
}

-(double)waveFrequency{
	return _outputWave.frequency;
}

-(void)setWaveFrequency:(double)waveFrequency{
	_outputWave.frequency = waveFrequency;
	_outputWave.count = 0;
	_outputWave.phase = 0;
}

-(void)start{
	NSLog(@"[IAAudioGenerator]: Start remoteIOUnit");
	AudioOutputUnitStart(_remoteIOUnit);
}

-(void)stop{
	NSLog(@"[IAAudioGenerator]: Stop remoteIOUnit");
	AudioOutputUnitStop(_remoteIOUnit);
}

-(void)initGeneratorAudioUnit
{
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	AudioComponent output = AudioComponentFindNext(NULL, &desc);
	AudioComponentInstanceNew(output, &_remoteIOUnit);
	
	UInt32 flag = 1;
	AudioUnitSetProperty(_remoteIOUnit,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Output,
						 0,&flag,sizeof(flag));
	
	AudioStreamBasicDescription fmt = [IAAudioGenerator streamDescription];
	
	AudioUnitSetProperty(_remoteIOUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0,&fmt,sizeof(fmt));
	
	AURenderCallbackStruct callback;
	callback.inputProc = renderCallback;
	callback.inputProcRefCon = &_outputWave;
	AudioUnitSetProperty(_remoteIOUnit,
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 0,&callback,sizeof(callback));
	
	AudioOutputUnitPublish(&_iaaDesc, (__bridge CFStringRef)_iaaName, 1, _remoteIOUnit);
	AudioUnitAddPropertyListener(_remoteIOUnit,
								 kAudioUnitProperty_IsInterAppConnected,
								 AudioUnitPropertyChanged,(__bridge void *)(self));
	
	AudioUnitInitialize(_remoteIOUnit);
}



@end

void AudioUnitPropertyChanged(void *inRefCon, AudioUnit inUnit,
							  AudioUnitPropertyID inID, AudioUnitScope inScope,
							  AudioUnitElement inElement)
{
	IAAudioGenerator *generator = (__bridge IAAudioGenerator*)inRefCon;
    if( inID==kAudioUnitProperty_IsInterAppConnected ){
        UInt32 connect;
        UInt32 dataSize = sizeof(UInt32);
        AudioUnitGetProperty(inUnit, kAudioUnitProperty_IsInterAppConnected,
							 kAudioUnitScope_Global, 0, &connect, &dataSize);
        if( connect ){
			NSLog(@"[IAAudioGenerator]: IAA Connected");
			[generator start];
        }else{
			[generator stop];
			NSLog(@"[IAAudioGenerator]: IAA Disconnected");
		}
    }
}

OSStatus renderCallback(void *inRefCon,
						AudioUnitRenderActionFlags 	*ioActionFlags,
						const AudioTimeStamp 		*inTimeStamp,
						UInt32 						inBusNumber,
						UInt32 						inNumberFrames,
						AudioBufferList 			*ioData)

{
	if( !ioData ){ return noErr; }
	WaveData *wave = (WaveData*)inRefCon;
	const double F = 2.0*M_PI*wave->frequency/wave->samplignRate;
	const double A = 1.0 * INT16_MAX;
	const double O = wave->phase;
	int16_t *ptr = (int16_t*)ioData->mBuffers[0].mData;
	for(int i=0; i<inNumberFrames; i++){
		ptr[i] = A*sin(F*i+O);
	}
	wave->count += inNumberFrames;
	wave->phase = fmod(F*wave->count,2.0*M_PI);
	return noErr;
}

