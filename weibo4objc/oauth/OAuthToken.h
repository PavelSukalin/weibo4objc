//
//  OAuthToken.h
//  weibo4objc
//
//  Created by fanng yuan on 11/29/10.
//  Copyright 2010 fangyuan@sina. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface OAuthToken : NSObject {
@protected
	NSString *key;
	NSString *secret;
	NSString *session;
	NSNumber *duration;
	NSMutableDictionary *attributes;
	NSDate *created;
	BOOL renewable;
	BOOL forRenewal;
}
@property(retain, readwrite) NSString *key;
@property(retain, readwrite) NSString *secret;
@property(retain, readwrite) NSString *session;
@property(retain, readwrite) NSNumber *duration;
@property(retain, readwrite) NSMutableDictionary *attributes;
@property(readwrite, getter=isForRenewal) BOOL forRenewal;

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret;
- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret session:(NSString *)aSession
		 duration:(NSNumber *)aDuration attributes:(NSDictionary *)theAttributes created:(NSDate *)creation
		renewable:(BOOL)renew;
- (id)initWithHTTPResponseBody:(NSString *)body;

- (id)initWithUserDefaultsUsingServiceProviderName:(NSString *)provider prefix:(NSString *)prefix;
- (int)storeInUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix;

- (BOOL)isValid;

- (void)setAttribute:(NSString *)aKey value:(NSString *)aValue;
- (NSString *)attribute:(NSString *)aKey;
- (void)setAttributesWithString:(NSString *)aAttributes;
- (NSString *)attributeString;

- (BOOL)hasExpired;
- (BOOL)isRenewable;
- (void)setDurationWithString:(NSString *)aDuration;
- (BOOL)hasAttributes;
- (NSDictionary *)parameters;

- (BOOL)isEqualToToken:(OAuthToken *)aToken;

+ (void)removeFromUserDefaultsWithServiceProviderName:(const NSString *)provider prefix:(const NSString *)prefix;

@end
