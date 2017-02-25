//
//  ArrayManager.h
//  RentTaxi
//
//  Created by Fahad Jamal on 5/23/13.
//  Copyright (c) 2013 iFahja. All rights reserved.
//

#import "ArrayManager.h"
#import "Reachability.h"

@implementation ArrayManager

#pragma mark - init Method -

-(id) init  {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

#pragma mark - Shared Instance Method -

+(ArrayManager *) sharedInstance {
	static id singletonObject = nil;
	if(singletonObject == nil) {
		singletonObject = [[ArrayManager alloc] init];
	}
	return singletonObject;
}

#pragma mark - Instance methods -

-(void) replaceToFile:(NSMutableDictionary *)reminderDictionary withIndex:(NSInteger)index {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *reminderList = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"ReminderList"]];
    [reminderList replaceObjectAtIndex:index withObject:reminderDictionary];
    [defaults setObject:reminderList forKey:@"ReminderList"];
    [defaults synchronize];
}

-(void) saveReminderToFile:(NSMutableDictionary *)reminderDictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *reminderList = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"ReminderList"]];
    [reminderList addObject:reminderDictionary];
    [defaults setObject:reminderList forKey:@"ReminderList"];
    [defaults synchronize];
}

- (NSMutableArray *)getAllReminders {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *reminderList = [[NSMutableArray alloc] initWithArray:[defaults objectForKey:@"ReminderList"]];
    return reminderList;
}

-(BOOL)isNetworkReachable {
    Reachability *internetReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus remoteHostStatus = [internetReachability currentReachabilityStatus];
    if (remoteHostStatus == NotReachable)
        return NO;
    else if (remoteHostStatus == ReachableViaWiFi || remoteHostStatus == ReachableViaWWAN)
        return YES;
    return NO;
}


@end
