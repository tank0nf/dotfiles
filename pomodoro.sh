#!/bin/bash

# Colors
BLUE='\033[1;34m'
RESET='\033[0m'

# Parse args
goal=""
duration=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--goal)
            goal="$2"
            shift 2
            ;;
        *)
            duration="$1"
            shift
            ;;
    esac
done

# Usage check
[[ -z "$duration" ]] && {
    echo "Usage: $0 [-g \"your goal\"] <duration>"
    echo "Example: $0 -g \"Write blog\" 25m"
    exit 1
}

if [[ "$duration" =~ ^([0-9]+)(m|hr)$ ]]; then
    value="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]}"
else
    echo "Invalid duration. Use format like 25m or 1hr."
    exit 1
fi

[[ "$unit" == "m" ]] && total_seconds=$((value * 60)) || total_seconds=$((value * 3600))

# Hide cursor and setup cleanup
tput civis
cleanup() {
    tput cnorm
    tput rmcup
    exit
}
trap cleanup INT

# Use alternate screen
tput smcup

# ASCII digits
declare -A digits=(
["0"]=" ███ \n█   █\n█   █\n█   █\n ███ "
["1"]="  █  \n ██  \n  █  \n  █  \n ███ "
["2"]=" ███ \n█   █\n  ██ \n █   \n█████"
["3"]="████ \n    █\n ███ \n    █\n████ "
["4"]="   ██\n  █ █\n █  █\n█████\n    █"
["5"]="█████\n█    \n████ \n    █\n████ "
["6"]=" ███ \n█    \n████ \n█   █\n ███ "
["7"]="█████\n    █\n   █ \n  █  \n  █  "
["8"]=" ███ \n█   █\n ███ \n█   █\n ███ "
["9"]=" ███ \n█   █\n ████\n    █\n ███ "
[":"]="     \n  █  \n     \n  █  \n     "
)

# Function to draw static layout
draw_static_layout() {
    read -r rows cols < <(stty size)
    box_height=7
    box_width=43
    start_row=$(( (rows - box_height) / 2 ))
    start_col=$(( (cols - box_width) / 2 ))

    tput cup "$start_row" "$start_col"
    echo -e "${BLUE}+$(printf '%0.s-' $(seq 1 $((box_width - 2))))+${RESET}"

    for i in {1..5}; do
        tput cup $((start_row + i)) "$start_col"
        printf "${BLUE}|%*s|${RESET}\n" $((box_width - 2)) ""
    done

    tput cup $((start_row + 6)) "$start_col"
    echo -e "${BLUE}+$(printf '%0.s-' $(seq 1 $((box_width - 2))))+${RESET}"

    if [[ -n "$goal" ]]; then
        tput cup $((start_row + 8)) $(( (cols - ${#goal} - 7) / 2 ))
        echo -e "Goal:  $goal"
    fi
}

# Function to print the time inside the box
print_time() {
    local time_str="$1"
    local -a lines=("" "" "" "" "")

    for ((i=0; i<${#time_str}; i++)); do
        char="${time_str:$i:1}"
        IFS=$'\n' read -rd '' -a char_lines <<< "$(echo -e "${digits[$char]}")"
        for j in {0..4}; do
            lines[$j]+="${char_lines[$j]}  "
        done
    done

    local print_row=$((start_row + 1))
    for j in {0..4}; do
        tput cup $((print_row + j)) $((start_col + 2))
        printf "%s" "${lines[$j]}"
    done
}

# Draw box once
clear
draw_static_layout

# Timer loop
paused=false

while (( total_seconds >= 0 )); do
    if ! $paused; then
        mins=$((total_seconds / 60))
        secs=$((total_seconds % 60))
        time_str=$(printf "%02d:%02d" "$mins" "$secs")
        print_time "$time_str"
        ((total_seconds--))
    fi

    read -t 1 -n 1 key
    if [[ "$key" == "q" || "$key" == "Q" ]]; then
        break
    elif [[ "$key" == $'\x0c' ]]; then  # Ctrl+L
        clear
        draw_static_layout
    elif [[ "$key" == "p" || "$key" == "P" ]]; then
        if $paused; then
	    paused=false
	else
	    paused=true
	fi
    fi
done

# Final display
print_time " DONE"
sleep 2
cleanup
