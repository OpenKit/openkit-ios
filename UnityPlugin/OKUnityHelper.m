/* -------------------------------------------------------------------------------------- /
 *  OKUnityHelper.m
 *  OpenKit Unity Plugin
 * 
 *  Created by Lou Zell on 2/14/13.
 *  Copyright 2013 OpenKit. All rights reserved.
 * -------------------------------------------------------------------------------------- */

#import "OKUnityHelper.h"

#if __has_feature(objc_arc)
#warning This file must not be compiled with ARC. Use the -fno-objc-arc flag.
#endif

char *OK_HS(const char *str)
{
	if (str == NULL)
		return NULL;
	
	char *res = (char *)malloc(strlen(str) + 1);
	strcpy(res, str);
	return res;
}

NSString *OK_NewString(const char *string)
{
	if (string)
		return [[NSString alloc] initWithUTF8String:string];
	else
		return [[NSString alloc] initWithUTF8String: ""];
}

