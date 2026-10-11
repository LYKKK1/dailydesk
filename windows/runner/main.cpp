#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // DailyDesk 单实例互斥（spec 8-1）：防止双进程读写 SQLite 死锁。
  HANDLE singleton_mutex =
      ::CreateMutexW(nullptr, TRUE, L"Global\\DailyDeskSingleton");
  if (singleton_mutex == nullptr) {
    return EXIT_FAILURE;
  }
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    // 找到已有窗口并广播唤醒消息，随后退出当前进程。
    HWND existing =
        ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"dailydesk");
    if (existing != nullptr) {
      ::SendMessageW(existing, WM_APP + 1, 0, 0);
      ::ShowWindow(existing, SW_RESTORE);
      ::SetForegroundWindow(existing);
    }
    ::ReleaseMutex(singleton_mutex);
    ::CloseHandle(singleton_mutex);
    return EXIT_FAILURE;
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
  if (!window.Create(L"dailydesk", origin, size)) {
    ::CloseHandle(singleton_mutex);
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  ::CloseHandle(singleton_mutex);
  return EXIT_SUCCESS;
}
