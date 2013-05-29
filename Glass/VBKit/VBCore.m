//
//  VBCore.m
//  Glass
//
//  Created by Volodymyr Boichentsov on 29/05/2013.
//  Copyright (c) 2013 Volodymyr Boichentsov. All rights reserved.
//

#import "VBCore.h"

@implementation VBCore

static VBCore *__core_instance;

+ (VBCore *)c  {
	@synchronized(self) {
		if(!__core_instance) {
			__core_instance = [[VBCore alloc] init];
            __core_instance.frameTime = 0.016999999999;
		}
	}
	return __core_instance;
}

@end
