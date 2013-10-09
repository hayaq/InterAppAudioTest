#import "ViewController.h"
#import "IAAudioGenerator.h"

@implementation ViewController{
	IAAudioGenerator *_iaaGenerator;
}

- (void)viewDidLoad{
    [super viewDidLoad];
	_iaaGenerator = [[IAAudioGenerator alloc] init];
	_iaaGenerator.waveFrequency = 1200.0;
}

-(void)setWaveFrequency:(double)freq{
	_iaaGenerator.waveFrequency = freq;
}

@end
