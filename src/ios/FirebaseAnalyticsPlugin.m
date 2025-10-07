#import "FirebaseAnalyticsPlugin.h"

@import FirebaseCore;
@import FirebaseAnalytics;
@import FirebaseAuth;

@implementation FirebaseAnalyticsPlugin

static FIRFirestore* firestore;
static NSString*const GOOGLE_ANALYTICS_ADID_COLLECTION_ENABLED = @"GOOGLE_ANALYTICS_ADID_COLLECTION_ENABLED";
static NSString*const GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE = @"GOOGLE_ANALYTICS_DEFAULT_ALLOW_ANALYTICS_STORAGE";
static NSString*const GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE = @"GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_STORAGE";
static NSString*const GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA = @"GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_USER_DATA";
static NSString*const GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS = @"GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS";


- (void)pluginInitialize {
    NSLog(@"Starting Firebase Analytics plugin");

    if(![FIRApp defaultApp]) {
        [FIRApp configure];
    }
}

+ (void) setFirestore:(FIRFirestore*) firestoreInstance{
    firestore = firestoreInstance;
}

- (void)createUserWithEmailAndPassword:(CDVInvokedUrlCommand*)command {
    @try {
        NSString* email = [command.arguments objectAtIndex:0];
        NSString* password = [command.arguments objectAtIndex:1];
        [[FIRAuth auth] createUserWithEmail:email
                                   password:password
                                 completion:^(FIRAuthDataResult * _Nullable authResult,
                                              NSError * _Nullable error) {
          @try {
              [self handleAuthResult:authResult error:error command:command];
          }@catch (NSException *exception) {
              [self handlePluginExceptionWithContext:exception :command];
          }
        }];
    }@catch (NSException *exception) {
        [self handlePluginExceptionWithContext:exception :command];
    }
}

- (void)signInUserWithEmailAndPassword:(CDVInvokedUrlCommand*)command {
    @try {
        NSString* email = [command.arguments objectAtIndex:0];
        NSString* password = [command.arguments objectAtIndex:1];
        [[FIRAuth auth] signInWithEmail:email
                                   password:password
                                 completion:^(FIRAuthDataResult * _Nullable authResult,
                                              NSError * _Nullable error) {
          @try {
              [self handleAuthResult:authResult error:error command:command];
          }@catch (NSException *exception) {
              [self handlePluginExceptionWithContext:exception :command];
          }
        }];
    }@catch (NSException *exception) {
        [self handlePluginExceptionWithContext:exception :command];
    }
}

- (void)signInWithCredential:(CDVInvokedUrlCommand*)command {
    @try {
        FIRAuthCredential* credential = [self obtainAuthCredential:[command.arguments objectAtIndex:0] command:command];
        if(credential == nil) return;

        [[FIRAuth auth] signInWithCredential:credential
                                  completion:^(FIRAuthDataResult * _Nullable authResult,
                                               NSError * _Nullable error) {
            [self handleAuthResult:authResult error:error command:command];
        }];
    }@catch (NSException *exception) {
        [self handlePluginExceptionWithContext:exception :command];
    }
}

- (void)isUserSignedIn:(CDVInvokedUrlCommand*)command {
    @try {
        bool isSignedIn = [self isSignedIn];
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isSignedIn] callbackId:command.callbackId];

    }@catch (NSException *exception) {
        [self handlePluginExceptionWithContext:exception :command];
    }
}

- (void)signOutUser:(CDVInvokedUrlCommand*)command {
    @try {
        if([self userNotSignedInError:command]) return;

        // If signed in with Google
        if([GIDSignIn.sharedInstance currentUser] != nil){
            // Sign out of Google
            [GIDSignIn.sharedInstance disconnectWithCompletion:^(NSError * _Nullable error) {
                if (error) {
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"Error signing out of Google: %@", error]] callbackId:command.callbackId];
                }

                [self signOutOfFirebase:command];
            }];
        }else{
            [self signOutOfFirebase:command];
        }
    }@catch (NSException *exception) {
        [self handlePluginExceptionWithContext:exception :command];
    }
}

