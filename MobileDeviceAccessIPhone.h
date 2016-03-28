/*! \mainpage MobileDeviceAccess
 *
 * This module is intended to provide access to the iPhone and iPod Touch file systems.
 * It achieves this via the same mechanism that iTunes uses, relying on direct entry
 * points into an undocumented private framework provided by Apple.
 *
 * This header is intended to be included into code that executes on the iPod/iPhone
 * rather than on the Mac.
 *
 * \author Jeff Laing
 * <br>
 * Copyright 2009 Tristero Computer Systems. All rights reserved.
 */

/// This class is designed to make it easier to listen for notifications from
/// the AMNotificationProxy object on the Mac (which are routed through the
/// com.apple.mobile.notification_proxy service)
///
/// To listen for notifications, create an instance of this object, then
/// register the methods which are to be invoked when specific notifications
/// are recieved.
@interface AMNotificationCenter : NSObject {
}

/// Send the specified message to the nominated object if the specified notification
/// is recieved.  The reciever is not retained so ensure it does not disappear before
/// the notification is ignore:'d
///
/// The message must take no arguments, and return void.
+ (void)send:(SEL)message
		  to:(NSObject*)reciever
		 for:(NSString*)notification;

/// Stop listening for the nominated notification.
+ (void)ignore:(NSString*)notification;

/// Send a notification
+ (void)postNotification:(NSString*)notification;

@end

/// This class is designed to make it easier to determine what applications
/// are actually installed on the iPod.
@interface MobileInstallationProxy : NSObject {
}

+ (id)browse:(NSString*)kind;
+ (id)lookup:(NSString*)identifier;

@end