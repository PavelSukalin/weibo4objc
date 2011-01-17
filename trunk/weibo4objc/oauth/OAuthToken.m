//
//  OAuthToken.m
//  weibo4objc
//
//  Created by fanng yuan on 11/29/10.
//  Copyright 2010 fangyuan@sina. All rights reserved.
//

#import "OAuthToken.h"


@interface OAuthToken (Private)

+ (NSString *)settingsKey:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (id)loadSetting:(const NSString *)name provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (void)saveSetting:(NSString *)name object:(id)object provider:(const NSString *)provider prefix:(const NSString *)prefix;
+ (NSNumber *)durationWithString:(NSString *)aDuration;
+ (NSDictionary *)attributesWithString:(NSString *)theAttributes;

@end

@implementation OAuthToken

@synthesize key, secret, session, duration, attributes, forRenewal;

#pragma mark init

- (id)init {
	return [self initWithKey:nil secret:nil];
}

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret {
	return [self initWithKey:aKey secret:aSecret session:nil duration:nil
				  attributes:nil created:nil renewable:NO];
}

- (id)initWithKey:(NSString *)aKey secret:(NSString *)aSecret session:(NSString *)aSession
		 duration:(NSNumber *)aDuration attributes:(NSDictionary *)theAttributes created:(NSDate *)creation
		renewable:(BOOL)renew {
	[super init];
	self.key = aKey;
	self.secret = aSecret;
	self.session = aSession;
	self.duration = aDuration;
	self.attributes = theAttributes;
	created = [creation retain];
	renewable = renew;
	forRenewal = NO;
	
	return self;
}

- (id)initWithHTTPResponseBody:(const NSString *)body {
    NSString *aKey = nil;
	NSString *aSecret = nil;
	NSString *aSession = nil;
	NSNumber *aDuration = nil;
	NSDate *creationDate = nil;
	NSDictionary *attrs = nil;
	BOOL renew = NO;
	NSArray *pairs = [body componentsSeparatedByString:@"&"];
	
	for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token"]) {
            aKey = [elements objectAtIndex:1];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_secret"]) {
            aSecret = [elements objectAtIndex:1];
        } else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_session_handle"]) {
			aSession = [elements objectAtIndex:1];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_duration"]) {
			aDuration = [[self class] durationWithString:[elements objectAtIndex:1]];
			creationDate = [NSDate date];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_attributes"]) {
			attrs = [[self class] attributesWithString:[[elements objectAtIndex:1] decodedURLString]];
		} else if ([[elements objectAtIndex:0] isEqualToString:@"oauth_token_renewable"]) {
			NSString *lowerCase = [[elements objectAtIndex:1] lowercaseString];
			if ([lowerCase isEqualToString:@"true"] || [lowerCase isEqualToString:@"t"]) {
				renew = YES;
			}
		}
    }
    
    return [self initWithKey:aKey secret:aSecret session:aSession duration:aDuration
				  attributes:attrs created:creationDate renewable:renew];
}

- (id)initWithUserDefaultsUsingServiceProviderName:(const NSString *)provider prefix:(const NSString *)prefix {
	[super init];
	self.key = [OAuthToken loadSetting:@"key" provider:provider prefix:prefix];
	self.secret = [OAuthToken loadSetting:@"secret" provider:provider prefix:prefix];
	self.session = [OAuthToken loadSetting:@"session" provider:provider prefix:prefix];
	self.duration = [OAuthToken loadSetting:@"duration" provider:provider prefix:prefix];
	self.attributes = [OAuthToken loadSetting:@"attributes" provider:provider prefix:prefix];
	created = [OAuthToken loadSetting:@"created" provider:provider prefix:prefix];
	renewable = [[OAuthToken loadSetting:@"renewable" provider:provider prefix:prefix] boolValue];
	
	if (![self isValid]) {
		[self autorelease];
		return nil;
	}
	
	return self;
}

#pragma mark dealloc

- (void)dealloc {
    self.key = nil;
    self.secret = nil;
    self.duration = nil;
    self.attributes = nil;
	[super dealloc];
}

#pragma mark settings

- (BOOL)isValid {
	return (key != nil && ![key isEqualToString:@""] && secret != nil && ![secret isEqualToString:@""]);
}

- (int)storeInUserDefaultsWithServiceProviderName:(const NSString *)provider prefix:(const NSString *)prefix {
	[OAuthToken saveSetting:@"key" object:key provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"secret" object:secret provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"created" object:created provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"duration" object:duration provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"session" object:session provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"attributes" object:attributes provider:provider prefix:prefix];
	[OAuthToken saveSetting:@"renewable" object:renewable ? @"t" : @"f" provider:provider prefix:prefix];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	return(0);
}

#pragma mark duration

- (void)setDurationWithString:(NSString *)aDuration {
	self.duration = [[self class] durationWithString:aDuration];
}

- (BOOL)hasExpired
{
	return created && [created timeIntervalSinceNow] > [duration intValue];
}

- (BOOL)isRenewable
{
	return session && renewable && created && [created timeIntervalSinceNow] < (2 * [duration intValue]);
}


