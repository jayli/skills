#!/bin/bash
# 注释完整度检查 - 主入口

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

get_comments_issues_file() {
    local project_type=$(detect_project_type)
    case "$project_type" in
        iOS) echo "${SCRIPT_DIR}/../.ios_comments_issues.txt" ;;
        Flutter) echo "${SCRIPT_DIR}/../.flutter_comments_issues.txt" ;;
        Java) echo "${SCRIPT_DIR}/../.java_comments_issues.txt" ;;
        Python) echo "${SCRIPT_DIR}/../.python_comments_issues.txt" ;;
        Go) echo "${SCRIPT_DIR}/../.go_comments_issues.txt" ;;
        Cpp) echo "${SCRIPT_DIR}/../.cpp_comments_issues.txt" ;;
        *) echo "${SCRIPT_DIR}/../.js_comments_issues.txt" ;;
    esac
}

check_comments() {
    local project_type=$(detect_project_type)
    local result

    case "$project_type" in
        iOS)
            result=$(bash "${SCRIPT_DIR}/checkers/ios/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        Flutter)
            result=$(bash "${SCRIPT_DIR}/checkers/flutter/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        Java)
            result=$(bash "${SCRIPT_DIR}/checkers/java/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        Python)
            result=$(bash "${SCRIPT_DIR}/checkers/python/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        Go)
            result=$(bash "${SCRIPT_DIR}/checkers/go/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        Cpp)
            result=$(bash "${SCRIPT_DIR}/checkers/cpp/comments.sh" 2>/dev/null || echo "0:0")
            ;;
        *)
            result=$(bash "${SCRIPT_DIR}/checkers/js/comments.sh" 2>/dev/null || echo "0:0")
            ;;
    esac

    echo "${result%%:*}"
}

output_comments_details() {
    local issues_file=$(get_comments_issues_file)
    if [ -f "$issues_file" ] && [ -s "$issues_file" ]; then
        cat "$issues_file"
    fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    check_comments
fi
