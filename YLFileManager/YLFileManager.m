//
//  YLFileManager.m
//  SportChina
//
//  Created by 杨磊 on 2018/6/5.
//  Copyright © 2018年 Beijing Sino Dance Culture Media Co.,Ltd. All rights reserved.
//

#import "YLFileManager.h"
#import <CommonCrypto/CommonDigest.h>
@implementation YLFileManager

/**
 删除所有的file
 */
- (void)deleteAllFile
{
    NSString *pathString = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    pathString = [NSString stringWithFormat:@"%@/LocationCsv",pathString];
    
    NSString *pathString2 = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    pathString2 = [NSString stringWithFormat:@"%@/DownlodCsv",pathString2];
    
    BOOL isExistLocal = [[NSFileManager defaultManager] fileExistsAtPath:pathString];
    if (isExistLocal)
    {
        NSFileManager* fileSystem = [NSFileManager defaultManager];
        if ([fileSystem removeItemAtPath:pathString error:nil]) {
            NSLog(@"本地轨迹file删除成功");
        }
        
    }
    
    BOOL isExistLocal2 = [[NSFileManager defaultManager] fileExistsAtPath:pathString2];
    if (isExistLocal2)
    {
        NSFileManager* fileSystem = [NSFileManager defaultManager];
        if ([fileSystem removeItemAtPath:pathString2 error:nil]) {
            NSLog(@"下载轨迹file删除成功");
        }
    }
}

/**
 下载CSV文件
 
 @param url 下载网址
 @param success 解析到的文件内容
 */
- (void)downloadFile:(NSString *)url suc:(stringBlock)success
{
    if ([self isNullOrNilWithObject:url])
    {//还没上传轨迹用本地的
        NSString* csvPath = [self findLocalPath];//文件路径
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:csvPath];
        if (isExist)
        {//本地存在 直接读取
            [self inputFile:csvPath suc:^(NSString *result) {
                success(result);
            }];
        }else
        {//本地也没有 返回空
            success(@"");
        }
        return;
    }
    
    //轨迹已经上传 删除本地写的
    NSString* csvPathLocal = [self findLocalPath];//文件路径
    BOOL isExistLocal = [[NSFileManager defaultManager] fileExistsAtPath:csvPathLocal];
    if (isExistLocal)
    {//删除CSV文件
        NSFileManager* fileSystem = [NSFileManager defaultManager];
        [fileSystem removeItemAtPath:csvPathLocal error:nil];
    }

    //下载后台返回的文件
    NSString* csvPath = [self findNetPath:url];//文件路径
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:csvPath];
    if (!isExist)
    {//本地不存在文件 下载
        dispatch_queue_t queue =dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
        dispatch_async(queue, ^{
            NSError *error = nil;
            NSString *strUrl = [NSString stringWithFormat:@"%@",url];
            strUrl = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *downUrl = [NSURL URLWithString:strUrl];
            NSData *data = [NSData dataWithContentsOfURL:downUrl options:0 error:&error];
            if(!error)
            {
                [data writeToFile:csvPath options:0 error:nil];//将下载的文件写到DownlodCsv文件夹下
                [self inputFile:csvPath suc:^(NSString *result) {
                    success(result);
                }];
            }
        });
    }else
    {//已经下载直接读取
        [self inputFile:csvPath suc:^(NSString *result) {
            success(result);
        }];
    }
}

/**
 读文件
 
 @param path 文件路径
 */
- (void)inputFile:(NSString *)path suc:(stringBlock)success
{
    NSError *error = nil;
    unsigned long encode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:encode error:&error];
    success(fileContents);
}

/**
 写文件
 @param success 完成回调
 */
- (void)exportFile:(stringBlock)success
{
    NSString* csvPath = [self findLocalPath];//文件路径
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //在子线程写文件
        [self exportCsv:csvPath success:^{
            success(csvPath);
        }];
    });
}


/**
 将数据取出 写入文件
 
 @param filename 文件路径
 @param success 完成回调
 
 */