#pragma mark attributes

- (void)setAttribute:(const NSString *)aKey value:(const NSString *)aAttribute {
	if (!attributes) {
		attributes = [[NSMutableDictionary alloc] init];
	}
	[attributes setObject: aAttribute forKey: aKey];
}

- (void)setAttributes:(NSDictionary *)theAttributes {
	[attributes release];
	attributes = [[NSMutableDictionary alloc] initWithDictionary:theAttributes];
	
}

- (BOOL)hasAttributes {
	return (attributes && [attributes count] > 0);
}

- (NSString *)attributeString {
	if (![self hasAttributes]) {
		return @"";
	}
	
	NSMutableArray *chunks = [[NSMutableArray alloc] init];
	for(NSString *aKey in self->attributes) {
		[chunks addObject:[NSString stringWithFormat:@"%@:%@", aKey, [attributes objectForKey:aKey]]];
	}
	NSString *attrs = [chunks componentsJoinedByString:@";"];
	[chunks release];
	return attrs;
}

- (NSString *)attribute:(NSString *)aKey
{
	return [attributes objectForKey:aKey];
}

- (void)setAttributesWithString:(NSString *)theAttributes
{
	self.attributes = [[self class] attributesWithString:theAttributes];
}

- (NSDictionary *)parameters
{
	NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
	
	if (key) {
		[params setObject:key forKey:@"oauth_token"];
		if ([self isForRenewal]) {
			[params setObject:session forKey:@"oauth_session_handle"];
		}
	} else {
		if (duration) {
			[params setObject:[duration stringValue] forKey: @"oauth_token_duration"];
		}
		if ([attributes count]) {
			[params setObject:[self attributeString] forKey:@"oauth_token_attributes"];
		}
	}
	return params;
}

#pragma mark comparisions

- (BOOL)isEqual:(id)object {
	if([object isKindOfClass:[self class]]) {
		return [self isEqualToToken:(OAuthToken *)object];
	}
	return NO;
}

- (BOOL)isEqualToToken:(OAuthToken *)aToken {
	/* Since ScalableOAuth determines that the token may be
	 renewed using the same key and secret, we must also
	 check the creation date */
	if ([self.key isEqualToString:aToken.key] &&
		[self.secret isEqualToString:aToken.secret]) {
		/* May be nil */
		if (created == aToken->created || [created isEqualToDate:aToken->created]) {
			return YES;
		}
	}
	
	return NO;
}

#pragma mark class_functions

+ (NSString *)settingsKey:(NSString *)name provider:(NSString *)provider prefix:(NSString *)prefix {
	return [NSString stringWithFormat:@"OAUTH_%@_%@_%@", provider, prefix, [name uppercaseString]];
}

+ (id)loadSetting:(NSString *)name provider:(NSString *)provider prefix:(NSString *)prefix {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self settingsKey:name
																		provider:provider
																		  prefix:prefix]];
}

+ (void)saveSetting:(NSString *)name object:(id)object provider:(NSString *)provider prefix:(NSString *)prefix {
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:[self settingsKey:name
																			provider:provider
																			  prefix:prefix]];
}

+ (void)removeFromUserDefaultsWithServiceProviderName:(NSString *)provider prefix:(NSString *)prefix {
	NSArray *keys = [NSArray arrayWithObjects:@"key", @"secret", @"created", @"duration", @"session", @"attributes", @"renewable", nil];
	for(NSString *name in keys) {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:[OAuthToken settingsKey:name provider:provider prefix:prefix]];
	}
}

+ (NSNumber *)durationWithString:(NSString *)aDuration {
	NSUInteger length = [aDuration length];
	unichar c = toupper([aDuration characterAtIndex:length - 1]);
	int mult;
	if (c >= '0' && c <= '9') {
		return [NSNumber numberWithInt:[aDuration intValue]];
	}
	if (c == 'S') {
		mult = 1;
	} else if (c == 'H') {
		mult = 60 * 60;
	} else if (c == 'D') {
		mult = 60 * 60 * 24;
	} else if (c == 'W') {
		mult = 60 * 60 * 24 * 7;
	} else if (c == 'M') {
		mult = 60 * 60 * 24 * 30;
	} else if (c == 'Y') {
		mult = 60 * 60 * 365;
	} else {
		mult = 1;
	}
	
	return [NSNumber numberWithInt: mult * [[aDuration substringToIndex:length - 1] intValue]];
}

+ (NSDictionary *)attributesWithString:(NSString *)theAttributes {
	NSArray *attrs = [theAttributes componentsSeparatedByString:@";"];
	NSMutableDictionary *dct = [[NSMutableDictionary alloc] init];
	for (NSString *pair in attrs) {
		NSArray *elements = [pair componentsSeparatedByString:@":"];
		[dct setObject:[elements objectAtIndex:1] forKey:[elements objectAtIndex:0]];
	}
	return [dct autorelease];
}

#pragma mark description

- (NSString *)description {
	return [NSString stringWithFormat:@"Key \"%@\" Secret:\"%@\"", key, secret];
}

@end
