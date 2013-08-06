
#import "OKColors.h"

@implementation OKColors

+(UIColor*)navbarTextColor {
    return [UIColor colorWithRed:77.0/255.0 green:77.0/255.0 blue:77.0/255.0 alpha:1.0] ;
}

+(UIColor*)navbarTintColor {
    return UIColorFromRGB(0xe8e8e8);
}

+(NSDictionary*)titleTextAttributesForNavBarButton {
    return  [NSDictionary dictionaryWithObjectsAndKeys:[OKColors navbarTextColor], UITextAttributeTextColor,[UIColor clearColor], UITextAttributeTextShadowColor, nil];
}

+(UIColor*)playerTopScoreBGColor {
    return UIColorFromRGB(0xe0eecf);
}

+(UIColor*)scoreCellBGColor {
    return [UIColor whiteColor];
}

@end
