# テスト用の共通処理。
#
# macOS 標準の bash 3.2 でも動かすため、配列や連想配列などは使わず POSIX sh に留める。
# 各スイートは test/run から source されるので、集計はここの変数に溜まる。

PASSED=0
FAILED=0
SKIPPED=0
FAILURES=""

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_OK=$(printf '\033[32m')
    C_NG=$(printf '\033[31m')
    C_SKIP=$(printf '\033[33m')
    C_HEAD=$(printf '\033[1m')
    C_OFF=$(printf '\033[0m')
else
    C_OK=""
    C_NG=""
    C_SKIP=""
    C_HEAD=""
    C_OFF=""
fi

suite() {
    printf '\n%s== %s%s\n' "$C_HEAD" "$1" "$C_OFF"
}

ok() {
    PASSED=$((PASSED + 1))
    printf '  %sok%s   %s\n' "$C_OK" "$C_OFF" "$1"
}

fail() {
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}
  - $1"
    printf '  %sFAIL%s %s\n' "$C_NG" "$C_OFF" "$1"
    if [ -n "${2:-}" ]; then
        printf '%s\n' "$2" | sed 's/^/         /'
    fi
}

skip() {
    SKIPPED=$((SKIPPED + 1))
    printf '  %sskip%s %s (%s)\n' "$C_SKIP" "$C_OFF" "$1" "${2:-理由なし}"
}

# コマンドを実行し、終了コード 0 なら ok。失敗したら出力を添えて FAIL
check() {
    description=$1
    shift
    if output=$("$@" 2>&1); then
        ok "$description"
    else
        fail "$description" "$output"
    fi
}

have() {
    command -v "$1" > /dev/null 2>&1
}

# コミットされているバイナリ (bin/cpdf など) をスクリプト向けの検査から外すため
is_binary() {
    if have file; then
        case $(file -b --mime-encoding "$1" 2> /dev/null) in
            binary) return 0 ;;
        esac
    fi
    return 1
}

assert_symlink_to() {
    description=$1
    link=$2
    want=$3
    if [ ! -L "$link" ]; then
        fail "$description" "シンボリックリンクではない: $link"
        return
    fi
    got=$(readlink "$link")
    if [ "$got" = "$want" ]; then
        ok "$description"
    else
        fail "$description" "リンク先が違う: $got (期待: $want)"
    fi
}

assert_missing() {
    description=$1
    path=$2
    if [ -e "$path" ] || [ -L "$path" ]; then
        fail "$description" "存在してはいけないものがある: $path"
    else
        ok "$description"
    fi
}

summary() {
    printf '\n%s== 結果%s\n' "$C_HEAD" "$C_OFF"
    printf '  成功 %d / 失敗 %d / スキップ %d\n' "$PASSED" "$FAILED" "$SKIPPED"
    if [ "$FAILED" -gt 0 ]; then
        printf '%s失敗した項目:%s%s\n' "$C_NG" "$C_OFF" "$FAILURES"
        return 1
    fi
    return 0
}
