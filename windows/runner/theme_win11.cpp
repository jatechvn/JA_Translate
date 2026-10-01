#include "theme_win11.h"
#include <dwmapi.h>

void ApplyThemeWin11(HWND hwnd, bool is_dark, bool /*is_startup*/) {
  BOOL enable_dark_mode = is_dark ? TRUE : FALSE;
  DwmSetWindowAttribute(hwnd, 19, &enable_dark_mode, sizeof(enable_dark_mode));
  DwmSetWindowAttribute(hwnd, 20, &enable_dark_mode, sizeof(enable_dark_mode));

  // Keep native composition authoritative on every theme sync.
  MARGINS margins = { -1, -1, -1, -1 };
  DwmExtendFrameIntoClientArea(hwnd, &margins);

  // Client-area Acrylic, using the same translucent tint as the Dart fallback.
  // System backdrop below handles the native title bar independently.
  struct AccentPolicy {
    int state;
    int flags;
    DWORD color;
    int animation;
  };
  struct CompositionData {
    int attribute;
    void* data;
    SIZE_T size;
  };
  using SetComposition = BOOL(WINAPI*)(HWND, CompositionData*);
  HMODULE user = GetModuleHandleW(L"user32.dll");
  if (user) {
    auto set_composition = reinterpret_cast<SetComposition>(
        GetProcAddress(user, "SetWindowCompositionAttribute"));
    if (set_composition) {
      // ACCENT_ENABLE_ACRYLICBLURBEHIND = 4; colors use ABGR with nonzero alpha.
      AccentPolicy policy = {4, 2, is_dark ? 0x1F1C0C0Au : 0x1FFCFAF8u, 0};
      CompositionData data = {19, &policy, sizeof(policy)};
      set_composition(hwnd, &data);
    }
  }

  int backdrop_type = 3; // DWMSBT_TRANSIENTWINDOW (Acrylic)
  DwmSetWindowAttribute(hwnd, 38, &backdrop_type, sizeof(backdrop_type));
  BOOL use_host_backdrop = TRUE;
  DwmSetWindowAttribute(hwnd, 17, &use_host_backdrop, sizeof(use_host_backdrop));
}
