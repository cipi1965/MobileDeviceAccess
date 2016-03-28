//
//  MobileDeviceAccessIPhone.m
//  Apps@HomeII
//
//  Created by Jeff Laing on 7/11/09.
//  Copyright 2009 Tristero Computer Systems. All rights reserved.
//

#import "MobileDeviceAccessIPhone.h"

static id _notificationHandlers = nil;

// we create an instance of these so that we can dispatch notifications
// to different objects.
@interface _handler : NSObject
{
	NSObject *_target;
	SEL _selector;
	NSMutableDictionary *_dict;
	NSString *_notification;
}
@end

@implementation _handler

static
void notificationDispatcher(
							CFNotificationCenterRef center,
							void                    *observer,
							CFStringRef             name,
							const void              *alwaysZero1,
							CFDictionaryRef         alwaysZero2)
{
	NSMutableDictionary *_notificationHandlers = (NSMutableDictionary*)observer;
	if (_notificationHandlers) {
		_handler *h = [_notificationHandlers objectForKey:(NSString*)name];
		if (h) {
			//	NSLog(@"send %@ to %@",NSStringFromSelector(h->_selector),h->_target);
			[h->_target performSelector:h->_selector];
		}
	}
}

- (id) initWithTarget:(NSObject*)target
		  andSelector:(SEL)selector
	  andNotification:(NSString*)notification
			   inDict:(NSMutableDictionary*)dict
{
	if (self=[super init]) {
		_target = target;
		_selector = selector;
		_notification = [notification copy];

		_dict = dict;
		[_dict setObject:self forKey:_notification];
		CFNotificationCenterAddObserver(
			CFNotificationCenterGetDarwinNotifyCenter(),
			_dict,
			notificationDispatcher,
			(CFStringRef)_notification,	// eg, @"com.myapp.notification"
			NULL,
			0 );
	}
	return self;
}

- (void)dealloc
{
	CFNotificationCenterRemoveObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		_dict,
		(CFStringRef)_notification,	// eg, @"com.myapp.notification"
		NULL );

	[_notification release];
	[super dealloc];
}

@end

@implementation AMNotificationCenter

+ (void)initialize
{
	_notificationHandlers = [NSMutableDictionary new];
}

+ (void)send:(SEL)message
		  to:(id)reciever
		 for:(NSString*)notification
{
	_handler *h = [[_handler alloc]
						initWithTarget:reciever
						andSelector:message
						andNotification:notification
						inDict:_notificationHandlers];
	// we can release now, the handler is retained by the dictionary
	[h release];
}

+ (void)ignore:(NSString*)notification
{
	_handler *h = [_notificationHandlers objectForKey:notification];
	if (h) {
		// removing it from the dictionary will release it, which
		// will un-register the observer
		[_notificationHandlers removeObject:h];
	}
}

/// Send a notification
+ (void)postNotification:(NSString*)notification
{
	CFNotificationCenterPostNotification (
		CFNotificationCenterGetDarwinNotifyCenter(),
		(CFStringRef)notification,
		nil,
		nil,
		YES );
}

@end

@implementation MobileInstallationProxy

// defined in PrivateFrameworks/MobileInstallation.Framework, though not with these arguments
int MobileInstallationBrowse(NSDictionary *options, int (*mibcallback)(NSDictionary *dict, id usercon), id usercon);

static int browse_mibcallback(NSDictionary *dict, id result)
{
	NSArray *currentlist = [dict objectForKey:@"CurrentList"];
	if (currentlist) {
		for (NSDictionary *appinfo in currentlist) {
			[(NSMutableArray*)result addObject:[[appinfo copy] autorelease]];
		}
	}

	return 0;
}

+ (id)browse:(NSString*)kind
{
	if (!kind) kind=@"Any";
	NSMutableArray *result = [NSMutableArray new];
	MobileInstallationBrowse(
		[NSDictionary dictionaryWithObject:kind forKey:@"ApplicationType"],
		&browse_mibcallback,
		result);
	return [result autorelease];
}

static id foundEntry;
static int lookup_mibcallback(NSDictionary *dict, id soughtEntry)
{
	NSArray *currentlist = [dict objectForKey:@"CurrentList"];
	if (currentlist) {
		for (NSDictionary *appinfo in currentlist) {
			if ([[appinfo objectForKey:@"CFBundleIdentifier"] isEqual:soughtEntry]) {
				foundEntry = [appinfo copy];
				return;
			}
		}
	}
	return 0;
}

+ (id)lookup:(NSString*)identifier
{
	NSMutableArray *result = [NSMutableArray new];
	foundEntry = nil;
	MobileInstallationBrowse(
		[NSDictionary dictionaryWithObject:@"Any" forKey:@"ApplicationType"],
		&lookup_mibcallback,
		identifier);
	return [foundEntry autorelease];
}

@end
