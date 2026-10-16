#!/usr/bin/env bash
# Claude Code status line — reads JSON from stdin, outputs a compact right-aligned bar.

input=$(cat)

# ── helpers ───────────────────────────────────────────────────────
# Colored pressure gauge: "PREFIX ███░░ 42%"; green < 70, yellow < 90, red ≥ 90.
gauge() {
    local prefix="$1" pct="$2" seg=10 fill empty bar color i
    fill=$(( (pct * seg + 50) / 100 ))
    [ "$fill" -lt 0 ] && fill=0
    [ "$fill" -gt "$seg" ] && fill=$seg
    empty=$(( seg - fill ))
    bar=""
    for ((i=0; i<fill; i++)); do bar="${bar}█"; done
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    if   [ "$pct" -ge 90 ]; then color=$(tput setaf 1 2>/dev/null)
    elif [ "$pct" -ge 70 ]; then color=$(tput setaf 3 2>/dev/null)
    else                          color=$(tput setaf 2 2>/dev/null); fi
    printf '%s%s %s %s%%' "$color" "$prefix" "$bar" "$pct"
    tput sgr0 2>/dev/null
}

# Effort level → green (lowest) to red (highest) gradient.
effort_color() {
    case "$1" in
      low)    tput setaf 2 2>/dev/null ;;
      medium) tput setaf 3 2>/dev/null ;;
      high)   printf '%s%s' "$(tput bold 2>/dev/null)" "$(tput setaf 3 2>/dev/null)" ;;
      xhigh)  tput setaf 1 2>/dev/null ;;
      max)    printf '%s%s' "$(tput bold 2>/dev/null)" "$(tput setaf 1 2>/dev/null)" ;;
      *)      tput setaf 2 2>/dev/null ;;
    esac
}

# ── model & effort ────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

effort_file="$HOME/.claude/settings.json"
effort=""
if [ -f "$effort_file" ]; then
    effort=$(jq -r '[.modelSettings[]?.effortLevel] | map(select(. != null)) | first // empty' "$effort_file" 2>/dev/null)
fi

# ── context window ────────────────────────────────────────────────
WINDOW=${CLAUDE_CODE_AUTO_COMPACT_WINDOW:-$(echo "$input" | jq -r '.context_window.context_window_size // 200000')}

HAS_TOKENS=$(echo "$input" | jq -r '(.context_window.current_usage.input_tokens // 0) > 0')
USED=$(echo "$input" | jq -r '
  .context_window.current_usage
  | if . == null then 0
    else (.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens)
    end')

# Context window fullness vs the auto-compact window (CTX 100% == /compact time).
CTXPCT=""
[ "$HAS_TOKENS" = "true" ] && CTXPCT=$(gauge "CTX" "$(awk -v u="$USED" -v w="$WINDOW" 'BEGIN { printf "%d", u * 100 / w }')")

# ── system memory usage (macOS) ───────────────────────────────────
# Approximate "in use" = active + wired + compressed, as a % of total RAM.
# Excludes cached file pages, so it reflects real pressure (relevant when a
# large ollama model like qwen is loaded). Falls back to empty on non-macOS.
MEMPCT=""
if command -v vm_stat >/dev/null 2>&1; then
    _vm=$(vm_stat 2>/dev/null)
    _page=$(printf '%s\n' "$_vm" | head -1 | sed -E 's/.*of ([0-9]+) bytes.*/\1/')
    _active=$(printf '%s\n' "$_vm" | awk '/^Pages active:/{v=$NF; sub(/\.$/,"",v); print v}')
    _wired=$(printf '%s\n' "$_vm" | awk '/^Pages wired down:/{v=$NF; sub(/\.$/,"",v); print v}')
    _comp=$(printf '%s\n' "$_vm" | awk '/^Pages occupied by compressor:/{v=$NF; sub(/\.$/,"",v); print v}')
    _total=$(sysctl -n hw.memsize 2>/dev/null)
    if [ -n "$_page" ] && [ -n "$_total" ] && [ -n "$_active" ]; then
        _used=$(( ($_active + $_wired + $_comp) * _page ))
        _pct=$(( _used * 100 / _total ))
        MEMPCT=$(gauge "MEM" "$_pct")
    fi
fi

# ── git branch & dirty indicator ──────────────────────────────────
branch=""
dirty="*"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ -n "$branch" ]; then
        dirty=$(git status --porcelain 2>/dev/null | head -1)
        # Keep '*' only if there are uncommitted changes
        if [ -z "$dirty" ]; then
            dirty=""
        fi
    else
        dirty=""
    fi
else
    branch=""
    dirty=""
fi

# ── middle: model, effort, percentage (bracketed) ─────────────────
middle_parts=()
[ -n "$model" ] && middle_parts+=("$model")
if [ -n "$effort" ]; then
    _eu=$(echo "$effort" | tr '[:lower:]' '[:upper:]')
    _ec=$(effort_color "$effort")
    middle_parts+=("${_ec}${_eu}"$(tput sgr0 2>/dev/null))
fi
[ -n "$CTXPCT" ] && middle_parts+=("$CTXPCT")
[ -n "$MEMPCT" ] && middle_parts+=("$MEMPCT")

middle=""
if [ ${#middle_parts[@]} -gt 0 ]; then
    for p in "${middle_parts[@]}"; do
        [ -z "$middle" ] && middle="$p" || middle="${middle} │ $p"
    done
    middle="[ $middle ]"
fi

# ── build right-side content ──────────────────────────────────────
right=""
[ -n "$middle" ] && right="$middle"

git_suffix=""
if [ -n "$branch" ]; then
    if [ -n "$dirty" ]; then
        git_suffix="${branch}*"
    else
        git_suffix="${branch}"
    fi
fi

# ── left side: path ───────────────────────────────────────────────
left="$(pwd | sed "s|^$HOME|~|")"

# ── render (middle bright, everything else dimmed) ─────────────────
dim="$(tput dim)"
sgr0="$(tput sgr0)"

output=""
[ -n "$left" ] && output="${dim}${left}"

if [ -n "$middle" ]; then
    [ -n "$left" ] && output="${output} "
    output="${output}${sgr0}${middle}"  # sgr0 cancels dim so middle is bright
fi

if [ -n "$git_suffix" ]; then
    ([ -n "$left" ] || [ -n "$middle" ]) && output="${output} "
    output="${output}${dim}${git_suffix}"  # re-dim for git suffix
fi

[ -n "$output" ] && printf "%s${sgr0}\n" "$output"
