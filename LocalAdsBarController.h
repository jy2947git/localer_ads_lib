//
//  LocalAdsBarControler.h
//  mylocal
//
//  Created by Junqiang You on 6/3/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CLLocation;
@interface LocalAdsBarController : UIViewController {
	@private
	NSMutableDictionary *ads;
	CLLocation *currentLocation;
	UILabel *adsLabel;
}

-(void)activateAdsBar:(CLLocation*)myLocation;

@end
