//
//  MobileDeviceAccess.m
//  MobileDeviceAccess
//
//  Created by Jeff Laing on 6/08/09.
//  Copyright 2009 Tristero Computer Systems. All rights reserved.
//
#import "MobileDeviceAccess.h"
#include <unistd.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <mach/error.h>
#include <AppKit/NSApplication.h>


#pragma mark MobileDevice.framework internals

// opaque structures
typedef struct _afc_directory			*afc_directory;
typedef struct _afc_dictionary			*afc_dictionary;
typedef struct _afc_operation			*afc_operation;

// some functions use different size longs on the different architectures
#if __x86_64__
typedef uint64_t	am_long;
#else
typedef uint32_t	am_long;
#endif

// Messages passed to device notification callbacks: passed as part of
// am_device_notification_callback_info.
typedef enum {
	ADNCI_MSG_CONNECTED		= 1,
	ADNCI_MSG_DISCONNECTED	= 2,
	ADNCI_MSG_UNSUBSCRIBED	= 3
} adnci_msg;

struct am_device_notification_callback_info {
	am_device	dev;				// 0    device
	uint32_t	msg;				// 4    one of adnci_msg
} __attribute__ ((packed));

// The type of the device notification callback function.
typedef void (*am_device_notification_callback)(struct am_device_notification_callback_info *,void* callback_data);

// notification related functions
mach_error_t AMDeviceNotificationSubscribe(
	am_device_notification_callback callback,
	uint32_t unused0,
	uint32_t unused1,
	void *callback_data,
	am_device_notification *notification);

mach_error_t AMDeviceNotificationUnsubscribe(
	am_device_notification subscription);

// device related functions
mach_error_t	AMDeviceConnect(am_device device);
mach_error_t	AMDeviceDisconnect(am_device device);
uint32_t		AMDeviceGetInterfaceType(am_device device);
enum {
    AMDeviceInterfaceTypeUSB = 1,
    AMDeviceInterfaceTypeWifi = 2
};

//uint32_t		AMDeviceGetInterfaceSpeed(am_device device);
//uint32_t		AMDeviceGetConnectionID(am_device device);
//CFStringRef		AMDeviceCopyDeviceIdentifier(am_device device);
CFStringRef		AMDeviceCopyValue(am_device device,CFStringRef domain,CFStringRef key);
mach_error_t	AMDeviceRetain(am_device device);
mach_error_t	AMDeviceRelease(am_device device);

// I can see these in the framework, but they don't seem to be exported
// in a way that lets us link directly against them
//?notexp? CFStringRef AMDeviceCopyDeviceLocation(am_device device);
//		looks to just return dword[device+28]
//?notexp? uint32_t AMDeviceUSBDeviceID(am_device device);
//?notexp? uint32_t AMDeviceUSBLocationID(am_device device);
//?notexp? uint32_t AMDeviceUSBProductID(am_device device);

// int AMDeviceIsPaired(am_device device);
// 000039f5 T _AMDevicePair (am_device)
// mach_error_t AMDeviceValidatePairing(am_device device);
// 000037e6 T _AMDeviceUnpair (am_device)

mach_error_t AMDeviceLookupApplications(am_device device, CFDictionaryRef options, CFDictionaryRef *result);

// 0000251f T _AMDeviceActivate (am_device, int32 )
// 000088ad T _AMDeviceArchiveApplication (am_device, int32, int32, int32, int32)
// 0000891e T _AMDeviceBrowseApplications (am_device, int32)
// 00008ecd T _AMDeviceCheckCapabilitiesMatch
// 0000179b T _AMDeviceConvertError
// 00009063 T _AMDeviceCopyProvisioningProfiles
// 00004133 T _AMDeviceCreate
// 000041d7 T _AMDeviceCreateFromProperties
// 0000243d T _AMDeviceDeactivate (am_device)
// 0000235b T _AMDeviceEnterRecovery (am_device)
// 00008c74 T _AMDeviceInstallApplication
// 0000a598 T _AMDeviceInstallPackage
// 00008f59 T _AMDeviceInstallProvisioningProfile
// 0000159a T _AMDeviceIsValid
// 00008710 T _AMDeviceLookupApplicationArchives
// 00008990 T _AMDeviceLookupApplications (am_device, int32, int32)
// 00009353 T _AMDeviceMountImage
// 000087cb T _AMDeviceRemoveApplicationArchive
// 00008fde T _AMDeviceRemoveProvisioningProfile
// 00002608 T _AMDeviceRemoveValue
// 0000883c T _AMDeviceRestoreApplication
// 0000121a T _AMDeviceSerialize
// 0000280f T _AMDeviceSetValue
// 00005ec5 T _AMDeviceSoftwareUpdate
// 0000794b T _AMDeviceTransferApplication
// 00008a91 T _AMDeviceUninstallApplication
// 0000a232 T _AMDeviceUninstallPackage
// 00003e21 T _AMDeviceUnserialize
// 00008b02 T _AMDeviceUpgradeApplication
// 000035d3 T _AMDeviceValidatePairing

// session related functions
mach_error_t AMDeviceStartSession(am_device device);
mach_error_t AMDeviceStopSession(am_device device);

// service related functions
mach_error_t AMDeviceStartService(am_device device, CFStringRef service_name, am_service *handle);
mach_error_t AMDeviceStartServiceWithOptions(am_device device,CFStringRef service_name,CFDictionaryRef options,am_service *handle);
// 000067f9 T _AMDeviceStartHouseArrestService

// AFC connection functions
afc_error_t AFCConnectionOpen(am_service handle,uint32_t io_timeout,afc_connection *conn);
afc_error_t AFCConnectionClose(afc_connection conn);
// int _AFCConnectionIsValid(afc_connection *conn)
am_long AFCConnectionGetContext(afc_connection conn);
am_long AFCConnectionSetContext(afc_connection conn, am_long ctx);
am_long AFCConnectionGetFSBlockSize(afc_connection conn);
am_long AFCConnectionSetFSBlockSize(afc_connection conn, am_long size);
am_long AFCConnectionGetIOTimeout(afc_connection conn);
am_long AFCConnectionSetIOTimeout(afc_connection conn, am_long timeout);
am_long AFCConnectionGetSocketBlockSize(afc_connection conn);
am_long AFCConnectionSetSocketBlockSize(afc_connection conn, am_long size);

CFStringRef AFCCopyErrorString(afc_connection a);
CFTypeRef AFCConnectionCopyLastErrorInfo(afc_connection a);

// 0001b8e6 T _AFCConnectionCopyLastErrorInfo
// 0001a8b6 T _AFCConnectionCreate
// 0001b8ca T _AFCConnectionGetStatus
// 0001a867 T _AFCConnectionGetTypeID
// 0001ae99 T _AFCConnectionInvalidate
// 0001b8c1 T _AFCConnectionProcessOperations
// 0001abdc T _AFCConnectionScheduleWithRunLoop
// 0001b623 T _AFCConnectionSubmitOperation
// 0001ad5a T _AFCConnectionUnscheduleFromRunLoop

// 000000000000603e T _AFCConnectionProcessOperations
// 0000000000005df8 T _AFCConnectionSetCallBack
// 00000000000064cc T _AFCConnectionSubmitOperation

// 0000000000008512 t _AFCLockCreate
// 0000000000007a83 t _AFCLockFree
// 00000000000084db t _AFCLockGetTypeID
// 0000000000007e69 t _AFCLockLock
// 00000000000083f2 t _AFCLockTryLock
// 000000000000810c t _AFCLockUnlock

const char * AFCGetClientVersionString(void);		// "@(#)PROGRAM:afc  PROJECT:afc-80"

// directory related functions
afc_error_t AFCDirectoryOpen(afc_connection conn,const char *path,afc_directory *dir);
afc_error_t AFCDirectoryRead(afc_connection conn,afc_directory dir,char **dirent);
afc_error_t AFCDirectoryClose(afc_connection conn,afc_directory dir);

afc_error_t AFCDirectoryCreate(afc_connection conn,const char *dirname);
afc_error_t AFCRemovePath(afc_connection conn,const char *dirname);
afc_error_t AFCRenamePath(afc_connection conn,const char *from,const char *to);
afc_error_t AFCLinkPath(afc_connection conn,uint64_t mode, const char *target,const char *link);
//	NSLog(@"linkpath returned %#lx",AFCLinkPath(_afc,(1=hard,2=sym)"/tmp/aaa","/tmp/bbb"));

// file i/o functions
afc_error_t AFCFileRefOpen(afc_connection conn, const char *path, uint64_t mode,afc_file_ref *ref);
afc_error_t AFCFileRefClose(afc_connection conn,afc_file_ref ref);
afc_error_t AFCFileRefSeek(afc_connection conn,	afc_file_ref ref, int64_t offset, uint64_t mode);
afc_error_t AFCFileRefTell(afc_connection conn, afc_file_ref ref, uint64_t *offset);
afc_error_t AFCFileRefRead(afc_connection conn,afc_file_ref ref,void *buf, afc_long *len);
afc_error_t AFCFileRefSetFileSize(afc_connection conn,afc_file_ref ref, afc_long offset);
afc_error_t AFCFileRefWrite(afc_connection conn,afc_file_ref ref, const void *buf, uint32_t len);
// afc_error_t AFCFileRefLock(afc_connection *conn, afc_file_ref ref, ...);
// 00019747 T _AFCFileRefUnlock

// device/file information functions
afc_error_t AFCDeviceInfoOpen(afc_connection conn, afc_dictionary *info);
afc_error_t AFCFileInfoOpen(afc_connection conn, const char *path, afc_dictionary *info);
afc_error_t AFCKeyValueRead(afc_dictionary dict, const char **key, const char **val);
afc_error_t AFCKeyValueClose(afc_dictionary dict);

// Notification stuff - only call these on "com.apple.mobile.notification_proxy" (AMSVC_NOTIFICATION_PROXY)
mach_error_t AMDPostNotification(am_service socket, CFStringRef notification, CFStringRef userinfo);
mach_error_t AMDShutdownNotificationProxy(am_service socket);
mach_error_t AMDObserveNotification(am_service socket, CFStringRef notification);
typedef void (*NOTIFY_CALLBACK)(CFStringRef notification, void* data);
mach_error_t AMDListenForNotifications(am_service socket, NOTIFY_CALLBACK cb, void* data);

// New style - seems to formalise the creation of the "request packet" seperately
// from the execution.
afc_error_t AFCConnectionProcessOperation(afc_connection a1, afc_operation op, double timeout);
afc_error_t AFCOperationGetResultStatus(afc_operation op);
CFTypeRef AFCOperationGetResultObject(afc_operation op);
CFTypeID AFCOperationGetTypeID(afc_operation op);
// 0000000000002dd3 T _AFCOperationGetState
// 00000000000030c5 T _AFCOperationCopyPacketData
afc_error_t AFCOperationSetContext(afc_operation op, void *ctx);
void *AFCOperationGetContext(afc_operation op);

