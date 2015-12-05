//
//  TCBlobDownload.m
//  Pods
//
//  Created by Enea Gjoka on 12/4/15.
//
//

#import "TCBlobDownload.h"

static const NSInteger kNumberOfSamples = 5;

@interface TCBlobDownload ()
@property (nonatomic, strong) NSMutableArray *samplesOfDownloadedBytes;
@property (nonatomic, assign) uint64_t receivedDataLength;
@property (nonatomic, assign) uint64_t expectedDataLength;
@property (nonatomic, assign) NSTimeInterval lastSpeedUpdateTime;
@end

@implementation TCBlobDownload

-(instancetype)initWithTask:(NSURLSessionDownloadTask *)downloadTask toDirectory:(NSURL *)directory fileName:(NSString *)fileName delegate:(id<TCBlobDownloadDelegate>)delegate {
    if (self = [super init]) {
        self.lastSpeedUpdateTime = [[NSDate date] timeIntervalSince1970];
        self.downloadTask = downloadTask;
        self.directory = directory;
        self.preferedFileName = fileName;
        self.delegate = delegate;
        self.samplesOfDownloadedBytes = [@[] mutableCopy];
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

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    self.expectedDataLength = totalBytesExpectedToWrite;
    [self updateSpeedRateWithTotalBytesWritten:totalBytesWritten];
    
    double progress = (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) ? -1 : (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    self.progress = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate download:self didProgress:progress withSpeed:self.speedRate remainingTime:self.remainingTime totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
        
        if (self.progressHandler) {
            self.progressHandler(progress, self.speedRate, self.remainingTime, totalBytesWritten, totalBytesExpectedToWrite);
        }
    });
    
}

-(void)updateSpeedRateWithTotalBytesWritten:(int64_t)totalBytesWritten {
    if (self.samplesOfDownloadedBytes.count > kNumberOfSamples) {
        [self.samplesOfDownloadedBytes removeObjectAtIndex:0];
    }
    
    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSince1970] - self.lastSpeedUpdateTime;
    
    if (timeDifference < 1) {
        return;
    }
    self.lastSpeedUpdateTime = [[NSDate date] timeIntervalSince1970];
    
    NSNumber *tBytesWritten = @(totalBytesWritten);
    NSNumber *receivedDataLength = @(self.receivedDataLength);
    NSNumber *expectedDataLength = @(self.expectedDataLength);
    
    NSLog(@"timeDifference: %f", timeDifference);
    NSLog(@"totalBytesWritten: %@", tBytesWritten);
    NSLog(@"download.receivedDataLength: %@", receivedDataLength);
    
    NSNumber *sample = @(([tBytesWritten doubleValue] - [receivedDataLength doubleValue]) / timeDifference);
    NSLog(@"adding sample: %@", sample);
    
    [self.samplesOfDownloadedBytes addObject:sample];
    [self setReceivedDataLength:totalBytesWritten];
    self.speedRate = [[self.samplesOfDownloadedBytes valueForKeyPath:@"@avg.doubleValue"] doubleValue];
    NSLog(@"speedRate: %f", self.speedRate);
    
    self.remainingTime = ([expectedDataLength doubleValue] - [receivedDataLength doubleValue]) / self.speedRate;
    NSLog(@"remainingTime: %f", self.remainingTime);
}
@end
