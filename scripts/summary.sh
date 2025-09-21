#!/bin/bash

#==============================================================================
#
#    Copyright (C) 2025 Robert Lindley
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#==============================================================================

# Summary collection script for GitHub Action
# This script collects execution details and generates structured summaries

set -euo pipefail

# Source utility functions
# shellcheck source=./utils.sh
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Summary data structure
declare -A SUMMARY_DATA
SUMMARY_DATA["start_time"]=""
SUMMARY_DATA["end_time"]=""
SUMMARY_DATA["execution_time"]=""
SUMMARY_DATA["status"]="running"
SUMMARY_DATA["inputs"]=""
SUMMARY_DATA["outputs"]=""
SUMMARY_DATA["events"]=""
SUMMARY_DATA["warnings"]=""
SUMMARY_DATA["errors"]=""

# Event tracking arrays
declare -a EVENTS
declare -a WARNINGS
declare -a ERRORS

# Initialize summary collection
init_summary() {
    SUMMARY_DATA["start_time"]="$(get_timestamp)"
    log_info "summary" "Initialized summary collection"
}

# Record an event
record_event() {
    local category="$1"
    local message="$2"
    local metadata="${3:-}"

    local timestamp
    timestamp=$(get_timestamp)

    local event="{\"timestamp\":\"${timestamp}\",\"category\":\"${category}\",\"message\":\"${message//\"/\\\"}\",\"metadata\":\"${metadata//\"/\\\"}\"}"
    EVENTS+=("$event")

    log_debug "summary" "Recorded event: ${category} - ${message}"
}

# Record a warning
record_warning() {
    local category="$1"
    local message="$2"
    local metadata="${3:-}"

    local timestamp
    timestamp=$(get_timestamp)

    local warning="{\"timestamp\":\"${timestamp}\",\"category\":\"${category}\",\"message\":\"${message//\"/\\\"}\",\"metadata\":\"${metadata//\"/\\\"}\"}"
    WARNINGS+=("$warning")

    log_debug "summary" "Recorded warning: ${category} - ${message}"
}

# Record an error
record_error() {
    local category="$1"
    local message="$2"
    local metadata="${3:-}"

    local timestamp
    timestamp=$(get_timestamp)

    local error="{\"timestamp\":\"${timestamp}\",\"category\":\"${category}\",\"message\":\"${message//\"/\\\"}\",\"metadata\":\"${metadata//\"/\\\"}\"}"
    ERRORS+=("$error")

    log_debug "summary" "Recorded error: ${category} - ${message}"
}

# Set input data
set_summary_input() {
    local key="$1"
    local value="$2"

    if [[ -z "${SUMMARY_DATA["inputs"]}" ]]; then
        SUMMARY_DATA["inputs"]="{\"${key}\":\"${value//\"/\\\"}\"}"
    else
        # Remove trailing } and add new key-value pair
        local current="${SUMMARY_DATA["inputs"]}"
        current="${current%?},\"${key}\":\"${value//\"/\\\"}\"}"
        SUMMARY_DATA["inputs"]="$current"
    fi
}

# Set output data
set_summary_output() {
    local key="$1"
    local value="$2"

    if [[ -z "${SUMMARY_DATA["outputs"]}" ]]; then
        SUMMARY_DATA["outputs"]="{\"${key}\":\"${value//\"/\\\"}\"}"
    else
        # Remove trailing } and add new key-value pair
        local current="${SUMMARY_DATA["outputs"]}"
        current="${current%?},\"${key}\":\"${value//\"/\\\"}\"}"
        SUMMARY_DATA["outputs"]="$current"
    fi
}

