//
//  StackMobQuery.h
//  StackMobiOS
//
//  Created by Jordan West on 10/14/11.
//  Copyright (c) 2011 StackMob, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SMGeoPoint.h"

typedef enum {
    SMOrderAscending = 0,
    SMOrderDescending = 1
} SMOrderDirection;

@interface StackMobQuery : NSObject
    
@property(nonatomic, copy) NSMutableDictionary *params;
@property(nonatomic, copy) NSMutableDictionary *headers;

+ (StackMobQuery *)query;

- (void)field:(NSString *)f mustEqualValue:(id)v;
- (void)field:(NSString *)f mustNotEqualValue:(id)v;
- (void)field:(NSString *)f mustBeLessThanValue:(id)v;
- (void)field:(NSString *)f mustBeLessThanOrEqualToValue:(id)v;
- (void)field:(NSString *)f mustBeGreaterThanValue:(id)v;
- (void)field:(NSString *)f mustBeGreaterThanOrEqualToValue:(id)v;
- (void)field:(NSString *)f mustBeOneOf:(NSArray *)arr;
- (void)field:(NSString *)f centeredAt:(SMGeoPoint *)point mustBeWithinMi:(double)radiusInMi;
- (void)field:(NSString *)f centeredAt:(SMGeoPoint *)point mustBeWithinKm:(double)radiusInKm;
- (void)field:(NSString *)f mustBeWithinBoxWithLowerLeft:(SMGeoPoint *)lowerLeft andUpperRight:(SMGeoPoint *)upperRight;
- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point;
- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point withinMi:(double)radiusInMi;
- (void)field:(NSString *)f mustBeNear:(SMGeoPoint *)point withinKm:(double)radiusInKm;
- (void)fieldMustBeNull:(NSString *)f;
- (void)fieldMustNotBeNull:(NSString *)f;
- (void)setExpandDepth:(NSUInteger)depth;
- (void)setSelectionToFields:(NSArray *)fields;
- (void)setRangeStart:(NSUInteger)start andEnd:(NSUInteger)end;
- (void)orderByField:(NSString *)f withDirection:(SMOrderDirection)dir;


@end
