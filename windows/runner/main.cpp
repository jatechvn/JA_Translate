#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <vector>
#include <string>

#include "flutter_window.h"
#include "utils.h"

// Helper callback to locate the existing JA Translate window
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
  wchar_t class_name[256];
  if (GetClassName(hwnd, class_name, 256)) {
    if (wcscmp(class_name, L"FLUTTER_RUNNER_WIN32_WINDOW") == 0) {
      wchar_t window_title[256];
      if (GetWindowText(hwnd, window_title, 256)) {
        if (wcsstr(window_title, L"JA Translate") != nullptr) {
          HWND* p_hwnd = reinterpret_cast<HWND*>(lParam);
          *p_hwnd = hwnd;
          return FALSE; // Stop enumeration
        }
      }
    }
  }
  return TRUE; // Continue enumeration
}

HWND FindExistingWindow() {
  HWND hwnd = nullptr;
  EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&hwnd));
  return hwnd;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Enforce single instance using a named Mutex
  HANDLE hMutex = CreateMutex(NULL, TRUE, L"Local\\ja_translate_single_instance_mutex");
  if (hMutex == NULL) {
    return EXIT_FAILURE;
  }
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    // Bring the existing window to the foreground
    HWND hwnd = FindExistingWindow();
    if (hwnd) {
      if (IsIconic(hwnd)) {
        ShowWindow(hwnd, SW_RESTORE);
      } else {
        ShowWindow(hwnd, SW_SHOW);
      }
      SetForegroundWindow(hwnd);
    }
    CloseHandle(hMutex);
    return EXIT_SUCCESS; // Exit the duplicate instance immediately
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"ja_translate", origin, size)) {
    CloseHandle(hMutex);
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  CloseHandle(hMutex); // Release Mutex handle
  return EXIT_SUCCESS;
}
