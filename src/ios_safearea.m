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
