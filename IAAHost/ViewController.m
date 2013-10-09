//
//  ViewController.m
//  IAAHost
//
//  Created by hayashi on 10/8/13.
//  Copyright (c) 2013 Qoncept. All rights reserved.
//

#import "ViewController.h"
#import "MyAUGraph.h"

#define GENERATOR_NAME @"IAADataEx"

@interface ViewController (){
	MyAUGraph *_myGraph;
	IBOutlet UIButton *_iaaAppButton;
}
@end

@implementation ViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appDidEnterBackground)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appWillEnterForeground)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
	[self start];
}

-(void)start{
	_myGraph = [[MyAUGraph alloc] init];
	[_iaaAppButton setImage:[_myGraph remoteAudioAppIcon] forState:UIControlStateNormal];
	[_iaaAppButton setTitle:@"" forState:UIControlStateNormal];
	[_myGraph start];
}

-(void)stop{
	[_myGraph stop];
	_myGraph = nil;
}

-(void)appWillEnterForeground{
	[self start];
}

-(void)appDidEnterBackground{
	[self stop];
}

-(IBAction)iaaButtonDidTouch:(id)sender{
	NSURL *appURL = [_myGraph remoteAudioAppURL];
	if( appURL ){
		[[UIApplication sharedApplication] openURL:appURL];
	}
}

@end
