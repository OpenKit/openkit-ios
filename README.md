Quick Start
------------
Getting started instructions for OpenKit's iOS client: 

1. Get the repo: 

  ```
    $ git clone https://github.com/OpenKit/openkit-ios.git
  ```

  Briefly, this is what you just got: 

  <pre>openkit-ios 
                /OpenKit            &lt;-- The OpenKit source
                /Vendor             &lt;-- Libraries that OpenKit depends on
                /Resources          &lt;-- Images and xib files
                /OpenKit.xcodeproj  &lt;-- A project to build the SDK and/or run a sample app
  </pre>

  When you build the OpenKit target, a new directory will be created at openkit-ios/OpenKitSDK.  
  This will contain the static lib, headers, and resources to use in your own project.  To add
  OpenKit to your own project: 
  
  - Drag the OpenKitSDK folder into your project (build first!)

  - Drag the Vendor folder into your project

  - Add the following frameworks to your project (sorry, working on a better way):
    
    ```
      libsqlite3.dylib
      Twitter.framework
      Security.framework
      QuartzCore.framework
      AdSupport.framework
      Accounts.framework
      Social.framework
      MobileCoreServices.framework
      SystemConfiguration.framework
    ```

  - Add the following lines to your prefix file: 

     #import <SystemConfiguration/SystemConfiguration.h>
     #import <MobileCoreServices/MobileCoreServices.h>

  - Browse the sample app found in OpenKit.xcodeproj for the API calls to make. Or keep reading...


Introduction
------------
OpenKit gives you cloud data storage, leaderboards, and user account management as a service.

OpenKit relies on Facebook and Twitter for user authentication. Your users login with those services, and there is no "OpenKit account" that is shown to them. 



Basic SDK Usage
---------------
Be sure to read how to integrate the SDK into your app at http://openkit.io/docs/


Initialize the SDK and set your application id
----------------------------------------------
In your main activity and all launchable activities, be sure to intialize the SDK:

Import the OpenKit Header
```
#import "OpenKit.h"
```

Specify your application key in application:didFinishLaunchingWithOptions:. You can get your application key from the OpenKit dashboard.
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Always enter your app key in didFinishLaunchingWithOptions
    [OpenKit initializeWithAppID:@"VwfMRAl5Gc4tirjw"];
	...
}
```




User accounts
==============
Because OpenKit uses Facebook and Twitter(coming soon!) as authentication providers, you don't need to worry about user account management.

OpenKit provides a user class, OKUser, that manages most of the functionality you'll need for account management. 

Users are unique to each developer, but can be shared across multiple OpenKit applications from the same developer account. 

To get the current OpenKit user, simply call:

```
if([OKUser currentUser] != nil) {
	//User is logged in
	OKUser *currentUser = [OKUser currentUser];
}
else {
	// No user is logged in
}
```
You can get the current user any time, it will return null if the user is not authenticated. 

User Login
----------

If you're using OpenKit leaderboards, your users will be prompted to log in when the Leaderboards UI is shown. You can optionally prompt them to login at anytime:

```
OKLoginView *loginView = [[OKLoginView alloc] init];
    [loginView showWithCompletionHandler:^{
        // The login view was dismissed
		// You can check whether the user is currently logged in
		// by calling [OKUser currentUser]
    }];
```

If you're using cloud storage, the cloud storage calls require an authenticated user.




Leaderboards
=============
The OpenKit SDK provides a drop in solution for cross-platform leaderboards that work on both iOS and Android.

You define your leaderboards and their attributes in the OpenKit dashboard, and the client 

Show Leaderboards
------------------
Import the OpenKit header file

```
#import "OpenKit.h"
```

Start the Leaderboards view controller. If the user isn't logged in, they will be prompted to login when the activity is shown.
```
OKLeaderboardsViewController *leaderBoards = [[OKLeaderboardsViewController alloc] init];
    [self presentModalViewController:leaderBoards animated:YES];
