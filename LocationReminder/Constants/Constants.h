//
//  Constants.h
//  PakSaw
//
//  Created by Fahad Jamal on 7/31/13.
//  Copyright (c) 2013 iFahja. All rights reserved.
//

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define isIPad UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#define kNumberOfCellsInRow 2

#define LOCATION_MATCHING_RADIUS 100

#define REGION_RADIUS 100

#define INTERNET_ERROR @"The Internet connecton appears to be offline. Plesae connect to internet for Address Fetching."

