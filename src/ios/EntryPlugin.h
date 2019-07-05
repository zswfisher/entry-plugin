//
//  EntryPlugin.h
//  CordovaApp
//
//  Created by zsw on 12/3/2019.
//

#import <Cordova/CDV.h>

typedef enum{
    MAPluginResultStatus_OK,
    MAPluginResultStatus_ERROR
}MAPluginResultStatus;

/**
 *  h5调用原生 回调对象
 */
typedef struct MAPluginBlock
{
    __unsafe_unretained id blockParam;//回调参数
    MAPluginResultStatus resultStatus;//状态
}MAPluginBlock;

typedef void (^PluginResultBlock)(struct MAPluginBlock pluginBlock);

@interface NSObject(MAPluginObject)

@property (nonatomic) PluginResultBlock ma_PluginBlock;
@property (nonatomic) UIViewController *currentController;
MAPluginBlock newMAPluginBlock(id blockParam,MAPluginResultStatus resultStatus);

@end

@interface EntryPlugin : CDVPlugin

- (void)jsCallNative:(CDVInvokedUrlCommand *)command;

@end