- (NSNumber*) getTimestampFromDate:(NSDate*)date {
    if(date == nil) return nil;
    return @([date timeIntervalSince1970] * 1000);
}

- (NSString *)stringBySha256HashingString:(NSString *)input {
  const char *string = [input UTF8String];
  unsigned char result[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256(string, (CC_LONG)strlen(string), result);

  NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (NSInteger i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [hashed appendFormat:@"%02x", result[i]];
  }
  return hashed;
}


- (void)setDocumentInFirestoreCollection:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        @try {
            NSString* documentId = [command.arguments objectAtIndex:0];
            NSDictionary* document = [command.arguments objectAtIndex:1];
            NSString* collection = [command.arguments objectAtIndex:2];
            bool  timestamp = [command.arguments objectAtIndex:3];

            NSMutableDictionary *document_mutable = [document mutableCopy];

            if(timestamp){
                document_mutable[@"lastUpdate"] = [FIRTimestamp timestampWithDate:[NSDate date]];
            }

            [[[firestore collectionWithPath:collection] documentWithPath:documentId] setData:document_mutable completion:^(NSError * _Nullable error) {
                [self handleEmptyResultWithPotentialError:error command:command];
            }];
        }@catch (NSException *exception) {
            [self handlePluginExceptionWithContext:exception :command];
        }
    }];
}

- (void)fetchDocumentInFirestoreCollection:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        @try {
            NSString* documentId = [command.arguments objectAtIndex:0];
            NSString* collection = [command.arguments objectAtIndex:1];

            FIRDocumentReference* docRef = [[firestore collectionWithPath:collection] documentWithPath:documentId];
            if(docRef != nil){
                [docRef getDocumentWithCompletion:^(FIRDocumentSnapshot * _Nullable snapshot, NSError * _Nullable error) {
                    if (error != nil) {
                        [self sendPluginErrorWithMessage:error.localizedDescription:command];
                    } else if(snapshot.data != nil) {
                        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self sanitiseFirestoreDataDictionary:snapshot.data]] callbackId:command.callbackId];
                    }else{
                        [self sendPluginErrorWithMessage:@"Document not found in collection":command];
                    }
                }];
            }else{
                [self sendPluginErrorWithMessage:@"Collection not found":command];
            }
        }@catch (NSException *exception) {
            [self handlePluginExceptionWithContext:exception :command];
        }
    }];
}

- (id)sanitizeFirestoreData:(id) value {
    if([value isKindOfClass:[FIRDocumentReference class]]){
        FIRDocumentReference* reference = (FIRDocumentReference*) value;
        NSString* path = reference.path;
        return path;
    }else if([value isKindOfClass:[NSDictionary class]]){
        return [self sanitiseFirestoreDataDictionary:value];
    }else if([value isKindOfClass:[NSArray class]]){
        NSMutableArray* array = [[NSMutableArray alloc] init];;
        for (id element in value) {
            id sanitizedValue = (id)[self sanitizeFirestoreData:element];
            [array addObject:(id)sanitizedValue];
        }
        return array;
    }else if([value isKindOfClass:[FIRTimestamp class]]){
        FIRTimestamp* dateTimestamp = (FIRTimestamp*) value;
        NSDictionary *dateDictionary = @{
            @"nanoseconds" : [NSNumber numberWithInt:dateTimestamp.nanoseconds],
            @"seconds" : [NSNumber numberWithLong:dateTimestamp.seconds]
        };

        return dateDictionary;
    } else if([value isKindOfClass:[NSNumber class]]){
        double number = [value doubleValue];
        if (isnan(number) || isinf(number)) {
            return nil;
        }
    }
    return value;
}

- (void) handleAuthResult:(FIRAuthDataResult*) authResult error:(NSError*) error command:(CDVInvokedUrlCommand*)command {
    @try {
        CDVPluginResult* pluginResult;
         if (error) {
             pluginResult = [self createAuthErrorResult:error];
         }else if (authResult == nil) {
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"User not signed in"];
         }else{
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
         }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     }@catch (NSException *exception) {
         [self handlePluginExceptionWithContext:exception :command];
     }
}

