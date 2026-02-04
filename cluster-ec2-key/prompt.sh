# ===============================
# Custom Bash Prompt (Git-aware, Compressed Path, Colors)
# ===============================

# --- Colors (Tokyonight Night) ---
RESET="\e[0m"
BOLD="\e[1m"
BLUE="\e[38;2;122;162;247m"   # main blue
CYAN="\e[38;2;125;207;255m"   # secondary blue
GRAY="\e[38;2;156;163;175m"   # gray for path
GREEN="\e[38;2;158;206;106m"  # clean branch
YELLOW="\e[38;2;249;196;83m"  # staged only
RED="\e[38;2;247;118;142m"    # dirty

# --- Git branch helper with colors ---
git_branch_colored() {
  local branch
  branch=$(git branch --show-current 2>/dev/null) || return

  local staged unstaged
  staged=$(git diff --cached --name-only 2>/dev/null)
  unstaged=$(git diff --name-only 2>/dev/null)

  if [[ -n $unstaged ]]; then
    # dirty (unstaged changes)
    echo -e "${RED}${branch}${CYAN}"
  elif [[ -n $staged ]]; then
    # staged only
    echo -e "${YELLOW}${branch}${CYAN}"
  else
    # clean
    echo -e "${GREEN}${branch}${CYAN}"
  fi
}

# --- Compress path: /h/w/.../current ---
compress_pwd() {
  local dir="${PWD/#$HOME/~}"

  [[ "$dir" == "~" ]] && { echo "~"; return; }

  IFS='/' read -ra parts <<< "$dir"
  local last="${parts[-1]}"
  local out=""

  for ((i=0; i<${#parts[@]}-1; i++)); do
    [[ -n "${parts[i]}" ]] && out+="/${parts[i]:0:1}"
  done

  echo "${out}/${last}"
}

# --- PS1 Prompt ---
PS1="\n\[\e[38;2;122;162;247m\]╭─ \[\e[38;2;158;206;106m\]\u@\h \[\e[38;2;156;163;175m\]\$(compress_pwd) \[\e[38;2;125;207;255m\] \$(git_branch_colored)\[\e[0m\]\n\[\e[38;2;122;162;247m\]╰─➤ \[\e[0m\]"