// each of these returns an op, with the appropriate request encoded.  The value of ctx is
// available via AFCOperationGetContext()
afc_operation AFCOperationCreateGetConnectionInfo(CFAllocatorRef allocator, void *ctx);
afc_operation AFCOperationCreateGetDeviceInfo(CFAllocatorRef allocator, void *ctx);
afc_operation AFCOperationCreateGetFileHash(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateGetFileInfo(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateLinkPath(CFAllocatorRef allocator, uint32_t mode, CFStringRef filename1, CFStringRef filename2, void *ctx);
afc_operation AFCOperationCreateMakeDirectory(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateOpenFile(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateReadDirectory(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateRemovePath(CFAllocatorRef allocator, CFStringRef filename, void *ctx);
afc_operation AFCOperationCreateRenamePath(CFAllocatorRef allocator, CFStringRef oldname, CFStringRef newname, void *ctx);
afc_operation AFCOperationCreateSetConnectionOptions(CFAllocatorRef allocator, CFDictionaryRef dict, void *ctx);
afc_operation AFCOperationCreateSetModTime(CFAllocatorRef allocator, CFStringRef filename, uint64_t mtm, void *ctx);

@interface AMDevice(Private)
- (am_service)_startService:(NSString*)name;
@property (readwrite,retain) NSString *lasterror;   // externally readonly, internally we can write to it
@end

@interface AMService(Private)
@property (readwrite,retain) NSString *lasterror;   // externally readonly, internally we can write to it
@end

@interface AFCFileReference(Private)
@property (readwrite,retain) NSString *lasterror;   // externally readonly, internally we can write to it
@end

@implementation AMService

@synthesize delegate = _delegate;

-(NSString*)lasterror {
    return _lasterror;
}
-(void)setLasterror:(NSString*)newval
{
    [newval retain];
    [_lasterror release];
    _lasterror = newval;
}

- (void)performDelegateSelector:(SEL)sel
			  		 withObject:(id)info
{
	if (_delegate) {
		if ([_delegate respondsToSelector:sel]) {
			[_delegate performSelector:sel withObject:info];
		}
	}
}

- (void)dealloc
{
	[_lasterror release];
	[super dealloc];
}

- (id)initWithName:(NSString*)name onDevice:(AMDevice*)device
{
	if (self = [super init]) {
		_delegate = nil;
		_service = [device _startService:name];
		if (_service == 0) {
			[self release];
			return nil;
		}
		
	}
	return self;
}

+ (AMService*)serviceWithName:(NSString *)name onDevice:(AMDevice*)device
{
	return [[[AMService alloc] initWithName:name onDevice:device] autorelease];
}

- (bool)sendXMLRequest:(id)message
{
	bool result = NO;
    CFErrorRef failed = nil;
    CFDataRef messageAsXML = CFPropertyListCreateData ( NULL, message, kCFPropertyListXMLFormat_v1_0, 0, &failed );
	if (messageAsXML) {
		CFIndex xmlLength = CFDataGetLength(messageAsXML);
		uint32_t sz;
		int sock = (int)_service;
		sz = htonl(xmlLength);
		if (send(sock, &sz, sizeof(sz), 0) != sizeof(sz)) {
			self.lasterror = @"Can't send message size";
		} else {
			if (send(sock, CFDataGetBytePtr(messageAsXML), xmlLength,0) != xmlLength) {
				self.lasterror = @"Can't send message text";
			} else {
				self.lasterror = nil;
				result = YES;
			}
		}
		CFRelease(messageAsXML);
	} else {
        if (failed) {
            self.lasterror = [(NSError*)failed localizedDescription];
            CFRelease(failed);
        } else {
            self.lasterror = @"Can't convert request to XML";
        }
	}
	return(result);
}

- (id)readXMLReply
{
	id result = nil;
	int sock = (int)((uint32_t)_service);
	uint32_t sz;

	/* now wait for the reply */

	if (sizeof(uint32_t) != recv(sock, &sz, sizeof(sz), 0)) {
		self.lasterror = @"Can't receive reply size";
	} else {
		sz = ntohl(sz);
		if (sz) {
			// we need to be careful in here, because there is a fixed buffer size in the
			// socket, and it may be smaller than the message we are going to recieve.  we
			// need to allocate a buffer big enough for the final result, but loop calling
			// recv() until we recieve the complete reply.
			unsigned char *buff = malloc(sz);
			unsigned char *p = buff;
			uint32_t left = sz;
			while (left) {
				uint32_t rc =recv(sock, p, left,0);
				if (rc==0) {
					self.lasterror = [NSString stringWithFormat:@"Reply was truncated, expected %d more bytes",left];
					free(buff);
					return(nil);
				}
				left -= rc;
				p += rc;
			}
			CFDataRef r = CFDataCreateWithBytesNoCopy(0,buff,sz,kCFAllocatorNull);
            CFErrorRef failed = nil;
			CFPropertyListRef reply = CFPropertyListCreateWithData(NULL,r, kCFPropertyListImmutable, NULL, &failed);
			CFRelease(r);
			free(buff);
            if (reply) {
                result = [[(id)reply copy] autorelease];
                CFRelease(reply);
                self.lasterror = nil;
            } else {
                if (failed) {
                    self.lasterror = [(NSError*)failed localizedDescription];
                    CFRelease(failed);
                } else {
                    self.lasterror = @"Failed to decode XML reply";
                }
            }
		}
	}

	return(result);
}

- (id)sendRequestAndWaitForSingleReply:(id)message
{
	if ([self sendXMLRequest:message]) {
		return [self readXMLReply];
	}
	return nil;
}

// common method to send a request, then loop waiting for final reply to a lengthy operation
// this is only appropriate for messages that return NSDictionary replies
- (BOOL)sendRequestAndWaitUntilDone:(NSDictionary*)message
{
	[self performDelegateSelector:@selector(operationStarted:) withObject:message];
	
	BOOL result = NO;
	// send request, this updates lasterror appropriately
	if ([self sendXMLRequest:message]) {
		for (;;) {
			// read next reply - this updates lasterror appropriately
			NSDictionary *reply = [self readXMLReply];
			if (!reply) break;
			[self performDelegateSelector:@selector(operationContinues:) withObject:reply];
			
			NSString *s;
			// if there is an error key, we bail out
			s = [reply objectForKey:@"Error"];
			if (s) {
				self.lasterror = s;
				break;
			}
			
			// otherwise, keep looping until the entry for Status == Complete
			s = [reply objectForKey:@"Status"];
			if (![s isEqual:@"Complete"]) continue;
			result = YES;
			break;
		}
	}
	[self performDelegateSelector:@selector(operationCompleted:) withObject:message];
	return result;
}

- (NSInputStream*)inputStreamFromSocket
{
	CFReadStreamRef s;
	int sock = (int)((uint32_t)_service);

	CFStreamCreatePairWithSocket(
		kCFAllocatorDefault, (CFSocketNativeHandle)sock, &s, NULL);
	return [(NSInputStream*)s autorelease];
}

/*
am_service socket;
AMDeviceStartService(dev, CFSTR("com.apple.mobile.notification_proxy"), &socket);
AMDPostNotification(socket, CFSTR("com.apple.itunes-mobdev.syncWillStart"), NULL);
AMDPostNotification(socket, &CFSTR("com.apple.itunes-mobdev.syncDidFinish"), NULL);
AMDShutdownNotificationProxy(socket);
*/
@end

@implementation AMDLService

- (id)waitForDLResponse:(NSString*)response
{
	id result = nil;
	NSArray *reply = [self readXMLReply];
	if (reply) {
		NSString *s = [reply firstObject];
		if (s) {
			if ([s isEqualToString:response]) {
				result = reply;
			} else if ([s isEqualToString:@"DLMessageDisconnect"]) {
				self.lasterror = [reply objectAtIndex:1];
			} else {
				self.lasterror = [NSString stringWithFormat:@"Expected '%@', got '%@'",response,s];
			}
		} else {
			self.lasterror = @"Response truncated";
		}
	}
	return result;
}

- (BOOL)versionHandshake
{
	BOOL result = NO;
	NSArray *request, *reply;

	// step 1 - he sends us DLMessageVersionExchange, major, minor
	reply = [self waitForDLResponse:@"DLMessageVersionExchange"];
	if (reply) {
		// we could check a bit harder here
		NSInteger major = [[reply objectAtIndex:1] intValue];
		NSInteger minor = [[reply objectAtIndex:2] intValue];
		NSLog(@"Device requesting DeviceLinkProtocol %ld,%ld", (long)major, (long)minor);

		// we say yes, we accept that version.  I suspect we might be able to tell him a lower
		// version number here, but I don't know what the versions really mean at this point so
		// lets just claim to understand him...
		request = @[
					@"DLMessageVersionExchange",
					@"DLVersionsOk",
					@(major)
		];

		if ([self sendXMLRequest:request]) {
			// he then replies with DLMessageDeviceReady
			if ([self waitForDLResponse:@"DLMessageDeviceReady"]) {
				// and we are cool to go
				result = YES;
			}
		}
	}

	return result;
}

- (id)sendDLProcessMessage:(NSDictionary*)message
		   andWaitForReply:(NSString*)replyType
{
	static NSString *header = @"DLMessageProcessMessage";
	
	// messages are actually send as arrays, first element being DLMessageProcessMessage
    NSArray *request = @[ header, message ];
	
	// transaction is still raw xml representations, but reply is an array whose first element
	// should also be our header, and whose second element is a dictionary
	NSDictionary *result = nil;
	if ([self sendXMLRequest:request]) {
		// and wait for a corresponding response
		NSArray *reply = [self waitForDLResponse:header];
		NSString *s;
		if (reply) {
			// if it gets here, we know that its the right kind of message, but we still need to
			// make sure it isn't truncated
			if ([reply count] < 2) {
				self.lasterror = @"Reply is too short";
				return nil;
			}

			// lift out the response dictionary
			result = [reply objectAtIndex:1];
			
			// look for an error message
			s = [result objectForKey:@"ErrorMessage"];
			if (s) {
				self.lasterror = s;
				return nil;
			}
			
			// no error message, is it the right message type ?
			s = [result objectForKey:@"MessageType"];
			if (![s isEqualToString:replyType]) {
				self.lasterror = [NSString stringWithFormat:@"Expected '%@', got '%@'", replyType, s];
				return nil;
			}
			
			// fall through to return
		}
	}
	return result;
}

// DLServices need an additional handshake to ensure that we all agree on the version
// of the protocol we are talking.
- (id)initWithName:(NSString*)name onDevice:(AMDevice*)device
{
	if (self = [super initWithName:name onDevice:device]) {
		// at this point, the service is started.  We need to do the version handshake.  If
		// that fails, we need to nuke ourselves
		if (![self versionHandshake]) {
			NSLog(@"failed to handshake: %@",self.lasterror);
			[self release];
			self = nil;
		}
	}
	return self;
}

@end

@implementation AFCFileReference

-(NSString*)lasterror {
    return _lasterror;
}

-(void)setLasterror:(NSString*)newval
{
    [newval retain];
    [_lasterror release];
    _lasterror = newval;
}

- (bool)checkStatus:(afc_error_t)ret from:(const char *)func
{
	if (ret != 0) {
		self.lasterror = [NSString stringWithFormat:@"%s failed: %d",func,ret];
		return NO;
	}
    self.lasterror = nil;
	return YES;
}

- (bool)ensureFileIsOpen
{
	if (_ref) return YES;
	self.lasterror = @"File is not open";
	return NO;
}

- (void)dealloc
{
	[self closeFile];
	[_lasterror release];
	[super dealloc];
}

- (id)initWithPath:(NSString*)path reference:(afc_file_ref)ref afc:(afc_connection)afc
{
	if (self=[super init]) {
		_ref = ref;
		_afc = afc;
	}
	return self;
}

- (bool)closeFile
{
	if (![self ensureFileIsOpen]) return NO;
	if (![self checkStatus:AFCFileRefClose(_afc, _ref) from:"AFCFileRefClose"]) return NO;
	_ref = 0;
	return YES;
}

- (bool)seek:(int64_t)offset mode:(int)m
{
	if (![self ensureFileIsOpen]) return NO;
	return [self checkStatus:AFCFileRefSeek(_afc, _ref, offset, m) from:"AFCFileRefSeek"];
}

- (bool)tell:(uint64_t*)offset
{
	if (![self ensureFileIsOpen]) return NO;
	return [self checkStatus:AFCFileRefTell(_afc, _ref, offset) from:"AFCFileRefTell"];
}

- (afc_long)readN:(afc_long)n bytes:(char *)buff
{
	if (![self ensureFileIsOpen]) return NO;

	afc_long afcSize = n;
	if (![self checkStatus:AFCFileRefRead(_afc, _ref, buff, &afcSize) from:"AFCFileRefRead"]) return 0;
	return afcSize;
}

- (bool)writeN:(afc_long)n bytes:(const char *)buff
{
	if (![self ensureFileIsOpen]) return NO;
	if (n>0) {
		return [self checkStatus:AFCFileRefWrite(_afc, _ref, buff, n) from:"AFCFileRefWrite"];
	}
	return YES;
}

- (bool)writeNSData:(NSData*)data
{
	return [self writeN:[data length] bytes:[data bytes]];
}

- (bool)setFileSize:(uint64_t)size
{
	if (![self ensureFileIsOpen]) return NO;
	return [self checkStatus:AFCFileRefSetFileSize(_afc, _ref, size) from:"AFCFileRefSetFileSize"];
}

@end

@implementation AFCDirectoryAccess

- (void)dealloc
{
	if (_afc) [self close];
	[super dealloc];
}

- (bool)checkStatus:(int)ret from:(const char *)func
{
	if (ret != 0) {
		self.lasterror = [NSString stringWithFormat:@"%s failed: Return code = 0x%04X",func,ret];
		return NO;
	}
    self.lasterror = nil;
	return YES;
}

- (bool)ensureConnectionIsOpen
{
	if (_afc) return YES;
	self.lasterror = @"Connection is not open";
	return NO;
}

- (void)close
{
	if (_afc) {
		NSLog(@"disconnecting");
		int ret = AFCConnectionClose(_afc);
		if (ret != 0) {
			NSLog(@"AFCConnectionClose failed: %d", ret);
		}
		_afc = nil;
	}
}

- (NSMutableDictionary*)readAfcDictionary:(afc_dictionary)dict
{
	NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
	const char *k, *v;
	while (0 == AFCKeyValueRead(dict, &k, &v)) {
		if (!k) break;
		if (!v) break;

		// if all the characters in the value are digits, pass it back as
		// as 'long long' in a dictionary - else pass it back as a string
		const char *p;
		for (p=v; *p; p++) if (*p<'0' | *p>'9') break;
		if (*p) {
			/* its a string */
			[result setObject:[NSString stringWithUTF8String:v] forKey:[NSString stringWithUTF8String:k]];
		} else {
			[result setObject:[NSNumber numberWithLongLong:atoll(v)] forKey:[NSString stringWithUTF8String:k]];
		}
	}
	return result;
}

// retrieve a dictionary of information describing the device
// {
//		FSFreeBytes = 93876224
//		FSBlockSize = 4096
//		FSTotalBytes = 524288000
//		Model = iPod1,1
// }
- (NSDictionary*)deviceInfo
{
	if (![self ensureConnectionIsOpen]) return nil;
	afc_dictionary dict;
	if ([self checkStatus:AFCDeviceInfoOpen(_afc, &dict) from:"AFCDeviceInfoOpen"]) {
		NSMutableDictionary *result = [self readAfcDictionary:dict];
		AFCKeyValueClose(dict);
        self.lasterror = nil;
		return [NSDictionary dictionaryWithDictionary:result];
	}
	return nil;
}

/***

/dev/console
2009-08-07 20:10:11.331 MobileDeviceAccess[7284:10b]  st_blocks = 0
2009-08-07 20:10:11.331 MobileDeviceAccess[7284:10b]  st_nlink = 1
2009-08-07 20:10:11.332 MobileDeviceAccess[7284:10b]  st_size = 0
2009-08-07 20:10:11.333 MobileDeviceAccess[7284:10b]  st_ifmt = S_IFCHR

/dev/disk1
2009-08-07 20:11:35.842 MobileDeviceAccess[7296:10b]  st_blocks = 0
2009-08-07 20:11:35.843 MobileDeviceAccess[7296:10b]  st_nlink = 1
2009-08-07 20:11:35.844 MobileDeviceAccess[7296:10b]  st_size = 0
2009-08-07 20:11:35.844 MobileDeviceAccess[7296:10b]  st_ifmt = S_IFBLK

****/
// var/mobile/Media
// 2009-08-06 23:38:04.070 MobileDeviceAccess[1823:813]  st_blocks = 0
// 2009-08-06 23:38:04.071 MobileDeviceAccess[1823:813]  st_nlink = 11
// 2009-08-06 23:38:04.071 MobileDeviceAccess[1823:813]  st_size = 476
// 2009-08-06 23:38:04.072 MobileDeviceAccess[1823:813]  st_ifmt = S_IFDIR

// jailbreak.log
// 2009-08-06 23:37:23.089 MobileDeviceAccess[1800:813]  st_blocks = 64
// 2009-08-06 23:37:23.089 MobileDeviceAccess[1800:813]  st_nlink = 1
// 2009-08-06 23:37:23.090 MobileDeviceAccess[1800:813]  st_size = 29260
// 2009-08-06 23:37:23.091 MobileDeviceAccess[1800:813]  st_ifmt = S_IFREG
//    "st_birthtime" = 9223372036854775807;
//    "st_mtime" = 280689926000000000;

// /Applications
// 2009-08-06 23:39:01.872 MobileDeviceAccess[1864:813]  st_blocks = 8
// 2009-08-06 23:39:01.872 MobileDeviceAccess[1864:813]  st_nlink = 1
// 2009-08-06 23:39:01.876 MobileDeviceAccess[1864:813]  st_size = 27
// 2009-08-06 23:39:01.877 MobileDeviceAccess[1864:813]  st_ifmt = S_IFLNK
// 2009-08-06 23:39:01.873 MobileDeviceAccess[1864:813]  LinkTarget = /var/stash/Applications.pwn

-(void) fix_date_entry:(NSString*)key in:(NSMutableDictionary *)dict
{
	id d = [dict objectForKey:key];
	if (d) {
		long v = [d doubleValue] / 1000000000.0;
		d = [NSDate dateWithTimeIntervalSince1970:v];
		[dict setObject:d forKey:key];
	}
}

- (NSDictionary*)getFileInfo:(NSString*)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return nil;
	}

	if ([self ensureConnectionIsOpen]) {
		afc_dictionary dict;
		if ([self checkStatus:AFCFileInfoOpen(_afc, [path UTF8String], &dict) from:"AFCFileInfoOpen"]) {
			NSMutableDictionary *result = [self readAfcDictionary:dict];
			[result setObject:path forKey:@"path"];
			AFCKeyValueClose(dict);
            self.lasterror = nil;

			// fix the ones we know are dates
			[self fix_date_entry:@"st_birthtime" in:result];
			[self fix_date_entry:@"st_mtime" in:result];
			return [NSDictionary dictionaryWithDictionary:result];
		}
	}
	return nil;
}

- (BOOL)fileExistsAtPath:(NSString *)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return NO;
	}
	if ([self ensureConnectionIsOpen]) {
		afc_dictionary dict;
		if (AFCFileInfoOpen(_afc, [path UTF8String], &dict)==0) {
			AFCKeyValueClose(dict);
            self.lasterror = nil;
			return YES;
		}
	}
	return NO;
}

- (NSArray*)directoryContents:(NSString*)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return nil;
	}

	if (![self ensureConnectionIsOpen]) return nil;
	afc_directory dir;
	if ([self checkStatus:AFCDirectoryOpen(_afc,[path UTF8String],&dir) from:"AFCDirectoryOpen"]) {
		NSMutableArray *result = [NSMutableArray new];
		while (1) {
			char *d = NULL;
			AFCDirectoryRead(_afc,dir,&d);
			if (!d) break;
			if (*d=='.') {
				if (d[1]=='\000') continue;			// skip '.'
				if (d[1]=='.') {
					if (d[2]=='\000') continue;		// skip '..'
				}
			}
			[result addObject:[NSString stringWithUTF8String:d]];
		}
		AFCDirectoryClose(_afc,dir);
        self.lasterror = nil;
		return [NSArray arrayWithArray:[result autorelease]];
	}

	// ret=4: path is a file
	// ret=8: can't open path
	return nil;
}

