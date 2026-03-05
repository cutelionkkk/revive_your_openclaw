<h1 align="center">🔄 revive_your_openclaw</h1>

<p align="center">
  <strong>OpenClaw 配置版本管理 + 安全重启工具<br>改坏了？一键回退到任意历史版本</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Shell-Bash_4+-green.svg?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash 4+">
  <img src="https://img.shields.io/badge/Platform-Linux_macOS-lightgrey.svg?style=for-the-badge" alt="Platform">
  <a href="https://github.com/cutelionkkk/revive_your_openclaw/stargazers"><img src="https://img.shields.io/github/stars/cutelionkkk/revive_your_openclaw?style=for-the-badge" alt="GitHub Stars"></a>
</p>

<p align="center">
  <b>中文</b> | <a href="README.en.md">English</a>
</p>

<p align="center">
  <a href="#给-openclaw-的一句话指令">给 OpenClaw 的指令</a> · <a href="#快速开始">快速开始</a> · <a href="#用法">用法</a> · <a href="#工作流">工作流</a> · <a href="#配置">配置</a>
</p>

---

## 给 OpenClaw 的一句话指令

**如果你是 OpenClaw 用户**，把下面这句话直接发给你的 OpenClaw，它会自动完成安装和配置：

```
帮我安装 revive_your_openclaw：https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/docs/agent-guide.md
```

OpenClaw 读完文档后会自动：下载 `revive.sh`、保存第一个快照、告诉你之后怎么用。

---

## 为什么需要这个工具？

OpenClaw 的配置（`openclaw.json`）改动之后，如果出了问题，你会遇到：

- 🔴 Gateway 无法启动，服务中断
- 😨 不知道改了哪里导致的问题
- 🔍 没有历史版本可以对比、回退
- 😤 只能一行一行排查，或者手动复制备份

`revive.sh` 解决这个问题：每次修改前自动快照，出了问题三秒回退。

> ⭐ **Star 这个项目**——如果你在使用 OpenClaw，这是最容易帮到你的安全工具。

### ✅ 你可能想知道

| | |
|---|---|
| 🔗 **一个文件搞定** | 整个工具就是一个 `revive.sh`，下载后 `chmod +x` 即可用 |
| 📸 **自动版本化** | 快照命名格式：`YYYYMMDD-HHMMSS`（如 `20260303-142500`），一目了然 |
| ⏪ **秒级回退** | 找到版本号，`revive.sh restore <版本>` 一行命令还原 |
| 🔄 **安全重启** | `revive.sh restart` 自动做：快照 → 停止旧进程 → 启动 → 检测 → 失败提示 |
| 🗒️ **支持备注** | 快照时可以加备注说明，方便事后定位："添加了飞书渠道之前" |
| ⚙️ **可配置** | 通过环境变量自定义配置路径、备份目录、启动脚本 |

---

## 快速开始

```bash
# 1. 下载脚本
curl -O https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/revive.sh
chmod +x revive.sh

# 2. 保存当前配置（第一个快照）
./revive.sh snapshot "初始快照"

# 3. 查看快照列表
./revive.sh list
```

**可选：安装到全局**

```bash
cp revive.sh /usr/local/bin/revive
# 之后直接用 revive 命令
```

---

## 用法

```
revive.sh <命令> [参数]
```

| 命令 | 说明 |
|------|------|
| `snapshot [备注]` | 保存当前配置快照，版本名自动生成（日期+时间） |
| `list` | 列出所有历史快照（从新到旧） |
| `restore <版本名>` | 回退到指定版本（自动先备份当前状态） |
| `restart` | 安全重启：自动快照 → 停止进程 → 启动 → 检测 |
| `status` | 查看 OpenClaw 是否正在运行 |
| `help` | 显示帮助 |

---

### snapshot — 保存快照

```bash
# 不加备注
revive.sh snapshot

# 加备注（推荐）
revive.sh snapshot "修改前备份"
revive.sh snapshot "添加了钉钉渠道"
revive.sh snapshot "升级到 2026.3.1 之前"
```

快照会自动命名为当前时间，例如 `20260303-142500`。

---

### list — 列出版本

```bash
revive.sh list
```

输出示例：

```
📦 可用快照（从新到旧）:

版本                   备注                                     OpenClaw版本
--------------------   --------------------------------------   ------------
20260303-152300        restart前自动备份                        2026.3.1
20260303-142500        添加了钉钉渠道                           2026.3.1
20260303-110000        修改前备份                               2026.3.1
20260227-091500        初始快照                                 2026.2.27
```

---

### restore — 回退版本

```bash
revive.sh restore 20260303-110000
```

> ⚠️ **回退前会自动备份当前状态**，不用担心覆盖。

回退后重启：

```bash
pkill -f 'openclaw gateway'
nohup /root/start_openclaw.sh &
```

---

### restart — 安全重启

```bash
revive.sh restart
```

执行流程：

