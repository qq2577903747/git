# AGENTS.md

本机 Godot 地址：
`D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`

编写代码时需要添加中文注释。

## Godot headless 验证

当前 Codex Windows 沙盒可能因沙盒初始化失败，导致 Godot 4.7 的 headless 模式在引擎启动早期崩溃
（signal 11）。这是 Codex 沙盒环境限制，不是项目脚本错误。

需要执行 headless 验证时，必须通过 Codex 的升级权限（`require_escalated`）在沙盒外运行，例如：

```powershell
& 'D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe' `
  --headless `
  --quit-after 1 `
  --path 'D:\MyProgect\codex\平台跳跃（测试）'
```

不要依赖默认沙盒运行 Godot headless，也不要为避免此问题而将 Codex 全局沙盒改成 `unelevated`。
在沙盒外运行确认可用后，桌面编辑器仍可用于交互式验证。

修改脚本、场景、资源或项目配置后，代理应自动使用 `require_escalated` 执行一次上述 headless 冒烟验证，
不要仅因默认沙盒探测失败而跳过验证。审批前缀规则有效时，无需让用户重复确认；
若 Codex 再次提示审批，则说明规则失效或被撤销，需要重新授权。