- (bool) isSignedIn {
    return [FIRAuth auth].currentUser ? true : false;
}

- (bool) userNotSignedInError:(CDVInvokedUrlCommand *)command {
    bool isError = ![self isSignedIn];
    if(isError){
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No user is currently signed"] callbackId:command.callbackId];    }
    return isError;
}

- (void)setAnalyticsConsentMode:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        NSDictionary* consentObject = [command.arguments objectAtIndex:0];

        NSMutableDictionary* consentSettings = [[NSMutableDictionary alloc] init];

        @try {
            // Build consent dictionary
            NSEnumerator *enumerator = [consentObject keyEnumerator];
            id key;
            while ((key = [enumerator nextObject])) {
                NSString* consentType = [self consentTypeFromString:key];
                NSString* consentStatus = [self consentStatusFromString:[consentObject objectForKey:key]];

                if (consentType != nil && consentStatus != nil) {
                    [consentSettings setObject:consentStatus forKey:consentType];
                } else {
                    NSLog(@"[FirebaseAnalyticsPlugin] Invalid consent key or status: %@ = %@", key, [consentObject objectForKey:key]);
                }
            }

            // Apply consent to Firebase
            [FIRAnalytics setConsent:consentSettings];

            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Consent applied successfully"];
        }
        @catch (NSException *exception) {
            NSLog(@"[FirebaseAnalyticsPlugin] setAnalyticsConsentMode exception: %@", exception.reason);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:exception.reason];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


- (NSString*)consentTypeFromString:(NSString*)consentTypeString {
    if ([consentTypeString isEqualToString:@"ANALYTICS_STORAGE"]) {
        return FIRConsentTypeAnalyticsStorage;
    } else if ([consentTypeString isEqualToString:@"AD_STORAGE"]) {
        return FIRConsentTypeAdStorage;
    } else if ([consentTypeString isEqualToString:@"AD_PERSONALIZATION"]) {
        return FIRConsentTypeAdPersonalization;
    } else if ([consentTypeString isEqualToString:@"AD_USER_DATA"]) {
        return FIRConsentTypeAdUserData;
    } else {
        return nil;
    }
}

- (NSString*)consentStatusFromString:(NSString*)consentStatusString {
    if ([consentStatusString isEqualToString:@"GRANTED"]) {
        return FIRConsentStatusGranted;
    } else if ([consentStatusString isEqualToString:@"DENIED"]) {
        return FIRConsentStatusDenied;
    } else {
        return nil;
    }
}

- (void)logEvent:(CDVInvokedUrlCommand *)command {
    NSString* name = [command.arguments objectAtIndex:0];
    NSDictionary* parameters = [command.arguments objectAtIndex:1];

    [FIRAnalytics logEventWithName:name parameters:parameters];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUserId:(CDVInvokedUrlCommand *)command {
    NSString* id = [command.arguments objectAtIndex:0];

    [FIRAnalytics setUserID:id];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUserProperty:(CDVInvokedUrlCommand *)command {
    NSString* name = [command.arguments objectAtIndex:0];
    NSString* value = [command.arguments objectAtIndex:1];

    [FIRAnalytics setUserPropertyString:value forName:name];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setEnabled:(CDVInvokedUrlCommand *)command {
    bool enabled = [[command.arguments objectAtIndex:0] boolValue];

    [FIRAnalytics setAnalyticsCollectionEnabled:enabled];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCurrentScreen:(CDVInvokedUrlCommand *)command {
    NSString* screenName = [command.arguments objectAtIndex:0];

    [FIRAnalytics logEventWithName:kFIREventScreenView parameters:@{
        kFIRParameterScreenName: screenName
    }];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)resetAnalyticsData:(CDVInvokedUrlCommand *)command {
    [FIRAnalytics resetAnalyticsData];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setDefaultEventParameters:(CDVInvokedUrlCommand *)command {
    NSDictionary* params = [command.arguments objectAtIndex:0];

    [FIRAnalytics setDefaultEventParameters:params];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
