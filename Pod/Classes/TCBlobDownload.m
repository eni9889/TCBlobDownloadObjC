//
//  TCBlobDownload.m
//  Pods
//
//  Created by Enea Gjoka on 12/4/15.
//
//

#import "TCBlobDownload.h"

@implementation TCBlobDownload

-(instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask toDirectory:(NSURL *)directory fileName:(NSString *)fileName delegate:(id<TCBlobDownloadDelegate>)delegate {
    if (self = [super init]) {
        self.downloadTask = downloadTask;
        self.directory = directory;
        self.preferedFileName = fileName;
        self.delegate = delegate;
    }
    return self;
}

-(instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask toDirectory:(NSURL *)directory fileName:(NSString *)fileName progress:(TCBlobDownloadProgressHandler)progressHandler completion:(TCBlobDownloadCompletionHandler)completionHandler {
    if (self = [self initWithTask:downloadTask toDirectory:directory fileName:fileName delegate:nil]) {
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
    }
    return self;
}

-(NSString *)fileName {
    return self.preferedFileName ? self.preferedFileName : self.downloadTask.response.suggestedFilename;
}

-(NSURL *)destinationURL {
    NSURL *destinationPath = self.directory ? self.directory : [NSURL fileURLWithPath:NSTemporaryDirectory()];
    return [[NSURL URLWithString:self.fileName relativeToURL:destinationPath] URLByStandardizingPath];
}

-(void)cancel {
    [self.downloadTask cancel];
}

-(void)suspend {
    [self.downloadTask suspend];
}

-(void)resume {
    [self.downloadTask resume];
}

-(void)cancelWithResumeData:(void (^)(NSData *))completion {
    [self.downloadTask cancelByProducingResumeData:completion];
}

-(NSString *)description {
    NSString *state = @"";
    switch (self.downloadTask.state) {
        case NSURLSessionTaskStateRunning:
            state = @"running";
            break;
        case NSURLSessionTaskStateCompleted:
            state = @"completed";
            break;
        case NSURLSessionTaskStateCanceling:
            state = @"canceling";
            break;
        case NSURLSessionTaskStateSuspended:
            state = @"suspended";
            break;
        default:
            state = @"unknown";
            break;
    }
    return [NSString stringWithFormat:@"TCBlobDownload URL: %@ Download task state: %@ destinationPath: %@ fileName: %@", self.downloadTask.originalRequest.URL, state, self.directory, self.fileName];
}
@end
