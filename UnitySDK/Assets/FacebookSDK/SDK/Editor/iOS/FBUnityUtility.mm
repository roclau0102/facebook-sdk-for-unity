// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBUnityUtility.h"

#include <string>
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

const char* const FB_OBJECT_NAME = "UnityFacebookSDKPlugin";

// Helper method to create C string copy
static char* FBUnityMakeStringCopy (const char* string)
{
    if (string == NULL)
        return NULL;
    
    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);
    return res;
}

@implementation FBUnityUtility

+ (void) sendCancelToUnity:(NSString *)unityMessage
                 requestId:(int)requestId
{
    [self sendMessageToUnity:unityMessage
                    userData:@{ @"cancelled" : @"true" }
                   requestId:requestId];
}

+ (void) triggerUploadViewHierarchy
{
    [self sendMessageToUnity:@"CaptureViewHierarchy"
                    userData:nil
                   requestId:0];
}

+ (void) triggerUpdateBindings:(NSString *)json
{
    [self sendMessageToUnity:@"OnReceiveMapping"
                     message:json
                   requestId:0];
}

+ (void)sendErrorToUnity:(NSString *)unityMessage
                   error:(NSError *)error
               requestId:(int)requestId
{
    NSString *errorMessage =
    error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?:
    error.userInfo[FBSDKErrorDeveloperMessageKey] ?:
    error.localizedDescription;
    [self sendErrorToUnity:unityMessage
              errorMessage:errorMessage
                 requestId:requestId];
}

+ (void)sendErrorToUnity:(NSString *)unityMessage
            errorMessage:(NSString *)errorMessage
               requestId:(int)requestId
{
    [self sendMessageToUnity:unityMessage
                    userData:@{ @"error" : errorMessage }
                   requestId:requestId];
}

+ (void)sendMessageToUnity:(NSString *)unityMessage
                  userData:(NSDictionary *)userData
                 requestId:(int)requestId
{
    NSMutableDictionary *resultDictionary = [ @{ @"callback_id": [@(requestId) stringValue] } mutableCopy];
    [resultDictionary addEntriesFromDictionary:userData];
    
    if (![NSJSONSerialization isValidJSONObject:resultDictionary]) {
        [self sendErrorToUnity:unityMessage errorMessage:@"Result cannot be converted to json" requestId:requestId];
        return;
    }
    
    NSError *serializationError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultDictionary options:0 error:&serializationError];
    if (serializationError) {
        [self sendErrorToUnity:unityMessage error:serializationError requestId:requestId];
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (!jsonString) {
        [self sendErrorToUnity:unityMessage errorMessage:@"Failed to generate response string" requestId:requestId];
        return;
    }
    
    const char *cString = [jsonString UTF8String];
    UnitySendMessage(FB_OBJECT_NAME, [unityMessage cStringUsingEncoding:NSASCIIStringEncoding], FBUnityMakeStringCopy(cString));
}

+ (void)sendMessageToUnity:(NSString *)unityMessage
                   message:(NSString *)message
                 requestId:(int)requestId
{
    const char *cString = [message UTF8String];
    UnitySendMessage(FB_OBJECT_NAME, [unityMessage cStringUsingEncoding:NSASCIIStringEncoding], FBUnityMakeStringCopy(cString));
}

+ (NSString *)stringFromCString:(const char *)string
{
    if (string && string[0] != 0)
    {
        return [NSString stringWithUTF8String:string];
    }
    
    return nil;
}

+ (NSDictionary *)dictionaryFromKeys:(const char **)keys
                              values:(const char **)vals
                              length:(int)length
{
    NSMutableDictionary *params = nil;
    if(length > 0 && keys && vals) {
        params = [NSMutableDictionary dictionaryWithCapacity:length];
        for(int i = 0; i < length; i++) {
            if (vals[i] && vals[i] != 0 && keys[i] && keys[i] != 0) {
                params[[NSString stringWithUTF8String:keys[i]]] = [NSString stringWithUTF8String:vals[i]];
            }
        }
    }
    
    return params;
}

