# Lists all functions and the comments immediately above them,
# scanning this script and any files it sources.
help() {
    local main_script="${BASH_SOURCE[0]}"
    local -a to_scan=("$main_script")
    local -A seen=()

    # Gather all files to scan by reading "source" lines
    while read -r line; do
        if [[ "$line" =~ ^[[:space:]]*source[[:space:]]+\"?([^\"]+)\"? ]]; then
            local src="${BASH_REMATCH[1]}"
            # only add once
            if [[ -f "$src" && -z "${seen[$src]}" ]]; then
                seen["$src"]=1
                to_scan+=("$src")
            fi
        fi
    done <"$main_script"

    echo "Available functions with descriptions:"

    for script in "${to_scan[@]}"; do
        echo
        echo "---- from $(basename "$script") ----"
        local -a desc_lines=()

        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                # collect comment text (strip leading "# " or "#")
                desc_lines+=("${line#\# }")
            elif [[ "$line" =~ ^[[:space:]]*([[:alnum:]_]+)\(\)[[:space:]]*\{ ]]; then
                local func="${BASH_REMATCH[1]}"
                # print function name in bold
                echo -e "\033[1m$func\033[0m"
                if ((${#desc_lines[@]})); then
                    # print each comment line in gray
                    for dl in "${desc_lines[@]}"; do
                        echo -e "\033[90m$dl\033[0m"
                    done
                else
                    echo "  (no description)"
                fi
                echo
                desc_lines=()
            else
                # any non-comment/non-function resets
                desc_lines=()
            fi
        done <"$script"
    done
}

# apply default actions for all commands
apply_default() {
    source .env
}

# run all tests
test() {
    apply_default
    cd contracts || exit
    forge test
}

# deploy contracts
deploy() {
    apply_default
    cd contracts || exit

    if [ -z "$PRIVATE_KEY" ]; then
        echo "Expected Private Key"
        exit 1
    fi

    if [ -z "$RPC_URL" ]; then
        echo "Expected RPC Url"
        exit 1
    fi

    forge script ./script/SubchainRegistry.sol:DeploySubchain --broadcast --private-key="$PRIVATE_KEY" --rpc-url="$RPC_URL"
}

"$1" "$2"
