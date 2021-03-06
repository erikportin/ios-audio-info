/********* iOSAudioInfo.m Cordova Plugin Implementation *******/

#import "iOSAudioInfo.h"
#import <AVFoundation/AVFoundation.h>

@implementation iOSAudioInfo

- (void) getTracks:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        MPMediaLibraryAuthorizationStatus authorizationStatus = MPMediaLibrary.authorizationStatus;
        
        if(authorizationStatus == MPMediaLibraryAuthorizationStatusDenied){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION messageAsString:@"MPMediaLibraryAuthorizationStatusDenied"];
        }
        else{
            MPMediaQuery *everything = [[MPMediaQuery alloc] init];
            [everything addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
            
            NSArray *itemsFromGenericQuery = [everything items];
            songsList = [[NSMutableArray alloc] init];
            
            for(MPMediaItem *song in itemsFromGenericQuery){
                [songsList addObject:[self buildInfo:song:NO:NO]];
            }
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:songsList];
        }
        
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}
- (void) getTrack:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        MPMediaLibraryAuthorizationStatus authorizationStatus = MPMediaLibrary.authorizationStatus;
        if(authorizationStatus == MPMediaLibraryAuthorizationStatusDenied){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION messageAsString:@"MPMediaLibraryAuthorizationStatusDenied"];
        }
        else{
            NSString * persistentID =[command argumentAtIndex : 0];
            
            if(persistentID == nil){
                pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_ERROR messageAsString :@"No ID found"];
            } else {
                MPMediaItem * song;
                MPMediaPropertyPredicate * predicate;
                MPMediaQuery * songQuery;
                
                predicate =[MPMediaPropertyPredicate predicateWithValue : persistentID forProperty : MPMediaItemPropertyPersistentID];
                songQuery =[[MPMediaQuery alloc] init];
                [songQuery addFilterPredicate : predicate];
                
                if (songQuery.items.count > 0){
                    song =[songQuery.items objectAtIndex : 0];
                    pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_OK messageAsDictionary :[self buildInfo : song : YES : NO]];
                } else {
                    pluginResult =[CDVPluginResult resultWithStatus : CDVCommandStatus_ERROR messageAsString :@"track not found"];
                }
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) getAlbum:(CDVInvokedUrlCommand *)command
{
    [self.commandDelegate runInBackground:^{
        MPMediaLibraryAuthorizationStatus authorizationStatus = MPMediaLibrary.authorizationStatus;
        if(authorizationStatus == MPMediaLibraryAuthorizationStatusDenied){
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION messageAsString:@"MPMediaLibraryAuthorizationStatusDenied"];
        }
        else{
            NSString *persistentAlbumID = [command argumentAtIndex:0];
            if(persistentAlbumID == nil){
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No ID found"];
            } else {
                MPMediaItem *album;
                MPMediaPropertyPredicate *predicate;
                MPMediaQuery *albumQuery;
                
                predicate = [MPMediaPropertyPredicate predicateWithValue: persistentAlbumID forProperty:MPMediaItemPropertyAlbumPersistentID];
                albumQuery = [[MPMediaQuery alloc] init];
                [albumQuery addFilterPredicate: predicate];
                
                if (albumQuery.items.count > 0){
                    album = [albumQuery.items objectAtIndex:0];
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self buildInfo:album:YES:YES]];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"album not found"];
                }
            }
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

//https://developer.apple.com/library/ios/documentation/MediaPlayer/Reference/MPMediaItem_ClassReference/index.html#//apple_ref/doc/constant_group/General_Media_Item_Property_Keys
- (NSMutableDictionary *)buildInfo :(MPMediaItem*)song :(BOOL)addImage :(BOOL)isAlbum
{
    NSString *title = [song valueForProperty:MPMediaItemPropertyTitle];
    NSString *albumTitle = [song valueForProperty:MPMediaItemPropertyAlbumTitle];
    NSString *artist = [song valueForProperty:MPMediaItemPropertyArtist];
    NSString *albumArtist = [song valueForProperty:MPMediaItemPropertyAlbumArtist];
    NSString *genre = [song valueForProperty:MPMediaItemPropertyGenre];
    NSString *persistentID = [song valueForProperty:MPMediaItemPropertyPersistentID];
    NSString *albumPersistentID = [song valueForProperty:MPMediaItemPropertyAlbumPersistentID];
    NSString *playCount = [song valueForProperty:MPMediaItemPropertyPlayCount];
    NSString *rating = [song valueForProperty:MPMediaItemPropertyRating];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    
    if(title != nil && !isAlbum) {
        [info setObject:title forKey:@"title"];
    }
    if(albumTitle != nil) {
        [info setObject:albumTitle forKey:@"albumTitle"];
    }
    if(artist !=nil) {
        [info setObject:artist forKey:@"artist"];
    }
    if(albumArtist !=nil && isAlbum) {
        [info setObject:albumArtist forKey:@"albumArtist"];
    }
    if(genre !=nil) {
        [info setObject:genre forKey:@"genre"];
    }
    if(persistentID !=nil && !isAlbum) {
        [info setObject:[NSString stringWithFormat:@"%@", persistentID] forKey:@"persistentID"];
    }
    if(albumPersistentID !=nil) {
        [info setObject:[NSString stringWithFormat:@"%@", albumPersistentID] forKey:@"albumPersistentID"];
    }
    if(playCount !=nil) {
        [info setObject:[NSNumber numberWithInteger: [playCount intValue]] forKey:@"playCount"];
    }
    if(rating !=nil) {
        [info setObject:[NSNumber numberWithInteger: [rating intValue]] forKey:@"rating"];
    } else {
        [info setObject:[NSNumber numberWithInteger: -1] forKey:@"rating"];
    }
    
    if(addImage){
        BOOL artImageFound = NO;
        NSData *imgData;
        MPMediaItemArtwork *artImage = [song valueForProperty:MPMediaItemPropertyArtwork];
        UIImage *artworkImage = [artImage imageWithSize:CGSizeMake(artImage.bounds.size.width, artImage.bounds.size.height)];
        if(artworkImage != nil){
            imgData = UIImagePNGRepresentation(artworkImage);
            artImageFound = YES;
        }
        if (artImageFound) {
            [info setObject:[imgData base64EncodedStringWithOptions:0] forKey:@"image"];
        }
    }
    
    return info;
}

@end