```
1. 自动快照当前配置
2. 停止现有 openclaw gateway 进程
3. 启动新进程（nohup start_openclaw.sh）
4. 等待 15s 检测是否启动成功
5a. ✅ 成功 → 显示运行状态
5b. ❌ 失败 → 提示回退命令 + 显示最近日志
```

---

### status — 检查状态

```bash
revive.sh status
```

---

## 工作流

### 日常修改配置

```
修改 openclaw.json
       ↓
revive.sh restart        ← 自动快照 + 重启 + 检测
       ↓
   启动成功？
  ✅ Yes → 继续工作
  ❌ No  → revive.sh list
           revive.sh restore <版本名>
           pkill -f 'openclaw gateway'
           nohup /root/start_openclaw.sh &
```

### 升级 OpenClaw 版本前

```bash
# 先备份
revive.sh snapshot "升级前备份 v2026.3.1"

# 升级
npm update -g openclaw

# 如果出问题，先看有哪些版本
revive.sh list

# 回退配置（注意：程序本体无法回退，只回退配置）
revive.sh restore 20260303-110000
```

---

## 快照目录结构

默认存储在 `/root/.openclaw/revive-backups/`：

```
revive-backups/
├── 20260303-152300/
│   ├── openclaw.json       ← 配置文件备份
│   ├── start_openclaw.sh   ← 启动脚本备份（如果存在）
│   └── meta.json           ← 元数据
├── 20260303-142500/
│   └── ...
└── 20260303-110000/
    └── ...
```

`meta.json` 内容：

```json
{
  "version": "20260303-152300",
  "note": "restart前自动备份",
  "timestamp": "2026-03-03T15:23:00+08:00",
  "config_file": "/root/.openclaw/openclaw.json",
  "openclaw_version": "2026.3.1"
}
```

---

## 配置

默认路径可通过环境变量覆盖：

| 环境变量 | 默认值 | 说明 |
|---------|--------|------|
| `OPENCLAW_BACKUP_DIR` | `/root/.openclaw/revive-backups` | 快照存储目录 |
| `OPENCLAW_CONFIG` | `/root/.openclaw/openclaw.json` | 配置文件路径 |
| `OPENCLAW_START_SCRIPT` | `/root/start_openclaw.sh` | 启动脚本路径 |

示例：

```bash
# 自定义备份目录
OPENCLAW_BACKUP_DIR=/data/openclaw-backups revive.sh snapshot

# 临时指定配置文件
OPENCLAW_CONFIG=/etc/openclaw/config.json revive.sh list
```

也可以在脚本开头直接修改默认值：

```bash
BACKUP_DIR="${OPENCLAW_BACKUP_DIR:-/your/path/here}"
```

---

## 常见问题

<details>
<summary><strong>回退后 OpenClaw 还是起不来怎么办？</strong></summary>

可能是程序本体（npm 包）有问题，不只是配置的问题。可以尝试：

```bash
# 查看启动日志
tail -50 /root/openclaw.log

# 重装 OpenClaw
npm install -g openclaw
```

`revive.sh` 目前只管理配置文件，不管理 npm 包本体（因为包体 1GB+，不适合版本化）。

</details>

<details>
<summary><strong>快照太多了怎么清理？</strong></summary>

手动删除不需要的版本目录：

```bash
ls /root/.openclaw/revive-backups/
rm -rf /root/.openclaw/revive-backups/20260227-091500
```

后续版本会考虑加 `revive.sh clean --keep 10` 这样的命令。

</details>

<details>
<summary><strong>能备份整个 .openclaw 目录吗？</strong></summary>

目前只备份 `openclaw.json`（配置文件）和 `start_openclaw.sh`（启动脚本）。

如果你想备份更多内容（比如自定义 skills、credentials），可以修改 `revive.sh` 中的 `cmd_snapshot` 函数，加一行 `cp` 命令。

</details>

<details>
<summary><strong>restart 检测超时了怎么办？</strong></summary>

默认等待 15 秒检测。OpenClaw 冷启动可能较慢（加载插件、建立连接），如果你的环境启动慢，可以修改脚本中的 `STARTUP_TIMEOUT=15` 改大一些，比如 `30`。

</details>

---

## 要求

- **Bash** 4.0+（Linux / macOS 默认满足）
- **OpenClaw** 已安装（`openclaw --version` 能正常输出）
- **Python 3**（可选，用于显示快照元数据，不装也能用）

---

## Roadmap

- [x] snapshot / list / restore / restart / status ✅
- [x] 自动备注当前 OpenClaw 版本 ✅
- [x] restore 前自动备份 ✅
- [ ] `revive.sh clean --keep N` — 自动清理旧快照
- [ ] `revive.sh diff <版本A> <版本B>` — 对比两个版本的配置差异
- [ ] `revive.sh export <版本>` — 导出快照为压缩包
- [ ] 支持备份自定义 skills 目录

---

## License

[MIT](LICENSE)
