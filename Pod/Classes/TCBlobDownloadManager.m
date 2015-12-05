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
    if (self = [super init]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnteredBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEntereForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        self.state = kDownloadManagerStateForeground;
        self.startImmediatly = YES;
        self.delegate = [[DownloadDelegate alloc] init];
        
        NSURLSessionConfiguration *foregroundConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        foregroundConfiguration.HTTPMaximumConnectionsPerHost = 40;
        self.foregroundSession = [NSURLSession sessionWithConfiguration:foregroundConfiguration delegate:self.delegate delegateQueue:nil];
        self.foregroundSession.sessionDescription = @"TCBlobDownloadManger Foreground session";
        
        NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kTCBlobDownloadBackgroundSessionIdentifier];
        backgroundConfiguration.HTTPMaximumConnectionsPerHost = 40;
        
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self.delegate delegateQueue:nil];
        self.backgroundSession.sessionDescription = @"TCBlobDownloadManger Background session";
    }
    return self;
}

-(NSURLSession *)activeSession {
    return self.state == kDownloadManagerStateForeground ? self.foregroundSession : self.backgroundSession;
}

-(void)applicationEnteredBackground:(NSNotification *)notification {
    [self switchToBackground];
}

- (void)switchToBackground {
    if (self.state == kDownloadManagerStateForeground) {
        [self.foregroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                TCBlobDownload *download = self.delegate.downloads[@(downloadTask.taskIdentifier)];
                [downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                    NSLog(@"%s: %@", __func__, self.delegate.downloads);
                    [self.delegate.downloads removeObjectForKey:@(downloadTask.taskIdentifier)];
                    NSURLSessionDownloadTask *newDownloadTask = [self.backgroundSession downloadTaskWithResumeData:resumeData];
                    download.downloadTask = newDownloadTask;
                    self.delegate.downloads[@(newDownloadTask.taskIdentifier)] = download;
                    [newDownloadTask resume];
                }];
            }
        }];
        
        self.state = kDownloadManagerStateBackground;
    }
}

-(void)applicationWillEntereForeground:(NSNotification *)notification {
    [self switchToForeground];
}

- (void)switchToForeground {
    if (self.state == kDownloadManagerStateBackground) {
        [self.backgroundSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
            for (NSURLSessionDownloadTask *downloadTask in downloadTasks) {
                TCBlobDownload *download = self.delegate.downloads[@(downloadTask.taskIdentifier)];
                [downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
                    NSLog(@"%s: %@", __func__, self.delegate.downloads);
                    [self.delegate.downloads removeObjectForKey:@(downloadTask.taskIdentifier)];
                    NSURLSessionDownloadTask *newDownloadTask = [self.foregroundSession downloadTaskWithResumeData:resumeData];
                    download.downloadTask = newDownloadTask;
                    self.delegate.downloads[@(newDownloadTask.taskIdentifier)] = download;
                    [newDownloadTask resume];
                }];
            }
        }];
        self.state = kDownloadManagerStateForeground;
    }
}

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate {
    NSURLSessionDownloadTask *downloadTask = [self.activeSession downloadTaskWithURL:url];
    TCBlobDownload *download = [[TCBlobDownload alloc] initWithTask:downloadTask toDirectory:directory fileName:name delegate:delegate];
    return [self downloadWithDownload:download];
}

-(TCBlobDownload *)downloadFileAtURL:(NSURL *)url toDirectory:(NSURL *)directory withName:(NSString *)name progress:(TCBlobDownloadProgressHandler)progressHandler completion:(TCBlobDownloadCompletionHandler)completionHandler {
    NSURLSessionDownloadTask *downloadTask = [self.activeSession downloadTaskWithURL:url];
    TCBlobDownload *download = [[TCBlobDownload alloc] initWithTask:downloadTask toDirectory:directory fileName:name progress:progressHandler completion:completionHandler];
    return [self downloadWithDownload:download];
}

-(TCBlobDownload *)downloadFileWithResumeData:(NSData *)resumeData toDirectory:(NSURL *)directory withName:(NSString *)name andDelegate:(id <TCBlobDownloadDelegate>)delegate {
    NSURLSessionDownloadTask *downloadTask = [self.activeSession downloadTaskWithResumeData:resumeData];
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

-(instancetype)init {
    if (self = [super init]) {
        self.downloads = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(BOOL)validateResponse:(NSHTTPURLResponse *)response {
    return response.statusCode >= 200 && response.statusCode <= 299;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location; {
    TCBlobDownload *download = self.downloads[@(downloadTask.taskIdentifier)];
    NSLog(@"download: %@", download);
    
    NSError *fileError;
    NSURL *resultingURL;
    
    
    BOOL result = [[NSFileManager defaultManager] replaceItemAtURL:download.destinationURL withItemAtURL:location backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingURL error:&fileError];
    if (result) {
        download.resultingURL = resultingURL;
    } else {
        download.error = fileError;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSLog(@"%s: downloadTask: %@ downloads: %@",__func__, downloadTask, self.downloads);
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
    NSLog(@"%s: downloadTask: %@ downloads: %@",__func__, downloadTask, self.downloads);
    NSLog(@"Resume at offset: %lld total expected: %lld", fileOffset, expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)sessionError {
    NSLog(@"%s: downloadTask: %@ error: %@ downloads: %@",__func__, task, sessionError, self.downloads);
    
    TCBlobDownload *download = self.downloads[@(task.taskIdentifier)];
    if (![task isEqual:download.downloadTask]) {
        return;
    }
    
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