-(void)exportCsv:(NSString*)filename success:(voidBlock)success
{
    [self createTempFile: filename];
    NSOutputStream* output = [[NSOutputStream alloc] initToFileAtPath: filename append: YES];
    [output open];
    if (![output hasSpaceAvailable])
    {
        NSLog(@"No space available in %@", filename);
    }else
    {
        NSInteger result = 0;
        for (int i = 0; i < 100; i++)
        {
            NSString *ctime             = [NSString stringWithFormat:@"%ld",arc4random()%10000000000];
            NSString *longitude         = [NSString stringWithFormat:@"%u",arc4random()%1000000000];
            NSString *latitude          = [NSString stringWithFormat:@"%u",arc4random()%100000000];
            NSString *elevation         = [NSString stringWithFormat:@"%u",arc4random()%10000000];
            NSString *distance          = [NSString stringWithFormat:@"%u",arc4random()%1000000];
            NSString *toprecosttime     = [NSString stringWithFormat:@"%u",arc4random()%100000];
            NSString *tostartcosttime   = [NSString stringWithFormat:@"%u",arc4random()%10000];
            NSString *speed             = [NSString stringWithFormat:@"%u",arc4random()%1000];

            NSString* line = [[NSString alloc]initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@\n",ctime, longitude, latitude, elevation,distance,toprecosttime,tostartcosttime,speed];
            if (i == 100 - 1)
            {
                line = [[NSString alloc]initWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@",ctime, longitude, latitude, elevation,distance,toprecosttime,tostartcosttime,speed];
            }
            uint8_t buffer[2048];
            memcpy(buffer, [line UTF8String], [line length]+1);
            result = [output write:buffer maxLength: [line length]];
        }
    }
    [output close];
    success();
}

/**
 将文件写入沙盒
 
 @param filename 文件路径
 */
- (void)createTempFile:(NSString*)filename
{
    NSFileManager* fileSystem = [NSFileManager defaultManager];
    [fileSystem removeItemAtPath: filename error: nil];
    
    NSMutableDictionary* attributes = [[NSMutableDictionary alloc] init];
    NSNumber* permission = [NSNumber numberWithLong: 0640];
    [attributes setObject: permission forKey: NSFilePosixPermissions];
    if (![fileSystem createFileAtPath: filename contents: nil attributes: attributes])
    {
        NSLog(@"Unable to create temp file for exporting CSV.");
    }
}

/**
 在沙盒的cache目录下创建一个文件夹
 
 @param name 文件夹名字
 @return 文件夹路径
 */
- (NSString *)creatFile:(NSString *)name
{
    NSString *pathString = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    pathString = [NSString stringWithFormat:@"%@/%@",pathString,name];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //创建盛放CSV文件的文件夹
    if (![fileManager fileExistsAtPath:pathString])
    {
        [fileManager createDirectoryAtPath:pathString withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return pathString;
}


/**
 生成本地写的文件的路径
 
 @return 沙盒路径
 */
- (NSString *)findLocalPath
{
    NSString* documentsDir = [self creatFile:@"LocationCsv"];//根据数据库本地生成CSV的文件夹
    NSString *name = [NSString stringWithFormat:@"location%@",self.fid];
    NSString *md5  = [self md5:name];
    NSString* csvPath = [NSString stringWithFormat:@"%@/%@.csv",documentsDir,md5];//文件路径
    NSLog(@"%@",csvPath);
    return csvPath;
}

/**
 生成下载的文件的路径
 
 @return 沙盒路径
 */
- (NSString *)findNetPath:(NSString *)url
{
    NSString* documentsDir = [self creatFile:@"DownlodCsv"];//下载CSV文件的文件夹
    NSString *md5  = [self md5:url];
    NSString* csvPath = [NSString stringWithFormat:@"%@/%@.csv",documentsDir,md5];//文件路径
    return csvPath;
}


/**
 判断是否为空

 @param object OC对象
 @return @YES 对象为空
 */
- (BOOL)isNullOrNilWithObject:(id)object;
{
    if (object == nil || [object isEqual:[NSNull null]]) {
        return YES;
    } else if ([object isKindOfClass:[NSString class]]) {
        if ([object isEqualToString:@""]||[object isEqualToString:@"(null)"]) {
            return YES;
        } else {
            return NO;
        }
    }
    else if ([object isKindOfClass:[NSNumber class]]) {
        if ([object isEqualToNumber:@0]) {
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}


/**
 md5加密

 @param str 要加密的字符串
 @return 加密后的串
 */
- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr,(CC_LONG)strlen(cStr), digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return  output;
}
@end
