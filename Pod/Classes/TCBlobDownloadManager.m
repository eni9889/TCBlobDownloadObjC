//
//  TCBlobDownloadManager.m
//  Pods
//
//  Created by Enea Gjoka on 12/4/15.
//
//

#import "TCBlobDownloadManager.h"

@implementation TCBlobDownloadManager

-(instancetype)init {
    return [self initWithConfig:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

-(instancetype)initWithConfig:(NSURLSessionConfiguration *)config {
    if (self = [super init]) {
        self.delegate = [[DownloadDelegate alloc] init];
        self.session = [NSURLSession sessionWithConfiguration:config delegate:self.delegate delegateQueue:nil];
        self.session.sessionDescription = @"TCBlobDownloadManger session";
    }
    return self;
}

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    TCBlobDownload *download = [[TCBlobDownload alloc] initWithTask:downloadTask toDirectory:directory fileName:name delegate:delegate];
    return [self downloadWithDownload:download];
}

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name progress:(TCBlobDownloadProgressHandler)progressHandler completion:(TCBlobDownloadCompletionHandler)completionHandler {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url];
    TCBlobDownload *download = [[TCBlobDownload alloc] initWithTask:downloadTask toDirectory:directory fileName:name progress:progressHandler completion:completionHandler];
    return [self downloadWithDownload:download];
}

-(TCBlobDownload *)downloadFileWithResumeData:(NSData *)resumeData toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithResumeData:resumeData];
    TCBlobDownload *download = [[TCBlobDownload alloc] initWithTask:downloadTask toDirectory:directory fileName:name delegate:delegate];
    return [self downloadWithDownload:download];
}

-(NSMutableArray *)currentDownloadsFilteredByState:(NSURLSessionTaskState)state {
    NSMutableArray *downloads = [@[] mutableCopy];
    for (TCBlobDownload *download in self.delegate.downloads.allValues) {
        if (download.downloadTask.state == state) {
            [downloads addObject:download];
        }
    }
    return downloads;
}

/**
 Base method to start a download, called by other download methods.
 
 :param: download Download to start.
 */
-(TCBlobDownload *)downloadWithDownload:(TCBlobDownload *)download {
    self.delegate.downloads[@(download.downloadTask.taskIdentifier)] = download;
    if (self.startImmediatly) {
        [download.downloadTask resume];
    }
    return download;
}

@end

@implementation DownloadDelegate
-(BOOL)validateResponse:(NSHTTPURLResponse *)response {
    return response.statusCode >= 200 && response.statusCode <= 299;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location; {
    TCBlobDownload *download = self.downloads[@(downloadTask.taskIdentifier)];
    NSError *fileError;
    NSURL *resultingURL;
    if ([[NSFileManager defaultManager] replaceItemAtURL:download.destinationURL withItemAtURL:location backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingURL error:&fileError]) {
        download.resultingURL = resultingURL;
    } else {
        download.error = fileError;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    TCBlobDownload *download = self.downloads[@(downloadTask.taskIdentifier)];
    double progress = (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) ? -1 : (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    download.progress = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (download.delegate) {
            [download.delegate download:download didProgress:progress totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
        
        if (download.progressHandler) {
            download.progressHandler(progress, totalBytesWritten, totalBytesExpectedToWrite);
        }
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    NSLog(@"Resume at offset: %lld total expected: %lld", fileOffset, expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)sessionError {
    TCBlobDownload *download = self.downloads[@(task.taskIdentifier)];
    NSError *error = sessionError ? sessionError : download.error;
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    if (![self validateResponse:response] && (error == nil || error.domain == NSURLErrorDomain)) {
        NSMutableDictionary *userInfo = [@{} mutableCopy];
        
        userInfo[kTCBlobDownloadErrorDescriptionKey] = [NSString stringWithFormat:@"Erroneous HTTP status code: %ld", (long)response.statusCode];
        userInfo[kTCBlobDownloadErrorHTTPStatusKey] = @(response.statusCode);
        if (task.originalRequest.URL) {
            userInfo[kTCBlobDownloadErrorFailingURLKey] = task.originalRequest.URL;
        }
        
        error = [NSError errorWithDomain:kTCBlobDownloadErrorDomain
                                    code:TCBlobDownloadHTTPError
                                userInfo:userInfo];
    }
    
    [self.downloads removeObjectForKey:@(task.taskIdentifier)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (download.delegate) {
            [download.delegate download:download didFinishWithError:error atLocation:download.resultingURL];
        }
        if (download.completionHandler) {
            download.completionHandler(error, download.resultingURL);
        }
    });
}
@end
