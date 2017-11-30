
#import "SafariViewManager.h"
#import <React/RCTUtils.h>
#import <React/RCTLog.h>
#import <React/RCTConvert.h>

@implementation SafariViewManager
{
    bool hasListeners;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"SafariViewOnShow", @"SafariViewOnDismiss"];
}

RCT_EXPORT_METHOD(show:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    // Error if no url is passed
    if (!args[@"url"]) {
        reject(@"E_SAFARI_VIEW_NO_URL", @"You must specify a url.", nil);
        return;
    }

    NSURL *url = [NSURL URLWithString:args[@"url"]];
    BOOL readerMode = [args[@"readerMode"] boolValue];
    UIColor *tintColorString = args[@"tintColor"];
    UIColor *barTintColorString = args[@"barTintColor"];
    BOOL fromBottom = [args[@"fromBottom"] boolValue];

    // Initialize the Safari View
    _safariView = [[SFSafariViewController alloc] initWithURL:url entersReaderIfAvailable:readerMode];
    _safariView.delegate = self;

    // Set tintColor if available
    if (tintColorString) {
        UIColor *tintColor = [RCTConvert UIColor:tintColorString];
        if ([_safariView respondsToSelector:@selector(setPreferredControlTintColor:)]) {
            [_safariView setPreferredControlTintColor:tintColor];
        } else {
            [_safariView.view setTintColor:tintColor];
        }
    }

    // Set barTintColor if available
    if (barTintColorString) {
        UIColor *barTintColor = [RCTConvert UIColor:barTintColorString];
        if ([_safariView respondsToSelector:@selector(setPreferredBarTintColor:)]) {
            [_safariView setPreferredBarTintColor:barTintColor];
        }
    }

    // Set modal transition style
    if (fromBottom) {
        _safariView.modalPresentationStyle = UIModalPresentationOverFullScreen;
    }

    // get the view controller closest to the foreground
    UIViewController *ctrl = RCTPresentedViewController();
    
    // Display the Safari View
    [ctrl presentViewController:_safariView animated:YES completion:nil];

    if (hasListeners) {
        [self sendEventWithName:@"SafariViewOnShow" body:nil];
    }

    resolve(@YES);
}

RCT_EXPORT_METHOD(isAvailable:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([SFSafariViewController class]) {
        // SafariView is available
        resolve(@YES);
    } else {
        reject(@"E_SAFARI_VIEW_UNAVAILABLE", @"SafariView is unavailable", nil);
    }
}

RCT_EXPORT_METHOD(dismiss)
{
    [self safariViewControllerDidFinish:_safariView];
}

-(void)safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:true completion:nil];
    NSLog(@"[SafariView] SafariView dismissed.");

    if (hasListeners) {
        [self sendEventWithName:@"SafariViewOnDismiss" body:nil];
    }
}
@end
