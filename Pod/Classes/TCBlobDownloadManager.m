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

/**
 Base method to start a download, called by other download methods.
 
 :param: download Download to start.
 */
-(TCBlobDownload *)downloadWithDownload:(TCBlobDownload *)download {
    self.delegate.downloads[download.downloadTask.taskIdentifier] = download;
    if (self.startImmediatly) {
        [download.downloadTask resume];
    }
    return download;
}

@end