```

This will show a list of all the leaderboards defined for your app.

Submit a Score
--------------
To submit a score, you simply create an OKScore object, set it's value, and then call submit. 

Submitting a score requires the user to be authenticated.

You can use blocks callbacks to handle success and failure when submitting a score, and handle them appropriately. 

```
OKScore *scoreToSubmit = [[OKScore alloc] init];
[scoreToSubmit setScoreValue:487];
[scoreToSubmit setOKLeaderboardID:23];
 
[scoreToSubmit submitScoreWithCompletionHandler:^(NSError *error) {
    if(error) {
        //There was an error submitting the score
        NSLog(@"Error submitting score: %@", error);
    }
    else {
        //Score submitted successfully
    }
}
```





Cloud Storage
=============
OpenKit allows you to seamlessly store data user data in the cloud. Saving user progress, game state, and other user information is as easy as using get and set methods. This data can then be accessed on both iOS and Android.

The OKCloud class provides a single set/get API pair, which automatically scopes the stored data by user. 

OKCloud requires that the user be authenticated before making get/set requests. 

Simple Example
--------------
Let's take a simple example, first storing the string "Hello world" for the key "myKey":

First, import the necessary package:
```
#import "OKCloud.h";
```
Now, call [OKCloud set]. This will be stored for the current authenticated OKUser.
```
[OKCloud set:@"Hello World" key:@"firstKey" completion:^(id obj, NSError *err) {
       if (!err) {
           NSLog(@"Successfully set string: %@", obj);
       } else {
           NSLog(@"Error setting string! %@", err);
       }
   }];
```
Sometime later, you can get the "Hello World" back with: 
```
[OKCloud get:@"firstKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully got: %@", obj);
        } else {
            NSLog(@"Error getting string! %@", err);
        }
    }];
```
Data Types 
------------
Along with Strings, the following data types can be stored successfully: 

* NSDictionary
* NSArray
* NSNumber (which includes Bool/Int/Float)
* Strings

Each of the above will be serialized and deserialized automatically for you.  For example, if we initialize a Dictionary like this: 

```
NSArray *arr = [NSArray arrayWithObjects:@"one", @"two", nil];
NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"foo",                           @"property1",
                   [NSNumber numberWithInt:-99],     @"property2",
                   [NSNumber numberWithBool:YES],    @"property3",
                   arr,                              @"property4",
                   nil];

```

We can then store the full object like this: 

```java
[OKCloud set:dict key:@"secondKey" completion:^(id obj, NSError *err) {
	if (!err) {
		NSLog(@"Successfully set dictionary: %@", obj);
	} 
	else {
     NSLog(@"Error setting dictionary! %@", err);
 	}
	}];
```

And then we can retrieve it (and print the deserialized data types) with:  

```
 [OKCloud get:@"secondKey" completion:^(id obj, NSError *err) {
        if (!err) {
            NSLog(@"Successfully got: %@", obj);
            NSLog(@"Class of property1: %@", [[obj objectForKey:@"property1"] class]);
            NSLog(@"Class of property2: %@", [[obj objectForKey:@"property2"] class]);
            NSLog(@"Class of property3: %@", [[obj objectForKey:@"property3"] class]);
            NSLog(@"Class of property4: %@", [[obj objectForKey:@"property4"] class]);
        } else {
            NSLog(@"Error getting dictionary! %@", err);
        }
    }];

```

This will output: 

```
Class of property1: __NSCFString
Class of property2: __NSCFNumber
Class of property3: __NSCFBoolean
Class of property4: JKArray
```


Builds the SDK as a static library. 

After building, right click on the product in Project Navigator (libOpenKit.a)
and select "Show in Finder".  Back out one directory and you will find a folder
called Release-universal.  That's where the goods are!


Building the Framework (Is this still necessary??)
--------
Install this https://github.com/kstenerud/iOS-Universal-Framework
  $ git clone https://github.com/kstenerud/iOS-Universal-Framework.git
  $ cd "iOS-Universal-Framework/Real Framework"
  $ ./install.sh

Paste in the Contents/Developer directory of your Xcode install (e.g. /Applications/Xcode46-DP2.app/Contents/Developer)

