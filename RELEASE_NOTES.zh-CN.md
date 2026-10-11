# DailyDesk v0.1.0

## 新特性

- 离线优先的待办、日历、便签、番茄钟、习惯、复盘、仪表盘与 AI 智囊模块。
- mDNS 局域网设备发现，UDP 组播作为降级通道。
- PIN 配对、HMAC 鉴权、增量同步、LWW 合并与便签冲突备份。
- Android 前台番茄钟常驻通知桥接。
- Windows 便携压缩包与 Android 分 ABI APK。

## 校验

- CI 执行 Flutter analyze 与全量测试。
- 构建门禁校验 APK/Windows 包体积、URL 白名单和 tag/version 一致性。

## 已知限制

- Windows/Android 实机局域网同步与通知行为仍需设备级验收。
- 正式发布前必须配置生产 Android 签名密钥。

