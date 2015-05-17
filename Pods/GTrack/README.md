
![Gtrack](Screenshots/gtrack_logo.png)

[![License](https://img.shields.io/cocoapods/l/GTrack.svg)](http://doge.mit-license.org) [![Build Status](https://img.shields.io/travis/gemr/GTrack.svg)](https://travis-ci.org/gemr/GTrack/) ![Badge w/ Version](https://img.shields.io/cocoapods/v/GTrack.svg)

GTrack is a lightweight Objective-C wrapper around the Google Analytics for iOS v3 SDK with some extra goodies, brought to you by [Gemr](http://www.gemr.com). It's built with simplicity and ease-of-use in mind, and adds some additional features not directly available through Google's SDK.

#Features

- **Automatic session management**
- **Screen view tracking**
- **Event Tracking**
- **Timed Events** - Easily track the duration of important events like filling out forms or network requests, to see where users are being bottlenecked in your app.

#Installation


GTrack assumes you've set up your own Google Analytics Account. If you haven't already, visit [Google Analytics]
(http://www.google.com/analytics/) to set up your account and get your application Tracking ID, which you will need to set up GTrack. If you desire any further reading for how the Google Analytics for iOS SDK works, take a look at their [Getting Started](https://developers.google.com/analytics/devguides/collection/ios/v3/) page.

GTrack is available via [CocoaPods](http://cocoapods.org/?q=GTrack) Add the following to your `podfile`, run `pod install`, and you should be good to go!

`pod 'GTrack'`

#Usage


#1. Setup

Import `<GTTracker.h>` in your `AppDelegate.m` file, and in `application:didFinishLaunchingWithOptions:` initialize the `GTTracker` singleton with your Google Analytics Tracking ID and your `GAILogLevel`.

```objective-c
GTTracker *tracker = [GTTracker sharedInstance];
[tracker initializeAnalyticsWithTrackingID:YOUR_TRACKING_ID logLevel:kGAILogLevelInfo];
```

#2. Session Management

GTrack handles Google Analytics session management automatically. By default, sessions begin when GTrack receives a `UIApplicationWillEnterForegroundNotification`, and ends when it receives either a `UIApplcationDidEnterBackgroundNotification` or `UIApplicationWillTerminateNotification` notification.

To customize when sessions begin and end, you can disable automatic session management as follows:

```objective-c
[tracker setAutomaticSessionManagementEnabled:NO];
```

Then, whenever you want sessions to begin and end, you can call the following methods accordingly:

```objective-c
[[GTTracker sharedInstance] startAnalyticsSession];
[[GTTracker sharedInstance] endAnalyticsSession];
```


#3. Logging

By default, `GTTracker` logging is disabled, but you can optionally enable logging for debugging purposes. It isn't recommended that you leave logging enabled for your production apps.

```
[tracker setLoggingEnabled:YES];
```

#4. Manual Screen Tracking

If you opt to use manual screen tracking over automatic screen tracking, to avoid having to require every view controller you want to track extend `GAITrackedViewController`, you can tell the GTTracker singleton to send a screen event with a defined title as follows:

```objective-c
- (void)viewDidAppear {
	[super viewDidAppear];
	
	[[GTTracker sharedInstance] sendScreenEventWithTitle:@"Your Screen Name Here"];
}
```

#5. Sending Events

To track Google Analytics events through GTrack, all you need to do is pass whatever combination of `category`, `action`, `label`, and `value` parameters you desire to the GTTracker singleton. The `category`, `action`, and `label` params are `NSString`'s, and the `value` param is an `NSNumber`. 

```objective-c
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Your Category" action:@"Your Action" label:@"Your Label" value:@(yourValue)];
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Your Category" action:@"Your Action" label:@"Your Label"];
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Your Category" action:@"Your Action"];
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Your Category"];
```

For example, you might provide multiple ways to login to your app, and may be curious what percentage of your users use which methods. In the different functions that implement these log in methods, you could add each of the following where they apply:

```objective-c
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Log In" action:@"Social" label:@"Facebook"];
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Log In" action:@"Social" label:@"Google"];
[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Log In" action:@"Normal" label:@"Email"];
```

Breaking up related events, as shown above, in a similar hierarchy means more insightful reports at the end of your cycle. All events related to "Log In" are encapsulated in the same category and thus can be filtered accordingly to retrieve interesting metrics based specifically on those categories. Subsequently, the "Log In" category is further broken into two main actions, "Social" and "Normal", so when filtered you're able to see what percentage of your users are signing in with email vs. Facebook/Google, and what percentage of users that used social login signed up with Facebook vs. Google. This can give you valuable data about how your users interact with your application and about popular or unused features you may want to focus on or remove entirely.

#6. Timing An Event

From a user-experience standpoint, it can extremely valuable to know how long certain activities take in the real-world. GTrack allows you to create *timed events* that start when you create them, and end when you tell them to, automatically sending the event off to Google along with your define event parameters with the duration of the event as the `value` of the event.

For example, you might want to know how long it takes users to fill out a signup form when your app launches for the first time. To achieve this, you could do something like the following:

```objective-c
- (void)viewDidAppear {
	[super viewDidAppear];
	
	// Create a GTTimedEvent instance and assign it to a property/instance variable so you can end it later.
	self.signUpTimedEvent = [GTTimedEvent eventStartingNowWithCategory:@"Sign Up" action:@"Success" label:@"Duration (seconds)"];
}

- (void)handleUserSubmittedForm {
	// Now that the user has submitted the form, you can end the event you created 
	// previously and define the desired interval unit. (seconds, minutes, or hours)
	[self.signUpTimedEvent endAndSendWithIntervalUnit:IntervalUnitSeconds];
	
	// continue with the form submission process
}

```

If it took the user 45 seconds to fill out the form and submit, this would result in a Google Analytics Event being sent off with "Sign Up" as the category, "Duration (seconds)" as the label, and "45.0" as the value of the event.

As these events are delivered to Google over time from all your users, you'll be able to see what the *average value* is. 

***NOTE:*** It appears that the `value` parameter is not visible using Google's *Real-Time Events* dashboard, but will be available when viewing previous days reports in *Behavior* -> *Events*.


#7. Timing Multiple Related Events

Expanding on the above example regarding users filling out an initial sign up form, you might suspect you have some user drop-off during the process. In this case, both events, a successful signup, and a cancelled signup, are related in that they both start at the same time, but end at different times. You can track the durations of both of these events using a shared `GTInterval` object, and when one or the other even completes, you can use that object to get the duration, and send the events normally:

```objective-c
- (void)viewDidAppear {
	[super viewDidAppear];
	
	// Create a GTInterval instance and assign it to a property/instance variable so you can access it later.
	self.signUpEventInterval = [GTInterval intervalWithNowAsStartDate];
}

- (void)handleUserCancelledForm {
	// Tell your GTInterval object to end.
	[self.signUpEventInterval end];
	
	// Send an event to Google denoting that the sign up process was cancelled, and that the duration of the
	// event was the number of seconds from the time you created your GTIterval.
	[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Sign Up" action:@"Cancel" label:@"Duration (seconds)" value:self.signUpEventInterval.intervalAsSeconds];
}

- (void)handleUserSubmittedForm {
	// Tell your GTInterval object to end.
	[self.signUpEventInterval end];

	// Send an event to Google denoting that the sign up process was completed successfully, and that the 
	// duration of the event was the number of seconds from the time you created your GTIterval.
	[[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Sign Up" action:@"Success" label:@"Duration (seconds)" value:self.signUpEventInterval.intervalAsSeconds];
}
```

---
[<img src="Screenshots/gemr_logo.png">](http://www.gemr.com)

###Gemr is a social community for collectors where you can discover, share, buy, sell, trade, and show-off your collectibles and other unique items. We want to connect you with like-minded people who share your passions.





#License

This project is made available under the MIT license. See LICENSE.txt for details.

