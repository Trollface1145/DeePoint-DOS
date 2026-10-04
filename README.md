# DeePoint DOS

![Status](https://img.shields.io/badge/Status-V0.0.3--Unlocked-brightgreen)
![Language](https://img.shields.io/badge/Language-x86%20Assembly-blue)
![License](https://img.shields.io/badge/License-MIT-orange)

> **“这是我的磁盘操作系统，使用汇编语言开发的。”**

DeePoint DOS 是一个面向 16 位实模式的轻量级操作系统，由一位 12 岁的初中生在业余时间手搓完成。它不依赖现代操作系统框架，基于 NASM 编译，支持从 1.44MB 软盘（Floppy）直接引导启动。


##  已解锁特性（V0.0.1）

- [x] **纯手搓 MBR 引导扇区**：使用 CHS 物理读取，精准加载软盘第二扇区（LBA 1）到内存 `0x7E00`。
- [x] **引导与内核分离架构**：突破 512 字节限制，引导器只负责搬运，内核负责业务逻辑。
- [x] **基础命令行交互（REPL）**：支持键盘输入、退格键回显、命令前缀匹配。
- [x] **内置命令**：目前支持 `deepoint -v`，输出专属版权信息。
- [x] **防溢出保护**：在输入循环中加入了缓冲区溢出检查（最多 62 字符）。
- [x] 加入 `help`、`clear`、`echo` 命令

##  开发环境与构建

### 依赖工具（“开发牢九门”）
- **编辑器**：记事本 / VS Code（本版本使用记事本硬核开发）
- **汇编器**：NASM 3.02+
- **虚拟机**：QEMU (i386)
- **十六进制编辑器**：010 Editor / HxD
- **脚本**：PowerShell + CMD

### 如何构建与运行
1. 确保 `nasm` 已加入环境变量，`qemu-system-i386` 位于 `C:\Program Files\qemu`。
2. 将本仓库下载到本地目录。
3. **双击运行 `run_os.bat`**。
4. 脚本会自动执行：编译 `boot.asm` 和 `kernel.asm` -> 创建/清空 1.44MB 软盘镜像 -> 将二进制写入 LBA 0 和 LBA 1 -> 启动 QEMU 并强制从软盘引导。

##  项目结构

| 文件 | 作用 |
| :--- | :--- |
| `boot.asm` | 引导扇区（MBR），负责读取内核并跳转 |
| `kernel.asm` | 系统内核，包含命令行循环和命令解析逻辑 |
| `run_os.bat` | 一键构建与点火脚本 |
| `write_disk.ps1` | 用 PowerShell 精准将二进制写入软盘镜像的指定偏移 |
| `test_floppy.img` | 构建产物：1.44MB 软盘镜像（由脚本生成，不推荐上传仓库） |

##  DeePoint 系统架构与理论

在开发过程中，我们总结了一些底层系统的核心概念：

### 1. 指针与内存错误（“四针定律”）
- **钝针**：空指针 / 无法映射地址（砸钢板打滑）
- **断针**：野指针 / 越界（乱甩钉子砸坏别人玻璃）
- **切针**：悬空指针 / Use-After-Free（墙拆了钉子还在）
- **敲针**：合法指针强制访问非法地址
- **介针**：中间指针 / 双重指针
- **尸针**：指针本身内存被污染

### 2. 特权级与救援机制
系统设计了 `guest` / `user` / `root` / `system (Ring0)` 几种用户级别。但是目前只处于V0.0.1内测版，所以大家以后期待一下吧

### 3. DOS Wizard (V0.1.0 规划中)
计划在后续版本加入独立的救援菜单界面：
- `[1]` 恢复备份（BAK文件）
- `[2]` 重写扇区（Sector Wizard）
- `[5]` 命令终端（默认 System 权限运行，可触发“核弹按钮”）

##  未来计划 (V0.0.4)
- [ ] 实现 `DOS Wizard` 的图形化文本菜单
- [ ] 支持多扇区内核读取（突破 2KB 限制）
- [ ] 尝试把 `SymbolLang`（作者的另一门编程语言）移植到 DeePoint 上
- [ ] 加入`cd`/`dir`等DOS命令

##  开源协议
本项目基于 [MIT License](LICENSE) 开源。欢迎对底层感兴趣的朋友提交 Issue 或 Pull Request！

## 鸣谢
Deep Seek

---
*“All_Perfect” —— 12岁，手搓 MBR，点亮屏幕，编写操作系统。*