static BOOL read_dir( AFCDirectoryAccess *self, afc_connection afc, NSString *path, NSMutableArray *files )
{
	BOOL result;

	afc_directory dir;
	int ret = AFCDirectoryOpen(afc,[path UTF8String],&dir);

	if (ret == 4) {
		// its a file, so add it in and return
		[files addObject:path];
		return YES;
	}

	if (ret != 0) {
		// something other than a file causes us to fail
		return [self checkStatus:ret from:"AFCDirectoryOpen"];
	}

	// collect us, with a trailing slash, since we are a directory
	[files addObject:[NSString stringWithFormat:@"%@/",path]];

	// build a list of all the files located here.
	NSMutableArray *here = [NSMutableArray new];
	while (1) {
		char *d = NULL;
		AFCDirectoryRead(afc,dir,&d);
		if (!d) break;
		if (*d=='.') {
			if (d[1]=='\000') continue;			// skip '.'
			if (d[1]=='.') {
				if (d[2]=='\000') continue;		// skip '..'
			}
		}
		[here addObject:[NSString stringWithFormat:@"%@/%s",path,d]];
	}
	AFCDirectoryClose(afc,dir);

	// step through everything we found and add to the array
	result = YES;
	for (NSString *f in here) {
		if (!read_dir(self, afc, f, files)) {
			result = NO;
			break;
		}
	}
	[here release];

	return result;
}

- (NSArray*)recursiveDirectoryContents:(NSString*)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return nil;
	}

	if (![self ensureConnectionIsOpen]) return nil;

	NSMutableArray *unsorted = [NSMutableArray new];
	if (read_dir(self, _afc, path, unsorted)) {
		[unsorted sortUsingSelector:@selector(compare:)];
		NSArray *result = [NSArray arrayWithArray:unsorted];
		[unsorted release];
		return result;
	}
	[unsorted release];
	return nil;
}

- (BOOL)mkdir:(NSString*)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;
	return [self checkStatus:AFCDirectoryCreate(_afc, [path UTF8String]) from:"AFCDirectoryCreate"];
}

- (BOOL)unlink:(NSString*)path
{
	if (!path) {
		self.lasterror = @"Input path is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;
	return [self checkStatus:AFCRemovePath(_afc, [path UTF8String]) from:"AFCRemovePath"];
}

- (BOOL)rename:(NSString*)path1 to:(NSString*)path2
{
	if (!path1) {
		self.lasterror = @"Old path is nil";
		return NO;
	}
	if (!path2) {
		self.lasterror = @"New path is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;
	return [self checkStatus:AFCRenamePath(_afc, [path1 UTF8String], [path2 UTF8String]) from:"AFCRenamePath"];
}

- (BOOL)link:(NSString*)path to:(NSString*)target
{
	if (!path) {
		self.lasterror = @"Path is nil";
		return NO;
	}
	if (!target) {
		self.lasterror = @"Target is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;
	return [self checkStatus:AFCLinkPath(_afc, 1, [target UTF8String], [path UTF8String]) from:"AFCLinkPath"];
}


- (BOOL)symlink:(NSString*)path to:(NSString*)target
{
	if (!path) {
		self.lasterror = @"Path is nil";
		return NO;
	}
	if (!target) {
		self.lasterror = @"Target is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;
	return [self checkStatus:AFCLinkPath(_afc, 2, [target UTF8String], [path UTF8String]) from:"AFCLinkPath"];
}

- (bool)processOp:(afc_operation)op from:(const char *)func
{
	BOOL result = NO;
	if ([self checkStatus:AFCConnectionProcessOperation(_afc, op, AFCConnectionGetIOTimeout(_afc)) from:"AFCConnectionProcessOperation"]) {
		afc_error_t e = AFCOperationGetResultStatus(op);
		if (e == 0) {
            self.lasterror = nil;
			result = YES;
		} else {
			CFTypeRef err = AFCConnectionCopyLastErrorInfo(_afc);
			if (err) {
				id msg = [(id)err objectForKey:@"NSLocalizedDescription"];
				if (msg) {
					self.lasterror = msg;
				} else {
					self.lasterror = [NSString stringWithFormat:@"Error %ld occurred, no message",(long)e];
				}
				CFRelease(err);
			} else {
				self.lasterror = [NSString stringWithFormat:@"Error %ld occurred, no error info",(long)e];
			}
		}
	}
	CFRelease(op);
	return result;
}

/**
 * Set file modification time for a file on the device
 * @param filename Full pathname of file to modify
 * @param modtime time to set it to
 */
- (BOOL)setmodtime:(NSString*)path to:(NSDate*)timestamp
{
	if (!path) {
		self.lasterror = @"Path is nil";
		return NO;
	}
	if (!timestamp) {
		self.lasterror = @"timestamp is nil";
		return NO;
	}
	if (![self ensureConnectionIsOpen]) return NO;

	double tm = [timestamp timeIntervalSince1970] * 1000000000;
	void *op = AFCOperationCreateSetModTime(NULL,(CFStringRef)path, tm, self);
	if (op) {
		return [self processOp:op from:"setmodtime:to:"];
	}
	self.lasterror = @"AFCOperationCreateSetModTime() failed";
	return NO;
}

- (AFCFileReference*)openForRead:(NSString*)path
{
	if (![self ensureConnectionIsOpen]) return nil;
	afc_file_ref ref;
	if ([self checkStatus:AFCFileRefOpen(_afc, [path UTF8String], 1, &ref) from:"AFCFileRefOpen"]) {
		return [[[AFCFileReference alloc] initWithPath:path reference:ref afc:_afc] autorelease];
	}
	// if mode==0, ret=7
	// if file does not exist, ret=8
	return nil;
}

- (AFCFileReference*)openForWrite:(NSString*)path
{
	if (![self ensureConnectionIsOpen]) return nil;
	afc_file_ref ref;
	if ([self checkStatus:AFCFileRefOpen(_afc, [path UTF8String], 2, &ref) from:"AFCFileRefOpen"]) {
		return [[[AFCFileReference alloc] initWithPath:path reference:ref afc:_afc] autorelease];
	}
	// if mode==0, ret=7
	// if file does not exist, ret=8
	return nil;
}

- (AFCFileReference*)openForReadWrite:(NSString*)path
{
	if (![self ensureConnectionIsOpen]) return nil;
	afc_file_ref ref;
	if ([self checkStatus:AFCFileRefOpen(_afc, [path UTF8String], 3, &ref) from:"AFCFileRefOpen"]) {
		return [[[AFCFileReference alloc] initWithPath:path reference:ref afc:_afc] autorelease];
	}
	// if mode==0, ret=7
	// if file does not exist, ret=8
	return nil;
}

- (BOOL)copyLocalFile:(NSString*)path1 toRemoteFile:(NSString*)path2
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	BOOL result = NO;
	if ([self ensureConnectionIsOpen]) {
		// make sure remote file doesn't exist
		if ([self fileExistsAtPath:path2]) {
			self.lasterror = @"Won't overwrite existing file";
		} else {
			// ok, make sure the input file opens before creating the
			// output file
			NSFileHandle *in = [NSFileHandle fileHandleForReadingAtPath:path1];
			if (in) {
				NSMutableDictionary *info = [[NSMutableDictionary new] autorelease];
				struct stat s;
				stat([path1 fileSystemRepresentation],&s);
				[info setObject:path1 forKey:@"Source"];
				[info setObject:path2 forKey:@"Target"];
				[info setObject:[NSNumber numberWithInt:s.st_size] forKey:@"Size"];
				[nc postNotificationName:@"AFCFileCopyBegin" object:self userInfo:info];
				// open remote file for write
				AFCFileReference *out = [self openForWrite:path2];
				if (out) {
					// copy all content across 10K at a time
					const uint32_t bufsz = 10240;
					uint32_t done = 0;
					while (1) {
						[info setObject:[NSNumber numberWithInt:done] forKey:@"Done"];
						[nc postNotificationName:@"AFCFileCopyProgress" object:self userInfo:info];
						NSData *nextblock = [in readDataOfLength:bufsz];
						uint32_t n = [nextblock length];
						if (n==0) break;
						[out writeNSData:nextblock];
						done += n;
					}
					[out closeFile];
					result = YES;
					[nc postNotificationName:@"AFCFileCopyDone" object:self userInfo:info];
				}
				// close input file regardless
				[in closeFile];
			} else {
				// hmmm, failed to open
				self.lasterror = @"Can't open input file";
			}
		}
	}
	return result;
}

- (BOOL)copyLocalFile:(NSString*)path1 toRemoteDir:(NSString*)path2
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *fname;
	BOOL isdir;
	isdir = NO;
	if ([fm fileExistsAtPath:path1 isDirectory:&isdir]) {
		if (isdir) {
			// create the target directory
			NSString *basename = [path2 stringByAppendingPathComponent:[path1 lastPathComponent]];
			if (![self mkdir:basename]) return NO;
			for (fname in [fm contentsOfDirectoryAtPath:path1 error:nil]) {
				BOOL worked;
				worked = [self copyLocalFile:[path1 stringByAppendingPathComponent:fname]
						toRemoteDir:basename];
				if (!worked) {
					NSLog(@"failed on %@/%@: %@",path1,fname,self.lasterror);
					return NO;
				}
			}
			return YES;
		} else {
			fname = [path1 lastPathComponent];
			NSString *dest = [path2 stringByAppendingPathComponent:fname];
			char buff[PATH_MAX+1];
			ssize_t buflen = readlink([path1 UTF8String], buff, sizeof(buff));
			if (buflen>0) {
				buff[buflen] = 0;
				return [self symlink:dest to:[NSString stringWithUTF8String:buff]];
			} else {
				return [self copyLocalFile:path1 toRemoteFile:dest];
			}
		}
	}

	return NO;
}

- (BOOL)copyRemoteFile:(NSString*)path1 toLocalFile:(NSString*)path2
{
	BOOL result = NO;
	if ([self ensureConnectionIsOpen]) {
		NSFileManager *fm = [NSFileManager defaultManager];
		// make sure local file doesn't exist
		if ([fm fileExistsAtPath:path2]) {
			self.lasterror = @"Won't overwrite existing file";
		} else {
			// open remote file for read
			AFCFileReference *in = [self openForRead:path1];
			if (in) {
				// open local file for write - stupidly we need to create it before
				// we can make an NSFileHandle
				[fm createFileAtPath:path2 contents:nil attributes:nil];
				NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:path2];
				if (!out) {
					self.lasterror = @"Can't open output file";
				} else {
					// copy all content across 10K at a time...  use
					// malloc for the buffer rather than NSData because I've noticed
					// strange problems in the debugger
					const am_long bufsz = 10240;
					char *buff = malloc(bufsz);
					while (1) {
						uint32_t n = [in readN:bufsz bytes:buff];
						if (n==0) break;
						NSData *b2 = [[NSData alloc]
									  initWithBytesNoCopy:buff length:n freeWhenDone:NO];
						[out writeData:b2];
						[b2 release];
					}
					free(buff);
					[out closeFile];
                    self.lasterror = nil;
					result = YES;
				}
				// close output file
				[in closeFile];
			}
		}
	}
	return result;
}

@end

@implementation AFCMediaDirectory

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.afc" onDevice:device]) {
		int ret = AFCConnectionOpen(_service, 0/*timeout*/, &_afc);
		if (ret != 0) {
			NSLog(@"AFCConnectionOpen failed: %d", ret);
			[self release];
			self = nil;
		}
	}
	return self;
}