# Finalize summary
finalize_summary() {
    local final_status="${1:-success}"

    SUMMARY_DATA["end_time"]="$(get_timestamp)"
    SUMMARY_DATA["status"]="$final_status"

    # Calculate execution time
    if [[ -n "${SUMMARY_DATA["start_time"]}" && -n "${SUMMARY_DATA["end_time"]}" ]]; then
        local start_seconds
        local end_seconds
        start_seconds=$(date -d "${SUMMARY_DATA["start_time"]}" +%s 2>/dev/null || echo "0")
        end_seconds=$(date -d "${SUMMARY_DATA["end_time"]}" +%s 2>/dev/null || echo "0")

        if [[ $start_seconds -gt 0 && $end_seconds -gt 0 ]]; then
            SUMMARY_DATA["execution_time"]="$((end_seconds - start_seconds))"
        fi
    fi

    # Convert arrays to JSON
    SUMMARY_DATA["events"]="[$(IFS=,; echo "${EVENTS[*]}")]"
    SUMMARY_DATA["warnings"]="[$(IFS=,; echo "${WARNINGS[*]}")]"
    SUMMARY_DATA["errors"]="[$(IFS=,; echo "${ERRORS[*]}")]"

    log_info "summary" "Finalized summary collection" "status=${final_status},events=${#EVENTS[@]},warnings=${#WARNINGS[@]},errors=${#ERRORS[@]}"
}

# Generate JSON summary
generate_json_summary() {
    local json="{"
    json="${json}\"start_time\":\"${SUMMARY_DATA["start_time"]}\","
    json="${json}\"end_time\":\"${SUMMARY_DATA["end_time"]}\","
    json="${json}\"execution_time\":\"${SUMMARY_DATA["execution_time"]}\","
    json="${json}\"status\":\"${SUMMARY_DATA["status"]}\","
    json="${json}\"inputs\":${SUMMARY_DATA["inputs"]:-null},"
    json="${json}\"outputs\":${SUMMARY_DATA["outputs"]:-null},"
    json="${json}\"events\":${SUMMARY_DATA["events"]:-[]},"
    json="${json}\"warnings\":${SUMMARY_DATA["warnings"]:-[]},"
    json="${json}\"errors\":${SUMMARY_DATA["errors"]:-[]}"
    json="${json}}"

    echo "$json"
}

