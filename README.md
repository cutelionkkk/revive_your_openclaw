# revive_your_openclaw

**OpenClaw 配置版本管理 + 安全重启工具**

当你修改 OpenClaw 配置后如果无法启动，用这个工具一键回退到任意历史版本。

---

## 功能

- 📸 **快照**：保存当前 `openclaw.json` 配置，版本名用日期+时间命名
- 📋 **列出版本**：查看所有历史快照
- ⏪ **回退**：一键还原到指定历史版本
- 🔄 **安全重启**：自动快照 → 重启 → 检测是否成功，失败时提示回退命令
- 🔍 **状态检查**：查看 OpenClaw 是否在运行

---

## 安装

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/revive.sh
chmod +x revive.sh

# 可选：安装到 PATH
cp revive.sh /usr/local/bin/revive
```

---

## 用法

```bash
# 修改配置前，先保存快照
revive.sh snapshot "修改前备份"

# 列出所有快照
revive.sh list

# 修改 openclaw.json 后重启（自动快照 + 启动检测）
revive.sh restart

# 如果启动失败，查看可用版本
revive.sh list

# 回退到指定版本
revive.sh restore 20260303-142500

# 然后重启
pkill -f 'openclaw gateway'; nohup /root/start_openclaw.sh &
```

---

## 工作流

```
修改 openclaw.json
       ↓
revive.sh restart
       ↓
   启动成功？
  ✅ Yes → 继续
  ❌ No  → revive.sh list
           revive.sh restore <版本>
           pkill -f 'openclaw gateway'
           nohup /root/start_openclaw.sh &
```

---

## 快照目录

默认存储在 `/root/.openclaw/revive-backups/`，每个快照包含：

```
revive-backups/
└── 20260303-142500/       ← 版本名（日期-时间）
    ├── openclaw.json      ← 配置文件备份
    ├── start_openclaw.sh  ← 启动脚本备份（如果存在）
    └── meta.json          ← 元数据（备注、时间戳、OpenClaw版本）
```

可通过环境变量自定义路径：

```bash
OPENCLAW_BACKUP_DIR=/my/backup/path revive.sh snapshot
OPENCLAW_CONFIG=/path/to/openclaw.json revive.sh snapshot
OPENCLAW_START_SCRIPT=/path/to/start.sh revive.sh restart
```

---

## 要求

- bash 4+
- python3（用于解析元数据，可选）
- OpenClaw 已安装

---

## 示例输出

```
$ revive.sh list

📦 可用快照（从新到旧）:

版本                   备注                                     OpenClaw版本
--------------------   --------------------------------------   ------------
20260303-152300        restart前自动备份                        2026.3.1
20260303-142500        添加了discord渠道                        2026.3.1
20260303-110000        修改前备份                               2026.3.1
20260227-091500        初始快照                                 2026.2.27
```

```
$ revive.sh restart
ℹ️  准备重启 OpenClaw...
ℹ️  快照当前配置...
✅ 快照保存: 20260303-152300
ℹ️  停止当前进程...
ℹ️  启动 OpenClaw...
ℹ️  等待 15s 检测是否启动成功...
...
✅ OpenClaw 启动成功！
✅ OpenClaw 正在运行 (PID: 12345)
ℹ️  最新快照: 20260303-152300
```

---

## License

MIT
