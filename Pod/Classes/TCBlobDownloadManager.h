//
//  TCBlobDownloadManager.h
//  Pods
//
//  Created by Enea Gjoka on 12/4/15.
//
//

#import <Foundation/Foundation.h>
#import "TCBlobDownload.h"

const NSString *kTCBlobDownloadSessionIdentifier = @"tcblobdownloadmanager_downloads";
const NSString *kTCBlobDownloadErrorDomain = @"com.tcblobdownloadswift.error";
const NSString *kTCBlobDownloadErrorDescriptionKey = @"TCBlobDownloadErrorDescriptionKey";
const NSString *kTCBlobDownloadErrorHTTPStatusKey = @"TCBlobDownloadErrorHTTPStatusKey";
const NSString *kTCBlobDownloadErrorFailingURLKey = @"TCBlobDownloadFailingURLKey";

typedef enum {
    TCBlobDownloadHTTPError = 1
} TCBlobDownloadError;

@interface DownloadDelegate : NSObject <NSURLSessionDownloadDelegate>
@property (nonatomic, strong) NSMutableArray *downloads;
@end

@interface TCBlobDownloadManager : NSObject

@property (nonatomic, strong) DownloadDelegate *delegate;
@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, assign) BOOL startImmediatly;

/**
 Custom `NSURLSessionConfiguration` init.
 :param: config The configuration used to manage the underlying session.
 */
-(instancetype)initWithConfig:(NSURLSessionConfiguration *)config;

/**
 Start downloading the file at the given URL.
 
 :param: url NSURL of the file to download.
 :param: directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
 :param: name Name to give to the file once the download is completed.
 :param: delegate An eventual delegate for this download.
 :return: A `TCBlobDownload` instance.
 */

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate;

/**
 Start downloading the file at the given URL.
 :param: url NSURL of the file to download.
 :param: directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
 :param: name Name to give to the file once the download is completed.
 :param: progression A closure executed periodically when a chunk of data is received.
 :param: completion A closure executed when the download has been completed.
 :return: A `TCBlobDownload` instance.
 */

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name progress:(TCBlobDownloadProgressHandler)progressHandler completion:(TCBlobDownloadCompletionHandler)completionHandler;

/**
 Resume a download with previously acquired resume data.
 
 :see: `TCBlobDownload -cancelWithResumeData:` to produce this data.
 :param: resumeData Data blob produced by a previous download cancellation.
 :param: directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
 :param: name Name to give to the file once the download is completed.
 :param: delegate An eventual delegate for this download.
 
 :return: A `TCBlobDownload` instance.
 */
-(TCBlobDownload *)downloadFileWithResumeData:(NSData *)resumeData toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate;
@end
