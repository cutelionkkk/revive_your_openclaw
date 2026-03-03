# revive.sh — OpenClaw Agent 使用指南

## 这个工具是干什么的

`revive.sh` 是 OpenClaw 的配置快照工具。

**核心场景：** 当你修改了 `openclaw.json` 导致 OpenClaw 无法启动时，用这个工具一键回退到之前可以正常运行的版本。

---

## 安装

```bash
curl -O https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/revive.sh
chmod +x revive.sh
```

建议安装到全局方便调用：

```bash
cp revive.sh /usr/local/bin/revive
```

---

## 你需要记住的三条命令

### 1. 改配置之前：保存快照

```bash
revive.sh snapshot "修改前备份"
```

版本名自动生成（格式：`20260303-142500`），加备注方便事后定位。

### 2. 出问题之后：看有哪些版本可以回退

```bash
revive.sh list
```

输出示例：
```
版本                   备注                      OpenClaw版本
20260303-152300        修改前备份                2026.3.1
20260227-091500        初始快照                  2026.2.27
```

### 3. 回退到指定版本

```bash
revive.sh restore 20260303-152300
```

回退后重启 OpenClaw：

```bash
pkill -f 'openclaw gateway' 2>/dev/null
nohup /root/start_openclaw.sh &
```

---

## 推荐工作流

**每次修改 openclaw.json 前：**

```
revive.sh snapshot "说明这次改了什么"
→ 修改 openclaw.json
→ 重启 OpenClaw
→ 如果启动失败：revive.sh list → revive.sh restore <版本>
```

---

## 快照存在哪

默认：`/root/.openclaw/revive-backups/`

每个快照包含：
- `openclaw.json` — 配置文件备份
- `meta.json` — 版本信息（备注、时间、OpenClaw 版本号）

---

## 全部命令

| 命令 | 说明 |
|------|------|
| `revive.sh snapshot [备注]` | 保存当前配置快照 |
| `revive.sh list` | 列出所有历史快照 |
| `revive.sh restore <版本名>` | 回退到指定版本（自动先备份当前） |
| `revive.sh diff <版本名>` | 对比该版本与当前配置的差异 |
| `revive.sh clean [N]` | 清理旧快照，保留最新 N 个（默认10） |
| `revive.sh restart` | 安全重启：快照 → 停进程 → 启动 → 检测 |
| `revive.sh status` | 查看运行状态和快照数量 |
