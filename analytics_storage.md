


##Analytics storage
```
[
	// ARRAY OF SESSION
	{
		"id" : session token,
		"st" : start time,
		"et" : end time,
		"ev" :  // ARRAY OF EVENTS
		[
			{
				"t" : time of event,
				"ts" : timestamp,
				"m" : metadata // optional
			},...
		]
	}...
]
```

##Types of events

- X**"lblist_open"**: Open the list of leaderboards
- X**"lblist_close"**: Close the list of leaderboards
- X**"lb_open"**: Open one leaderboard (metadata: id of leaderboard)
- X**"lb_close"**: Close one leaderboard (metadata: id of leaderboard)
- **"chat_open"**: Open the chat room
- **"chat_close"**: Close the chat room
- X**"tap_invite"**: Tap the invite button
- X**"send_invite"**: Actually send an invite
- X**"challenge_not"**: Game opened due to a social challenge 
- X**"fb_success"**: Signed in with facebook through the login screen
- X**"fb_login"**: Signed in with facebook through the login screen
- X**"fb_social"**: Signed in with facebook though social leaderboards





