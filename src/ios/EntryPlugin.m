//
//  EntryPlugin.m
//  CordovaApp
//
//  Created by zsw on 12/3/2019.
//

#import "EntryPlugin.h"
#import <objc/runtime.h>

static NSString *ProtocolType = @"ProtocolType";//协议类型
static NSString *ProtocolClassName = @"ProtocolClassName";//类名
static NSString *ProtocolMethodId = @"ProtocolMethodId";//方法ID
static NSString *ProtocolMethodName = @"ProtocolMethodName";//方法名
static NSString *ProtocolParameter = @"ProtocolParameter";//参数

#pragma - Class MAResolveProtocol

@interface MAResolveProtocol : NSObject

/**
 *  解析协议
 *  hybrid://WXPage:23900610/setFullScreen?{"fullScreen":false,"style":2}
 *  @param protocol 协议内容
 */
+ (NSDictionary *)parseProtocol:(NSString *)protocol;

@end

@implementation MAResolveProtocol

/**
 *  解析协议
 *  hybrid://WXPage:23900610/setFullScreen?{"fullScreen":false,"style":2}
 *  @param protocol 协议内容
 */
+ (NSDictionary *)parseProtocol:(NSString *)protocol{
    
    NSString *parameter = nil;
    NSString *postUrl = protocol;
    
    NSRange parameterRange = [protocol rangeOfString:@"?" options:NSForcedOrderingSearch];
    if (parameterRange.length != 0) {
        parameter = [protocol substringFromIndex:parameterRange.location+parameterRange.length];
        postUrl = [protocol substringToIndex:parameterRange.location];;
    }
    
    NSString *methodAction = postUrl.lastPathComponent;//获取事件
    
    NSRange range = [postUrl rangeOfString:methodAction];
    
    NSString *mainProtocol = [postUrl substringToIndex:range.location-1];
    
    NSString *protocolType,*name,*protocolId;
    if ([mainProtocol hasPrefix:@"hybrid://"]) {//hybrid协议
        protocolType = @"hybrid";
        NSRange range = [mainProtocol rangeOfString:@"hybrid://"];
        NSString *protocolFlag = [mainProtocol substringFromIndex:range.location+range.length];
        range = [protocolFlag rangeOfString:@":"];
        name = [protocolFlag substringToIndex:range.location];
        protocolId = [protocolFlag substringFromIndex:range.location+range.length];
    }
    
//    NSLog(@"name = %@ , protocolId = %@ , methodAction = %@ , parameter = %@",name,protocolId,methodAction,parameter);
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    dic[ProtocolType] = protocolType;
    dic[ProtocolClassName] = notNull(name);
    dic[ProtocolMethodId] = notNull(protocolId);
    dic[ProtocolMethodName] = notNull(methodAction);
    
    //参数
    id para = notNull(dictionaryWithJsonString(parameter));
    if ([para isKindOfClass:[NSString class]] && [para isEqualToString:@""]) {
        dic[ProtocolParameter] = parameter;
    }else{
        dic[ProtocolParameter] = para;
    }
    
    return dic;
}
/*!
 * @brief 把格式化的JSON格式的字符串转换成字典
 * @param jsonString JSON格式的字符串
 * @return 返回字典
 */
NSDictionary *dictionaryWithJsonString(NSString *jsonString) {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
    
}
/**
 *  不能为空
 *  @param object 对象
 */
NSString *notNull(id object){
    if ([object isKindOfClass:[NSString class]]) {
        return !isNull(object)?object:@"";
    }else{
        if (!object) return @"";
    }
    return object;
}
/**
 *  判断是否为空
 *  @param object 对象
 */
BOOL isNull(id object){
    if ([object isKindOfClass:[NSString class]]) {
        if (!object || [object isEqualToString:@""]) {
            return YES;
        }
    } else {
        if (!object) return YES;
    }
    
    return NO;
}

@end

#pragma - Class NSObject(MAPluginObject)

