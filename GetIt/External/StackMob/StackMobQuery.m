//
//  StackMobQuery.m
//  StackMobiOS
//
//  Created by Jordan West on 10/14/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import "StackMobQuery.h"

const double earthRadianInMi = 3956.6;
const double earthRadiamInKm = 6367.5;

@interface StackMobQuery (Private)
- (NSString *)keyForField:(NSString *)f andOperator:(NSString *)op;
- (void)setGeoParam:(SMGeoPoint *)pt withRadius:(double)r andDiv:(double)d forField:(NSString *)f andOperator:(NSString *)o;
@end

@implementation StackMobQuery

@synthesize params = _params;
@synthesize headers = _headers;

+ (StackMobQuery *)query {
    return [[[StackMobQuery alloc] init] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        _params = [[NSMutableDictionary alloc] initWithCapacity:4];
        _headers = [[NSMutableDictionary alloc] initWithCapacity:4];
    }
    
    return self;
}

- (void)field:(NSString *)f mustEqualValue:(id)v {
    [self.params setValue:v forKey:f];
}

- (void)field:(NSString *)f mustNotEqualValue:(id)v {
    [self.params setValue:v forKey:[self keyForField:f andOperator:@"ne"]];
}
     
- (void)field:(NSString *)f mustBeLessThanValue:(id)v {
    [self.params setValue:v forKey:[self keyForField:f andOperator:@"lt"]];  
}

- (void)field:(NSString *)f mustBeLessThanOrEqualToValue:(id)v {
    [self.params setValue:v forKey:[self keyForField:f andOperator:@"lte"]]; 
}

- (void)field:(NSString *)f mustBeGreaterThanValue:(id)v {
    [self.params setValue:v forKey:[self keyForField:f andOperator:@"gt"]];
}

- (void)field:(NSString *)f mustBeGreaterThanOrEqualToValue:(id)v {
    [self.params setValue:v forKey:[self keyForField:f andOperator:@"gte"]];
}

- (void)field:(NSString *)f mustBeOneOf:(NSArray *)arr {
    [self.params setValue:arr forKey:[self keyForField:f andOperator:@"in"]];
}


- (void)field:(NSString *)f centeredAt:(SMGeoPoint *)point mustBeWithinMi:(double)mi {
    [self setGeoParam:point withRadius:mi andDiv:earthRadianInMi forField:f andOperator:@"within"];    
}

- (void)field:(NSString *)f centeredAt:(SMGeoPoint *)point mustBeWithinKm:(double)km {
    [self setGeoParam:point withRadius:km andDiv:earthRadiamInKm forField:f andOperator:@"within"];
}


- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point {
    [self.params setValue:[point stringValue] forKey:[self keyForField:f andOperator:@"near"]];
}

- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point withinMi:(double)mi {
    [self setGeoParam:point withRadius:mi andDiv:earthRadianInMi forField:f andOperator:@"near"];
}

- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point withinKm:(double)km {
    [self setGeoParam:point withRadius:km andDiv:earthRadiamInKm forField:f andOperator:@"near"];
}

- (void)field:(NSString *)f mustBeWithinBoxWithLowerLeft:(SMGeoPoint *)lowerLeft andUpperRight:(SMGeoPoint *)upperRight {
    NSString *boxString = [NSString stringWithFormat:@"%@,%@", [lowerLeft stringValue], [upperRight stringValue]];
    [self.params setValue:boxString forKey:[self keyForField:f andOperator:@"within"]];
}

- (void)fieldMustBeNull:(NSString *)f  {
    [self.params setValue:@"true" forKey:[self keyForField:f andOperator:@"null"]];
}

- (void)fieldMustNotBeNull:(NSString *)f  {
    [self.params setValue:@"false" forKey:[self keyForField:f andOperator:@"null"]];
}

- (void)setExpandDepth:(NSUInteger)depth {
    [self.headers setValue:[NSString stringWithFormat:@"%d", depth] forKey:@"X-StackMob-Expand"];
}

- (void)setSelectionToFields:(NSArray *)fields {
    [self.headers setValue:[fields componentsJoinedByString:@","] forKey:@"X-StackMob-Select"];
}

- (void)setRangeStart:(NSUInteger)start andEnd:(NSUInteger)end {
    [self.headers setValue:[NSString stringWithFormat:@"objects=%d-%d", start, end] forKey:@"Range"];
}

- (void)orderByField:(NSString *)f withDirection:(SMOrderDirection)dir {
    NSString *orderStr;
    NSString *currentHeader = [self.headers objectForKey:@"X-StackMob-OrderBy"];
    NSString *newHeaderValue;
    if (dir == SMOrderAscending) {
        orderStr = @"asc";
    } else {
        orderStr = @"desc";
    }    

    if ([currentHeader isKindOfClass:[NSString class]]) {
        newHeaderValue = [NSString stringWithFormat:@"%@,%@:%@", currentHeader, f, orderStr];
    } else {
        newHeaderValue = [NSString stringWithFormat:@"%@:%@", f, orderStr];
    }
    [self.headers setValue:newHeaderValue forKey:@"X-StackMob-OrderBy"];
}

- (NSString *)keyForField:(NSString *)f andOperator:(NSString *)op {
    return [NSString stringWithFormat:@"%@[%@]", f, op];
}

- (void)setGeoParam:(SMGeoPoint *)pt withRadius:(double)r andDiv:(double)d forField:(NSString *)f andOperator:(NSString *)o {
    NSNumber *radius = [NSNumber numberWithDouble:r / d];
    NSString *arg = [NSString stringWithFormat:@"%@,%@", [pt stringValue], radius];
    [self.params setValue:arg forKey:[self keyForField:f andOperator:o]];

}

- (void)dealloc {
    self.params = nil;
    self.headers = nil;
    [super dealloc];
}

@end
