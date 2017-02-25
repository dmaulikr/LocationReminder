//
//  ArrayManager.h
//  RentTaxi
//
//  Created by Fahad Jamal on 5/23/13.
//  Copyright (c) 2013 iFahja. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArrayManager : NSObject

+(ArrayManager *) sharedInstance;

-(void) saveReminderToFile:(NSMutableDictionary *)reminderDictionary;
-(void) replaceToFile:(NSMutableDictionary *)reminderDictionary withIndex:(NSInteger)index;
- (NSMutableArray *)getAllReminders;

-(BOOL)isNetworkReachable;

@end