+ (FBSDKGameRequestFilter) gameRequestFilterFromString:(NSString *)filter {
    if (filter.length == 0 || [filter isEqualToString:@"none"]) {
        return FBSDKGameRequestFilterNone;
    } else if ([filter isEqualToString:@"app_users"]) {
        return FBSDKGameRequestFilterAppUsers;
    } else if ([filter isEqualToString:@"app_non_users"]) {
        return FBSDKGameRequestFilterAppNonUsers;
    }
    
    NSLog(@"Unexpected filter type: %@", filter);
    return FBSDKGameRequestFilterNone;
}

+ (FBSDKGameRequestActionType) gameRequestActionTypeFromString:(NSString *)actionType {
    NSString *actionUpper = [actionType uppercaseString];
    if (actionUpper.length == 0 || [actionUpper isEqualToString:@"NONE"]) {
        return FBSDKGameRequestActionTypeNone;
    } else if ([actionUpper isEqualToString:@"SEND"]) {
        return FBSDKGameRequestActionTypeSend;
    } else if ([actionUpper isEqualToString:@"ASKFOR"]) {
        return FBSDKGameRequestActionTypeAskFor;
    } else if ([actionUpper isEqualToString:@"TURN"]) {
        return FBSDKGameRequestActionTypeTurn;
    }
    
    NSLog(@"Unexpected action type: %@", actionType);
    return FBSDKGameRequestActionTypeNone;
}

+ (NSDictionary *)appLinkDataFromUrl:(NSURL *)url
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    if (url) {
        [dict setObject:url.absoluteString forKey:@"url"];
        FBSDKURL *parsedUrl = [FBSDKURL URLWithInboundURL:url sourceApplication:nil];
        if (parsedUrl) {
            if (parsedUrl.appLinkExtras) {
                [dict setObject:parsedUrl.appLinkExtras forKey:@"extras"];
                
                // TODO - Try to parse ref param out and pass back
            }
            
            if (parsedUrl.targetURL) {
                [dict setObject:parsedUrl.targetURL.absoluteString forKey:@"target_url"];
            }
        }
    } else {
        [dict setObject:@true forKey:@"did_complete"];
    }
    return dict;
}

+ (NSDictionary *)getUserDataFromAccessToken:(FBSDKAccessToken *)token
{
    if (token) {
        if (token.tokenString &&
            token.expirationDate &&
            token.userID &&
            token.permissions &&
            token.declinedPermissions) {
            NSInteger expiration = token.expirationDate.timeIntervalSince1970;
            NSInteger lastRefreshDate = token.refreshDate ? token.refreshDate.timeIntervalSince1970 : 0;
            return @{
                @"opened" : @"true",
                @"access_token" : token.tokenString,
                @"expiration_timestamp" : [@(expiration) stringValue],
                @"user_id" : token.userID,
                @"permissions" : [token.permissions allObjects],
                @"granted_permissions" : [token.permissions allObjects],
                @"declined_permissions" : [token.declinedPermissions allObjects],
                @"last_refresh" : [@(lastRefreshDate) stringValue],
                @"graph_domain" : token.graphDomain ? : @"facebook",
            };
        }
    }
    
    return nil;
}

+ (UIImage *)imageWithURL:(NSString *)photoURL
{
    UIImage *image = [UIImage alloc];
    if ([photoURL hasPrefix:@"/"])
    {
        image = [UIImage imageWithContentsOfFile:photoURL];
    }
    else
    {
        // Get DocumentsDirectory
        NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAIndex:0];
        // Get image from url
        UIImage *imageFromURL = [self getImageFromURL:photoURL];
        // Save image to DocumentsDirectory
        [self saveImage:imageFromURL withFileName:@"tempImage" ofType:@"png" inDirectory:documentsDirectoryPath];
        // Load image from DocumentsDirectory
        image = [self loadImage:@"tempImage" ofType:@"png" inDirectory:documentsDirectoryPath];
    }
    return image;
}

+ (UIImage *)getImageFromURL:(NSString *)imageURL
{
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
    UIImage *image = [UIImage imageWithData:data];
    return image;
}

