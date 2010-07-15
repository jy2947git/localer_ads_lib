//
//  LocalAdsBarControler.m
//  mylocal
//
//  Created by Junqiang You on 6/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LocalAdsBarController.h"
#import "CoreLocation/CLLocation.h"

@interface LocalAdsBarController()

@property(nonatomic, retain) CLLocation *currentLocation;
@property(nonatomic, retain) NSMutableDictionary *ads;
@property(nonatomic, retain) UILabel *adsLabel;
-(void)downloadAdsForLocation:(CLLocation*)location To:(NSMutableDictionary*)adsArray;
-(void)reportAdsDisplayData;
-(void)animateMessageToLeftBorder:(NSString*)message;
-(void)animateMessageOutOfLeftBorder:(NSString*)message;
-(NSString*)sendGetMethod:(NSString*)urlString error:(NSError *)error;
@end

@implementation LocalAdsBarController
@synthesize ads;
@synthesize currentLocation;
@synthesize adsLabel;


int currentMessage=0;
//NSString *adsServerHost=@"localhost:8083";
NSString *adsServerHost=@"locallerads.appspot.com";
NSString *adsServerToken=@"939237200300-1=39012";

-(id)init{
	if((self=[super init])!=nil){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reportAdsDisplayData) name:UIApplicationWillTerminateNotification object:[UIApplication sharedApplication]];
		
		
		NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
		self.ads = d;
		[d release];
		
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 460, 320, 20)];
		
		label.backgroundColor=[UIColor clearColor];
		label.font=[UIFont systemFontOfSize:13];
		label.textColor=[UIColor whiteColor];
		self.adsLabel=label;
		[label release];
	}
	return self;
}

-(UIView*)view{
	return self.adsLabel;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}






-(void)activateAdsBar:(CLLocation*)myLocation{
	self.currentLocation=myLocation;
	//download ads
	[self downloadAdsForLocation:self.currentLocation To:self.ads];
	//set up ads bar if there is ads
	if(self.ads!=nil && [self.ads count]>0 ){
		//start display ads
		[self animateMessageToLeftBorder:[self.ads.allKeys objectAtIndex:currentMessage]];
	}
}

