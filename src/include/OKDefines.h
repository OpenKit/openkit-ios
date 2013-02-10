//
//  OKDefines.h
//  OKClient
//
//  Created by Louis Zell on 1/25/13.
//  Copyright (c) 2013 OpenKit. All rights reserved.
//

#ifndef OKClient_OKDefines_h
#define OKClient_OKDefines_h

#ifdef DEBUG
    #define OKBaseURL @"http://localhost:3000/"
#else
    #define OKBaseURL @"http://stage.openkit.io/"
#endif
#define OKErrorDomain @"OKError"

#endif  // end if OKClient_OKDefines_h
