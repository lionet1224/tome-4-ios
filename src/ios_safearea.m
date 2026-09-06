/* iOS port: the safe area (Dynamic Island / notch, home indicator) in points,
   plus the window size in points so Lua can convert to its logical units. */
#import <UIKit/UIKit.h>

void te4_ios_safe_area(float *l, float *t, float *r, float *b, float *pw, float *ph)
{
	*l = *t = *r = *b = 0; *pw = *ph = 0;
	UIApplication *app = [UIApplication sharedApplication];
	UIWindow *w = nil;
	for (UIWindow *win in app.windows) { if (win.isKeyWindow) { w = win; break; } }
	if (!w) w = app.windows.firstObject;
	if (!w) return;
	if (@available(iOS 11.0, *)) {
		UIEdgeInsets i = w.safeAreaInsets;
		*l = i.left; *t = i.top; *r = i.right; *b = i.bottom;
	}
	*pw = w.bounds.size.width;
	*ph = w.bounds.size.height;
}

/* ---- iOS port: keep-awake, haptics, local notifications (auto-act) ---- */
#import <AudioToolbox/AudioToolbox.h>
#import <UserNotifications/UserNotifications.h>

@interface TE4NotifDelegate : NSObject <UNUserNotificationCenterDelegate>
@end
@implementation TE4NotifDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
	/* show the banner even while the game is in the foreground */
	if (@available(iOS 14.0, *)) completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
	else completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
}
@end
static TE4NotifDelegate *te4_notif_delegate = nil;

void te4_ios_keep_awake(int on)
{
	[UIApplication sharedApplication].idleTimerDisabled = on ? YES : NO;
}

void te4_ios_haptic(int kind)
{
	if (kind >= 2) {
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	}
	UINotificationFeedbackGenerator *g = [[UINotificationFeedbackGenerator alloc] init];
	[g prepare];
	[g notificationOccurred:(kind == 0 ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeWarning)];
}

void te4_ios_notify(const char *title, const char *body)
{
	UNUserNotificationCenter *c = [UNUserNotificationCenter currentNotificationCenter];
	if (!te4_notif_delegate) { te4_notif_delegate = [[TE4NotifDelegate alloc] init]; c.delegate = te4_notif_delegate; }
	NSString *t = [NSString stringWithUTF8String:title ? title : ""];
	NSString *b = [NSString stringWithUTF8String:body ? body : ""];
	[c requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError *err) {
		if (!granted) return;
		UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
		content.title = t;
		content.body = b;
		content.sound = [UNNotificationSound defaultSound];
		UNTimeIntervalNotificationTrigger *trig = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5 repeats:NO];
		UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"te4-auto" content:content trigger:trig];
		[c addNotificationRequest:req withCompletionHandler:nil];
	}];
}

float te4_ios_brightness(float set)
{
	UIScreen *s = [UIScreen mainScreen];
	if (set >= 0) s.brightness = set;
	return (float)s.brightness;
}

/* iOS port: the app's Documents directory (for the on-device log file) */
const char *te4_ios_documents_path(void)
{
	static char buf[1024];
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *dir = [paths firstObject];
	if (!dir) return NULL;
	snprintf(buf, sizeof(buf), "%s", [dir UTF8String]);
	return buf;
}

/* iOS port: the allowed orientations changed (SDL reads SDL_HINT_ORIENTATIONS
   whenever UIKit asks). On iOS 16+ the view controller can be told to re-ask
   at once, which rotates the app if it is now held the wrong way; older
   versions only re-read on the next launch. Returns 1 when applied live. */
int te4_ios_orientation_changed(void)
{
	int live = 0;
	if (@available(iOS 16.0, *)) {
		for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
			if (![scene isKindOfClass:[UIWindowScene class]]) continue;
			for (UIWindow *w in ((UIWindowScene *)scene).windows) {
				UIViewController *vc = w.rootViewController;
				if (!vc) continue;
				[vc setNeedsUpdateOfSupportedInterfaceOrientations];
				live = 1;
			}
		}
	}
	return live;
}

/* iOS port: is the screen currently taller than wide (device held portrait)? */
int te4_ios_is_portrait(void)
{
	CGRect b = [UIScreen mainScreen].bounds;
	return b.size.height > b.size.width ? 1 : 0;
}
