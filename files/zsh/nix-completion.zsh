_nix() {
    local ifs_bk="$IFS"
    local input=("${(Q)words[@]}")

    IFS=$'\n'
    local res=($(NIX_GET_COMPLETIONS=$((CURRENT - 1)) "$input[@]" 2>/dev/null))
    IFS="$ifs_bk"

    local tpe="${${res[1]}%%>       *}"
    local -a suggestions args
    local suggestion

    for suggestion in ${res:1}; do
        suggestion="${suggestion%%   *}"

        # Nix expands ~/ to $HOME when generating filename
        # completions. Restore the prefix expected by zsh.
        if [[ "$words[CURRENT]" == "~/"* && "$suggestion" == "$HOME/"* ]]; then
            suggestion="${suggestion#$HOME/}"
            suggestion="~/$suggestion"
        fi

        suggestions+=("$suggestion")
    done

    if [[ "$tpe" == filenames ]]; then
        args+=('-f')
    elif [[ "$tpe" == attrs ]]; then
        args+=('-S' '')
    fi

    compadd -J nix "${args[@]}" -a suggestions
}