-(void)downloadAdsForLocation:(CLLocation*)location To:(NSMutableDictionary*)adsDictionary{
	NSString *latitudeString = [[NSString alloc]initWithFormat:@"%.6f",self.currentLocation.coordinate.latitude];
	NSString *longitudeString = [[NSString alloc]initWithFormat:@"%.6f",self.currentLocation.coordinate.longitude];
	NSString *messageString = [[NSString alloc] initWithFormat:@"token=%@&command=browse&start=0&end=100&latitude=%@&longitude=%@",adsServerToken,latitudeString,longitudeString];
	//DebugLog(@"request:%@", messageString);
    //NSString *encodedMessageString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)messageString, CFSTR(""), CFSTR(" %\"?=&+<>;:-"),  kCFStringEncodingUTF8);
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/serve?%@",adsServerHost, messageString];
	NSError *error = nil;

	NSString *replyString = [self sendGetMethod:urlString error:error];
	[urlString release];
	[messageString release];
	[latitudeString release];
	[longitudeString release];

	
	if(error){
		//could not log on, alert
		//[self displayWarning:NSLocalizedString(@"Could not connect to server",@"Could not connect to server")];
		return;
	}else{
		
		//success SUCCESS|id^address^desecription^startDate^endDate|id2
		if(replyString!=nil && [replyString rangeOfString:@"SUCCESS"].location!=NSNotFound){
			//success
			[adsDictionary removeAllObjects];
			NSArray *components = [[replyString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"|"];
			if(components!=nil && [components count]>1){
				//there are records
				for(int i=1;i<[components count];i++){
					NSMutableString *s = [[NSMutableString alloc] initWithString:[components objectAtIndex:i]];
					//calculate distance from me, and append it
					[adsDictionary setValue:@"0" forKey:s];
					[s release];
				}
			}else{
				//DebugLog(@"no data");
				//[self displayWarning:NSLocalizedString(@"No sale around you",@"No sale around you")];
			}
		}else{
			//strange
			//DebugLog(@"no error, and not success either");
			//[self displayWarning:NSLocalizedString(@"Server was too busy or down",@"Server was too busy or down")];
		}
		
		[replyString release];
		
	}
	
}

-(void)reportAdsDisplayData{
	//DebugLog(@"reporting....");
	
	NSArray *messages = self.ads.allKeys;

	for(int i=0; i<[messages count];i++){
		NSString *s = [messages objectAtIndex:i];
		NSArray *components = [s componentsSeparatedByString:@"^"];
		NSString *messageId = [components objectAtIndex:0];
		NSString *displayCount = [self.ads valueForKey:s];
		if([displayCount intValue]<=0){
			continue;
		}
		NSString *latitudeString = [[NSString alloc]initWithFormat:@"%.6f",self.currentLocation.coordinate.latitude];
		NSString *longitudeString = [[NSString alloc]initWithFormat:@"%.6f",self.currentLocation.coordinate.longitude];
		NSString *messageString = [[NSString alloc] initWithFormat:@"token=%@&command=report&id=%@&count=%@&latitude=%@&longitude=%@",adsServerToken,messageId, displayCount, latitudeString,longitudeString];
		//DebugLog(@"request:%@", messageString);
		//NSString *encodedMessageString = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)messageString, CFSTR(""), CFSTR(" %\"?=&+<>;:-"),  kCFStringEncodingUTF8);
		NSString *urlString = [[NSString alloc] initWithFormat:@"http://%@/serve?%@",adsServerHost, messageString];
		NSError *error = nil;
		
		NSString *replyString = [self sendGetMethod:urlString error:error];
		[urlString release];
		[messageString release];
		[latitudeString release];
		[longitudeString release];
		
		
		if(error){
			//DebugLog(@"failed to connect");
			break;
		}else{
			
			//success
			//DebugLog(@"reported %@", replyString);
			
			
			[replyString release];
		}
	}

}

-(void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context{
	//DebugLog(@"one message is done, display next");
	if(animationID==@"move-to-left-border"){
		[self performSelector:@selector(animateMessageOutOfLeftBorder:) withObject:[self.ads.allKeys objectAtIndex:currentMessage] afterDelay:5];
	}else if(animationID==@"move-out-totally"){
		//plus one of the message displayed
		NSMutableString *s = [self.ads.allKeys objectAtIndex:currentMessage];
		NSString *currentCount = [self.ads valueForKey:s];
		NSString *newCount = [[NSString alloc] initWithFormat:@"%i", [currentCount intValue]+1];
		[self.ads setValue:newCount forKey:s];
		[newCount release];
		
		//increase the message count
		currentMessage++;
		if(currentMessage>=[self.ads count]){
			currentMessage=0;
		}
		[self performSelector:@selector(animateMessageToLeftBorder:) withObject:[self.ads.allKeys objectAtIndex:currentMessage] afterDelay:0];
	}
}

-(void)animateMessageToLeftBorder:(NSString*)message{
	//
	NSArray *components = [message componentsSeparatedByString:@"^"];
	self.adsLabel.text=[components objectAtIndex:3];
	
	CGRect originalFrame = CGRectMake(20, self.adsLabel.frame.origin.y, [self.adsLabel.text length]*10, self.adsLabel.frame.size.height);
	//move to right side
	int animationDuration=5;
	self.adsLabel.frame = CGRectMake(320+[self.adsLabel.text length]*0.7, originalFrame.origin.y, [self.adsLabel.text length]*10, originalFrame.size.height);
	//move to left then disaapear
	[UIView beginAnimations:@"move-to-left-border" context: nil ]; // Tell UIView we're ready to start animations.
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop: finished: context:)];
	[UIView setAnimationCurve: UIViewAnimationCurveLinear];
	[UIView setAnimationDuration: animationDuration]; // Set the duration.
	CGRect f2 = self.adsLabel.frame;
	//f2.origin.x=(int)[msg length]*(-7)+10;
	f2.origin.x=10;
	self.adsLabel.frame=f2;
	[UIView commitAnimations];
}

-(void)animateMessageOutOfLeftBorder:(NSString*)message{
	NSArray *components = [message componentsSeparatedByString:@"^"];
	self.adsLabel.text=[components objectAtIndex:3];
	
	
	//continue move to left side, and disappear
	int animationDuration=[self.adsLabel.text length]*0.2;
	[UIView beginAnimations:@"move-out-totally" context: nil ]; // Tell UIView we're ready to start animations.
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop: finished: context:)];
	[UIView setAnimationCurve: UIViewAnimationCurveLinear];
	[UIView setAnimationDuration: animationDuration]; // Set the duration.
	CGRect f2 = self.adsLabel.frame;
	f2.origin.x=(int)[self.adsLabel.text length]*(-7)+10;
	self.adsLabel.frame=f2;
	[UIView commitAnimations];
}


-(NSString*)sendGetMethod:(NSString*)urlString error:(NSError *)error{
	//DebugLog(@"%@",urlString);
	NSString *urlEncodedString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:urlEncodedString]];
	
	// send it
	NSURLResponse *response;
	NSData *serverReply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	[request release];
	if(error){
		return nil;
	}else{
		//NSString *replyString = [[NSString alloc] initWithBytes:[serverReply bytes] length:[serverReply length] encoding: NSUTF8StringEncoding];
		NSString *replyString = [[NSString alloc] initWithData:serverReply encoding:NSUTF8StringEncoding];
		return replyString;
	}
}

- (void)dealloc {
	[self.adsLabel release];
	[self.currentLocation release];	
	[self.ads release];
	[super dealloc];
}



@end