# Generate Markdown summary
generate_markdown_summary() {
    local title="${1:-Action Summary}"
    local json_summary
    json_summary=$(generate_json_summary)

    # Parse JSON to extract values
    local status execution_time events_count warnings_count errors_count start_time end_time

    status=$(echo "$json_summary" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    execution_time=$(echo "$json_summary" | grep -o '"execution_time":"[^"]*"' | cut -d'"' -f4)
    start_time=$(echo "$json_summary" | grep -o '"start_time":"[^"]*"' | cut -d'"' -f4)
    end_time=$(echo "$json_summary" | grep -o '"end_time":"[^"]*"' | cut -d'"' -f4)

    # Count items in arrays
    events_count=$(echo "$json_summary" | grep -o '"events":\[[^]]*\]' | grep -o '{' | wc -l)
    warnings_count=$(echo "$json_summary" | grep -o '"warnings":\[[^]]*\]' | grep -o '{' | wc -l)
    errors_count=$(echo "$json_summary" | grep -o '"errors":\[[^]]*\]' | grep -o '{' | wc -l)

    # Extract inputs and outputs as formatted text
    local inputs_text outputs_text events_text warnings_text errors_text

    # Format inputs
    if [[ "${SUMMARY_DATA["inputs"]}" != "null" && -n "${SUMMARY_DATA["inputs"]}" ]]; then
        inputs_text=$(echo "${SUMMARY_DATA["inputs"]}" | sed 's/[{}"]//g' | sed 's/:/: /g' | sed 's/,/\n- /g' | sed 's/^/- /')
    else
        inputs_text="*No inputs recorded*"
    fi

    # Format outputs
    if [[ "${SUMMARY_DATA["outputs"]}" != "null" && -n "${SUMMARY_DATA["outputs"]}" ]]; then
        outputs_text=$(echo "${SUMMARY_DATA["outputs"]}" | sed 's/[{}"]//g' | sed 's/:/: /g' | sed 's/,/\n- /g' | sed 's/^/- /')
    else
        outputs_text="*No outputs recorded*"
    fi

    # Format events (show last 5)
    if [[ ${#EVENTS[@]} -gt 0 ]]; then
        local event_list=()
        local count=0
        for ((i=${#EVENTS[@]}-1; i>=0 && count<5; i--)); do
            local event="${EVENTS[$i]}"
            local timestamp=$(echo "$event" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
            local category=$(echo "$event" | grep -o '"category":"[^"]*"' | cut -d'"' -f4)
            local message=$(echo "$event" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
            event_list+=("- **${timestamp}** [${category}]: ${message}")
            ((count++))
        done
        events_text=$(printf '%s\n' "${event_list[@]}")
    else
        events_text="*No events recorded*"
    fi

    # Format warnings
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        warnings_text=""
        for warning in "${WARNINGS[@]}"; do
            local timestamp=$(echo "$warning" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
            local category=$(echo "$warning" | grep -o '"category":"[^"]*"' | cut -d'"' -f4)
            local message=$(echo "$warning" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
            warnings_text="${warnings_text}- **${timestamp}** [${category}]: ${message}\n"
        done
    else
        warnings_text="*No warnings recorded*"
    fi

    # Format errors
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        errors_text=""
        for error in "${ERRORS[@]}"; do
            local timestamp=$(echo "$error" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
            local category=$(echo "$error" | grep -o '"category":"[^"]*"' | cut -d'"' -f4)
            local message=$(echo "$error" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
            errors_text="${errors_text}- **${timestamp}** [${category}]: ${message}\n"
        done
    else
        errors_text="*No errors recorded*"
    fi

    # Use template if available, otherwise use inline template
    local template_file
    template_file="$(dirname "${BASH_SOURCE[0]}")/summary_template.md"

    if [[ -f "$template_file" ]]; then
        local template
        template=$(cat "$template_file")

        # Replace placeholders
        template="${template//\{\{TITLE\}\}/$title}"
        template="${template//\{\{STATUS\}\}/$status}"
        template="${template//\{\{EXECUTION_TIME\}\}/$execution_time}"
        template="${template//\{\{EVENTS_COUNT\}\}/$events_count}"
        template="${template//\{\{WARNINGS_COUNT\}\}/$warnings_count}"
        template="${template//\{\{ERRORS_COUNT\}\}/$errors_count}"
        template="${template//\{\{START_TIME\}\}/$start_time}"
        template="${template//\{\{END_TIME\}\}/$end_time}"
        template="${template//\{\{INPUTS\}\}/$inputs_text}"
        template="${template//\{\{OUTPUTS\}\}/$outputs_text}"
        template="${template//\{\{EVENTS\}\}/$events_text}"
        template="${template//\{\{WARNINGS\}\}/$warnings_text}"
        template="${template//\{\{ERRORS\}\}/$errors_text}"
        template="${template//\{\{JSON_SUMMARY\}\}/$json_summary}"
        template="${template//\{\{GENERATION_TIME\}\}/$(get_timestamp)}"

        echo "$template"
    else
        # Fallback to inline template
        cat << EOF
# $title

## 📊 Overview

- **Status**: ${status^}
- **Execution Time**: ${execution_time}s
- **Events Recorded**: $events_count
- **Warnings**: $warnings_count
- **Errors**: $errors_count

## 📥 Inputs

$inputs_text

## 📤 Outputs

$outputs_text

## 📝 Recent Events

$events_text

## ⚠️ Warnings

$warnings_text

## ❌ Errors

$errors_text

## 📋 Raw Data

\`\`\`json
$json_summary
\`\`\`

---

Generated by bash-action-template on $(get_timestamp)
EOF
    fi
}

# Export functions for use in other scripts
export -f init_summary record_event record_warning record_error
export -f set_summary_input set_summary_output finalize_summary
export -f generate_json_summary generate_markdown_summary
