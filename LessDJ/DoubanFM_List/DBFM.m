//
//  DBFM.m
//  LessDJ
//
//  Created by xu xhan on 11/7/11.
//  Copyright (c) 2011 xu han. All rights reserved.
//

#import "DBFM.h"
#import "DBList.h"

#import "JSON.h"
#import "PLHttpBlock.h"
@implementation DBFM
@synthesize list = _list, channels = _channels, currentChannel= _currentChannel;
@synthesize delegate = _delegate;

- (id)init{
    self = [super init];
    _channels = [[NSMutableArray alloc] init];
    _history  = [[NSMutableArray alloc] init];
    _list     = [[DBList alloc] init];
    [_list setFM:self];
    return self;
}

- (void)dealloc
{
    PLSafeRelease(_history);
    PLSafeRelease(_channels);
    PLCleanRelease(_clientList);
    PLSafeRelease(_list);
    [super dealloc];
}

- (void)reloadList
{
    if (!_clientList) {
        _clientList = [[PLHttpBlock alloc] init];
    }
    [_clientList get:URL(@"http://www.douban.com/j/app/radio/channels")
                  ok:^(NSDictionary*d){
                      [self _updateList:d];
                      [_delegate dbfmResponseReceived:DBResponseTypeChannel state:([_channels count] >0)];
                  }
                fail:^(NSError*e){
//                    NSLog(@"e on list %@",e);
                    [_delegate dbfmResponseReceived:DBResponseTypeChannel state:NO];
                }];
}

- (void)_updateList:(NSDictionary*)dict
{
    
    NSArray* chns = PLHashV(dict, @"channels");
    if ([chns isKindOfClass:NSArray.class] && [chns count]) {
        
        [self willChangeValueForKey:@"channels"];
        [_channels removeAllObjects];        
        for (NSDictionary* item in chns) {            
            DBChannel* channel = [[DBChannel alloc] initWithDict:item];
            
            // skip personal channel
            if (channel.mid != 0) {
                [_channels addObject:channel];
            }
            
            [channel release];
        }
        [self didChangeValueForKey:@"channels"];
//        NSLog(@"get channels %lu",[_channels count]);
    }
}

- (void)setChannelAtIndex:(int)index
{    
    _currentChannel = [_channels objectAtIndex:index];
    [_list updateWithChannelItem:_currentChannel];
}
@end


#define ApiEngineError @"com.xhan.error"
@implementation DBFM (APIService)
+ (NSDictionary*)parseContent:(NSString*)responseContent withError:(NSError**)error
{
    int errorNO ;
    BOOL isDict;
    NSDictionary* dict = [responseContent JSONValue];
    isDict = dict && [dict isKindOfClass:NSDictionary.class];
    if (isDict) {
        // errorNO = [PLHashV(dict, @"err") intValue];
        errorNO = 0;
    }else{
        errorNO = 1;
    }
    
    if (isDict && errorNO == 0) {
        *error = nil;
        return dict;
    }else{
//        NSString* errorMSG = [self descriptionForErrorCode:errorNO];
        NSString* errorMSG = @"内容解析错误";
        *error = [NSError errorWithDomain:ApiEngineError
                                     code:errorNO
                                 userInfo:PLDict(errorMSG,NSLocalizedDescriptionKey)];
//        if (errorNO == ApiEngineErrorUserAuthFail) {
//            [[SecretAppDelegate sharedDelegate] userAuthFailed];
//        }
        
        return nil;
    }
}
@end