#import <Cordova/CDV.h>

@interface FirebaseAnalyticsPlugin : CDVPlugin

- (void)logEvent:(CDVInvokedUrlCommand*)command;
- (void)setUserId:(CDVInvokedUrlCommand*)command;
- (void)setUserProperty:(CDVInvokedUrlCommand*)command;
- (void)setEnabled:(CDVInvokedUrlCommand*)command;
- (void)setCurrentScreen:(CDVInvokedUrlCommand*)command;
- (void)resetAnalyticsData:(CDVInvokedUrlCommand*)command;
- (void)setDefaultEventParameters:(CDVInvokedUrlCommand*)command;
- (void)setAnalyticsConsentMode:(CDVInvokedUrlCommand*)command;
- (void)createUserWithEmailAndPassword:(CDVInvokedUrlCommand*)command;
- (void)signInUserWithEmailAndPassword:(CDVInvokedUrlCommand*)command;
- (void)authenticateUserWithEmailAndPassword:(CDVInvokedUrlCommand*)command;
- (void)signInWithCredential:(CDVInvokedUrlCommand*)command;
- (void)signOutUser:(CDVInvokedUrlCommand*)command;
- (void)setDocumentInFirestoreCollection:(CDVInvokedUrlCommand*)command;
- (void)fetchDocumentInFirestoreCollection:(CDVInvokedUrlCommand*)command;

+ (FirebasePlugin *) firebasePlugin;
+ (NSString*) appleSignInNonce;
+ (void) setFirestore:(FIRFirestore*) firestoreInstance;
- (void) handlePluginExceptionWithContext: (NSException*) exception :(CDVInvokedUrlCommand*)command;
- (void) handlePluginExceptionWithoutContext: (NSException*) exception;
- (void) _logError: (NSString*)msg;
- (void) _logInfo: (NSString*)msg;
- (void) _logMessage: (NSString*)msg;
- (BOOL) _shouldEnableCrashlytics;
- (NSNumber*) saveAuthCredential: (FIRAuthCredential *) authCredential;
- (void)executeGlobalJavascript: (NSString*)jsString;

@end
