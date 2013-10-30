OPENKIT'S PROTOCOL 2.0 (work in progress)
=======

###0. Legend

```
	#comments
	(( )) variables
```



##1. APPLICATION PROTOCOL

1. **HTTP header (POST and GET)**  

	```
Accept				application/json
Content-Type		application/json
Accept-Encoding		gzip, deflate  # posible performance improvement 
Authorization		# defined in oauth 1.0a specification
```


2. ***Openkit* should use HTTPS**  
HTTPS is recommended for a superior security level. ***Oauth 1.0a* protocol** is safe even over HTTP but *openkit* sends the credentials(see 3.4) in plaintext during login.


3. **Security configurations**  
	1. [Low security] No SSL certificate (plain http).
	2. [Medium security] CA signed SSL certificate in server side.
	3. [High security] CA or self-signed SSL certificate shared in both sides, server and client. [trusted-ssl-certificates](http://www.indelible.org/ink/trusted-ssl-certificates/)  
	This method provides the maximum security level. Invulnerable to man-in-the-middle attacks.
This method needs additional logic in the client side.



##2. DEFINITIONS

1. **((openkit's protocol version))**  
Should be specified in the first folder. http://api.openkit.io/**1.0v**/...


2. **((date))**  
Using this format: `yyyy-MM-dd HH:mm:ss`


3. **((user's id))**  
User id provided by the backend and identifies uniquely each user.


4. **((service's name))**  
For example: *"facebook"*, *"gamecenter"*, *"twitter"*...


5. **((user_id in service))**  
For example: `10001302592140` ( user-id in *facebook* )


6. **((app's key))**  
Consumer key provided by *[oauth](http://oauth.net/core/1.0/#anchor6)*.


7. **((app's secret))**  
Consumer secret provided by *[oauth](http://oauth.net/core/1.0/#anchor6)*.



##3. AUTHORIZATION
Valid credentials (see 3.4) are needed to get an openkit's access_token (see 3.5).

1. ***OAUTH 1.0a***  
*Openkit* uses the [standardized *oauth 1.0a* protocol](http://tools.ietf.org/html/rfc5849).


2. **Authorization in header**  
The authorization tokens are included in the HTTP header (not in the http body or URL). [http://oauth.net/core/1.0a/#auth_header](http://oauth.net/core/1.0a/#auth_header)


3. ***oauth* signature**  
The HTTP body is not included in the signature base string.

5. **Path & method**: `localuser/` (POST)

4. **Login/sign in**  

	```
{
    "requests" : 
    [
        {
            "service" : *((service's name)),
            "user_id" : ((user's id in service)),
            "user_name" : ((user's name in service)),
            "user_image_url" : ((user's image url in service)), #optional
            "key" : (( )),
            "data" : (( )), #optional
            "public_key_url" : (( )) #optional
        },...
    ]
}
```

	Example:
	
	```
{
    "requests" : 
    [
        {
            "service" : "facebook",
            "user_id" : "1451173071",  #facebook user ID
            "user_name" : "Manuel Mtz.",
            "user_image_url" : "https://graph.facebook.com/234324/picture",
            "key" : "px274ZBWPAIO4OA4abfvcm77uhrF4JK8wdDWeQ8J",
        },
        {
            "service" : "gamecenter",
            "user_id" : "6456367", #gamecenter user ID
            "user_name" : "Manu",
            "data" : "io.openkit.game1103403020498345hib6hj245b614j2j54",
            "public_key_url" : "https://signature.gc.apple.com/public352g4tte324m"
            "key" : "zMBoLykpx274ZBWPAIO4OA4abfvcm77uhrF4JRzqjC5bryRCm2sBZB8",
		}
	]
}
```


5. **Server's respond:**  
( If login was successful, ie, the server validated that the credentials were valid. )
Full OKLocalUser representation.
			
	```
{
    "access_token" : "((user's access token))",
    "access_secret" : "((user's access token))",
    "name" : *((user's nick))",
    "image_url" : ((user's image url)), #optional
    "services" : {	
        # dictionary of services: facebook, twitter, etc. #
        "*((service's name))" : *((user_id in service)),...
    }
    "friends" : {
        "*((service's name))" : ((serialized array of friend IDs)),
        ...
    }
}
```

	Example:

	```
{
    "access_token" : "vhj5k6c23fx3l6k3ad89jHuihhIHh",
    "access_secret" : "hbhjkjbhHJjhbjhkHGv7v7568gbvgfGHCG456v5465V65$5465VBvhgfJgh76567BJGFhftreuhkoojiHiuoHu",
    "name" : "Manuel Mtz.",
    "image_url" : "https://graph.facebook.com/234324/picture",
    "services" : {
        "facebook" : "1451173071",
        "gamecenter" : "110340"
    }
    "friends" : {
        "facebook" : "2342,345351,104353465,104534003450430,14030435434"
    }
}
```
See:
	- [https://dev.twitter.com/docs/oauth/xauth](https://dev.twitter.com/docs/oauth/xauth)
	- [http://oauth.net/core/1.0/#anchor29](http://oauth.net/core/1.0/#anchor29)



##4. AUTHORIZED SERVICES
A valid access_token is needed to do these kind of tasks.

---
###1. Updating OKUSER
Updating OKUser:

- Update nick name.
- Update list of friends.
***

1. **Path & method:** `localuser/` (PUT)

2. **Client's request:**  
The values you want to change. All optional.

	```
{
    "name" : ((user's nick)), #optional
    "image_url" : ((user's image)), #optional
    "friends_((service's name))" : ((serialized array of friend IDs)) #optional
}
```

	Example:
		
    ```
{
    "name" : "Manuel",
    "friends_facebook" : "1400034324,1002302434,10000023232",
    "friends_gamecenter" : "1400034324,1002302434,10000023232"
}
```
	


4. **Server's response:**

    ```
{
    "name" : ((user's nick)), #optional
    "image_url" : ((user's image)), #optional
    "friends_((service's name))" : ((serialized array of friend IDs)) #optional
} 
```
A error code if something was wrong.



###3. OKSCORE
Posting scores to server.
***

1. **Path & method:** ```scores/``` (POST)


2. **Client's request:**
We do not need to send the token in the body because it's in the deader.

	```
{
    "leaderboard_id" : ((score's leaderboard ID)),
    "value" : ((score's value)),
    "metadata" : ((score's metadata)),
    "created_date" : *((date)),
    "display_string" : ((score's display string)) #optional
}
```

	Example:
	
	```
{
    "leaderboard_id" : 23,
    "value" : 295826,
    "metadata" : null,
    "created_date" : "2013-03-12 07:23:11"
}
```

3. **Server's response:**

	```
{
    "id" : ((score's backend id)),
    "leaderboard_id" : ((score's leaderboard ID)),
    "value" : ((score's value)),
    "rank" : ((score's rank))
}
```

	Example:

	```
{
    "id" : 83457823,
    "leaderboard_id" : 23,
    "value" : 295826,
}
```

###3. OKACHIEVEMENTS
Posting achievements.
***

1. **Path & method:** ```achievements/``` (POST)


2. **Client's request:**


3. **Server's response:**



##5. UNAUTHORIZED SERVICES
Unauthorized services use the GET method.

###1. OKLEADERBOARD
Getting the list of leaderboards for the specified app.
***

1. **Path & method:** ```leaderboards/``` (GET)


2. **((timestamp))**  
Used internally by the SDK to optimize the internet usage. Inspired by ```HTTP 304 Not Modified``` error code.


3. **Client's request:**  

	```
{
    "leaderboard_version" : ((leaderboard's version)),
}
```
Example:

	```
{
    "leaderboard_version" : "v1",
    "last_update" : 42564442
}
```


4. **Server's response:**  

	```
[
	# array of leaderboards
	{
		"id" : ((leaderboard's backend id)),
   	    "name" : ((leaderboard's name)),
   	    "sort_type" : *((leaderboard's sort type)),
   	    "icon_url" : ((leaderboard's icon url)),
        "player_count : ((leaderboard's player count)),
        "services" : {
        	"((service's name))" : ((leaderboard_id in gamecenter)),
            ...
      	}
	}, ...
]
```

	Example:
	
	```
[
    {
        "id" : 2,
        "name" : "Level 1",
        "sort_type" : "HighValue",
        "icon_url" : "http://storage.openkit.io/image_23234234.png",
        "player_count : 18334,
        "services" : {
            "gamecenter" : "Level 1",
            "disney" : "23124"
        }
    },
    {
        "id" : 5,
        "name" : "Level 2",
        "sort_type" : "HighValue",
        "icon_url" : "http://storage.openkit.io/image_5325444.png",
        "player_count : 876,
        "services" : {
            "gamecenter_id" : "Level 3",
            "disney" : "342505"
        }
    },
    {
        "id" : 12,
        "name" : "Level 3",
        "sort_type" : "HighValue",
        "icon_url" : "http://storage.openkit.io/image_45624644.png",
        "player_count : 13330,
        "services" : {
            "gamecenter" : "Level 3",
            "disney" : "64345"
        }
    },
    ...
]
```
	
	
	**((leaderboard's sort type))**  
	- "HighValue": descending (higher is better)
	- "LowValue": ascending (lower is better)



###2. OKSCORE (top scores)
Getting a list of scores for the specified leaderboard.
***
 
1. **Path & method:** ```best_scores/(*)``` (GET)  
To make it consistent and reusable, all these paths should use the same request/respond protocol explained later.
	- ```/best_scores``` best worldwide scores (no filter)
	- ```/best_scores/social``` best scores from friends
	
	
2. **Client's request:**

	```
{
    "leaderboard_id" : ((leaderboard's id)),
    "leaderboard_range" : *((leaderboard_range)), #optional
    "num_per_page" : *((num_per_page)), #optional
    "page_num" : *((page_num)), #optional
}
```

	Example:
	
	```
{
    "leaderboard_id" : 23,
    "leaderboard_range" : "all_time", #optional
    "num_per_page" : 50, #optional
    "page_num" : 2, #optional
}
```
	**((leaderboard_range))**  
	Three values. All-time, week, month.

	**((num_per_page))** (a limit would be a good idea)  
	Number of scores to respond.

	**((page_num))**  
	Number of page.


3. **Server's respond:**

	```
[
    # array of scores #
    {
        "id" : ((score's id)),
        "leaderboard_id" : ((leaderboard's id)),
        "value" : ((score's value)),
        "rank" : ((score's rank)),
        "user" : {
            "name" : ((user's nick)),
            "image_url" : ((user's image url)),
    		"services" : {
    			# dictionary of services: facebook, twitter, etc. #
        		"*((service's name))" : *((user_id in service)),...
        	}
        }
    },
    ...
]
```

##6. APPENDIXES

###Example 1: Login flow with *facebook*
1. Getting the user_id and access_token from *facebook*: (see 3)   
	The user logs in *facebook*, and the SDK returns the user's id and an *facebook*'s oauth_token.
	
2. Getting a access_token for *openkit*: (see 3)  
	We send the *facebook*'s userID and oauth_token as credentials to get a openkit's access_token.
	
3. Once we have a valid access_token, we can do any "Authorized Service" (see 4)	
