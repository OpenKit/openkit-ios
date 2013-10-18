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
For example: ```10001302592140``` ( user-id in *facebook* )


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


4. **Client's request, based in x-auth (idea from *twitter*'s *oauth* fork)**  
*Oauth* was designed to provide authorized access to "untrusted" third party consumers ( 3-legged authorization ). Obviously in this case ( *openkit* ), both, server(provider) and app(consumer) are managed by the same developer so we shouldn't redirect the user to an external login through the browser. The request_token step is omitted.
[https://dev.twitter.com/docs/oauth/xauth](https://dev.twitter.com/docs/oauth/xauth)

	4.1. **Login credentials**  
	Credentials are used to get an valid *openkit*'s access_token. Similarly, the openkit server use the  ```*((access_token provided by the service))``` provided by the service ( *facebook*, *twitter*, etc. ) to valide the credentials.  
	The path and method are defined in *oauth*. For example ```users/``` (POST)
	
	```
{
	"requests" : 
	[
		{
			"service" : *((service's name)),
			"data" : (( )),
			"key" : (( )),
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
			"data" : "1451173071",  #facebook user ID
			"key" : "CAAGZAk4ZABCjwBAFN6qUw0kMSZBkfXFVIZBLB2UiZBFLsQY6lWDoyV8dta6dmLZBEFYLcgq9e5MqOGSR45VceO2o4ATg2G7kPfXOnPRoGWh2cgLwp8twCoX2NWzkVzMBoLykpx274ZBWPAIO4OA4abfvcm77uhrF4JK8wdDWeQ8zGj4RzqjC5bryRCm2sBZB8Xnpl4yXY0ObzX1oBM0yZAorJ",
		},
		{
			"service" : "gamecenter",
			"data" : "io.openkit.game1103403020498345hib6hj245b614j2j54",
			"key" : "CAAGZAk4ZABCjwBAFN6qUw0kMSZBkfXFVIZBLB2UiZBFLsQY6lWDoyV8dta6dmLZBEFYLcgq9e5MqOGSR45VceO2o4ATg2G7kPfXOnPRoGWh2cgLwp8twCoX2NWzkVzMBoLykpx274ZBWPAIO4OA4abfvcm77uhrF4JK8wdDWeQ8zGj4RzqjC5bryRCm2sBZB8Xnpl4yXY0ObzX1oBM0yZAorJ",
			"public_key_url" : "https://signature.gc.apple.com/public352g4tte324m"
		}
	]
}
```


5. **Server's respond:**  
( If login was successful, ie, the server validated that the credentials were valid. )
Full OKLocalUser representation.
			
	```
{
	"id" : *((user's id))",
	"nick" : *((user's nick))",
	"oauth_token" : "((user's access token))"",
	"oauth_token_secret" : "((user's token secret))"",
	"services" :
	{	
		# dictionary of services: facebook, twitter, etc. #
		"*((service's name))" : *((user_id in service)),...
	}
	"friends" :
		"*((service's name))" : ((serialized array of friend IDs)),
		...
	}
}
```

	Example:

	```
{
	"id" : "245",
	"nick" : "Manu",
	"oauth_token" : "vhj5k6c23fx3l6k3ad89jHuihhIHh",
	"oauth_token_secret" : "hbhjkjbhHJjhbjhkHGv7v7568gbvgfGHCG456v5465V65$5465VBvhgfJgh76567BJGFhftreuhkoojiHiuoHu",
	"services" :
	{
		"facebook" : "1451173071",
		"gamecenter" : "110340"
	}
	"friends" :
	{
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
###0. Encrypted messages

```
{
	"encryption" : "SHA256+AES256",
	"encoding" : "UTF-8",
	"compression" : "gzip",
	"payload" : "hjkHJGlhkkjhñILHChiu=="
}
```

- **encryption:** Defines the algorithm used for the encryiption. The followin methods are explained in the appendixes.
	- SHA256_AES256
- **encoding:** It defines how the json string was encoded into data, by default it should be UTF-8.
- **compression**: If used it, the compression algorithm should be specified here.
- **payload**: ThThe payload must be encoded with base64.
"encryption": should be the cryptographic algorithm used to protect it, openkit uses SHA256+AES256 by default


###1. Updating OKUSER
Updating OKUser:

- Update nick name.
- Update list of friends.
***

1. **Path & method:** `/localuser` (POST)

2. **Client's request:**  
Json with the values you want to change. All optional.

	```
{
	"nick" : ((user's nick)), #optional
	"friends_((service's name))" : ((serialized array of friend IDs))
}
```

	Example:
		
	```
{
	"nick" : "Manuel",
	"friends_facebook" : "1400034324,1002302434,10000023232",
	"friends_gamecenter" : "1400034324,1002302434,10000023232"
}
```
	


4. **Server's response:**

	```
{ } 
```
Nothing, a error code if something was wrong.


###2. OKCLOUD
Synchronizing data entries between client and server. This protocol implements a simple toolkit to resolve conflicts if several devices modify the same values.
***

1. **Path & method:** ```/cloud``` (POST)


2. **((priority))**  
It is an arbitrary real number managed by the client and used by the server to resolve conflicts.
If the "priority" in the client-side is equal or greater than the "priority" in the server-side, the values are overwritten in the server, otherwise the values are overwritten in the client.


3. **((timestamp))**  
It's a timestamp managed by the server that indicates the date of the last sync with the client.


4. **A void request can be used to get the whole stored data.**  

	```
{ }
```


5. **Client's request:**  

	```
{
	"priority" : *((priority)), #optional
	"last_update" : *((timestamp)), #optional
	"entries" : #optional
	{
		# dictionary of the entries that changed since the last update #
		"((key))" :  ((object)),
		...
	}
}
```


6. **Server's response:**  

	```
{
	"priority" : *((priority)),
	"last_update" : *((timestamp)),
	"entries" :
	{
		# dictionary of the entries that should change in the client #
		"((key))" : ((object)),
		...
	}
}
```



###3. OKSCORE
Posting scores to server.
***

1. **Path & method:** ```/scores``` (POST)


2. **Client's request:**

	```
{
	"leaderboard_id" : ((score's leaderboard ID)),
	"value" : ((score's value)),
	"metadata" : ((score's metadata)),
	"created_date" : *((date))
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
	"rank" : 87
}
```

###3. OKACHIEVEMENTS
Posting achievements.
***

1. **Path & method:** ```/achievements``` (POST)


2. **Client's request:**


3. **Server's response:**



##5. UNAUTHORIZED SERVICES
Unauthorized services use the GET method.

###1. OKLEADERBOARD
Getting the list of leaderboards for the specified app.
***

1. **Path & method:** ```/leaderboards``` (GET)


2. **((timestamp))**  
Used internally by the SDK to optimize the internet usage. Inspired by ```HTTP 304 Not Modified``` error code.


3. **Client's request:**  

	```
{
	"app_key" : *((app's key)),
	"leaderboard_version" : ((leaderboard's version)),
	"last_update" : *((timestamp))   #optional
}
```
Example: getting leaderboards of the app "frf3352s2". ```/leaderboards?app_key=frf3352s2```


4. **Server's response:**  

	```
{
	"last_update" : *((timestamp)),
	"leaderboards" :
	[
		# array of dictionaries updated after specified in the "last_update" request param #
		{
			"id" : ((leaderboard's backend id)),
			"name" : ((leaderboard's name)),
			"sort_type" : *((leaderboard's sort type)),
			"icon_url" : ((leaderboard's icon url)),
			"player_count : ((leaderboard's player count)),
			"services" : 
			{
				"gamecenter_id" : (()), # leaderboard id in gamecenter
				"custom_id" : (()),
				...
			}
		},
		...
	]
}
```

	Example:
	
	```
{
	"last_update" : 14309234930,
	"leaderboards" :
	[
		{
			"id" : 2,
			"name" : "Level 1",
			"sort_type" : 0,
			"icon_url" : "http://storage.openkit.io/image_23234234.png",
			"player_count : 18334,
			"other_services" : 
			{
				"gamecenter_id" : 7342414,
			}
		},
		{
			"id" : 5,
			"name" : "Level 2",
			"sort_type" : 0,
			"icon_url" : "http://storage.openkit.io/image_5325444.png",
			"player_count : 876,
			"other_services" : 
			{
				"gamecenter_id" : 3367006,
			}
		},
		{
			"id" : 12,
			"name" : "Level 3",
			"sort_type" : 0,
			"icon_url" : "http://storage.openkit.io/image_45624644.png",
			"player_count : 13330,
			"other_services" : 
			{
				"gamecenter_id" : 1246512,
			}
		},
		...
	]
}
```
	
	
	**((leaderboard's sort type))**  
	- 0: descending (higher is better)
	- 1: ascending (lower is better)



###2. OKSCORE (top scores)
Getting a list of scores for the specified leaderboard.
***
 
1. **Path & method:** ```/best_scores/(*)``` (GET)  
To make it consistent and reusable, all these paths should use the same request/respond protocol explained later.
	- ```/best_scores``` best worldwide scores (no filter)
	- ```/best_scores/social``` best scores from friends
	
	
2. **Client's request:**

	```
{
	"app_key" : *((app's key)),
	"leaderboard_id" : ((leaderboard's id)),
	"leaderboard_range" : *((range)), #optional
	"num_per_page" : *((size)), #optional
	"page_num" : *((offset)), #optional
}
```

	Example:
	
	```
{
	"app_key" : "heuX3r98sjJJ",
	"leaderboard_id" : 23,
	"leaderboard_range" : "all_time", #optional
	"num_per_page" : 50, #optional
	"page_num" : 2, #optional
}
```
	**((range))**  
	Three values. All-time, week, month.

	**((size))** (a limit would be a good idea)
	Number of scores to respond.

	**((offset))** from 0 to 2^32-1  
	Example: getting the best scores from rank 30 to 45. ```/best_scores?offset=30&size=15...```


3. **Server's respond:**

	```
[
	# array of scores #
	{
		"id" : ((score's id)),
		"leaderboard_id" : ((leaderboard's id)),
		"value" : ((score's value)),
		"rank" : ((score's rank)),
		"user" :
		{
			"id" : ((user's id)),
			"nick" : ((user's nick))
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
