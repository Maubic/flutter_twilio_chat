#import "FlutterTwilioChatPlugin.h"
#if __has_include(<flutter_twilio_chat/flutter_twilio_chat-Swift.h>)
#import <flutter_twilio_chat/flutter_twilio_chat-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_twilio_chat-Swift.h"
#endif

@implementation FlutterTwilioChatPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterTwilioChatPlugin registerWithRegistrar:registrar];
}
@end
