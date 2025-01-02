if [ `uname -m` = "arm64" ]; then
  export ZPLUG_HOME=/opt/homebrew/opt/zplug
  source $ZPLUG_HOME/init.zsh
else
  export ZPLUG_HOME=/usr/local/opt/zplug
  source $ZPLUG_HOME/init.zsh
fi

chpwd() { ls -lr }

# syntax
zplug "chrissicool/zsh-256color"
zplug "Tarrasch/zsh-colors"
# compinit 以降に読み込むようにロードの優先度を変更する
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "ascii-soup/zsh-url-highlighter"

# tools
zplug "marzocchi/zsh-notify"

zplug mafredri/zsh-async, from:github
zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme

# fh - repeat history
fh() {
  eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# fkill - kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}

#fbr - checkout git branch (including remote branches)
fbr() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
    fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# fd - cd to selected directory
fd() {
  local dir
  dir=$(find ${1:-.} -path '*/\.*' -prune \
                  -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# Set AWS PROFILE using fzf.
fpro() {
  # Select AWS PROFILE
  local selected_profile=$(aws configure list-profiles |
    grep -v "default" |
    sort |
    fzf --prompt "Select PROFILE. If press Ctrl-C, unset PROFILE. > " \
        --height 50% --layout=reverse --border --preview-window 'right:50%' \
        --preview "grep {} -A5 ~/.aws/config")

  # If the profile is not selected, unset the environment variable 'AWS_PROFILE', etc.
  if [ -z "$selected_profile" ]; then
    echo "Unset env 'AWS_PROFILE'!"
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    return
  fi

  # If a profile is selected, set the environment variable 'AWS_PROFILE'.
  echo "Set the environment variable 'AWS_PROFILE' to '${selected_profile}'!"
  export AWS_PROFILE="$selected_profile"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  
  # Check sso-session 
  local AWS_SSO_SESSION_NAME="dc-sso"  # sso-sessionの名称に変更

  check_sso_session=$(aws sts get-caller-identity 2>&1)
  if [[ "$check_sso_session" == *"Token has expired"* ]]; then
    # If the session has expired, log in again.
    echo -e "\n----------------------------\nYour Session has expired! Please login...\n----------------------------\n"
    aws sso login --sso-session "${AWS_SSO_SESSION_NAME}"
    aws sts get-caller-identity
  else
    # Display account information upon successful login, and show an error message upon login failure.
    echo ${check_sso_session}
  fi
}

connect_bastion() {
  local name=$1
  # ホストを取得
  local config_result=$(parse_bastion_config "$name")
  if [ -z "$config_result" ]; then
    echo "設定が見つかりません: $name"
    return 1
  fi
  
  local bastion_host=$(echo "$config_result" | awk -F, '{print $2}')
  local bastion_profile=$(echo "$config_result" | awk -F, '{print $3}')
  local bastion_port=$(echo "$config_result" | awk -F, '{print $4}')
  
  start_bastion_session "$bastion_profile" "$bastion_host" "$bastion_port"
}

function parse_bastion_config() {
    local name=$1
    awk -v name="$name" '
        BEGIN { ORS="" }  # 出力レコードセパレータを空文字に設定
        /^Host / {
            host=$2
        }
        /Hostname/ {
            hostname=$2
        }
        /AwsProfile/ {
            profile=$2
        }
        /Port/ {
            port=$2
            if (tolower(host) == tolower(name)) {
                printf "%s,%s,%s,%s", host, hostname, profile, port
            }
        }
    ' ~/.bastion/config
}

## AWS EC2 Bastion
function start_bastion_session() {
    local profile=$1 # aws profile
    local host=$2 # db host
    local port=$3 # local port

    AWS_EC2_BASTION_ID=$(
        aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=*bastion*" \
                      "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" \
            --output text \
            --profile "$profile"
    )
    aws ssm start-session \
        --profile "$profile" \
        --target $AWS_EC2_BASTION_ID \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters '{
            "portNumber":["5432"],
            "localPortNumber":["'"$port"'"],
            "host":["'"$host"'"]
        }'
}

fbas() {
    local bastion_host=$(cat ~/.bastion/config |
        grep -i ^host |
        awk '{print $2}' |
        fzf --prompt "Select Bastion Host. > " \
          --height 50% --layout=reverse --border --preview-window 'right:50%' \
        --preview "grep {} -A2 ~/.bastion/config")

    if [ "$bastion_host" = "" ]; then
        # ex) Ctrl-C.
        return 1
    fi
    connect_bastion ${bastion_host}
}

if [ -n "$LS_COLORS" ]; then
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
fi

if [ -f ~/.dircolors ]; then
    if type dircolors > /dev/null 2>&1; then
        eval $(dircolors ~/.dircolors)
    elif type gdircolors > /dev/null 2>&1; then
        eval $(gdircolors ~/.dircolors)
    fi
fi

# 未インストール項目をインストールする
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load

if [ `uname -m` = "arm64" ]; then
  export ANYENV_ROOT="$HOME/.anyenv"
  path=(
    $ANYENV_ROOT/bin(N-/)
    $path
  )
  eval "$(anyenv init -)"
else
  export ANYENV_ROOT="$HOME/.anyenv_x64"
  path=(
    $ANYENV_ROOT/bin(N-/)
    $path
  )
  eval "$(anyenv init -)"
fi


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
