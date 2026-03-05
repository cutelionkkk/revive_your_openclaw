<h1 align="center">🔄 revive_your_openclaw</h1>

<p align="center">
  <strong>OpenClaw Config Version Control + Safe Restart<br>Broke something? Roll back to any previous working version in one command.</strong>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Shell-Bash_4+-green.svg?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash 4+">
  <img src="https://img.shields.io/badge/Platform-Linux_macOS-lightgrey.svg?style=for-the-badge" alt="Platform">
  <a href="https://github.com/cutelionkkk/revive_your_openclaw/stargazers"><img src="https://img.shields.io/github/stars/cutelionkkk/revive_your_openclaw?style=for-the-badge" alt="GitHub Stars"></a>
</p>

<p align="center">
  <b>English</b> | <a href="README.md">中文</a>
</p>

<p align="center">
  <a href="#one-liner-for-openclaw">OpenClaw Command</a> · <a href="#quick-start">Quick Start</a> · <a href="#usage">Usage</a> · <a href="#workflow">Workflow</a> · <a href="#configuration">Configuration</a>
</p>

---

## One-liner for OpenClaw

**If you're an OpenClaw user**, just send this to your OpenClaw agent and it will install everything automatically:

```
Install revive_your_openclaw: https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/docs/agent-guide.md
```

Your agent will: download `revive.sh`, save the first snapshot, and tell you how to use it going forward.

---

## Why You Need This

Editing `openclaw.json` is the most common way to break OpenClaw. When that happens:

- 🔴 Gateway fails to start, service goes down
- 😨 You don't know which change caused it
- 🔍 No version history to compare or revert
- 😤 Stuck manually debugging or restoring from a backup you may not have

`revive.sh` solves this: every time OpenClaw starts successfully, it automatically saves a snapshot. When something breaks, you're three commands away from recovery.

> ⭐ **Star this project** — if you're running OpenClaw, this is the easiest safety tool to add.

### ✅ What You Should Know

| | |
|---|---|
| 🔗 **Single file** | The entire tool is one `revive.sh`. Download and `chmod +x`. |
| 📸 **Auto-versioned** | Snapshot names are `YYYYMMDD-HHMMSS` (e.g. `20260303-142500`) — always easy to read |
| ⏪ **Instant rollback** | `revive restore <version>` — that's it |
| 🔄 **Safe restart** | `revive restart`: snapshot → stop → start → verify → alert on failure |
| 🗒️ **Notes support** | Add a note when snapshotting: `revive snapshot "before adding feishu channel"` |
| 🧩 **Skills included** | Snapshots back up your `~/.openclaw/skills/` directory too — broken skills, broken installs, all covered |
| ⚙️ **Configurable** | Override all paths via environment variables |

---

## Quick Start

```bash
# 1. Download
curl -o /usr/local/bin/revive https://raw.githubusercontent.com/cutelionkkk/revive_your_openclaw/main/revive.sh
chmod +x /usr/local/bin/revive

# 2. Save your first snapshot
revive snapshot "initial snapshot"

# 3. Check it
revive list
```

---

## Usage

```
revive <command> [args]
```

| Command | Description |
|---------|-------------|
| `snapshot [note]` | Save a snapshot of current config + skills |
| `list` | List all snapshots (newest first) |
| `restore <version>` | Roll back to a version (auto-saves current state first) |
| `diff <versionA> [versionB]` | Compare two versions, or a version vs current |
| `clean [N]` | Delete old snapshots, keep newest N (default: 10) |
| `restart` | Safe restart: snapshot → stop → start → verify |
| `status` | Check if OpenClaw is running + snapshot count |

---

### snapshot

```bash
revive snapshot                         # no note
revive snapshot "before adding webhook"
revive snapshot "before upgrading to 2026.3.1"
```

Snapshot names are auto-generated timestamps: `20260303-142500`.

---

### list

```bash
revive list
```

Output:

