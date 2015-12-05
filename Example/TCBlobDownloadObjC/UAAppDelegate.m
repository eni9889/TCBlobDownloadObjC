//
//  UAAppDelegate.m
//  TCBlobDownloadObjC
//
//  Created by UnlimApps Inc on 12/04/2015.
//  Copyright (c) 2015 UnlimApps Inc. All rights reserved.
//

#import "UAAppDelegate.h"

#import <TCBlobDownloadManager.h>

@interface UAAppDelegate ()
@property (nonatomic, strong) TCBlobDownloadManager *manager;
@end

@implementation UAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.manager = [[TCBlobDownloadManager alloc] init];
    self.manager.startImmediatly = YES;
    [self.manager downloadFileAtURL:[NSURL URLWithString:@"http://mirror.internode.on.net/pub/test/100meg.test"]
                        toDirectory:nil
                           withName:nil
                           progress:^(double progress,double speedRate, double time,int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
//                               NSLog(@"progress: %f", progress);
                           }
                         completion:^(NSError *error, NSURL *location) {
                             NSLog(@"File at: %@", location);
                         }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    [self.manager application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

@end