@end

@implementation AFCCrashLogDirectory

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.crashreportcopymobile" onDevice:device]) {
		int ret = AFCConnectionOpen(_service, 0/*timeout*/, &_afc);
		if (ret != 0) {
			NSLog(@"AFCConnectionOpen failed: %d", ret);
			[self release];
			self = nil;
		}
	}
	return self;
}

@end

@implementation AFCRootDirectory

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.afc2" onDevice:device]) {
		int ret = AFCConnectionOpen(_service, 0/*timeout*/, &_afc);
		if (ret != 0) {
			NSLog(@"AFCConnectionOpen failed: %d", ret);
			[self release];
			self = nil;
		}
	}
	return self;
}

@end

@implementation AFCApplicationDirectory

- (id)initWithAMDevice:(AMDevice*)device
			   andName:(NSString*)identifier
{
	if (self = [super initWithName:@"com.apple.mobile.house_arrest" onDevice:device]) {
		NSDictionary *message = @{
			@"Command":		@"VendDocuments",
			@"Identifier":	identifier,
		};
		NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
		if (reply) {
			// The reply will contain one of
			// "Error" => "the error message"
			// "Status" => "Complete"
			NSString *err = [reply objectForKey:@"Error"];
			if (err) {
                [device setLasterror:[NSString stringWithFormat:@"com.apple.mobile.house_arrest failed: %@",err]];
				[self release];
				self = nil;
			} else {
				int ret = AFCConnectionOpen(_service, 0/*timeout*/, &_afc);
				if (ret != 0) {
                    [device setLasterror:[NSString stringWithFormat:@"AFCConnectionOpen failed: %d", ret]];
					[self release];
					self = nil;
				}
			}
		} else {
            [device setLasterror:self.lasterror];
			[self release];
			self = nil;
		}
	}
	return self;
}
@end

@implementation AMApplication

- (void)dealloc
{
	[_info release];
	[_bundleid release];
	[_appname release];
	[super dealloc];
}

// we are immutable so it costs nothing to make copies
- (id)copyWithZone:(NSZone*)zone
{
	return [self retain];
}

// initialise a new installed app, based on the contents of the specified directory
- (id)initWithDictionary:(NSDictionary*)info
{
	if (self=[super init]) {
		_info = [info retain];
		_bundleid = [[_info objectForKey:@"CFBundleIdentifier"] retain];

		// appname is harder than you think, for some reason many apps don't
		// seem to populate the correct keys.  Way to go, Apples validation team...
		_appname = nil;
		if (!_appname) _appname = [info objectForKey:@"CFBundleDisplayName"];
		if ([_appname compare:@""]==NSOrderedSame) _appname = nil;		// PuzzleManiak, I'm looking at you
		if (!_appname) _appname = [info objectForKey:@"CFBundleName"];
		if (!_appname) _appname = [info objectForKey:@"CFBundleExecutable"];
		[_appname retain];
	}
	return self;
}

- (id)bundleid
{
	return [[_bundleid retain] autorelease];
}

- (NSString*)appname
{
	return [[_appname retain] autorelease];
}

- (NSDictionary*)info
{
	return [[_info retain] autorelease];
}

// we fake out missing entries in our object with NSNull.  That way,
// I think NSPredicate can refer to "missing" entries without throwing exceptions
- (id)valueForKey:(NSString *)key
{
	if ([key isEqual:@"appname"]) return _appname;
	if ([key isEqual:@"bundleid"]) return _bundleid;
	id v = [_info valueForKey:key];
	if (v) return v;
	return [NSNull null];
}

- (id)appdir
{
	return [_info objectForKey:@"Container"];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<AMApplication name=%@ id=%@>",_appname,_bundleid];
}

- (NSUInteger)hash
{
	return [_bundleid hash];
}

- (NSComparisonResult)compare:(AMApplication *)other
{
	return [_appname caseInsensitiveCompare:other->_appname];
}

- (BOOL)isEqual:(id)anObject
{
	if (![anObject isKindOfClass:[self class]]) return NO;
	return ([self compare:anObject] == NSOrderedSame);
}

@end

@implementation AMInstallationProxy

#if 0
Yeah, I’ve just found out how to handle this and terminate sync when user slides cancel switch.

We need following functions (meta-language):

ERROR AMDObserveNotification(HANDLE proxy, CFSTR notification);

ERROR AMDListenForNotifications(HANDLE proxy, NOTIFY_CALLBACK cb, USERDATA data);

and callback delegate:

typedef void (*NOTIFY_CALLBACK)(CFSTR notification, USERDATA data);

First, we need AMDObserveNotification to subscribe notifications about “com.apple.itunes-client.syncCancelRequest”. Then we should start listening for notifications (second function) until we get “AMDNotificationFaceplant”.
That’s it. When notification got, you should unlock and close lock file handle (don’t sure if you need to post “syncDidFinish” to proxy, seems it doesn’t matter) and terminate sync gracefully.

P.S. The same notification is also got when you unplug your device, so you should always be ready for errors.
#endif

- (NSArray *)browse:(NSString*)type
{
	return [self browseFiltered:nil];
}

- (NSArray *)browseFiltered:(NSPredicate*)filter
{
	NSDictionary *message;
	message = @{
		@"Command":				@"Browse",
		@"ClientOptions": @{
			@"ApplicationType":	@"Any"
		}
	};
	[self performDelegateSelector:@selector(operationStarted:) withObject:message];

	NSArray *result = nil;
	if ([self sendXMLRequest:message]) {
		//
		// we return all applications in a single array.  However,
		// the protocol between ipod and mac does not - instead, the ipod only returns up to
		// about 20 at a time, passing a Status field as well which tells us whether the
		// transfer is finished or not.  This loop worries about gluing the responses
		// back together for you.
		//
		NSMutableArray *thelist = nil;
		for (;;) {
			// read next slab of information
			NSDictionary *reply = [self readXMLReply];
			if (!reply) break;
			[self performDelegateSelector:@selector(operationContinues:) withObject:reply];

			// first time through, thelist will be nil so we'll allocate it.
			if (nil == thelist) {
				// each reply that comes back has a list size in the Total key, so we can 
				// ask for an array of the correct size up front...  If we have a filter,
				// then we'll be over-estimating but thats not that big a deal...
				NSNumber *total = [reply objectForKey:@"Total"];
				if (total && [total isKindOfClass:[NSNumber class]]) {
					thelist = [[NSMutableArray alloc] initWithCapacity:[total intValue]];
				} else {
					// Hmmm, no Total, do it the hard way
					thelist = [[NSMutableArray alloc] init];
				}
			}

			// now, this reply might not have a current list in it so we need to be careful
			NSArray *currentlist = [reply objectForKey:@"CurrentList"];
			if (currentlist) {
				for (NSDictionary *appinfo in currentlist) {
					AMApplication *app = [[AMApplication alloc] initWithDictionary:appinfo];
					if (filter==nil || [filter evaluateWithObject:app]) {
						[thelist addObject:app];
					}
					[app release];
				}
			}

			NSString *s = [reply objectForKey:@"Status"];
			if (![s isEqual:@"BrowsingApplications"]) break;
		}

		// all finished, make it immutable and return
		if (thelist) {
			result = [NSArray arrayWithArray:thelist];
			[thelist release];
		}
	}
	[self performDelegateSelector:@selector(operationCompleted:) withObject:message];
	return result;
}

- (BOOL)archive:(NSString*)bundleid
		container:(BOOL)container
		payload:(BOOL)payload
		uninstall:(BOOL)uninstall
{
	NSString *mode;
	if (container) {
		if (payload) {
			mode = @"All";
		} else {
			mode = @"DocumentsOnly";
		}
	} else {
		if (payload) {
			mode = @"ApplicationOnly";
		} else {
			return NO;
		}
	}

	// { "Command" => "Archive";	"ApplicationIdentifier" => ...; ClientOptions => ... }
	// it also takes {"ArchiveType" => oneof "All", "DocumentsOnly", "ApplicationOnly" }
	// it also takes {"SkipUninstall" => True / False}
	NSDictionary *message;
	message = @{
		@"Command":					@"Archive",
		@"ApplicationIdentifier":	bundleid,
		@"ClientOptions": @{
			@"ArchiveType":		mode,
			@"SkipUninstall":	uninstall ? @NO : @YES
		}
	};

	return [self sendRequestAndWaitUntilDone:message];
}

// at 7.0.4, we see the following error message:
// Restore functionality is no longer supported (<rdar://problem/11051250>); %@ should stop
// calling AMDeviceRestoreApplication or AMDeviceSecureRestoreApplication

- (BOOL)restore:(NSString*)bundleid
{
	NSDictionary *message;
	message = @{
		@"Command":					@"Restore",
		@"ApplicationIdentifier":	bundleid
	};
	return [self sendRequestAndWaitUntilDone:message];
}

/// Remove the archive for a given bundle id.
- (BOOL)removeArchive:(NSString*)bundleid
{
	NSDictionary *message;
	message = @{
				@"Command":					@"RemoveArchive",
				@"ApplicationIdentifier":	bundleid,
				};
	return [self sendRequestAndWaitUntilDone:message];
}

#if 0
http://libiphone.lighthouseapp.com/projects/27916/tickets/104/a/365185/0001-new-installation_proxy-interface.patch

// { "Command" => "Install";
//			"PackagePath" => "...";	// Will be prefixed with /var/mobile/Media/
//									// if PackageType="Developer", it should be a pointer to an expanded .app
//									// containing code signature stuff, etc.
//			"ClientOptions" = { "PackageType" = "Developer"; "ApplicationSINF" = ... "; "iTunesMetadata" = "...",  }
//							  { "PackageType" = "Customer";
//							  { "PackageType" = "CarrierBundle"; ...
//		<- { Status => Complete; }
//		<- { Status => "..."; PercentComplete = ... }
// { "Command" => "Upgrade"; "PackagePath" => "..." }
//

2010-06-08 20:01:34.628 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 0;
    Status = TakingInstallLock;
}
2010-06-08 20:01:34.640 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 5;
    Status = CreatingStagingDirectory;
}
2010-06-08 20:01:34.656 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 10;
    Status = StagingPackage;
}
2010-06-08 20:01:34.694 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 15;
    Status = ExtractingPackage;
}
2010-06-08 20:01:34.697 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 20;
    Status = InspectingPackage;
}
2010-06-08 20:01:34.701 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 30;
    Status = PreflightingApplication;
}
2010-06-08 20:01:34.704 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 30;
    Status = InstallingEmbeddedProfile;
}
2010-06-08 20:01:34.708 iPodBackup[40130:a0f] operationContinues::{
    PercentComplete = 40;
    Status = VerifyingApplication;
}
2010-06-08 20:01:34.722 iPodBackup[40130:a0f] operationContinues::{
    Error = BundleVerificationFailed;
}
2010-06-08 20:01:34.728 iPodBackup[40130:a0f] operationContinues::{
    Error = APIInternalError;
}
2010-06-08 20:01:34.730 iPodBackup[40130:a0f] operationCompleted::{
    ClientOptions =     {
        PackageType = Developer;
    };
    Command = Install;
    PackagePath = "PublicStaging/AncientFrogHD.app";
}

// { "Command" => "Uninstall";	"ApplicationIdentifier" => ...; ClientOptions => ... }

// { "Command" => "RemoveArchive";	"ApplicationIdentifier" => ...; ClientOptions => ... }
// { "Command" => "CheckCapabilitiesMatch"; Capabilities => ...; ClientOptions => ... }
//		<- { Status => Complete; LookupResult => ... }
//		<- { Error = APIInternalError; }
//

