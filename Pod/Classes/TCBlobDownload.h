//
//  TCBlobDownload.h
//  Pods
//
//  Created by Enea Gjoka on 12/4/15.
//
//

#import <Foundation/Foundation.h>

@class TCBlobDownload;

@protocol TCBlobDownloadDelegate <NSObject>

/**
 Periodically informs the delegate that a chunk of data has been received (similar to `NSURLSession -URLSession:dataTask:didReceiveData:`).
 
 :see: `NSURLSession -URLSession:dataTask:didReceiveData:`
 
 :param: download The download that received a chunk of data.
 :param: progress The current progress of the download, between 0 and 1. 0 means nothing was received and 1 means the download is completed.
 :param: totalBytesWritten The total number of bytes the download has currently written to the disk.
 :param: totalBytesExpectedToWrite The total number of bytes the download will write to the disk once completed.
 */
-(void)download:(TCBlobDownload *)download didProgress:(double)progress withSpeed:(double)speedRate remainingTime:(double)remainingTime totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

/**
 Informs the delegate that the download was completed (similar to `NSURLSession -URLSession:task:didCompleteWithError:`).
 
 :see: `NSURLSession -URLSession:task:didCompleteWithError:`
 
 :param: download The download that received a chunk of data.
 :param: error An eventual error. If `nil`, consider the download as being successful.
 :param: location The location where the downloaded file can be found.
 */
-(void)download:(TCBlobDownload *)download didFinishWithError:(NSError *)error atLocation:(NSURL *)location;
@end

typedef void (^TCBlobDownloadProgressHandler)(double progress, double speedRate, double remainingTime, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite);
typedef void (^TCBlobDownloadCompletionHandler)(NSError *error, NSURL *location);

@interface TCBlobDownload : NSObject
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, weak) id <TCBlobDownloadDelegate> delegate;

@property (nonatomic, copy) TCBlobDownloadProgressHandler progressHandler;
@property (nonatomic, copy) TCBlobDownloadCompletionHandler completionHandler;

@property (nonatomic, copy) NSString *preferedFileName;

@property (nonatomic, strong) NSURL *resultingURL;
@property (nonatomic, strong) NSURL *directory;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double speedRate;
@property (nonatomic, assign) double remainingTime;

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSURL *destinationURL;

@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, copy) NSString *uniqueFileId;
@property (nonatomic, assign) NSURLSessionTaskState state;

/**
 Initialize a new download assuming the `NSURLSessionDownloadTask` was already created.
 
 :param: downloadTask The underlying download task for this download.
 :param: directory The directory where to move the downloaded file once completed.
 :param: fileName The preferred file name once the download is completed.
 :param: delegate An optional delegate for this download.
 */
-(instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask toDirectory:(NSURL *)directory fileName:(NSString *)fileName delegate:(id <TCBlobDownloadDelegate>)delegate;
-(instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask toDirectory:(NSURL *)directory fileName:(NSString *)fileName progress:(TCBlobDownloadProgressHandler)progressHandler completion:(TCBlobDownloadCompletionHandler)completionHandler;

/**
 Cancel a download. The download cannot be resumed after calling this method.
 
 :see: `NSURLSessionDownloadTask -cancel`
 */

-(void)cancel;

/**
 Suspend a download. The download can be resumed after calling this method.
 
 :see: `TCBlobDownload -resume`
 :see: `NSURLSessionDownloadTask -suspend`
 */
-(void)suspend;

/**
 Resume a previously suspended download. Can also start a download if not already downloading.
 
 :see: `NSURLSessionDownloadTask -resume`
 */
-(void)resume;

/**
 Cancel a download and produce resume data. If stored, this data can allow resuming the download at its previous state.
 :see: `TCBlobDownloadManager -downloadFileWithResumeData`
 :see: `NSURLSessionDownloadTask -cancelByProducingResumeData`
 :param: completionHandler A completion handler that is called when the download has been successfully canceled. If the download is resumable, the completion handler is provided with a resumeData object.
 */
-(void)cancelWithResumeData:(void (^)(NSData *data))completion;

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
@end
