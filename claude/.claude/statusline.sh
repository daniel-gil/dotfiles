#!/usr/bin/env bash
# Claude Code status line — reads JSON from stdin, prints one compact line:
#   <dir> [ <model> │ <EFFORT> │ CTX ███░░ 42% │ MEM ███░░ 61% ] <branch>[*]
# Compatible with bash 3.2 (default macOS /bin/bash).

input=$(cat)

# ── colours (raw ANSI: no dependency on a TERM/terminfo being set) ──
RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
ORANGE=$RED   # fallback when the terminal doesn't advertise 256 colours
case "${TERM:-}${COLORTERM:-}" in
    *256color*|*truecolor*|*24bit*) ORANGE=$'\033[38;5;208m' ;;
esac

# ── helpers ───────────────────────────────────────────────────────
# Colored pressure gauge: "PREFIX ███░░ 42%"; green < 70, yellow < 90, red ≥ 90.
gauge() {
    local prefix="$1" pct="$2" seg=10 fill empty bar="" color i
    [[ "$pct" =~ ^[0-9]+$ ]] || return 1
    fill=$(( (pct * seg + 50) / 100 ))
    [ "$fill" -gt "$seg" ] && fill=$seg
    empty=$(( seg - fill ))
    for ((i=0; i<fill; i++));  do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    if   [ "$pct" -ge 90 ]; then color=$RED
    elif [ "$pct" -ge 70 ]; then color=$YELLOW
    else                         color=$GREEN; fi
    printf '%s%s %s %s%%%s' "$color" "$prefix" "$bar" "$pct" "$RESET"
}

# Effort level → green (lowest) to red (highest) gradient.
effort_color() {
    case "$1" in
      low)    printf '%s' "$GREEN" ;;
      medium) printf '%s' "$YELLOW" ;;
      high)   printf '%s' "$ORANGE" ;;
      xhigh)  printf '%s' "$RED" ;;
      max)    printf '%s%s' "$BOLD" "$RED" ;;
      *)      printf '%s' "$RESET" ;;
    esac
}

# ── working directory (use the session's, not the script's) ───────
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -n "$dir" ] && [ -d "$dir" ] && cd "$dir" 2>/dev/null
dir=$(pwd)

# ── model & effort ────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

# Canonical source: effort.level in the statusline input (Claude Code ≥ 2.1.119).
# It reflects session-only changes (e.g. /effort max), unlike settings.json.
# If the field is absent (older version, non-Anthropic model), nothing is shown.
effort=$(echo "$input" | jq -r '.effort.level // empty')

# ── context window ────────────────────────────────────────────────
WINDOW=${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-$(echo "$input" | jq -r '.context_window.context_window_size // 200000')}
[[ "$WINDOW" =~ ^[0-9]+$ ]] || WINDOW=200000

USED=$(echo "$input" | jq -r '
  .context_window.current_usage
  | if . == null then 0
    else ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
    end')
[[ "$USED" =~ ^[0-9]+$ ]] || USED=0

# Fullness vs the window (CTX 100% ≈ compaction time when the override is set).
CTXPCT=""
if [ "$USED" -gt 0 ] && [ "$WINDOW" -gt 0 ]; then
    CTXPCT=$(gauge "CTX" $(( USED * 100 / WINDOW )))
fi

# ── system memory usage (macOS) ───────────────────────────────────
# Approximate "in use" = active + wired + compressed, as a % of total RAM.
# Excludes cached file pages, so it reflects real pressure (relevant when a
# large ollama model like qwen is loaded). Empty on non-macOS.
MEMPCT=""
if command -v vm_stat >/dev/null 2>&1; then
    _vm=$(vm_stat 2>/dev/null)
    _page=$(printf '%s\n' "$_vm" | head -1 | sed -E 's/.*of ([0-9]+) bytes.*/\1/')
    _active=$(printf '%s\n' "$_vm" | awk '/^Pages active:/{v=$NF; sub(/\.$/,"",v); print v}')
    _wired=$(printf '%s\n' "$_vm" | awk '/^Pages wired down:/{v=$NF; sub(/\.$/,"",v); print v}')
    _comp=$(printf '%s\n' "$_vm" | awk '/^Pages occupied by compressor:/{v=$NF; sub(/\.$/,"",v); print v}')
    _total=$(sysctl -n hw.memsize 2>/dev/null)
    if [[ "$_page" =~ ^[0-9]+$ ]] && [[ "$_total" =~ ^[0-9]+$ ]] && [ "$_total" -gt 0 ] \
       && [[ "$_active" =~ ^[0-9]+$ ]]; then
        _used=$(( (_active + ${_wired:-0} + ${_comp:-0}) * _page ))
        MEMPCT=$(gauge "MEM" $(( _used * 100 / _total )))
    fi
fi

# ── git branch & dirty indicator ──────────────────────────────────
branch=""
dirty=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Branch name, or short SHA when HEAD is detached.
    branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
    # --no-optional-locks: don't contend with Claude's own git commands.
    if [ -n "$(git --no-optional-locks status --porcelain 2>/dev/null | head -1)" ]; then
        dirty="*"
    fi
fi
git_suffix=""
[ -n "$branch" ] && git_suffix="${branch}${dirty}"

# ── middle: model, effort, gauges (bracketed) ─────────────────────
middle_parts=()
[ -n "$model" ] && middle_parts+=("$model")
if [ -n "$effort" ]; then
    _eu=$(echo "$effort" | tr '[:lower:]' '[:upper:]')
    middle_parts+=("$(effort_color "$effort")${_eu}${RESET}")
fi
[ -n "$CTXPCT" ] && middle_parts+=("$CTXPCT")
[ -n "$MEMPCT" ] && middle_parts+=("$MEMPCT")

middle=""
if [ ${#middle_parts[@]} -gt 0 ]; then
    for p in "${middle_parts[@]}"; do
        if [ -z "$middle" ]; then middle="$p"; else middle="${middle} │ $p"; fi
    done
    middle="[ $middle ]"
fi

# ── left side: path (~ for $HOME) ─────────────────────────────────
left="${dir/#$HOME/~}"

# ── render (middle bright, everything else dimmed) ────────────────
output=""
[ -n "$left" ] && output="${DIM}${left}${RESET}"
if [ -n "$middle" ]; then
    [ -n "$output" ] && output="${output} "
    output="${output}${middle}"
fi
if [ -n "$git_suffix" ]; then
    [ -n "$output" ] && output="${output} "
    output="${output}${DIM}${git_suffix}${RESET}"
fi

[ -n "$output" ] && printf '%s\n' "$output"