2010-06-08 20:16:59.431 iPodBackup[40417:a0f] operationStarted::{
    ClientOptions =     {
        PackageType = Developer;
    };
    Command = Install;
    PackagePath = "PublicStaging/Rooms.app";
}
2010-06-08 20:16:59.462 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 0;
    Status = TakingInstallLock;
}
2010-06-08 20:16:59.479 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 5;
    Status = CreatingStagingDirectory;
}
2010-06-08 20:16:59.488 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 10;
    Status = StagingPackage;
}
2010-06-08 20:16:59.504 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 15;
    Status = ExtractingPackage;
}
2010-06-08 20:16:59.511 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 20;
    Status = InspectingPackage;
}
2010-06-08 20:16:59.518 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 30;
    Status = PreflightingApplication;
}
2010-06-08 20:16:59.526 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 30;
    Status = InstallingEmbeddedProfile;
}
2010-06-08 20:16:59.533 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 40;
    Status = VerifyingApplication;
}
2010-06-08 20:17:02.915 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 50;
    Status = CreatingContainer;
}
2010-06-08 20:17:02.926 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 60;
    Status = InstallingApplication;
}
2010-06-08 20:17:02.935 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 70;
    Status = PostflightingApplication;
}
2010-06-08 20:17:02.939 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 80;
    Status = SandboxingApplication;
}
2010-06-08 20:17:02.977 iPodBackup[40417:a0f] operationContinues::{
    PercentComplete = 90;
    Status = GeneratingApplicationMap;
}
2010-06-08 20:17:04.943 iPodBackup[40417:a0f] operationContinues::{
    Status = Complete;
}
#endif

- (BOOL)install:(NSString*)pathname
{
	NSDictionary *message = @{
		@"Command":					@"Install",
		@"PackagePath":				pathname,
		@"ClientOptions": @{
			@"PackageType":			@"Developer",
		}
	};
	return [self sendRequestAndWaitUntilDone:message];
}

- (BOOL)upgrade:(NSString*)bundleId from:(NSString*)pathname;
{
	NSDictionary *message = @{
		@"Command":					@"Upgrade",
		@"PackagePath":				pathname,
		@"ApplicationIdentifier":	bundleId,
		@"ClientOptions": @{
			@"PackageType":			@"Developer",
		}
	};
	return [self sendRequestAndWaitUntilDone:message];
}

- (NSDictionary*)archivedAppInfo
{
	NSDictionary *message = @{
		@"Command": @"LookupArchives"
	};
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		return [[[reply objectForKey:@"LookupResult"] retain] autorelease];
	}
	return nil;
}

- (NSArray*)archivedAppBundleIds
{
	NSDictionary *appInfo = [self archivedAppInfo];
	return [appInfo allKeys];
}

//
// lookup is similiar to browse - it looks like it has clever filtering
// capability but its not that useful.  You can look up all attributes that
// *have* an explicit value for a specific attribute - you can't filter on actual
// values, just on the presence/absence of the attribute - use browseFiltered:
// instead.
//
// note we return a DICTIONARY indexed by bundle id
//
- (NSDictionary*)lookupType:(NSString*)type
			  withAttribute:(NSString*)attr
{
	if (type == nil) type = @"Any";

	NSDictionary *message = @{
		@"Command":				@"Lookup",
		@"ClientOptions": @{
			@"ApplicationType": type,
			@"Attribute" :		attr
		}
	};
	[self performDelegateSelector:@selector(operationStarted:) withObject:message];
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		[self performDelegateSelector:@selector(operationContinues:) withObject:reply];
		NSMutableDictionary *result = [[NSMutableDictionary new] autorelease];
		NSDictionary *lookup_result = [reply objectForKey:@"LookupResult"];
		for (NSString *key in lookup_result) {
			NSDictionary *info = [lookup_result objectForKey:key];
			AMApplication *app = [[AMApplication alloc] initWithDictionary:info];
			[result setObject:app forKey:key];
			[app release];
		}
		[self performDelegateSelector:@selector(operationCompleted:) withObject:message];
		return [NSDictionary dictionaryWithDictionary:result];
	}
	[self performDelegateSelector:@selector(operationCompleted:) withObject:message];
	return nil;
}

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobile.installation_proxy" onDevice:device]) {
	}
	return self;
}
@end

@implementation AMSyslogRelay

// This gets called back whenever there is data in the socket that we need
// to read out of it.
static
void AMSyslogRelayCallBack (
	CFReadStreamRef stream,
	CFStreamEventType eventType,
	void *clientCallBackInfo )
{
	AMSyslogRelay *relay = (AMSyslogRelay*)clientCallBackInfo;

	switch (eventType) {
	case kCFStreamEventNone:
	case kCFStreamEventOpenCompleted:
	case kCFStreamEventCanAcceptBytes: 
	case kCFStreamEventErrorOccurred:
	case kCFStreamEventEndEncountered:
		break;

	case kCFStreamEventHasBytesAvailable:
		{
			// The relay has a maximum buffer size of 0x4000, so we might as
			// well match it.  The buffer consists of multiple syslog records
			// which are \0 terminated - they may contain \n characters within
			// a record, and they never seem to send us an unterminated message
			// (again, the server code seems to preclude it)
			//
			// Control characters seem to be escaped with \ - ie, tab comes through as \ followed by t
			UInt8 buffer[0x4000];
			const CFIndex len = CFReadStreamRead(stream,buffer,sizeof(buffer));
			if (len) {
				UInt8 *p, *q;
				CFIndex left = len;
				p = buffer;
				buffer[sizeof(buffer)-1] = '\000';
				while (left>0) {
					// remove leading newlines
					while (*p == '\n') {
						if (--left) p++;
						else break;
					}
					q = p;
					while (*q && left>0) {q++;left--;}
					if (left) {
						// occasionally we encounter a null record - no need
						// to pass that on and confuse our listener.  Also, sometimes
						// the relay seems to pass us lines of the form "> ".  It looks
						// like thats the 'end' marker that the syslog daemon on the
						// device uses to communicate with the relay to tell it "thats
						// all for now".
						if (q-p) {
							NSString *s = [[NSString alloc] initWithBytesNoCopy:p length:q-p encoding:NSUTF8StringEncoding freeWhenDone:NO];
							[relay->_listener performSelector:relay->_message withObject:s];
							[s release];
						}
						p = q+1;
						left--;
					}
				}
			}
		}
	}
}

- (void)dealloc
{
	if (_service) {
		if (_readstream) {
			CFReadStreamUnscheduleFromRunLoop (_readstream,CFRunLoopGetMain(),kCFRunLoopCommonModes);
			CFReadStreamClose(_readstream);
			CFRelease(_readstream);
		}
	}
	[super dealloc];
}

- (id)initWithAMDevice:(AMDevice*)device listener:(id)listener message:(SEL)message
{
	if (self = [super initWithName:@"com.apple.syslog_relay" onDevice:device]) {
		_listener = listener;
		_message = message;
		int sock = (int)((uint32_t)_service);
		CFSocketNativeHandle s = (CFSocketNativeHandle)sock;
		CFStreamCreatePairWithSocket ( 0, s, &_readstream, NULL);
		if (_readstream) {
			CFStreamClientContext ctx = { 0,self,0,0,0 };
			int flags = kCFStreamEventHasBytesAvailable;
			flags = 31;
			if (CFReadStreamSetClient (_readstream,flags, &AMSyslogRelayCallBack, &ctx )) {
				CFReadStreamScheduleWithRunLoop (_readstream,CFRunLoopGetMain(),kCFRunLoopCommonModes);
				if (CFReadStreamOpen(_readstream)) {
					// NSLog(@"stream opened ok");
				} else {
					[device setLasterror:@"stream did not open"];
				}
			} else {
				[device setLasterror:@"couldn't set client"];
			}
		} else {
			[device setLasterror:@"couldn't create read stream"];
		}
	}
	return self;
}

@end

@implementation AMFileRelay

- (bool)slurpInto:(NSOutputStream*)writestream
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	bool result = NO;
	UInt8 buf[1024];

	// make sure they remembered to open the stream
	bool opened = NO;
	if ([writestream streamStatus] == NSStreamStatusNotOpen) {
		[writestream open];
		opened = YES;
	}

	// create an input stream to read from the socket 
	// loop around reading till its all done
	NSInputStream *readstream = [self inputStreamFromSocket];
	[readstream open];
	for (;;) {
		NSInteger nr = [readstream read:buf maxLength:sizeof(buf)];
		if (nr > 0) {
			NSInteger nw = [writestream write:buf maxLength:nr];
			if (nw != nr) {
				self.lasterror = [NSString stringWithFormat:@"File truncated on write, nr=%ld nw=%ld",(long)nr,(long)nw];
				break;
			}
		} else if (nr < 0) {
			self.lasterror = [[readstream streamError] localizedDescription];
			break;
		} else {
            self.lasterror = nil;
			result = YES;
			break;
		}
	}
	[readstream close];

	// if we opened the stream, we close it as well
	if (opened) [writestream close];

	[pool drain];
	return(result);
}

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobile.file_relay" onDevice:device]) {
		_used = NO;
	}
	return self;
}

- (bool)getFileSets:(NSArray*)set into:(NSOutputStream*)output
{
	if (_used) {
		self.lasterror = @"AlreadyUsed";
		return NO;
	}
	_used = YES;

	NSDictionary *message = @{
		@"Sources": set
	};

	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		// If the reply contains an "Error" item, we failed
		id err = [reply objectForKey:@"Error"];
		if (err) {
			self.lasterror = [NSString stringWithFormat:@"%@",err];
			return NO;
		}
		// We could check for "Status = Acknowledged" but why bother
		return [self slurpInto:output];
	}
	return NO;
}

- (bool)getFileSet:(NSString*)name into:(NSOutputStream*)output
{
	return [self getFileSets:[NSArray arrayWithObject:name] into:output];
} 

@end

@implementation AMIOSDiagnosticsRelay

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.iosdiagnostics.relay" onDevice:device]) {
	}
	return self;
}

// There are a bunch of interesting entries in the results dictionary under the key "aggd".
// For example, these:
//
// "netstats.counts.TCP.en0.KBIn.com.i-free.coinkeeper" =         {
// 	"2014-01-09" = 3;
// };
// "netstats.counts.TCP.en0.KBOut.com.i-free.coinkeeper" =         {
// 	"2014-01-09" = 1;
// };
// "netstats.counts.TCP.en0.KBOut.com.jumpgapsoftware.allowance" =         {
// 	"2014-01-09" = 6;
// 	"2014-01-11" = 133;
// 	"2014-01-14" = 49;
// };
//
// look to be network usage statistics for specific applications, keyed by day.  ie, the CoinKeeper
// app read 3KB in and wrote 1KB out on 2014-01-09. Just a guess but other entries look
// similiar enough and the numbers look sane.
//
// presumably TCP is the protocol and en0 is the network device - perhaps en1 gets switched in if
// you use a VPN connection.
//
// Sadly, they don't seem to show up on iOS7.

- (NSDictionary *)getDiagnostics
{
	NSDictionary *message = @{
		  @"Request": @"All"
	};

	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		// technically they would like us to send a Request: Goodbye at this point
		id err = [reply objectForKey:@"Status"];
		if (err) {
			if ([err isEqualToString:@"Success"]) {
				return [reply objectForKey:@"Diagnostics"];
			}
			self.lasterror = err;
			return nil;
		}
		self.lasterror = @"Reply did not contain Status entry";
	}
	return nil;
}

@end

@implementation AMPowerService

- (id)initWithAMDevice:(AMDevice*)device
{
    if (self = [super initWithName:@"com.apple.mobile.diagnostics_relay" onDevice:device]) {
    }
    return self;
}

// There are a bunch of interesting entries in the results dictionary under the key "aggd".
// For example, these:
//
// "netstats.counts.TCP.en0.KBIn.com.i-free.coinkeeper" =         {
// 	"2014-01-09" = 3;
// };
// "netstats.counts.TCP.en0.KBOut.com.i-free.coinkeeper" =         {
// 	"2014-01-09" = 1;
// };
// "netstats.counts.TCP.en0.KBOut.com.jumpgapsoftware.allowance" =         {
// 	"2014-01-09" = 6;
// 	"2014-01-11" = 133;
// 	"2014-01-14" = 49;
// };
//
// look to be network usage statistics for specific applications, keyed by day.  ie, the CoinKeeper
// app read 3KB in and wrote 1KB out on 2014-01-09. Just a guess but other entries look
// similiar enough and the numbers look sane.
//
// presumably TCP is the protocol and en0 is the network device - perhaps en1 gets switched in if
// you use a VPN connection.
//
// Sadly, they don't seem to show up on iOS7.

- (BOOL)sleep
{
    NSDictionary *message = @{
                              @"Request": @"Sleep"
                              };
    
    NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
    if (reply) {
        id err = [reply objectForKey:@"Status"];
        if (err) {
            if ([err isEqualToString:@"Success"]) {
                return YES;
            }
            self.lasterror = err;
            return NO;
        }
        self.lasterror = @"Reply did not contain Status entry";
    }
    return NO;
}

- (BOOL)shutdown
{
    NSDictionary *message = @{
                              @"Request": @"Shutdown",
                              @"DisplayPass": @YES,
                              @"WaitForDisconnect": @NO
                              };
    
    NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
    if (reply) {
        id err = [reply objectForKey:@"Status"];
        if (err) {
            if ([err isEqualToString:@"Success"]) {
                return YES;
            }
            self.lasterror = err;
            return NO;
        }
        self.lasterror = @"Reply did not contain Status entry";
    }
    return NO;
}