+ (void)saveImage:(UIImage *)image
     withFileName:(NSString *)imageName
           ofType:(NSString *)extension
      inDirectory:(NSString *)directoryPath
{
    if ([[extension lowercaseString] isEqualToString:@"png"])
    {
        [UIImagePNGRepresentation(image) writeToFile:[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", imageName, @"png"]] options:NSAtomicWrite error:nil];
    }
    else if ([[extension lowercaseString] isEqualToString:@"jpg"])
    {
        [UIImageJPEGRepresentation(image, 1.0) writeToFile:[directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", imageName, @"jpg"]] options:NSAtomicWrite error:nil];
    }
    else
    {
        NSLog(@"Image save failed\nExtension: (%@) is not recognized, use (png or jpg)", extension);
    }
}

+ (UIImage *)loadImage:(NSString *)withFileName 
                ofType:(NSString *)extension
           inDirectory:(NSString *)directoryPath
{
    UIImage *image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.%@", directoryPath, withFileName, extension]];
    return image;
}

// public - ask for photo permission to save video
+ (void)saveVideo:(NSString *)videoURL
completionHandler:(void(^)(PHAsset *))completionHandler
{
    NSURL *videoFileURL = [videoURL hasPrefix:@"file://"] ? [NSURL URLWithString:videoURL] : [NSURL fileURLWithPath:videoURL];
    if ([PHPhotoLibrary authrozationStatus] == PHAuthorizationStatusAuthorized) {
        [self saveVideoWithFileURL:videoURL completionHandler:completionHandler];
    }
    else
    {
        [PHPhotoLibrary requestAuthrization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized)
            {
                [self saveVideoWithFileURL:videoFileURL completionHandler:completionHandler];
            }
        }];
    }
}

// private - save video with permission
+ (void)saveVideoWithFileURL:(NSURL *)videoFileURL
           completionHandler:(void(^)(PHAsset *))completionHandler
{
    // 1. read config data from local json file
    NSMutableDictionary *config = [self readJsonConfigFromDocument];
    // 2. calc videoFileURL's md5
    NSString *md5 = [self md5:[videoFileURL absoluteString]];
    // 3. look up video asset identifier from config data by md5
    NSString *identifier = [config valueForKey:md5];
    
    if (identifier)
    {
        // 3.1 look up Photo asset by identifier
        PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil] firstObject];
        if (asset)
        {
            // 3.1.1 look up success
            completionHandler(asset);
            return;
        }
    }
    
    // 3.2 look up failed, no video asset exists, will save video asset to library
    __block PHObjectPlaceHolder *videoAssetPlaceHolder = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *createVideoAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoFileURL];
        videoAssetPlaceHolder = createVideoAssetRequest.placeHolderForCreateAsset;
        createVideoAssetRequest.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success)
            {
                // 3.2.1 save video asset success
                PHAsset *video = [[PHAsset fetchAssetsWithLocalIdentifiers:@[videoAssetPlaceHolder.localIdentifier] options:nil] firstObject];
                if (video)
                {
                    [config setValue:videoAssetPlaceHolder.localIdentifier forKey:md5];
                    [self saveJsonConfigToDocument:config];
                }
                completionHandler(video);
            }
            else
            {
                NSLog(@"ERROR save video failed. Reason: %@", error);
                completionHandler(nil);
            }
        });
    }];
}

+ (NSMutableDictionary *)readJsonConfigFromDocument
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *filePath = [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"config.txt"];
    if (filePath)
    {
        NSData *data = [NSData dataWithContentsOfURL:filePath];
        if (data)
        {
            NSError *error;
            dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error == nil)
            {
                NSLog(@"SUCCESS config.txt's data convert to dictionary.");
                return dict;
            }
            else
            {
                NSLog(@"ERROR config.txt's data could not converts to dictionary");
            }
        }
        else
        {
            NSLog(@"ERROR read config.txt failed.");
        }
    }
    else
    {
        NSLog(@"WARNING config.txt not exists!");
    }
    return dict;
}

+ (void)saveJsonConfigToDocument:(NSMutableDictionary *)config
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:config options:0 error:&error];
    
    if (jsonData && error == nil)
    {
        NSString *documentPath = [[self applicationDocumentsDirectory] path];
        NSString *savePath = [documentPath stringByAppendingPathComponent:@"config.txt"];
        [jsonData writeToFile:savePath atomically:YES];
    }
    else
    {
        NSLog(@"dataWithJSONObject failed, error: %@", error);
    }
}

+ (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSString *)md5:(NSString *)input
{
    const char *cStr = [input UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (int)strlen(cStr), digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

@end
