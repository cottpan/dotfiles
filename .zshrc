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

# Load custom functions from .zsh/functions directory
if [ -d "$HOME/.zsh/functions" ]; then
  for func_file in $HOME/.zsh/functions/*; do
    source "$func_file"
  done
fi

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
            --profile "$profile" | head -1
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

eval "$(mise activate zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
