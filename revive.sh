#!/usr/bin/env bash
# ============================================================
# revive.sh — OpenClaw 配置版本管理 + 安全重启
# 
# 用法:
#   revive.sh snapshot [备注]    # 保存当前配置快照
#   revive.sh list               # 列出所有快照
#   revive.sh restore <版本名>   # 回退到指定版本
#   revive.sh restart            # 安全重启（自动快照 + 启动检测）
#   revive.sh status             # 查看 openclaw 是否在运行
# ============================================================

set -euo pipefail

BACKUP_DIR="${OPENCLAW_BACKUP_DIR:-/root/.openclaw/revive-backups}"
CONFIG_FILE="${OPENCLAW_CONFIG:-/root/.openclaw/openclaw.json}"
START_SCRIPT="${OPENCLAW_START_SCRIPT:-/root/start_openclaw.sh}"
PID_FILE="/tmp/openclaw-revive.pid"
STARTUP_TIMEOUT=15   # 秒：等待确认启动成功

mkdir -p "$BACKUP_DIR"

# ── 颜色 ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✅ $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠️  $*${RESET}"; }
err()  { echo -e "${RED}❌ $*${RESET}"; }
info() { echo -e "${CYAN}ℹ️  $*${RESET}"; }

# ── 快照名：日期+时间 ─────────────────────────────────────────
make_version_name() {
    date '+%Y%m%d-%H%M%S'
}

# ── 保存快照 ──────────────────────────────────────────────────
cmd_snapshot() {
    local note="${1:-}"
    local ver
    ver=$(make_version_name)
    local dest="$BACKUP_DIR/$ver"
    mkdir -p "$dest"

    # 复制 openclaw.json
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$dest/openclaw.json"
        ok "配置已快照: $ver"
    else
        warn "未找到配置文件: $CONFIG_FILE"
    fi

    # 复制 start_openclaw.sh（如果存在）
    if [ -f "$START_SCRIPT" ]; then
        cp "$START_SCRIPT" "$dest/start_openclaw.sh"
    fi

    # 写元数据
    cat > "$dest/meta.json" <<META
{
  "version": "$ver",
  "note": "$note",
  "timestamp": "$(date -Iseconds)",
  "config_file": "$CONFIG_FILE",
  "openclaw_version": "$(openclaw --version 2>/dev/null || echo unknown)"
}
META

    echo "$ver"
}

