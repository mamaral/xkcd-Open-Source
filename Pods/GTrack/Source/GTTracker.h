//
//  GTTracker.h
//  GTrack
//
//  Created by Michael Amaral on 1/23/15.
//  Copyright (c) 2015 Gemr, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import <GoogleAnalytics-iOS-SDK/GAIFields.h>
#import <GoogleAnalytics-iOS-SDK/GAIDictionaryBuilder.h>
#import <GoogleAnalytics-iOS-SDK/GAITracker.h>

/**
 * GTTracker is a wrapper around the Google Analytics SDK for iOS, providing automatic session management and quick-and-easy screen and event tracking.
 */
@interface GTTracker : NSObject


/**
 * Whether or not the GTTracker will handle Google Analytics sessions automatically. The default value of this property is YES.
 */
@property (nonatomic) BOOL automaticSessionManagementEnabled;


/**
 * Whether or not the GTTracker will log events to the console. May aid in debugging if any issues arise, but it is recommended that this is set to NO for production builds. The default value of this property is NO.
 */
@property (nonatomic) BOOL loggingEnabled;


/**
 * Whether or not the Google Analytics session is active. This is primarily used for testing purposes.
 */
@property (nonatomic, readonly) BOOL isSessionActive;


/**
 * Creates or returns the shared GTTracker singleton.
*/
+ (instancetype)sharedInstance;


/**
 * Initializes the GTTracker with your Google Analytics tracking identifier and desired log level.
 *
 * @param trackingID    Your Google Analytics tracking ID to use for the tracker. It should be of the form `UA-xxxxx-y`. The name of the underlying Google tracker will be the same as trackingID.
 * @param logLevel      The desired verbosity of the underlying Google Analytics SDK logger.
 */
- (void)initializeAnalyticsWithTrackingID:(NSString *)trackingID logLevel:(GAILogLevel)logLevel;


/**
 * Sets the beginning of the Google Analytics session.
 *
 * @note The GTTracker will handle session management by default, unless the handleSessionManagement property is set to NO. Sessions begin when a UIApplicationWillEnterForegroundNotification is received, and end when either a UIApplicationWillTerminateNotification or UIApplcationDidEnterBackgroundNotification is received. If you wish to handle sessions yourself, set the handleSessionManagement property to NO.
 */
- (void)startAnalyticsSession;


/**
 * Sets the end of the Google Analytics session.
 *
 * @note The GTTracker will handle session management by default, unless the handleSessionManagement property is set to NO. Sessions begin when a UIApplicationWillEnterForegroundNotification is received, and end when either a UIApplicationWillTerminateNotification or UIApplcationDidEnterBackgroundNotification is received. If you wish to handle sessions yourself, set the handleSessionManagement property to NO.
 */
- (void)endAnalyticsSession;


/**
 * Sends a screen event to Google Analtics with the provided title. This value will be used as the screen name in your Google Analytics reports.
 *
 * @param title    The title of the screen representing the content users are viewing within your app.
 */
- (void)sendScreenEventWithTitle:(NSString *)title;


/**
 * Sends an event to Google Analytics with a specified category. The action, label, and value parameters will all be nil, and thus empty in your Google Analytics reports.
 *
 * @param category    The category describing the Google Analytics event.
 *
 * @note The iOS Google Analytics SDK for iOS  may throttle events, as well as other hits, if a large number of send calls are made in a short period of time. https://developers.google.com/analytics/devguides/collection/ios/v3/events
 */
- (void)sendAnalyticsEventWithCategory:(NSString *)category;


/**
 * Sends an event to Google Analytics with a specified category and action. The label and value parameters will be nil, and thus empty in your Google Analytics reports.
 *
 * @param category  The category describing the Google Analytics event.
 * @param action    The action describing the Google Analytics event.
 *
 * @note The iOS Google Analytics SDK for iOS  may throttle events, as well as other hits, if a large number of send calls are made in a short period of time. https://developers.google.com/analytics/devguides/collection/ios/v3/events
 */
- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action;


/**
 * Sends an event to Google Analytics with a specified category, action, and label. The value parameter will be nil, and thus empty in your Google Analytics reports.
 *
 * @param category  The category describing the Google Analytics event.
 * @param action    The action describing the Google Analytics event.
 * @param label     The label describing the Google Analytics event.
 *
 * @note The iOS Google Analytics SDK for iOS  may throttle events, as well as other hits, if a large number of send calls are made in a short period of time. https://developers.google.com/analytics/devguides/collection/ios/v3/events
 */
- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label;


/**
 * Sends an event to Google Analytics with a specified category, action, label, and value.
 *
 * @param category  The category describing the Google Analytics event.
 * @param action    The action describing the Google Analytics event.
 * @param label     The label describing the Google Analytics event.
 * @param value     The value describing the Google Analytics event.
 *
 * @note The iOS Google Analytics SDK for iOS may throttle events, as well as other hits, if a large number of send calls are made in a short period of time. https://developers.google.com/analytics/devguides/collection/ios/v3/events
 */
- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value;

@end


@class GTInterval;

typedef enum {
    /**
     * The time interval representated as seconds with accuracy to the tenth-of-a-second. (ex. 4.5)
     */
    IntervalUnitSeconds,
    
    /**
     * The time interval representated as minutes with accuracy to the tenth-of-a-minute. (ex. 4.5)
     */
    IntervalUnitMinutes,
    
    /**
     * The time interval representated as hours with accuracy to the tenth-of-an-hour. (ex. 4.5)
     */
    IntervalUnitHours
} IntervalUnit;


/**
 * The GTTimedEvent encapsulates a Google Analytics event and the duration that event took to complete.
 *
 * @note GTTimedEvent objects are typically defined using a combination of the Google Analytics category, action, and label properties, and the value will be automatically generated when the GTTimedEvent is told to stop and dispatch with a call to `endAndSendWithIntervalUnit:`.
 */

@interface GTTimedEvent : NSObject


/**
 * The category describing the Google Analytics event.
 */
@property (nonatomic, strong) NSString *category;


/**
 * The action describing the Google Analytics event.
 */
@property (nonatomic, strong) NSString *action;


/**
 * The label describing the Google Analytics event.
 */
@property (nonatomic, strong) NSString *label;


/**
 * The GTInterval object associated with this event, used to calculate the duration of the event and report it back as the associated Google Analytics event's value parameter.
 */
@property (nonatomic, strong) GTInterval *eventInterval;


/**
 * Create and return a GTTimedEvent instance, used to track a Google Analytics event's duration.
 *
 * @param category  The category describing the Google Analytics event.
 * @param action    The action describing the Google Analytics event.
 * @param label     The label describing the Google Analytics event.
 */
+ (instancetype)eventStartingNowWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label;


/**
 * Tells the GTTimedEvent that the predefined event has completed, calculates the duration of the event and set that as the `value` param for the event, and dispatches the event to Google Analytics.
 *
 * @param intervalUnit  The desired unit of time the analytics event will report as the duration of the event. See `IntervalUnit` for more details.
 */
- (void)endAndSendWithIntervalUnit:(IntervalUnit)intervalUnit;

@end


static NSTimeInterval const kAnalyticsSecondsPerMinute = 60.0;
static NSTimeInterval const kAnalyticsSecondsPerHour = 3600.0;
static NSTimeInterval const kAnalyticsDefaultTimeInterval = -1;

/**
 * The GTInterval object encapsulates the start, end, and subsequently the duration of an event.
 */
@interface GTInterval : NSObject


/**
 * The start time of this interval represented as an NSDate.
 */
@property (nonatomic, strong) NSDate *startDate;


/**
 * The end time of this interval represented as an NSDate.
 */
@property (nonatomic, strong) NSDate *endDate;


/**
 * The time interval between the start and end times.
 *
 * @note    If the end time is not defined, this value will return the value constant `kAnalyticsDefaultTimeInterval` value.
 */
@property (nonatomic) NSTimeInterval timeInterval;

+ (instancetype)intervalWithNowAsStartDate;


/**
 * Sets the `endDate` on the GTInterval object to the current time and subsequently calculates and sets the `interval` property.
 */
- (void)end;


/**
 * Returns an NSNumber representation of the interval as seconds, rounded to the nearest tenth-of-a-second (ex. 4.5).
 */
- (NSNumber *)intervalAsSeconds;


/**
 * Returns an NSNumber representation of the interval as minutes, rounded to the nearest tenth-of-a-minute (ex. 4.5).
 */
- (NSNumber *)intervalAsMinutes;


/**
 * Returns an NSNumber representation of the interval as hours, rounded to the nearest tenth-of-an-hour (ex. 4.5).
 */
- (NSNumber *)intervalAsHours;

@end