- (BOOL)reboot
{
    NSDictionary *message = @{
                              @"Request": @"Reboot"
                              };
    
    NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
    if (reply) {
        id err = [reply objectForKey:@"Status"];
        if (err) {
            if ([err isEqualToString:@"Success"]) {
                return YES;
            }
            self.lasterror = err;
            return NO;
        }
        self.lasterror = @"Reply did not contain Status entry";
    }
    return NO;
}

@end

@implementation AMMobileDiagnosticsRelay

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobile.diagnostics_relay" onDevice:device]) {
	}
	return self;
}

- (NSDictionary *)getDiagnostics:(NSString*)key
{
	// Goodbye
	// All
	// WiFi
	// HDMI
	// Shutdown		+WaitForDisconnect:BOOL	+DisplayPass:BOOL ?  +DisplayFail:BOOL?
	// Restart
	// Sleep
	// MobileGestalt	+MobileGestaltKeys:NSArray<NSString>
	// https://github.com/Cykey/ios-reversed-headers/blob/master/MobileGestalt/MobileGestalt.h
	// NAND
	// IORegistry		+CurrentPlant:String	+EntryName:String		+EntryClass:String
	// Obliterate
	NSDictionary *message = @{
							  @"Request": key
							  };
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		NSLog(@"reply=%@",reply);
		// technically they would like us to send a Request: Goodbye at this point
		id err = [reply objectForKey:@"Status"];
		if (err) {
			if ([err isEqualToString:@"Success"]) {
				return [reply objectForKey:@"Diagnostics"];
			}
			self.lasterror = err;
			return nil;
		}
		self.lasterror = @"Reply did not contain Status entry";
	}
	return nil;
}

- (NSDictionary *)getWiFiDiagnostics
{
	return [self getDiagnostics:@"WiFi"];
}

- (NSDictionary *)getHDMIDiagnostics
{
	return [self getDiagnostics:@"HDMI"];
}

- (NSDictionary *)getGasGaugeDiagnostics
{
	return [self getDiagnostics:@"GasGauge"];
}

- (NSDictionary *)getNANDDiagnostics
{
	return [self getDiagnostics:@"NAND"];
}

- (BOOL)sleep
{
	NSDictionary *message = @{
							  @"Request": @"Sleep"
							  };
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		id err = [reply objectForKey:@"Status"];
		if (err) {
			if ([err isEqualToString:@"Success"]) {
				return YES;
			}
			self.lasterror = err;
			return NO;
		}
		self.lasterror = @"Reply did not contain Status entry";
	}
	return NO;
}

- (NSDictionary*)getMobileGestaltValues:(NSArray*)keys
{
	NSDictionary *message = @{
							  @"Request" : @"MobileGestalt",
							  @"MobileGestaltKeys" : keys
							};
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		// technically they would like us to send a Request: Goodbye at this point
		id err = [reply objectForKey:@"Status"];
		if (err) {
			if ([err isEqualToString:@"Success"]) {
				NSDictionary *result = [reply objectForKey:@"Diagnostics"];
				return [result objectForKey:@"MobileGestalt"];
			}
			self.lasterror = err;
			return nil;
		}
		self.lasterror = @"Reply did not contain Status entry";
	}
	return nil;
}

- (id)getMobileGestaltValue:(NSString*)key
{
	NSDictionary *result = [self getMobileGestaltValues:@[key]];
	if (result) {
		return [result objectForKey:key];
	}
	return nil;
}

- (NSDictionary *)test
{
	// Goodbye
	// All
	// WiFi
	// HDMI
	// Shutdown		+WaitForDisconnect:BOOL	+DisplayPass:BOOL or  +DisplayFail:BOOL?
	// Restart			+WaitForDisconnect:BOOL	+DisplayPass:BOOL or  +DisplayFail:BOOL?
	// Sleep
	// MobileGestalt	+MobileGestaltKeys:NSArray<NSString>
	// https://github.com/Cykey/ios-reversed-headers/blob/master/MobileGestalt/MobileGestalt.h
	// NAND
	// IORegistry		+CurrentPlane:String	OR (+EntryName:String		+EntryClass:String)
	// Obliterate		+InternalBuild:BOOL	+DataPartitionOnly:BOOL	+ObliterationType:ObliterateDataPartition | ObliterationTypeWipeAndBrick
	//
#if 0
IORegistryPlanes =             {
	CoreCapture = CoreCapture;
	IO80211Plane = IO80211Plane;
	IOAccessory = IOAccessory;
	IODeviceTree = IODeviceTree;
	IOPower = IOPower;
	IOService = IOService;
};
#endif
	NSDictionary *message = @{
							  @"Request" : @"MobileGestalt",
							  @"MobileGestaltKeys" : @[@"DeviceSupports3DMaps", @"BatteryIsFullyCharged"]
							  /*
							  @"Request": @"IORegistry",
							  @"CurrentPlane" : @"IOPower",
//							  @"EntryClass" : @"AppleTriStarBuiltIn",
							  @"EntryName": @"AppleTriStarBuiltIn"			// seems to match the IOClass field
//							  };
				
							   IORegistryPlanes =             {
							   CoreCapture = CoreCapture;
							   IO80211Plane = IO80211Plane;
							   IOAccessory = IOAccessory;
							   IODeviceTree = IODeviceTree;
							   IOPower = IOPower;
							   IOService = IOService;
							   */
							  };
	
	NSDictionary *reply = [self sendRequestAndWaitForSingleReply:message];
	if (reply) {
		// technically they would like us to send a Request: Goodbye at this point
		id err = [reply objectForKey:@"Status"];
		if (err) {
			if ([err isEqualToString:@"Success"]) {
				return [reply objectForKey:@"Diagnostics"];
			}
			self.lasterror = err;
			return nil;
		}
		self.lasterror = @"Reply did not contain Status entry";
	}
	return nil;
}

@end

@implementation AMNotificationProxy

/*

http://matt.colyer.name/projects/iphone-linux/index.php?title=Banana's_lockdownd_session

+// NotificationProxy related
+// notifications for use with post_notification (client --> device)
+#define NP_SYNC_WILL_START      "com.apple.itunes-mobdev.syncWillStart"
+#define NP_SYNC_DID_START       "com.apple.itunes-mobdev.syncDidStart"
+#define NP_SYNC_DID_FINISH      "com.apple.itunes-mobdev.syncDidFinish"
+
+// notifications for use with observe_notification (device --> client)
+#define NP_SYNC_CANCEL_REQUEST  "com.apple.itunes-client.syncCancelRequest"
+#define NP_SYNC_SUSPEND_REQUEST "com.apple.itunes-client.syncSuspendRequest"
+#define NP_SYNC_RESUME_REQUEST  "com.apple.itunes-client.syncResumeRequest"
+#define NP_PHONE_NUMBER_CHANGED "com.apple.mobile.lockdown.phone_number_changed"
+#define NP_DEVICE_NAME_CHANGED  "com.apple.mobile.lockdown.device_name_changed"
+#define NP_ATTEMPTACTIVATION    "com.apple.springboard.attemptactivation"
+#define NP_DS_DOMAIN_CHANGED    "com.apple.mobile.data_sync.domain_changed"
+#define NP_APP_INSTALLED        "com.apple.mobile.application_installed"
+#define NP_APP_UNINSTALLED      "com.apple.mobile.application_uninstalled"
+

*/
- (void)dealloc
{
	if (_service) {
		AMDShutdownNotificationProxy(_service);
		// don't nil it, superclass might need to do something?
		[_messages release];
	}
	[super dealloc];
}

// Note, sometimes we get called with "AMDNotificationFaceplant" - that happens
// when the connection to the device goes away.  We may have a race condition in
// here because we may have killed the AMDevice which will close all the services
static 
void AMNotificationProxy_callback(CFStringRef notification, void* data)
{
	AMNotificationProxy *proxy = (AMNotificationProxy*)data;
	if (proxy->_messages) {
		NSMutableArray *message_observers = [proxy->_messages objectForKey:(NSString*)notification];
		for (NSArray *a in message_observers) {
			id observer = [a objectAtIndex:0];
			SEL message = NSSelectorFromString([a objectAtIndex:1]);
			[observer performSelector:message withObject:(NSString*)notification];
		}
	}
}

// AMDListenForNotification() is a bit stupid.  It creates a CFSocketRunloopSource but
// it hooks it up to the *current* runloop - we need it to be hooked to the *main*
// runloop.  Thus, we arrange for our registration to be punted across to the
// main thread, whose runloop should be the main one.
- (void)_amdlistenfornotifications
{
	mach_error_t status;
	status = AMDListenForNotifications(_service, AMNotificationProxy_callback, self);
	if (status != ERR_SUCCESS) NSLog(@"AMDListenForNotifications returned %d",status);
}

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobile.notification_proxy" onDevice:device]) {
		_messages = [NSMutableDictionary new];
		[self performSelectorOnMainThread:@selector(_amdlistenfornotifications) withObject:nil waitUntilDone:YES];
	}
	return self;
}

- (void)postNotification:(NSString*)notification
{
	AMDPostNotification(_service, (CFStringRef)notification, (CFStringRef)NULL);
}

/// Add an observer for a specific message.
- (void)addObserver:(id)notificationObserver
           selector:(SEL)notificationSelector
               name:(NSString *)notificationName
{
	// make sure this method is appropriate
	NSMethodSignature *sig = [notificationObserver methodSignatureForSelector:notificationSelector];
	if (
		sig == nil
		||
		strcmp([sig methodReturnType],"v")!=0
		||
		[sig numberOfArguments] != 3
		||
		strcmp([sig getArgumentTypeAtIndex:2],"@")!=0
	) {
		NSString *c = NSStringFromClass([notificationObserver class]);
		NSString *s = NSStringFromSelector(notificationSelector);
		NSLog(@"%@.%@ defined incorrectly for AMNotificationCenter.addObserver:selector:name:",c,s);
		NSLog(@"It should be:");
		NSLog(@"-(void)%@: (id)notificationname;",s);
		return;
	}

	if ([notificationObserver respondsToSelector:notificationSelector]) {
		// we keep an array of observers in a dictionary indexed by notificationName.
		// each observer is recorded as an array containing { object, "selector-as-string" }
		NSMutableArray *message_observers = [_messages objectForKey:notificationName];
		if (message_observers) {
			for (NSArray *a in message_observers) {
				// already here, just ignore it?
				if ([a objectAtIndex:0] == notificationObserver) return;
			}
		} else {
			// we aren't watching this one yet, so start it now
			mach_error_t status;
			status = AMDObserveNotification(_service, (CFStringRef)notificationName);
			if (status != ERR_SUCCESS) NSLog(@"AMDObserveNotification returned %d",status);

			message_observers = [NSMutableArray new];
			[_messages setObject:message_observers forKey:notificationName];
			[message_observers release];
		}
		[message_observers addObject:[NSArray arrayWithObjects:notificationObserver,NSStringFromSelector(notificationSelector),nil]];
	} else {
		NSLog(@"%@ does not respond to %@",notificationObserver,NSStringFromSelector(notificationSelector));
	}
}

/// Remove an observer for a specific message.
- (void)removeObserver:(id)notificationObserver
                  name:(NSString *)notificationName
{
	NSMutableArray *message_observers = [_messages objectForKey:notificationName];
	if (message_observers) {
		for (NSArray *a in message_observers) {
			if ([a objectAtIndex:0] == notificationObserver) {
				[message_observers removeObject:a];
				// there is no mechanism for us to "unobserve" so we just leave
				// the listener in place
				break;
			}
		}
	}
}

/// Remove an observer for all messages.
- (void)removeObserver:(id)notificationObserver
{
	for (NSString *k in [_messages allKeys]) {
		[self removeObserver:notificationObserver name:k];
	}
}

@end

@implementation AMSpringboardServices

- (id)getIconState
{
	NSDictionary *message = @{
		@"command":		@"getIconState"
	};
	return [self sendRequestAndWaitForSingleReply:message];
}

- (id)getIconPNGData:(NSString*)bundleId
{
	NSDictionary *message = @{
		@"command":		@"getIconPNGData",
		@"bundleId":	bundleId
	};
	return [self sendRequestAndWaitForSingleReply:message];
}

- (NSImage*)getIcon:(NSString*)displayIdentifier
{
	id reply = [self getIconPNGData:displayIdentifier];
	if (reply) {
		NSData *pngdata = [reply objectForKey:@"pngData"];
		if (pngdata) {
			return [[[NSImage alloc] initWithData:pngdata] autorelease];
		}
	}
	return nil;
}

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.springboardservices" onDevice:device]) {
		// nothing special
	}
	return self;
}

/*
 /// - \p "com.apple.mobile.springboardservices"
 ///			(implemented as /usr/libexec/springboardservicesrelay)
 
 {	"command" = "getIconState"; }
 - returns an NSArray() of pages
 -   page 0 is the dock
 -   each page is an NSArray() of icon entries
 -       each entry is an NSDictionary()
 -               bundleIdentifier = "com.apple.mobileipod";
 -               displayIdentifier = "com.apple.mobileipod-AudioPlayer";
 -               displayName = Music;
 -               iconModDate = 2009-09-26 20:45:29 +1000;
 -       or a zero (for an unused slot)
 -       padded to a multiple of four.

 {	"command" = "getIconPNGData"; "bundleId" = ... };
 
 {	"command" = "setIconState"; }
	perhaps expects to be passed a follow up plist with the new state
*/
@end

