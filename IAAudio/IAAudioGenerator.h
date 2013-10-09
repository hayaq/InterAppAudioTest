//
//  IAAudio.h
//  InterAppDataEx
//
//  Created by hayashi on 10/8/13.
//  Copyright (c) 2013 Qoncept. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@interface IAAudioGenerator : NSObject
+(NSString*)iaaName;
+(AudioComponentDescription)iaaDescription;
+(AudioComponent)findComponent;
+(AudioStreamBasicDescription)streamDescription;
@property (assign) double waveFrequency;
@end

