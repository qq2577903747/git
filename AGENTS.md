# AGENTS.md

本机 Godot 地址：
`D:\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe`

编写代码时需要添加中文注释。

## 已知限制

在当前受限沙盒环境中，Godot 4.7 的 headless 模式会在引擎启动早期崩溃（signal 11），
即使用 `--headless --quit-after 1` 且不加载项目也会触发。`--headless --version` 可以正常返回版本，
但 `--check-only`、项目加载和冒烟运行都会在初始化系统/图形信息阶段段错误。
这是环境限制，不是项目脚本错误。需要实际运行验证时，应在桌面正常会话中用编辑器打开项目，
不要依赖命令行的 headless 启动。