static const void *pluginBlock = &pluginBlock;
static const void *currentCtrl = &currentCtrl;
@implementation NSObject(MAPluginObject)

@dynamic ma_PluginBlock;
@dynamic currentController;

- (void)setMa_PluginBlock:(PluginResultBlock)block{
    objc_setAssociatedObject(self, pluginBlock, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (PluginResultBlock)ma_PluginBlock{
    return objc_getAssociatedObject(self, pluginBlock);
}
-(void)setCurrentController:(UIViewController *)vc{
    objc_setAssociatedObject(self, currentCtrl, vc, OBJC_ASSOCIATION_ASSIGN);
}
-(UIViewController *)currentController{
    return objc_getAssociatedObject(self, currentCtrl);
}
MAPluginBlock newMAPluginBlock(id blockParam,MAPluginResultStatus resultStatus){
    MAPluginBlock pluginBlock;
    memset(&pluginBlock, 0, sizeof(MAPluginBlock));
    pluginBlock.blockParam = blockParam;
    pluginBlock.resultStatus = resultStatus;
    return pluginBlock;
}


@end

#pragma - Class MAReflection

@interface MAReflection : NSObject
@property (strong, nonatomic) id boModel;
@end

@implementation MAReflection

#define PropertyKey @"pluginResultBlock"

/**
 *  反射对象调用方法
 *
 *  @param className   类名
 *  @param methodName  方法名
 *  @param paramter    方法参数
 *  @param resultBlock 回调
 */
void ma_invoke(NSString *className,NSString *methodName,NSDictionary *paramter, UIViewController *ctrl ,PluginResultBlock resultBlock){
    @autoreleasepool {
        NSObject *object = [[NSClassFromString(className) alloc] init];
        if (!isNull(paramter)) {
            methodName = [methodName stringByAppendingString:@":"];
        }
        
        if ([object respondsToSelector:NSSelectorFromString(methodName)]) {
            //动态添加属性
            object.ma_PluginBlock = resultBlock;
            object.currentController = ctrl;
            
            NSArray *params = isNull(paramter)?nil:@[paramter];
            invokeSelector(object, NSSelectorFromString(methodName), params);
        } else {
            
            MAPluginBlock pluginBlock = newMAPluginBlock(nil, MAPluginResultStatus_ERROR);
            resultBlock(pluginBlock);
        }
    }
}
void invokeSelector(id object, SEL selector, NSArray *arguments)
{
    NSMethodSignature *signature = [object methodSignatureForSelector:selector];
    
    if (signature.numberOfArguments == 0) {
        return; //@selector未找到
    }
    if (signature.numberOfArguments > [arguments count]+2) {
        return; //传入arguments参数不足。signature至少有两个参数，self和_cmd
    }
    //    id returnObject = nil;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:object];
    [invocation setSelector:selector];
    
    for(int i=0; i<[arguments count]; i++)
    {
        id arg = [arguments objectAtIndex:i];
        [invocation setArgument:&arg atIndex:i+2]; // The first two arguments are the hidden arguments self and _cmd
    }
    
    [invocation invoke]; // Invoke the selector
}
@end

#pragma - Class MAReflection

@implementation EntryPlugin

- (void)jsCallNative:(CDVInvokedUrlCommand *)command{
    __weak EntryPlugin *weakSelf = self;
    
    NSString *hybridStr = command.arguments.firstObject;
    if (isNull(hybridStr)) {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数为空！"];
        return [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    
    NSDictionary *paramDic = [MAResolveProtocol parseProtocol:hybridStr];
    
    ma_invoke(paramDic[ProtocolClassName], paramDic[ProtocolMethodName], paramDic[ProtocolParameter], self.viewController, ^(struct MAPluginBlock pluginBlock) {
        CDVPluginResult * pluginResult;
        if (pluginBlock.resultStatus == MAPluginResultStatus_OK) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:pluginBlock.blockParam];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:pluginBlock.blockParam];
        }
        
        [weakSelf.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

@end
