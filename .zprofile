# 補完機能
autoload -U compinit
compinit

# prompt
PROMPT='%m:%c %n$ '

# コマンド履歴
HISTFILE=~/.zsh_history
HISTSIZE=6000000
SAVEHIST=6000000
setopt hist_ignore_dups     # ignore duplication command history list
setopt share_history        # share command history data

# コマンド履歴検索
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# alias
alias diff="colordiff"
# If you set the alias of `cat` to `bat`, the function to display the branch name will not work.
# alias cat='bat'
alias gip='curl ifconfig.io/all'

# Homebrew。置き場所は環境ごとに違い (Apple Silicon / Intel / Linuxbrew)、
# Linux では入っていないこともあるので、実際にあるものを使う。
# アーキテクチャで振り分けると、Linux が Intel Mac のパスを掴んで毎回エラーになる
for brew_candidate in \
  /opt/homebrew/bin/brew \
  /usr/local/bin/brew \
  /home/linuxbrew/.linuxbrew/bin/brew \
  "$HOME/.linuxbrew/bin/brew"
do
  if [ -x "$brew_candidate" ]; then
    eval "$("$brew_candidate" shellenv)"
    break
  fi
done
unset brew_candidate
