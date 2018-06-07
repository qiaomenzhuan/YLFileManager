//
//  YLFileManager.h
//  SportChina
//
//  Created by 杨磊 on 2018/6/5.
//  Copyright © 2018年 Beijing Sino Dance Culture Media Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^stringBlock)(NSString *result);
typedef void(^voidBlock)(void);

//文件管理
@interface YLFileManager : NSObject

@property (nonatomic,  copy) NSString       *fid;//报名id 是唯一的

/**
 写文件
 @param success 完成回调
 */
- (void)exportFile:(stringBlock)success;

/**
 下载CSV文件
 
 @param url 下载网址
 @param success 解析到的文件内容
 */
- (void)downloadFile:(NSString *)url suc:(stringBlock)success;

/**
 删除所有的file
 */
- (void)deleteAllFile;

@end
