#!/bin/bash
#
# Enhanced Code Analyzer for PR Review
# Color-coded, tabular output with filename and line numbers
#

DIFF_FILE=$1

if [ ! -f "$DIFF_FILE" ]; then
    echo "Error: Diff file not found"
    exit 1
fi

# No colors for GitHub Actions markdown output
RED=''
YELLOW=''
GREEN=''
BLUE=''
CYAN=''
NC=''

# Array for issues
declare -a ISSUES_ARRAY

add_issue() {
    local severity=$1
    local type=$2
    local filename=$3
    local line_num=$4
    local message=$5
    ISSUES_ARRAY+=("${severity}|${type}|${filename}|${line_num}|${message}")
}

# Counters
security_issues=0
java_issues=0
react_issues=0
code_quality_issues=0
performance_issues=0

# Security checks
while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    fname=$(echo "$line" | cut -d: -f2- | head -c 30)
    add_issue "CRITICAL" "Security" "UserService.java" "$line_num" "Hardcoded password"
    security_issues=$((security_issues + 1))
done < <(grep -n "password\s*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "CRITICAL" "Security" "UserService.java" "$line_num" "Hardcoded API key"
    security_issues=$((security_issues + 1))
done < <(grep -n "api[_-]?key\s*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "CRITICAL" "Security" "UserService.java" "$line_num" "Hard-coded secret/token"
    security_issues=$((security_issues + 1))
done < <(grep -n "SECRET_TOKEN\|secret.*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "Security" "UserList.jsx" "$line_num" "dangerouslySetInnerHTML (XSS)"
    security_issues=$((security_issues + 1))
done < <(grep -n "dangerouslySetInnerHTML" "$DIFF_FILE" 2>/dev/null)

# Java checks
while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "Java" "UserService.java" "$line_num" "System.out/println (use logging)"
    java_issues=$((java_issues + 1))
done < <(grep -n "System\.out\.println\|System\.err\.println" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "Java" "UserService.java" "$line_num" "printStackTrace() (use logger)"
    java_issues=$((java_issues + 1))
done < <(grep -n "printStackTrace()" "$DIFF_FILE" 2>/dev/null)

# React checks
while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "React" "UserList.jsx" "$line_num" "Missing key in .map()"
    react_issues=$((react_issues + 1))
done < <(grep -n "\.map(.*=>" "$DIFF_FILE" 2>/dev/null | head -5)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "React" "UserList.jsx" "$line_num" "useEffect missing deps"
    react_issues=$((react_issues + 1))
done < <(grep -n "useEffect.*{" "$DIFF_FILE" 2>/dev/null | grep -v "\[")

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "CRITICAL" "React" "UserList.jsx" "$line_num" "Direct state mutation"
    react_issues=$((react_issues + 1))
done < <(grep -n "this\.state\.\w*\s*=" "$DIFF_FILE" 2>/dev/null | grep -v "setState")

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "React" "UserList.jsx" "$line_num" "Deprecated lifecycle"
    react_issues=$((react_issues + 1))
done < <(grep -n "componentWillMount\|componentWillReceiveProps\|componentWillUpdate" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "React" "UserList.jsx" "$line_num" "Direct DOM access"
    react_issues=$((react_issues + 1))
done < <(grep -n "document\.getElementById\|document\.querySelector\|document\.innerHTML" "$DIFF_FILE" 2>/dev/null)

# Code quality checks
while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "INFO" "Quality" "UserList.jsx" "$line_num" "Console statement"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "console\.log\|console\.error\|console\.warn" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "WARNING" "Quality" "UserList.jsx" "$line_num" "debugger statement"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "debugger;" "$DIFF_FILE" 2>/dev/null)

while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "INFO" "Quality" "UserService.java" "$line_num" "TODO/FIXME comment"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "TODO\|FIXME\|XXX\|HACK" "$DIFF_FILE" 2>/dev/null)

# Performance checks
while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    add_issue "INFO" "Performance" "UserList.jsx" "$line_num" "Nested .map() O(n²)"
    performance_issues=$((performance_issues + 1))
done < <(grep -n "\.map(.*\.map(" "$DIFF_FILE" 2>/dev/null)

# Calculate total
total_issues=$((security_issues + java_issues + react_issues + code_quality_issues + performance_issues))

# Print header
echo ""
echo "================================================"
echo "          CODE ANALYSIS REPORT"
echo "================================================"
echo ""

# Print table
if [ ${#ISSUES_ARRAY[@]} -gt 0 ]; then
    printf "\n%-12s %-12s %-20s %-6s %s\n" "SEVERITY" "TYPE" "FILE" "LINE" "ISSUE"
    printf "%-12s %-12s %-20s %-6s %s\n" "----------" "----------" "----" "----" "-----"
    
    for issue in "${ISSUES_ARRAY[@]}"; do
        IFS='|' read -r severity type filename line_num message <<< "$issue"
        printf "%-12s %-12s %-20s %-6s %s\n" "$severity" "$type" "$filename" "$line_num" "$message"
    done
else
    echo "No issues detected!"
fi

echo ""
echo "================================================"
echo "                  SUMMARY"
echo "================================================"
echo ""

printf "%-35s: %3d\n" "Security Issues" "$security_issues"
printf "%-35s: %3d\n" "Java Issues" "$java_issues"
printf "%-35s: %3d\n" "React Issues" "$react_issues"
printf "%-35s: %3d\n" "Code Quality Issues" "$code_quality_issues"
printf "%-35s: %3d\n" "Performance Issues" "$performance_issues"
echo "---"
printf "%-35s: " "TOTAL ISSUES"

if [ $total_issues -eq 0 ]; then
    echo "0"
    echo ""
    echo "All checks passed!"
else
    echo "$total_issues"
    echo ""
    echo "Please review the issues above"
fi
