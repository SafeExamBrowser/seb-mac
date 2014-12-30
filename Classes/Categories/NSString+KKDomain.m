//
//  NSString+KKDomain.m
//  KKDomain
//
//  Created by Luke on 4/6/14.
//  Copyright (c) 2014 geeklu. All rights reserved.
//

#import "NSString+KKDomain.h"

@implementation NSString (KKDomain)

#pragma mark -
#pragma mark Private Methods

- (NSDictionary *)etldRuleTree{
    static NSDictionary *rules = nil;
    if (!rules) {
        for (NSBundle *bundle in [NSBundle allBundles]) {
            NSString *rulePath = [bundle pathForResource:@"etld" ofType:@"plist"];
            if (rulePath) {
                rules = [NSDictionary dictionaryWithContentsOfFile:rulePath];
                break;
            }
        }
    }
    return rules;
}

- (NSString *)processRegisteredDomainForHostComponents:(NSMutableArray *)components withRuleTree:(NSDictionary *)ruleTree{
    if ([components count] == 0) {
        return nil;
    }
    
    NSString *lastComponent = [[components lastObject] lowercaseString];
    [components removeLastObject];
    
    NSString *result = nil;
    
    if (ruleTree[lastComponent]) {
        NSDictionary *subTree = ruleTree[lastComponent];
        if (subTree[@"!"]) {
            return lastComponent;
        } else {
            result = [self processRegisteredDomainForHostComponents:components withRuleTree:ruleTree[lastComponent]];
        }
    } else if (ruleTree[@"*"]) {
        result = [self processRegisteredDomainForHostComponents:components withRuleTree:ruleTree[@"*"]];
    } else {
        return lastComponent;
    }
    
    if (result && [result length] > 0) {
        return [NSString stringWithFormat:@"%@.%@",result,lastComponent];
    } else {
        return nil;
    }
}

- (NSString *)processPublicSuffixForComponents:(NSMutableArray *)components withRuleTree:(NSDictionary *)ruleTree{
    if ([components count] == 0) {
        return nil;
    }
    
    NSString *lastComponent = [[components lastObject] lowercaseString];
    [components removeLastObject];
    
    NSString *result = nil;
    if (ruleTree[lastComponent]) {
        NSDictionary *subTree = ruleTree[lastComponent];
        if (subTree[@"!"]) {
            return nil;
        } else {
            result = [self processPublicSuffixForComponents:components withRuleTree:subTree];
        }
    } else if (ruleTree[@"*"]) {
        result = [self processPublicSuffixForComponents:components withRuleTree:ruleTree[@"*"]];
    } else {
        return nil;
    }
    
    if (result && [result length] > 0) {
        return [NSString stringWithFormat:@"%@.%@",result,lastComponent];
    } else {
        return lastComponent;
    }
}

#pragma mark -
#pragma mark Public

- (NSString *)registeredDomain{
    if ([self hasPrefix:@"."] || [self hasSuffix:@"."]) {
        return nil;
    }
    
    NSMutableArray *hostComponents = [[self componentsSeparatedByString:@"."] mutableCopy];
    if ([hostComponents count] <= 1) {
        return nil;
    }
    
    NSString *registeredDomain = [self processRegisteredDomainForHostComponents:hostComponents withRuleTree:[self etldRuleTree]];
    return registeredDomain;
}


- (NSString *)publicSuffix{
    NSMutableArray *components = [[self componentsSeparatedByString:@"."] mutableCopy];
    NSString *publicSuffix = [self processPublicSuffixForComponents:components withRuleTree:[self etldRuleTree]];
    return publicSuffix;
}

@end