```
📦 Available snapshots (newest first):

Version                Skills   Note                                 OpenClaw
--------------------   -------  -----------------------------------  ------------
20260303-152300        ✅       startup auto-snapshot                2026.3.1
20260303-142500        ✅       before adding feishu channel         2026.3.1
20260227-091500        —        initial snapshot                     2026.2.27
```

The `Skills` column shows `✅` if the snapshot includes a skills backup.

---

### restore

```bash
revive restore 20260303-142500
```

> ⚠️ The current state is auto-saved before restoring — no data loss.

Then restart OpenClaw:

```bash
pkill -f 'openclaw gateway'
nohup /root/start_openclaw.sh &
```

---

### restart

```bash
revive restart
```

Flow:

```
1. Auto-snapshot current config
2. Stop existing openclaw gateway process
3. Start new process via start_openclaw.sh
4. Wait up to 15s for startup confirmation
5a. ✅ Success → show status
5b. ❌ Failure → suggest restore command + show recent logs
```

---

### diff

```bash
revive diff 20260303-110000            # compare to current
revive diff 20260303-110000 20260227-091500  # compare two versions
```

---

## Workflow

### Everyday config changes

```
Edit openclaw.json
       ↓
revive restart        ← auto-snapshot + restart + verify
       ↓
   Started OK?
  ✅ Yes → done
  ❌ No  → revive list
           revive restore <version>
           pkill -f 'openclaw gateway'
           nohup /root/start_openclaw.sh &
```

### Before upgrading OpenClaw

```bash
revive snapshot "before upgrade to v2026.4.0"
npm update -g openclaw
# if things break:
revive list
revive restore 20260303-110000
```

---

## Snapshot Storage

Default: `/root/.openclaw/revive-backups/`

Each snapshot contains:

```
revive-backups/
└── 20260303-142500/
    ├── openclaw.json       ← config backup
    ├── skills/             ← full skills directory backup
    ├── start_openclaw.sh   ← startup script backup (if exists)
    └── meta.json           ← metadata
```

`meta.json`:

```json
{
  "version": "20260303-142500",
  "note": "before adding feishu channel",
  "timestamp": "2026-03-03T14:25:00+08:00",
  "config_file": "/root/.openclaw/openclaw.json",
  "skills_dir": "/root/.openclaw/skills",
  "skills": "agent-reach,browser-use,find-skills",
  "openclaw_version": "2026.3.1"
}
```

---

## Configuration

Override defaults via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_BACKUP_DIR` | `/root/.openclaw/revive-backups` | Snapshot storage directory |
| `OPENCLAW_CONFIG` | `/root/.openclaw/openclaw.json` | Config file path |
| `OPENCLAW_SKILLS_DIR` | `/root/.openclaw/skills` | Skills directory path |
| `OPENCLAW_START_SCRIPT` | `/root/start_openclaw.sh` | Startup script path |

---

## FAQ

<details>
<summary><strong>Rolled back but OpenClaw still won't start?</strong></summary>

The config rollback is fine but the OpenClaw binary itself may have an issue. Try:

```bash
tail -50 /root/openclaw.log
npm install -g openclaw   # reinstall
```

`revive.sh` manages config and skills only, not the npm package itself.

</details>

<details>
<summary><strong>Too many snapshots — how do I clean up?</strong></summary>

```bash
revive clean 5    # keep only the newest 5
```

</details>

<details>
<summary><strong>Can I back up more than just openclaw.json?</strong></summary>

Yes — skills are now backed up automatically. If you want to back up more (e.g. credentials, custom scripts), edit the `cmd_snapshot` function in `revive.sh` and add a `cp` line.

</details>

---

## Requirements

- **Bash** 4.0+ (standard on Linux/macOS)
- **OpenClaw** installed (`openclaw --version` works)
- **Python 3** (optional, for snapshot metadata display)

---

## Roadmap

- [x] snapshot / list / restore / restart / status ✅
- [x] Skills directory backup + restore ✅
- [x] Auto-snapshot on successful startup ✅
- [ ] `revive clean --keep N`
- [ ] `revive diff <A> <B>` — config diff between two versions ✅
- [ ] `revive export <version>` — export snapshot as archive

---

## License

[MIT](LICENSE)
