# Keys for deviceValueForDomain: 

## Domain: nil
(Passing nil as the domain name specifies the device itself - alternately, just use `deviceValue:`)

Key						|Value
-----------------------	|-----
ActivationState			|Activated
ActivationStateAcknowledged	|1
ActivityURL				|https://albert.apple.com/deviceservices/activity
BasebandStatus			|NoTelephonyCapabilty
BluetoothAddress		|b8:cc:ff:ee:dd:ee
BoardId					|16
BuildVersion			|11B554a
CPUArchitecture			|arm64
ChipID					|35168
CompassCalibration		|NSData...
DeviceClass				|iPad
DeviceColor				|#3b3b3c
DeviceName				|Bernoulli
DevicePublicKey			|NSData...
DieID					|1609239303108
EthernetAddress			|b8:11:11:33:44:55
FirmwareVersion			|iBoot-1940.3.5
HardwareModel			|J71AP
HardwarePlatform		|s5l8960x
HostAttached			|1
MLBSerialNumber			|DMP49494UUABCDHAB
ModelNumber				|MD786
NonVolatileRAM			|{"auto-boot" = <...>; "backlight-level" = <...>; "boot-args" = ""; bootdelay = <...>}
PartitionType			|
PasswordProtected		|1
ProductType				|iPad4,1
ProductVersion			|7.0.4
ProductionSOC			|1
ProtocolVersion			|2
ProximitySensorCalibration	|NSData...
RegionInfo				|X/A
SBLockdownEverRegisteredKey	|0
SIMStatus				|kCTSIMSupportSIMStatusReady
SerialNumber			|DLXLH3S1FK11
SoftwareBehavior		|NSData
SoftwareBundleVersion	|
SupportedDeviceFamilies	|(1,2)
TelephonyCapability		|0
TimeIntervalSince1970	|1390795105.697946
TimeZone				|Australia/Melbourne
TimeZoneOffsetFromUTC	|39600
TrustedHostAttached		|1
UniqueChipID			|1609239303108
UniqueDeviceID			|779899123915611234565d88827c654321427
UseRaptorCerts			|1
Uses24HourClock			|0
WiFiAddress				|b8:fe:dc:ba:98:76

These have been observed in the past, but I don't see them on an iPad Air (ios7) or an iPod Touch (ios6)

Key							|Value
----------------------		|-----
BasebandBootloaderVersion	|"5.8_M3S2"
BasebandVersion				|"01.45.00"
BluetoothAddress			|?
DeviceCertificate			|lots of bytes
IntegratedCircuitCardIdentity	|?
InternationalMobileEquipmentIdentity	|?
InternationalMobileSubscriberIdentity	|?
PhoneNumber					|?
SomebodySetTimeZone			|1
iTunesHasConnected			|1

## Domain: com.apple.mobile.battery

I believe this superceded `com.apple.springboard.curvedBatteryCapacity`.

Key						|Value
----------------------	|-----
BatteryCurrentCapacity	|100
BatteryIsCharging		|0
ExternalChargeCapable	|1
ExternalConnected		|1
FullyCharged			|1
GasGaugeCapability[^1]	|1

[^1]:Only sighted on iOS7.

## Domain: com.apple.disk_usage

Key						|Value
----------------------	|-----
AmountDataAvailable		|4294914048
AmountDataReserved		|209715200
CalculateDiskUsage		|"OkilyDokily"[^2]
TotalDataAvailable		|4504629248
TotalDataCapacity		|29481025536
TotalDiskCapacity		|31708938240
TotalSystemAvailable	|335544320
TotalSystemCapacity		|2227912704
NANDInfo				|NSData...

[^2]: Yes, really.

These have been observed in the past, but I don't see them any more on an iPad Air (ios7) or an iPod Touch (ios6), though there are some clues still visible inside /usr/libexec/lockdownd

Key							|Value
----------------------		|-----
AmountCameraAvailable		|556707840
AmountCameraUsageChanged	|-58721
CalendarUsage				|311296		(/var/mobile/Library/Calendar ?)
CameraUsage					|27063896
MediaCacheUsage				|0			(/tmp/MediaCache ?)
MobileApplicationUsage		|5058054749
NotesUsage					|40960		(/var/mobile/Library/Notes ?)
PhotoUsage					|6096396
VoicemailUsage				|28672		(/var/mobile/Library/Voicemail ?)
WebAppCacheUsage			|600064		(/var/mobile/Library/Caches/com.apple.WebAppCache ?)

## Domain: com.apple.mobile.data_sync

Key						|Value
----------------------	|-----
Bookmarks				|{...}
Calendars				|{...}
Contacts				|{...}
Notes					|{...}

Each of the values is a subdictionary with a similiar set of keys.  For example,
<PRE>
Notes =
    AccountNames =     (
        iCloud
    );
    Sources =     (
        "com.apple.dataaccess.IMAPNotes",
        iCloud
    );
}
</PRE>

## Domain: com.apple.mobile.sync_data_class