# ── 列出快照 ──────────────────────────────────────────────────
cmd_list() {
    if [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        warn "没有任何快照。运行: revive.sh snapshot"
        return 0
    fi

    echo -e "\n${BLUE}📦 可用快照（从新到旧）:${RESET}\n"
    printf "%-22s %-40s %s\n" "版本" "备注" "OpenClaw版本"
    printf "%-22s %-40s %s\n" "--------------------" "--------------------------------------" "------------"

    for dir in $(ls -1 "$BACKUP_DIR" | sort -r); do
        meta="$BACKUP_DIR/$dir/meta.json"
        if [ -f "$meta" ]; then
            note=$(python3 -c "import json; d=json.load(open('$meta')); print(d.get('note','')[:38])" 2>/dev/null || echo "")
            ocver=$(python3 -c "import json; d=json.load(open('$meta')); print(d.get('openclaw_version','?'))" 2>/dev/null || echo "?")
            printf "%-22s %-40s %s\n" "$dir" "$note" "$ocver"
        else
            printf "%-22s %-40s %s\n" "$dir" "(无元数据)" "?"
        fi
    done
    echo ""
}

# ── 回退版本 ──────────────────────────────────────────────────
cmd_restore() {
    local ver="${1:-}"
    if [ -z "$ver" ]; then
        err "请指定版本名，例如: revive.sh restore 20260303-142500"
        cmd_list
        exit 1
    fi

    local src="$BACKUP_DIR/$ver/openclaw.json"
    if [ ! -f "$src" ]; then
        err "找不到版本: $ver"
        cmd_list
        exit 1
    fi

    # 先保存当前状态
    info "先保存当前状态..."
    cmd_snapshot "restore前自动备份" > /dev/null

    # 执行回退
    cp "$src" "$CONFIG_FILE"
    ok "已回退到: $ver"
    echo ""
    info "运行以下命令重启 OpenClaw:"
    echo "  pkill -f 'openclaw gateway' 2>/dev/null; nohup $START_SCRIPT &"
}

# ── 安全重启 ──────────────────────────────────────────────────
cmd_restart() {
    info "准备重启 OpenClaw..."

    # 1. 自动快照
    info "快照当前配置..."
    local ver
    ver=$(cmd_snapshot "restart前自动备份")
    ok "快照保存: $ver"

    # 2. 停止现有进程
    info "停止当前进程..."
    pkill -f 'openclaw gateway' 2>/dev/null && sleep 2 || true

    # 3. 启动新进程
    info "启动 OpenClaw..."
    nohup bash "$START_SCRIPT" >> /root/openclaw.log 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"

    # 4. 等待检测是否启动成功
    info "等待 ${STARTUP_TIMEOUT}s 检测是否启动成功..."
    local elapsed=0
    local success=false
    while [ $elapsed -lt $STARTUP_TIMEOUT ]; do
        sleep 3
        elapsed=$((elapsed + 3))
        # 检测进程是否还活着
        if kill -0 $pid 2>/dev/null; then
            if pgrep -f 'openclaw gateway' > /dev/null 2>&1; then
                success=true
                break
            fi
        else
            # nohup子进程会fork，检测openclaw gateway
            if pgrep -f 'openclaw gateway' > /dev/null 2>&1; then
                success=true
                break
            fi
        fi
        echo -n "."
    done
    echo ""

    if $success; then
        ok "OpenClaw 启动成功！"
        cmd_status
    else
        err "OpenClaw 启动失败！"
        warn "可以回退到快照: revive.sh restore $ver"
        echo ""
        info "最近5行日志:"
        tail -5 /root/openclaw.log 2>/dev/null || true
        exit 1
    fi
}

# ── 状态检查 ──────────────────────────────────────────────────
cmd_status() {
    echo ""
    if pgrep -f 'openclaw gateway' > /dev/null 2>&1; then
        local pids
        pids=$(pgrep -f 'openclaw gateway' | tr '\n' ' ')
        ok "OpenClaw 正在运行 (PID: $pids)"
    else
        err "OpenClaw 未运行"
    fi

    # 最新快照
    local latest
    latest=$(ls -1 "$BACKUP_DIR" 2>/dev/null | sort -r | head -1)
    if [ -n "$latest" ]; then
        info "最新快照: $latest"
    else
        warn "暂无快照"
    fi
    echo ""
}

# ── 帮助 ──────────────────────────────────────────────────────
cmd_help() {
    cat << HELP

${CYAN}revive.sh — OpenClaw 配置版本管理${RESET}

用法:
  ${GREEN}revive.sh snapshot [备注]${RESET}      保存当前配置快照（自动命名：日期+时间）
  ${GREEN}revive.sh list${RESET}                 列出所有快照
  ${GREEN}revive.sh restore <版本名>${RESET}     回退到指定版本
  ${GREEN}revive.sh restart${RESET}              安全重启（自动快照 + 启动检测）
  ${GREEN}revive.sh status${RESET}               检查运行状态

示例:
  revive.sh snapshot "添加了discord渠道"
  revive.sh list
  revive.sh restore 20260303-142500
  revive.sh restart

快照存储位置: ${BACKUP_DIR}
HELP
}

# ── 主入口 ───────────────────────────────────────────────────
CMD="${1:-help}"
shift || true

case "$CMD" in
    snapshot) cmd_snapshot "$@" ;;
    list)     cmd_list ;;
    restore)  cmd_restore "$@" ;;
    restart)  cmd_restart ;;
    status)   cmd_status ;;
    help|--help|-h) cmd_help ;;
    *)
        err "未知命令: $CMD"
        cmd_help
        exit 1
        ;;
esac