#if 0
misagent
__cfstring:000020B0 cfstr_Profiletype __CFString <0, 0x7C8, aProfiletype, 0xB> ; "ProfileType"
__cfstring:000020C0 cfstr_Provisioning __CFString <0, 0x7C8, aProvisioning, 0xC> ; "Provisioning"
__cfstring:000020D0 cfstr_Messagetype __CFString <0, 0x7C8, aMessagetype, 0xB> ; "MessageType"
__cfstring:000020E0 cfstr_Install   __CFString <0, 0x7C8, aInstall, 7> ; "Install"
__cfstring:000020F0 cfstr_Profile   __CFString <0, 0x7C8, aProfile, 7> ; "Profile"
__cfstring:00002100 cfstr_Remove    __CFString <0, 0x7C8, aRemove, 6> ; "Remove"
__cfstring:00002110 cfstr_Profileid __CFString <0, 0x7C8, aProfileid, 9> ; "ProfileID"
__cfstring:00002120 cfstr_Copy      __CFString <0, 0x7C8, aCopy, 4> ; "Copy"
__cfstring:00002130 cfstr_Status    __CFString <0, 0x7C8, aStatus, 6> ; "Status"
__cfstring:00002140 cfstr_Payload   __CFString <0, 0x7C8, aPayload, 7> ; "Payload"
__cfstring:00002150 cfstr_Response  __CFString <0, 0x7C8, aResponse, 8> ; "Response"

#endif

@implementation AMMobileSync

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobilesync" onDevice:device]) {
		// wait for the version exchange
		NSLog(@"waiting for the version exchange");
		NSLog(@"%@", [self readXMLReply]);
		NSLog(@"sending OK");
		[self sendXMLRequest:[NSArray arrayWithObjects:@"DLMessageVersionExchange", @"DLVersionsOk",
			[NSNumber numberWithInt:100],[NSNumber numberWithInt:100],nil]];
		NSLog(@"%@", [self readXMLReply]);
	}
	return self;
}

- (void)dealloc
{
	[self sendXMLRequest:[NSArray arrayWithObjects:@"DLMessageDisconnect", @"So long and thanks for all the fish",nil]];
	[super dealloc];
}

// note, this has not been tested at all - I doubt that it works
- (id)getContactData
{
	NSDictionary *message;
	message = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArray arrayWithObjects:
				@"SDMessageGetAllRecordsFromDevice",
				@"com.apple.Contacts",
				@"---",
				[NSDate date],
				[NSNumber numberWithInt:106],		// protocol version 106
				@"___EmptyParameterString___",
				nil ],
		   @"DLMessageProcessMessage",
			nil];
	NSLog(@"sending %@",message);
	if ([self sendXMLRequest:message]) {
		NSLog(@"waiting reply");
		NSLog(@"%@", [self readXMLReply]);
	}
	return nil;
}

#if 0

http://github.com/MattColyer/libiphone/blob/master/src/MobileSync.c

http://iphone-docs.org/doku.php?id=docs:protocols:screenshot

http://libimobiledevice.org/docs/mobilesync.html

Like other DeviceLink protocols, it starts with a simple handshake (binary plists represented as ruby objects):

< ["DLMessageVersionExchange", 100, 0]
> ["DLMessageVersionExchange", "DLVersionsOk"]
< ["DLMessageDeviceReady"]
After which it will accept commands (in the form [“DLMessageProcessMessage”, {“MessageType” ⇒ commandname}]).

< ["DLMessageProcessMessage", {"MessageType" => "ScreenShotRequest"}]
> ["DLMessageProcessMessage", {"MessageType" => "ScreenShotReply", "ScreenShotData" => png_data}]

	message = [NSArray arrayWithObjects:
				@"SDMessageGetAllRecordsFromDevice",
				@"com.apple.Contacts",
				@"---",
				[NSDate date],
				[NSNumber numberWithInt:106],		// protocol version 106
				@"___EmptyParameterString___",
				nil ];

__cstring:00007008 aSyncsubscribed DCB "SyncSubscribedCalendars",0

__cstring:00006FF4 aCom_apple_cale DCB "com.apple.Calendars",0
__cstring:00007020 aCom_apple_devi DCB "com.apple.DeviceLink",0
__cstring:00007038 aCom_apple_book DCB "com.apple.Bookmarks",0
__cstring:0000704C aCom_apple_note DCB "com.apple.Notes",0



Notifications:
com.apple.MobileSync.SyncAgent.kSyncAgentSyncEnded
com.apple.MobileSync.SyncAgent.kSyncAgentSyncStarted

Commands:
__text:000068EC						; "SDMessageSyncDataClassWithDevice"
__text:000068F0						; "SDMessageSyncDataClassWithComputer"
__text:000068F4						; "SDMessageRefuseToSyncDataClassWithComputer"
__text:000068F8						; "SDMessageClearAllRecordsOnDevice"
__text:000068FC						; "SDMessageDeviceWillClearAllRecords"
__text:00006900						; "SDMessageGetChangesFromDevice"
__text:00006904						; "SDMessageGetAllRecordsFromDevice"
__text:00006908						; "SDMessageProcessChanges"
__text:00006910						; "SDMessageAcknowledgeChangesFromDevice"
__text:00006914						; "SDMessageDeviceReadyToReceiveChanges"
__text:00006918						; "SDMessageRemapRecordIdentifiers"
__text:0000691C						; "SDMessageFinishSessionOnDevice"
__text:00006920						; "SDMessageDeviceFinishedSession"
__text:00006924						; "SDMessageCancelSession"


	plist_t array = build_contact_hello_msg(env);
	ret = iphone_msync_send(env->msync, array);
	plist_free(array);
	array = NULL;
	ret = iphone_msync_recv(env->msync, &array);

		array = plist_new_array();
		plist_add_sub_string_el(array, "SDMessageAcknowledgeChangesFromDevice");
		plist_add_sub_string_el(array, "com.apple.Contacts");

		ret = iphone_msync_send(env->msync, array);
		plist_free(array);
		array = NULL;


	array = plist_new_array();
	plist_add_sub_string_el(array, "DLMessagePing");
	plist_add_sub_string_el(array, "Preparing to get changes for device");

	ret = iphone_msync_send(env->msync, array);
	plist_free(array);
	array = NULL;

	array = plist_new_array();
	plist_add_sub_string_el(array, "SDMessageFinishSessionOnDevice");
	plist_add_sub_string_el(array, "com.apple.Contacts");

	ret = iphone_msync_send(env->msync, array);
	plist_free(array);
	array = NULL;

	ret = iphone_msync_recv(env->msync, &array);

plist_t build_contact_hello_msg(iphone_env *env)
{
	plist_t array = NULL;

	array = plist_new_array();
	plist_add_sub_string_el(array, "SDMessageSyncDataClassWithDevice");
	plist_add_sub_string_el(array, "com.apple.Contacts");

	//get last anchor and send new one
	OSyncError *anchor_error;
	char *timestamp = NULL;
	timestamp = osync_anchor_retrieve(osync_objtype_sink_get_anchor(env->contact_sink),
					  &anchor_error);

	if (timestamp && strlen(timestamp) > 0)
		osync_trace(TRACE_INTERNAL, "timestamp is: %s\n", timestamp);
	else {
		if (timestamp)
			free(timestamp);
		timestamp = strdup("---");
		osync_trace(TRACE_INTERNAL, "first sync!\n");
	};

	time_t t = time(NULL);

	char* new_timestamp = osync_time_unix2vtime(&t);

	plist_add_sub_string_el(array, timestamp);
	plist_add_sub_string_el(array, new_timestamp);

	plist_add_sub_uint_el(array, 106);
	plist_add_sub_string_el(array, "___EmptyParameterString___");

	return array;
}

#endif
@end

@implementation AMScreenshotService

- (id)initWithAMDevice:(AMDevice*)device
{
	if (self = [super initWithName:@"com.apple.mobile.screenshotr" onDevice:device]) {
		// at this point, we are connected to the service, and the initial version handshake has
		// completed successfully.
	}
	return self;
}

- (NSImage *)getScreenshot
{
    NSDictionary *request = @{
		@"MessageType" : @"ScreenShotRequest"
	};

    // Send and receive
    NSDictionary *dict = [self sendDLProcessMessage:request andWaitForReply:@"ScreenShotReply"];
	if (dict) {
		NSImage *image = nil;
		image = [[NSImage alloc] initWithData:[dict objectForKey:@"ScreenShotData"]];
		if (image) {
			return [image autorelease];
		}
		self.lasterror = @"Bad image data in ScreenShotData";
	}
	return nil;
}

- (BOOL)getScreenshot:(NSString*)path
			   ofType:(NSBitmapImageFileType)fileType
		   properties:(NSDictionary*)properties
{
	NSImage *image = [self getScreenshot];
	if (image) {
		// based on http://stackoverflow.com/questions/17507170/how-to-save-png-file-from-nsimage-retina-issues?rq=1
		CGImageRef cgRef = [image CGImageForProposedRect:NULL
												 context:nil
												   hints:nil];
		NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithCGImage:cgRef];
		[newRep setSize:[image size]];
		NSData *imgData = [newRep representationUsingType:fileType properties:properties];
		[imgData writeToFile:path atomically:YES];
		[newRep release];
		return YES;
	}
	return NO;
}

- (BOOL)getPNGScreenshot:(NSString*)path
{
	return [self getScreenshot:path ofType:NSPNGFileType properties:nil];
}

- (BOOL)getJPEGScreenshot:(NSString*)path
{
	return [self getScreenshot:path ofType:NSJPEGFileType properties:nil];
}

@end

@implementation AMDevice

@synthesize udid=_udid;
@synthesize deviceName=_deviceName;
@synthesize applicationAttributes = _applAttributes;

-(NSString*)lasterror {
    return _lasterror;
}
-(void)setLasterror:(NSString*)newval
{
    [newval retain];
    [_lasterror release];
    _lasterror = newval;
}

- (bool)checkStatus:(int)ret from:(const char *)func
{
	if (ret != 0) {
		self.lasterror = [NSString stringWithFormat:@"%s failed: %x",func,ret];
		return NO;
	}
    self.lasterror = nil;
	return YES;
}

- (bool)isDevice:(am_device) d
{
	return _device == d;
}

- (void)forgetDevice
{
	_device = nil;
}

- (am_service)_startService:(NSString*)name
{
	am_service result;
	mach_error_t ret = AMDeviceStartService(_device,(CFStringRef)name, &result);
	if (ret == 0) return result;
	NSLog(@"AMDeviceStartService failed: %#x,%#x,%#x", err_get_system(ret), err_get_sub(ret), err_get_code(ret));
	return 0;
}

- (bool)deviceConnect
{
	if (![self checkStatus:AMDeviceConnect(_device) from:"AMDeviceConnect"]) return NO;
	_connected = YES;
    self.lasterror = nil;
	return YES;
}

- (bool)deviceDisconnect
{
	if ([self checkStatus:AMDeviceDisconnect(_device) from:"AMDeviceDisconnect"]) {
		_connected = NO;
		return YES;
	}
	return NO;
}

- (bool)startSession
{
	if ([self checkStatus:AMDeviceStartSession(_device) from:"AMDeviceStartSession"]) {
		_insession = YES;
		return YES;
	}
	return NO;
}

- (bool)stopSession
{
	if ([self checkStatus:AMDeviceStopSession(_device) from:"AMDeviceStopSession"]) {
		_insession = NO;
		return YES;
	}
	return NO;
}

- (void)dealloc
{
	if (_device) {
		if (_insession) [self stopSession];
		if (_connected) [self deviceDisconnect];
	}
	[_deviceName release];
	[_udid release];
	[_lasterror release];
	[super dealloc];
}

// the application is dying, time to shut down - can't rely on
// dealloc because of reference counting
- (void)applicationWillTerminate:(NSNotification*)notification
{
	if (_device) {
		if (_insession) [self stopSession];
		if (_connected) [self deviceDisconnect];
	}
}

- (id)deviceValueForKey:(NSString*)key inDomain:(NSString*)domain
{
	BOOL opened_connection = NO;
	BOOL opened_session = NO;
	id result = nil;

	// first, check for a connection
	if (!_connected) {
		if (![self deviceConnect]) goto bail;
		opened_connection = YES;
	}

	// one way or another, we have a connection, look for a session
	if (!_insession) {
		if (![self startSession]) goto bail;
		opened_session = YES;
	}

	// ok we have a session running, just query and set up to return
	result = (id)AMDeviceCopyValue(_device,(CFStringRef)domain,(CFStringRef)key);

bail:
	if (opened_session) [self stopSession];
	if (opened_connection) [self deviceDisconnect];
	return [result autorelease];
}

- (id)deviceValueForKey:(NSString*)key
{
	return [self deviceValueForKey:key inDomain:nil];
}

- (id)allDeviceValuesForDomain:(NSString*)domain
{
	return [self deviceValueForKey:nil inDomain:domain];
}

- (NSString*)productType
{
	return [self deviceValueForKey:@"ProductType"];
}

- (NSString*)deviceClass
{
	return [self deviceValueForKey:@"DeviceClass"];
}

- (NSString*)serialNumber
{
	return [self deviceValueForKey:@"SerialNumber"];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"AMDevice('%@')", _deviceName];
}

