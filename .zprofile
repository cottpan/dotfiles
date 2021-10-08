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
alias ls='exa'
alias ll='exa -ahl --git'
# If you set the alias of `cat` to `bat`, the function to display the branch name will not work.
# alias cat='bat'
alias gip='curl ifconfig.io/all'

export PATH="$HOME/.cargo/bin:$PATH"
eval "$(/opt/homebrew/bin/brew shellenv)"

export PYENV_ROOT="$HOME/.anyenv/envs/pyenv"
# export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"