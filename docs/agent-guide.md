# revive.sh — OpenClaw Agent 使用指南

## For AI Agents — 安装步骤

当用户发来这条指令时，按以下步骤完成安装：

```
帮我安装 revive_your_openclaw：https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/docs/agent-guide.md
```

### Step 1：下载 revive 脚本

```bash
curl -o /usr/local/bin/revive https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/revive.sh
chmod +x /usr/local/bin/revive
```

### Step 2：找到启动脚本，加入自动快照逻辑

找到用户的 OpenClaw 启动脚本（通常是 `start_openclaw.sh` 或 `nohup.out` 对应的启动命令），在其中 **openclaw 启动命令之后、等待进程结束之前** 加入以下逻辑：

```bash
# 等待最多 30s，确认 openclaw 成功启动
started=false
for i in $(seq 1 10); do
    sleep 3
    if pgrep -f 'openclaw gateway' > /dev/null 2>&1; then
        started=true
        break
    fi
done

# 启动成功 → 快照当前配置（这份是"已知可用"的版本）
if $started && [ -x /usr/local/bin/revive ]; then
    /usr/local/bin/revive snapshot "启动成功自动备份" >> /tmp/openclaw.log 2>&1
fi
```

**完整的启动脚本模板**（如果用户没有现成的，帮他创建）：

```bash
#!/bin/bash
LOG_FILE="/tmp/openclaw.log"
RETRY_DELAY=5

echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting openclaw..." | tee -a "$LOG_FILE"

while true; do
    start_time=$(date +%s)

    # 启动 openclaw（根据用户实际命令调整）
    openclaw gateway --verbose 2>&1 | tee -a "$LOG_FILE" &
    OC_PID=$!

    # 确认启动成功后快照
    started=false
    for i in $(seq 1 10); do
        sleep 3
        if kill -0 $OC_PID 2>/dev/null && pgrep -f 'openclaw gateway' > /dev/null 2>&1; then
            started=true
            break
        fi
    done

    if $started && [ -x /usr/local/bin/revive ]; then
        /usr/local/bin/revive snapshot "启动成功自动备份" >> "$LOG_FILE" 2>&1
    fi

    wait $OC_PID
    exit_code=$?
    uptime=$(( $(date +%s) - start_time ))

    if [ $exit_code -eq 0 ] && [ $uptime -gt 60 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - openclaw exited normally." | tee -a "$LOG_FILE"
        break
    fi

    sleep $RETRY_DELAY
done
```

> ⚠️ 注意：不要在模板里加 `proxychains4` 或其他代理命令，除非用户明确要求。启动命令以用户实际环境为准。

### Step 3：保存第一个快照

```bash
revive snapshot "初始快照 — 安装 revive 时"
```

### Step 4：告诉用户安装完成

向用户说明：
> "revive 已安装好了。以后改 openclaw.json 不用管，每次 OpenClaw 成功启动后会自动保存一份可用的配置快照。出问题了运行 `revive list` 看版本，`revive restore <版本名>` 回退，然后重启 OpenClaw 即可。"

---

## 这个工具是干什么的

`revive.sh` 是 OpenClaw 的配置快照工具。

**核心场景：** 当你修改了 `openclaw.json` 导致 OpenClaw 无法启动时，用这个工具一键回退到之前可以正常运行的版本。

**快照时机：** 每次 OpenClaw 成功启动后自动保存，确保快照永远是"已知可用"的版本。

---

## 出问题时怎么办

```
openclaw 启动失败
    ↓
revive list          # 看有哪些历史快照
    ↓
revive restore 20260303-142500   # 回退到某个可用版本
    ↓
重启 openclaw
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
| `revive snapshot [备注]` | 手动保存当前配置快照 |
| `revive list` | 列出所有历史快照（从新到旧） |
| `revive restore <版本名>` | 回退到指定版本（自动先备份当前） |
| `revive diff <版本名>` | 对比该版本与当前配置的差异 |
| `revive clean [N]` | 清理旧快照，保留最新 N 个（默认10） |
| `revive status` | 查看运行状态和快照数量 |
