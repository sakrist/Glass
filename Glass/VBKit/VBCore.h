//
//  VBCore.h
//  Glass
//
//  Created by Volodymyr Boichentsov on 29/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//


@interface VBCore : NSObject

@property (nonatomic) GLKVector2 viewSize;
@property (nonatomic) float aspect;
@property (nonatomic) float frameTime;
@property (nonatomic) float runTime;

+ (VBCore *)c;

@end