- (id)initWithDevice:(am_device)device orBust:(NSString**)msg
{
	if (self=[super init]) {
		_device = device;
		if (![self deviceConnect]) {
			*msg = self.lasterror;
			_device = nil;
			[self release];
			return nil;
		}

		// we can access device values once we are connected - at 5.0.1, the behaviour
        // seemed to change slightly, and we need a session established as well, so we
        // use our regular method rather than directly calling AMDeviceCopyValue()
        //
        // Could there be a UserAssignedDeviceName ?
        //
		_deviceName = [[self deviceValueForKey:@"DeviceName"] retain];
        _udid = [[self deviceValueForKey:@"UniqueDeviceID"] retain];

		// NSLog(@"AMDeviceGetInterfaceType() returns %d",AMDeviceGetInterfaceType(device));
		// NSLog(@"AMDeviceGetInterfaceSpeed() returns %.0fK",AMDeviceGetInterfaceSpeed(device)/1024.0);
		// NSLog(@"AMDeviceGetConnectionID() returns %d",AMDeviceGetConnectionID(device));

		// apparently we need to disconnect whenever we aren't doing anything or
		// the connection will time-out at the other end???
		[self deviceDisconnect];
	}
	return self;
}

+ (AMDevice*)deviceFrom:(am_device)device
{
	NSString *msg = nil;
	AMDevice *result = [[[self class] alloc] initWithDevice:device orBust:&msg];
	if (result) return([result autorelease]);
	NSLog(@"Failed to create AMDevice: %@", msg);
	return nil;
}

// common plumbing to start an instance of one of our handler objects.  only works
// if the handler has an initializer initWithAMDevice:
- (id)newServiceHandler:(Class)handlerClass
{
    id result = nil;
    if ([self deviceConnect]) {
        NSString *err = nil;
        if ([self startSession]) {
            result = [(id)[handlerClass alloc] initWithAMDevice:self];
            if (!result) err = self.lasterror;
            [self stopSession];
        }
        [self deviceDisconnect];
        if (err) self.lasterror=err;
    }
    return result;

}

- (AFCMediaDirectory*)newAFCMediaDirectory
{
    return [self newServiceHandler:[AFCMediaDirectory class]];
}

- (AFCCrashLogDirectory*)newAFCCrashLogDirectory
{
    return [self newServiceHandler:[AFCCrashLogDirectory class]];
}

- (AFCRootDirectory*)newAFCRootDirectory
{
    return [self newServiceHandler:[AFCCrashLogDirectory class]];
}

- (AFCApplicationDirectory*)newAFCApplicationDirectory:(NSString*)name
{
	AFCApplicationDirectory *result = nil;
	if ([self deviceConnect]) {
        NSString *err = nil;
		if ([self startSession]) {
			result = [[AFCApplicationDirectory alloc] initWithAMDevice:self andName:name];
            if (!result) err = self.lasterror;
			[self stopSession];
		}
		[self deviceDisconnect];
        if (err) self.lasterror=err;
	}
	return result;
}

- (AMInstallationProxy*)newAMInstallationProxyWithDelegate:(id<AMInstallationProxyDelegate>)delegate
{
	AMInstallationProxy *result = nil;
	if ([self deviceConnect]) {
        NSString *err = nil;
		if ([self startSession]) {
			result = [[AMInstallationProxy alloc] initWithAMDevice:self];
            if (result) {
                result.delegate = delegate;
            } else {
                err = self.lasterror;
            }
			[self stopSession];
		}
		[self deviceDisconnect];
        if (err) self.lasterror=err;
	}
	return result;
}

- (AMNotificationProxy*)newAMNotificationProxy
{
    return [self newServiceHandler:[AMNotificationProxy class]];
}

- (AMSpringboardServices*)newAMSpringboardServices
{
    return [self newServiceHandler:[AMSpringboardServices class]];
}

- (AMSyslogRelay*)newAMSyslogRelay:(id)listener message:(SEL)message
{
	AMSyslogRelay *result = nil;
	if ([self deviceConnect]) {
        NSString *err = nil;
		if ([self startSession]) {
			result = [[AMSyslogRelay alloc] initWithAMDevice:self listener:listener message:message];
            if (!result) err = self.lasterror;
			[self stopSession];
		}
		[self deviceDisconnect];
        if (err) self.lasterror=err;
	}
	return result;
}

- (AMFileRelay*)newAMFileRelay
{
    return [self newServiceHandler:[AMFileRelay class]];
}

- (AMIOSDiagnosticsRelay*)newAMIOSDiagnosticsRelay
{
    return [self newServiceHandler:[AMIOSDiagnosticsRelay class]];
}

- (AMMobileDiagnosticsRelay*)newAMMobileDiagnosticsRelay
{
    return [self newServiceHandler:[AMMobileDiagnosticsRelay class]];
}

- (AMMobileSync*)newAMMobileSync
{
    return [self newServiceHandler:[AMMobileSync class]];
}

- (AMScreenshotService*)newAMScreenshotService
{
    return [self newServiceHandler:[AMScreenshotService class]];
}

- (AMPowerService*)newAMPowerService
{
    return [self newServiceHandler:[AMPowerService class]];
}

// At around iOS6.0, we started seeing a new console log message
//
//		AMDeviceBrowseApplications was called without specifying an options dictionary
//		containing kLookupReturnAttributesKey. This usage is inefficient and may cause
//		performance problems. Break on AMDeviceSlowLookupBreak to debug.
//
// Previously, I thought that AMDeviceLookupApplications second argument was a
// string - it appears that it is a dictionary containing options.
// The entry keyed by "ReturnAttributes" needs to be an NSArray of strings, each
// of which is a key into the info dictionary it returns for each app.
//
// If you omit the entry for "CFBundleIdentifier", you see console warnings like this:
//
//		browse_callback (thread 0xb029a000): Could not extract identifier for entry 1 of 10
//
// This method returns an appropriate dictionary
- (CFDictionaryRef)defaultReturnAttributes
{
	NSArray *a = self.applicationAttributes;
	if (a == nil) {
		a = [NSArray arrayWithObjects:
				@"CFBundleIdentifier",			// absolute must
				@"ApplicationDSID",
				@"ApplicationType",
				@"CFBundleExecutable",
				@"CFBundleDisplayName",
				@"CFBundleIconFile",
				@"CFBundleName",
				@"CFBundleShortVersionString",
//				@"CFBundleSupportedPlatforms",
//				@"CFBundleURLTypes",
				@"CFBundleVersion",
//				@"CodeInfoIdentifier",
//				@"Container",
//				@"Entitlements",
//				@"HasSettingsBundle",
//				@"IsUpgradeable",
				@"MinimumOSVersion",
//				@"Path",
//				@"SignerIdentity",
				@"UIDeviceFamily",
				@"UIFileSharingEnabled",
//				@"UIStatusBarHidden",
//				@"UISupportedInterfaceOrientations",

// iPhone Configuration Utility appears to ask for these:
//				@"CFBundlePackageType",
//				@"BuildMachineOSBuild",
//				@"CFBundleResourceSpecification",
//				@"DTPlatformBuild",
//				@"DTCompiler",
//				@"CFBundleSignature",
//				@"DTSDKName",
//				@"NSBundleResolvedPath",
//				@"UISupportedInterfaceOrientations",
//				@"DTXcode",
//				@"CFBundleInfoDictionaryVersion",
//				@"CFBundleSupportedPlatforms",
//				@"DTXcodeBuild",
//				@"UIStatusBarTintParameters",
//				@"DTPlatformVersion",
//				@"DTPlatformName",
//				@"CFBundleDevelopmentRegion",
//				@"DTSDKBuild",

				nil];
	}

	NSDictionary *options = [NSDictionary dictionaryWithObject:a forKey:@"ReturnAttributes"];
	return (CFDictionaryRef)options;
}

- (NSArray*)installedApplications
{
	NSArray* result = nil;
	if ([self deviceConnect]) {
		if ([self startSession]) {
			CFDictionaryRef dict = nil;
			CFDictionaryRef options = [self defaultReturnAttributes];
			if (
				[self checkStatus:AMDeviceLookupApplications(_device, options, &dict)
							 from:"AMDeviceLookupApplications"]
			) {
				NSMutableArray *temp = [[NSMutableArray new] autorelease];
				// each key here is the ID of an application
				for (NSString *key in (NSDictionary*)dict) {
					NSDictionary *info = [(NSDictionary*)dict objectForKey:key];
					// "User", "System", "Internal" ??
					if ([[info objectForKey:@"ApplicationType"] isEqual:@"User"]) {
						AMApplication *newapp = [[AMApplication alloc] initWithDictionary:info];
						[temp addObject:newapp];
						[newapp release];
					}
				}
				CFRelease(dict);
				result = [NSArray arrayWithArray:temp];
			}
			[self stopSession];
		}
		[self deviceDisconnect];
	}
	return result;
}

- (AMApplication*)installedApplicationWithId:(NSString*)id
{
	AMApplication* result = nil;
	if ([self deviceConnect]) {
		if ([self startSession]) {
			CFDictionaryRef dict = nil;
			CFDictionaryRef options = (CFDictionaryRef)[self defaultReturnAttributes];
			if (
				[self checkStatus:AMDeviceLookupApplications(_device, options, &dict)
							 from:"AMDeviceLookupApplications"]
			) {
				NSDictionary *info = [(NSDictionary*)dict objectForKey:id];
				if (info) {
					result = [[[AMApplication alloc] initWithDictionary:info] autorelease];
				}
				CFRelease(dict);
			}
			[self stopSession];
		}
		[self deviceDisconnect];
	}
	return result;
}

@end

@implementation MobileDeviceAccess

@synthesize devices=_devices;

// this is (indirectly) called back by AMDeviceNotificationSubscribe()
// whenever something interesting happens
- (void)Notify:(struct am_device_notification_callback_info*)info
{
    // we get connections by usb, or wifi - Apple have pretty much killed all the useful things you can do via wifi
    // so we don't bother allowing the connection to go through for now.
    if (AMDeviceGetInterfaceType(info->dev) != AMDeviceInterfaceTypeUSB) {
        NSLog(@"Ignoring non-usb connection by %@",info->dev);
        return;
    }

	AMDevice *d;
	switch (info->msg) {
	default:
		NSLog(@"Ignoring unknown message: %d",info->msg);
		return;

	case ADNCI_MSG_UNSUBSCRIBED:
		return;

	case ADNCI_MSG_CONNECTED:
		d = [AMDevice deviceFrom:info->dev];
		[_devices addObject:d];
		if (_listener && [_listener respondsToSelector:@selector(deviceConnected:)]) {
			[_listener deviceConnected:d];
		}
		break;

	case ADNCI_MSG_DISCONNECTED:
		for (d in _devices) {
			if ([d isDevice:info->dev]) {
				[d forgetDevice];
				if (_listener && [_listener respondsToSelector:@selector(deviceDisconnected:)]) {
					[_listener deviceDisconnected:d];
				}
				[_devices removeObject:d];
				break;
			}
		}
		break;
	}

	// if he's waiting for us to do something, break him
	if (_waitingInRunLoop) CFRunLoopStop(CFRunLoopGetCurrent());
}

// someone outside us wants to detach a device - perhaps they've closed the window.
// 
- (void)detachDevice:(AMDevice*)d
{
	[_devices removeObject:d];
}

// this is called back by AMDeviceNotificationSubscribe()
// we just punt back into a regular method
static
void notify_callback(struct am_device_notification_callback_info *info, void* arg)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(MobileDeviceAccess*)arg Notify:info];
    [pool drain];
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
	for (AMDevice *device in _devices) {
		[device applicationWillTerminate:notification];
	}
}

- (id)init
{
	if (self=[super init]) {
		_subscribed = NO;					// we are not subscribed yet
		_devices = [NSMutableArray new];	// we have no device connected
		_waitingInRunLoop = NO;			// we are not currently waiting in a runloop

		// we opened, we need to ensure that we get closed or our
		// services stay running on the ipod
		[[NSNotificationCenter defaultCenter] 
			addObserver: self
			   selector: @selector(applicationWillTerminate:)
				   name: NSApplicationWillTerminateNotification
				 object: nil];
    }
	return self;
}

- (bool)setListener:(id<MobileDeviceAccessListener>)listener
{
	_listener = listener;
	if (_listener) {
		// if we are not subscribed yet, do it now
		if (!_subscribed) {
			// try to subscribe for notifications - pass self as the callback_data
			int ret = AMDeviceNotificationSubscribe(notify_callback, 0, 0, self, &_notification);
			if (ret == 0) {
				_subscribed = YES;
			} else {
				// we should throw or something in here...
				NSLog(@"AMDeviceNotificationSubscribe failed: %d", ret);
			}
		}
	}
	return YES;
}

- (void)dealloc
{
	// we must stop observing everything before we evaporate
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// if we are currently waiting, stop now
	if (_waitingInRunLoop) CFRunLoopStop(CFRunLoopGetCurrent());

	[_devices release];
	[super dealloc];
}

- (bool)waitForConnection
{
	// we didn't manage to subscribe for notifications so there is no
	// point waiting
	if (!_subscribed) return NO;

	NSLog(@"calling CFRunLoopRun(), plug iPod in now!!!");
	_waitingInRunLoop = YES;
	CFRunLoopRun();
	_waitingInRunLoop = NO;
	NSLog(@"back from calling CFRunLoopRun()");

// while (something?) {
// 		_waitingInRunLoop = YES;
//		CFRunLoopRunInMode (@"waiting for connection", 5/*seconds*/, NO/*returnAfterSourceHandled*/);
//		_waitingInRunLoop = NO;
//		if (_device) return YES;
// }
	return YES;
}

- (NSString*)clientVersion
{
	return [NSString stringWithUTF8String:AFCGetClientVersionString()];
}

+ (MobileDeviceAccess*)singleton
{
	static MobileDeviceAccess *_singleton = nil;
	@synchronized(self) {
		if (_singleton == nil) {
			_singleton = [[MobileDeviceAccess alloc] init];
			
		}
	}
	return _singleton;
}

@end

