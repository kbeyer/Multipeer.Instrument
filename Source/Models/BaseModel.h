//
//  MPIBaseModel.h
//  Multipeer.Instrument
//
//  Created by Kyle Beyer on 6/10/14.
//  Copyright (c) 2014 Kyle Beyer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPIBaseModel : NSObject

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;
-(NSDictionary*)convertToDictionary;

// used to determine if initWithDictionary should return new object or not
// check for required fields
// Abstract: MUST BE OVERRIDEN
-(BOOL)isValid;

@end