Key								|Value
------------------------------	|-----
Bookmarks						|{}
Calendars						|{}
Contacts						|{}
DeviceHandlesDefaultCalendar	|1
DeviceSupportsClearingData		|1
Mail Accounts					|{ "ReadOnly" = 1 }
Notes							|{}
SupportsEncryptedBackups		|1
SyncSupportsCalDAV				|1

## Domain: com.apple.mobile.lockdown_cache

Key						|Value
----------------------	|-----
ActivationState			|Activated

## Domain: com.apple.mobile.iTunes

Key							|Value
--------------------------	|-----
64Bit						|3
AccessibilityLanguages		|("fr-CA","nl-BE", ...)
AlbumArt					|(3013, {...}, 3018, {...}, ...)
AppleDRMVersion				|{ Format = 2; Maximum = 4; Minimum = 0 }
AudioCodecs					|{"AAC"={...}; "AIFF"={...}; ...}
BatteryPollInterval			|60
ChapterImageSpecs			|(3006, {...}, 3013, {...}, ... })
ConnectedBus				|USB
CustomerRingtones			|1
DBVersion					|5
FairPlayCBMaxVersion		|4
FairPlayCBMinVersion		|3
FairPlayCertificate			|NSData...
FairPlayDeviceType			|94
FairPlayGUID				|888455bb1568888888809ca4c27ce2b648888
FairPlayID					|NSData...
FamilyID					|10032
GeniusConfigMaxVersion		|20
GeniusConfigMinVersion		|1
GeniusMetadataMaxVersion	|20
GeniusMetadataMinVersion	|1
GeniusSimilaritiesMaxVersion	|20
GeniusSimilaritiesMinVersion	|1
HomeScreenIconColumns		|4
HomeScreenIconDockMaxCount	|6
HomeScreenIconHeight		|72
HomeScreenIconRows			|5
HomeScreenIconWidth			|72
HomeScreenMaxPages			|15
HomeScreenNewsstand			|1
HomeVideosSupported			|1
IconFolderColumns			|3
IconFolderMaxPages			|15
IconFolderRows				|3
IconStateSaves				|1
ImageSpecifications			|(901, {...}, 3141, {...}, ...)
KeyTypeSupportVersion		|492
MinITunesVersion			|11.1.0
MinMacOSVersion				|10.5.8
NeedsAntiPhishingDB			|1
OEMA						|1
OEMID						|0
PhotoEventsSupported		|1
PhotoFacesSupported			|1
PhotoVideosSupported		|1
PlaylistFoldersSupported	|1
PodcastsSupported			|1
RentalsSupported			|1
Ringtones					|1
ScreenHeight				|2048
ScreenScaleFactor			|2
ScreenWidth					|1536
SupportedKeyboards			|("ar","bg_BG",...)
SupportsAccessibility		|1
SupportsAirTraffic			|1
SupportsAlertTones			|1
SupportsAntiPhishing		|1
SupportsApplicationInstall	|1
SupportsConfigurationBlobs	|1
SupportsDownloadedPodcasts	|1
SupportsGenius				|1
SupportsGeniusMixes			|1
SupportsProvisioningBlobs	|1
SyncDataClasses				|("Contacts", "Calendars", ...)
TVShowRentalsSupported		|1
UseVoiceMemosFolder			|1
VideoCodecs					|{"H.263" = {...}; "H.264" = {...}; ...}
VideoPlaylistsSupported		|1
VoiceMemoFormats			|{"AAC"={...}; "AIFF"={...}; ...}
VoiceMemosSupported			|1
iPhoneCheckpointVersion		|1
iTunesSetupComplete			|1
iTunesStoreCapable			|1
iTunesUSupported			|1

## Domain: com.apple.mobile.restriction

Key						|Value
----------------------	|-----
ProhibitAppDelete		|0
ProhibitAppInstall		|0

## Domain: com.apple.international

Key						|Value
----------------------	|-----
Locale					|en_AU
Language				|en
SupportedLocales		|("sv_AX", "ro_RO", ...)
SupportedKeyboards		|("ar", "bg_BG", ...)
SupportedLanguages		|("en", "fr", ..)

///     Keyboard = "en_AU";


## Domain: com.apple.xcode.developerdomain
Key						|Value
----------------------	|-----
DeveloperStatus			|Development

## Domain: com.apple.mobile.software_behavior
Key						|Value
----------------------	|-----
ChinaBrick				|0
GoogleMail				|0
NTSC					|0
NoVOIP					|0
NoWiFi					|0
ShutterClick			|0
Valid					|1
VolumeLimit				|0

## Domain: com.apple.mobile.internal
Key						|Value
----------------------	|-----
CarrierBuild			|0
IsInternal				|0
UIBuild					|1

/// <PRE>
///		VoidWarranty = ???;					// not observed but deduced
///		PasswordProtected = ???;			//
///		ActivationStateAcknowledged = ???;	//
/// </PRE>

