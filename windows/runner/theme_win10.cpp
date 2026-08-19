#include "theme_win10.h"
#include <dwmapi.h>

// Undocumented SetWindowCompositionAttribute API structures
typedef enum _WINDOWCOMPOSITIONATTRIB {
  WCA_UNDEFINED = 0,
  WCA_NCRENDERING_ENABLED = 1,
  WCA_NCRENDERING_POLICY = 2,
  WCA_TRANSITIONS_FORCEDISABLED = 3,
  WCA_ALLOW_NCPAINT = 4,
  WCA_CAPTION_BUTTON_BOUNDS = 5,
  WCA_NONCLIENT_RTL_LAYOUT = 6,
  WCA_FORCE_ICONIC_REPRESENTATION = 7,
  WCA_EXTENDED_FRAME_BOUNDS = 8,
  WCA_HAS_ICONIC_BITMAP = 9,
  WCA_THEME_ATTRIBUTES = 10,
  WCA_NCRENDERING_EXENDED_FRAME_BOUNDS = 11,
  WCA_ACTIVE_BORDER_SCENE = 12,
  WCA_BACKGROUND_REPAINT = 13,
  WCA_BANNER_FREE_KEY = 14,
  WCA_LAST_KEY = 15,
  WCA_ACCENT_POLICY = 19,
  WCA_FREEZE_REPRESENTATION = 20,
  WCA_VERALL = 21
} WINDOWCOMPOSITIONATTRIB;

typedef struct _WINDOWCOMPOSITIONATTRIBDATA {
  WINDOWCOMPOSITIONATTRIB Attrib;
  PVOID pvData;
  SIZE_T cbData;
} WINDOWCOMPOSITIONATTRIBDATA;

typedef enum _ACCENT_STATE {
  ACCENT_DISABLED = 0,
  ACCENT_ENABLE_GRADIENT = 1,
  ACCENT_ENABLE_TRANSPARENTBACKGROUND = 2,
  ACCENT_ENABLE_BLURBEHIND = 3,
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
  ACCENT_INVALID_STATE = 5
} ACCENT_STATE;

typedef struct _ACCENT_POLICY {
  ACCENT_STATE AccentState;
  DWORD AccentFlags;
  DWORD GradientColor;
  DWORD AnimationId;
} ACCENT_POLICY;

typedef BOOL(WINAPI* pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA*);

void ApplyThemeWin10(HWND hwnd, bool is_dark) {
  BOOL enable_dark_mode = is_dark ? TRUE : FALSE;
  DwmSetWindowAttribute(hwnd, 19, &enable_dark_mode, sizeof(enable_dark_mode));
  DwmSetWindowAttribute(hwnd, 20, &enable_dark_mode, sizeof(enable_dark_mode));

  HMODULE hUser = GetModuleHandleA("user32.dll");
  if (hUser) {
    pSetWindowCompositionAttribute setWindowCompAttr = 
        (pSetWindowCompositionAttribute)GetProcAddress(hUser, "SetWindowCompositionAttribute");
    if (setWindowCompAttr) {
      int alpha = 0x66; // ~40% opacity
      if (alpha == 0) alpha = 1; // Zero-alpha guard
      
      int r = is_dark ? 0x12 : 0xFA;
      int g = is_dark ? 0x12 : 0xFA;
      int b = is_dark ? 0x12 : 0xFA;
      int tint_color = (alpha << 24) | (b << 16) | (g << 8) | r; // ABGR format
      
      ACCENT_POLICY policy = { ACCENT_ENABLE_BLURBEHIND, 2, static_cast<DWORD>(tint_color), 0 };
      WINDOWCOMPOSITIONATTRIBDATA data = { WCA_ACCENT_POLICY, &policy, sizeof(policy) };
      setWindowCompAttr(hwnd, &data);
    }
  }

  // Authorize composition with a 1px top margin to prevent duplicate border rendering
  MARGINS margins = { 0, 0, 1, 0 };
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  // Resize window 1px and back to force immediate non-client area recalculation
  RECT rect;
  GetWindowRect(hwnd, &rect);
  SetWindowPos(hwnd, nullptr, 0, 0, (rect.right - rect.left) - 1, (rect.bottom - rect.top), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
  SetWindowPos(hwnd, nullptr, 0, 0, (rect.right - rect.left), (rect.bottom - rect.top), SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

  SendMessage(hwnd, WM_NCACTIVATE, FALSE, 0);
  SendMessage(hwnd, WM_NCACTIVATE, TRUE, 0);
}
