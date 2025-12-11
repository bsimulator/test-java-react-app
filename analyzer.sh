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

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
while IFS=: read -r filename line_num rest; do
    add_issue "CRITICAL" "Security" "$filename" "$line_num" "Hardcoded password"
    security_issues=$((security_issues + 1))
done < <(grep -n "password\s*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "CRITICAL" "Security" "$filename" "$line_num" "Hardcoded API key"
    security_issues=$((security_issues + 1))
done < <(grep -n "api[_-]?key\s*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "CRITICAL" "Security" "$filename" "$line_num" "Hard-coded secret/token"
    security_issues=$((security_issues + 1))
done < <(grep -n "SECRET_TOKEN\|secret.*=\s*['\"]" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "Security" "$filename" "$line_num" "dangerouslySetInnerHTML (XSS)"
    security_issues=$((security_issues + 1))
done < <(grep -n "dangerouslySetInnerHTML" "$DIFF_FILE" 2>/dev/null)

# Java checks
while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "Java" "$filename" "$line_num" "System.out/println (use logging)"
    java_issues=$((java_issues + 1))
done < <(grep -n "System\.out\.println\|System\.err\.println" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "Java" "$filename" "$line_num" "printStackTrace() (use logger)"
    java_issues=$((java_issues + 1))
done < <(grep -n "printStackTrace()" "$DIFF_FILE" 2>/dev/null)

# React checks
while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "React" "$filename" "$line_num" "Missing key in .map()"
    react_issues=$((react_issues + 1))
done < <(grep -n "\.map(.*=>" "$DIFF_FILE" 2>/dev/null | head -5)

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "React" "$filename" "$line_num" "useEffect missing deps"
    react_issues=$((react_issues + 1))
done < <(grep -n "useEffect.*{" "$DIFF_FILE" 2>/dev/null | grep -v "\[")

while IFS=: read -r filename line_num rest; do
    add_issue "CRITICAL" "React" "$filename" "$line_num" "Direct state mutation"
    react_issues=$((react_issues + 1))
done < <(grep -n "this\.state\.\w*\s*=" "$DIFF_FILE" 2>/dev/null | grep -v "setState")

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "React" "$filename" "$line_num" "Deprecated lifecycle"
    react_issues=$((react_issues + 1))
done < <(grep -n "componentWillMount\|componentWillReceiveProps\|componentWillUpdate" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "React" "$filename" "$line_num" "Direct DOM access"
    react_issues=$((react_issues + 1))
done < <(grep -n "document\.getElementById\|document\.querySelector\|document\.innerHTML" "$DIFF_FILE" 2>/dev/null)

# Code quality checks
while IFS=: read -r filename line_num rest; do
    add_issue "INFO" "Quality" "$filename" "$line_num" "Console statement"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "console\.log\|console\.error\|console\.warn" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "WARNING" "Quality" "$filename" "$line_num" "debugger statement"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "debugger;" "$DIFF_FILE" 2>/dev/null)

while IFS=: read -r filename line_num rest; do
    add_issue "INFO" "Quality" "$filename" "$line_num" "TODO/FIXME comment"
    code_quality_issues=$((code_quality_issues + 1))
done < <(grep -n "TODO\|FIXME\|XXX\|HACK" "$DIFF_FILE" 2>/dev/null)

# Performance checks
while IFS=: read -r filename line_num rest; do
    add_issue "INFO" "Performance" "$filename" "$line_num" "Nested .map() O(n²)"
    performance_issues=$((performance_issues + 1))
done < <(grep -n "\.map(.*\.map(" "$DIFF_FILE" 2>/dev/null)

# Calculate total
total_issues=$((security_issues + java_issues + react_issues + code_quality_issues + performance_issues))

# Print header
echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}          CODE ANALYSIS REPORT${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

# Print table
if [ ${#ISSUES_ARRAY[@]} -gt 0 ]; then
    printf "%-12s %-12s %-30s %-6s %s\n" "SEVERITY" "TYPE" "FILE" "LINE" "ISSUE"
    printf "%-12s %-12s %-30s %-6s %s\n" "----------" "----------" "-----------" "----" "-----"
    
    for issue in "${ISSUES_ARRAY[@]}"; do
        IFS='|' read -r severity type filename line_num message <<< "$issue"
        
        case $severity in
            CRITICAL)
                color=$RED
                severity_display="[CRITICAL]"
                ;;
            WARNING)
                color=$YELLOW
                severity_display="[WARNING]"
                ;;
            INFO)
                color=$CYAN
                severity_display="[INFO]"
                ;;
            *)
                color=$NC
                severity_display="[INFO]"
                ;;
        esac
        
        printf "${color}%-12s${NC} %-12s %-30s %-6s %s\n" "$severity_display" "$type" "$filename" "L$line_num" "$message"
    done
else
    echo -e "${GREEN}✓ No issues detected!${NC}"
fi

echo ""
echo -e "${CYAN}================================================${NC}"
echo -e "${CYAN}                  SUMMARY${NC}"
echo -e "${CYAN}================================================${NC}"
echo ""

printf "%-35s: ${RED}%3d${NC}\n" "Security Issues" "$security_issues"
printf "%-35s: ${YELLOW}%3d${NC}\n" "Java Issues" "$java_issues"
printf "%-35s: ${YELLOW}%3d${NC}\n" "React Issues" "$react_issues"
printf "%-35s: ${CYAN}%3d${NC}\n" "Code Quality Issues" "$code_quality_issues"
printf "%-35s: ${CYAN}%3d${NC}\n" "Performance Issues" "$performance_issues"
echo "---"
printf "%-35s: " "TOTAL ISSUES"

if [ $total_issues -eq 0 ]; then
    echo -e "${GREEN}0${NC}"
    echo ""
    echo -e "${GREEN}✓ All checks passed!${NC}"
else
    echo -e "${RED}$total_issues${NC}"
    echo ""
    echo -e "${YELLOW}⚠ Please review the issues above${NC}"
fi

echo ""
echo -e "${CYAN}================================================${NC}"