## Domain: com.apple.Accessibility
Key										|Value
-----------------------					|-----
SpeakAutoCorrectionsEnabledByiTunes	|0
ZoomTouchEnabledByiTunes				|0
InvertDisplayEnabledByiTunes			|0
ClosedCaptioningEnabledByiTunes			|0
MonoAudioEnabledByiTunes				|0
VoiceOverTouchEnabledByiTunes			|0

## Domain: com.apple.mobile.wireless_lockdown

These appear to relate to the wireless connection between the device and iTunes.

Key										|Value
-----------------------					|-----
BonjourFullServiceName					|"ee:e8:ff:dd:4d:cc@fe80::eeee:ffff:4567._apple-mobdev2._tcp.local."
EnableWifiConnections					|0
SupportsWifi							|1
SupportsWifiSyncing						|1

WirelessBuddyID appears to be a dynamic value.  Its format is as a <uuid> and it appears that the MobileDevice.framework retrieves it from CFPreferences("com.apple.iTunes","WirelessBuddyID"), allocating a new one if it does not already exist.

AMDeviceSetWirelessBuddyFlags() seems to push the hosts value across into the device, when it sets EnableWifiConnections to True.


## return nothing at iOS6

This section is not well formatted, and contains data that has been deduced/observed in the past but no longer appears to be valid.

com.apple.mobile.iTunes.SQLMusicLibraryPostProcessCommands
/// <PRE>
///    SQLCommands =     {
///        AddAlbumArtistBlankColumn = "ALTER TABLE item ADD COLUMN album_artist_blank INTEGER NOT NULL DEFAULT 0;";
///        AddAlbumArtistNameBlankColumn = "ALTER TABLE album_artist ADD COLUMN name_blank INTEGER NOT NULL DEFAULT 0;";
///        AddAlbumArtistSectionOrderColumn = "ALTER TABLE item ADD COLUMN album_artist_section_order BLOB;";
///        AddAlbumArtistSortNameSectionColumn = "ALTER TABLE album_artist ADD COLUMN sort_name_section INTEGER NOT NULL DEFAULT 0;";
///        ...
///        CreateItemArtistIndex = "CREATE INDEX IF NOT EXISTS item_idx_artist ON item (artist);";
///        CreateItemArtistPidIndex = "CREATE INDEX IF NOT EXISTS item_idx_artist_pid ON item (artist_pid);";
///        ...
///        UpdateItemArtistNameBlankColumn = "UPDATE item_artist SET name_blank = 1 WHERE (name = '' OR name IS NULL);";
///        UpdateItemInSongsCollectionBlankColumns = "UPDATE item SET title_blank = (title = '' OR title IS NULL), artist_blank = (artist = '' OR artist IS NULL), composer_blank = (composer = '' OR composer IS NULL), album_blank = (album = '' OR album IS NULL), album_artist_blank = (album_artist = '' OR album_artist IS NULL), in_songs_collection = ((media_kind&33) AND ((media_kind&2)=0 AND is_rental=0));";
///        Version = 19;
///    };
///    UserVersionCommandSets = {
///        8 = {
///            Commands = (
///                DropUpdateItemInSongsCollectionTrigger,
///                DropUpdateItemTitleBlankTrigger,
///                DropUpdateItemArtistBlankTrigger,
///                ...
///                "MarkITunesCommandsExecuted_CurrentVersion"
///            );
///            SchemaDependencies = {
///                artist = (
///                    DropItemArtistTable,
///                    DropAlbumArtistTable,
///                    Artist2RenameArtistTable,
///                    ...
///                    DeleteEmptyAlbumArtists
///                );
///            };
///        };
///    };
/// </PRE>

com.apple.mobile.user_preferences
/// <PRE>
///    DiagnosticsAllowed = 0;
/// </PRE>

com.apple.mobile.lockdown
/// <PRE>
///		LogToDisk = ???;				// not observed but deduced
///		ExtendedLogging	= ???;			//
/// </PRE>

com.apple.mobile.mobile_application_usage
/// <PRE>
///    "01028E50-0F1B-409D-B39A-98151466B4BB" = 148302989;
///    "034052C6-0573-46EF-BE17-86622EEB2CE3" = 2832934;
///    "03F43111-D9C5-40D3-9B01-50DBD68D6C87" = 12780530;
///		...
///    "05DFBBF2-C3E6-413F-B466-D358BFD88054" = 3141019;
/// </PRE>

com.apple.mobile.iTunes.store
/// <PRE>
///    AccountKind = 0;
///    AppleID = stevejobs;
///    CreditDisplayString = "";
///    DSPersonID = 1;
///    KnownAccounts =     (
///                {
///            AccountKind = 0;
///            AppleID = stevejobs;
///            CreditDisplayString = "";
///            DSPersonID = 1;
///        }
///    );
///    PreferHQTracks = 1;
///    PurchaseTypes = 0;
///    Storefront = "1,1";
///    UserName = "Steve Jobs";
/// </PRE>

com.apple.mobile.debug

com.apple.mobile.nikita

com.apple.fairplay

com.apple.mobile.lockdownd

