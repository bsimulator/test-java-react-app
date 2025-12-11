#!/bin/bash
# Enhanced Code Analyzer for PR Review - Java & React
# With Tabular Format and Code Snippets

DIFF_FILE=$1

if [ ! -f "$DIFF_FILE" ]; then
    echo "❌ Error: Diff file not found"
    exit 1
fi

# Initialize counters by priority
critical_issues=0
high_issues=0
medium_issues=0
low_issues=0
info_items=0

# Arrays to store issues with details
declare -a critical_list
declare -a high_list
declare -a medium_list
declare -a low_list
declare -a info_list

# Function to extract line numbers and code snippets
get_violation_details() {
    local pattern=$1
    local issue_type=$2
    
    # Get matching lines with line numbers
    grep -n "$pattern" "$DIFF_FILE" 2>/dev/null | head -3 | while IFS=: read -r line_num line_content; do
        # Clean up the line content - remove leading +/- and trim
        clean_content=$(echo "$line_content" | sed 's/^[+\-]\s*//' | sed 's/^[[:space:]]*//' | cut -c1-80)
        if [ -n "$clean_content" ]; then
            echo "$line_num|$clean_content"
        fi
    done
}

# Function to add issues with code snippets
add_critical_with_code() {
    critical_issues=$((critical_issues + 1))
    critical_list+=("$1")
}

add_high_with_code() {
    high_issues=$((high_issues + 1))
    high_list+=("$1")
}

add_medium_with_code() {
    medium_issues=$((medium_issues + 1))
    medium_list+=("$1")
}

add_low_with_code() {
    low_issues=$((low_issues + 1))
    low_list+=("$1")
}

add_info_with_code() {
    info_items=$((info_items + 1))
    info_list+=("$1")
}

echo ""
echo "# 🔍 Enhanced PR Code Analysis Report"
echo ""
echo "📅 **Analysis Date:** $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "---"
echo ""

# Security Analysis
echo "## 🔒 Security Analysis"
echo ""

# Critical Security Issues
if grep -q "password.*=.*['\"]" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "password.*=.*['\"]" "Hardcoded Password")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "Hardcoded password|$line_num|\`$code_snippet\`|Credential exposure"
        done <<< "$violation_details"
    fi
fi

if grep -q "api.*key.*=.*['\"]" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "api.*key.*=.*['\"]" "Hardcoded API Key")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "Hardcoded API key|$line_num|\`$code_snippet\`|Unauthorized access"
        done <<< "$violation_details"
    fi
fi

if grep -q "private.*key\|secret.*key\|token.*=.*['\"]" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "private.*key\|secret.*key\|token.*=" "Hardcoded Secret")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "Hardcoded secret/token|$line_num|\`$code_snippet\`|Security breach"
        done <<< "$violation_details"
    fi
fi

# High Security Issues
if grep -q "dangerouslySetInnerHTML" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "dangerouslySetInnerHTML" "XSS Vulnerability")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "XSS vulnerability (dangerouslySetInnerHTML)|$line_num|\`$code_snippet\`|Cross-site scripting"
        done <<< "$violation_details"
    fi
fi

if grep -q "eval.*(" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "eval.*(" "Dangerous eval")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "Dangerous eval() usage|$line_num|\`$code_snippet\`|Code injection"
        done <<< "$violation_details"
    fi
fi

if grep -q "innerHTML.*=" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "innerHTML.*=" "innerHTML Usage")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "innerHTML usage|$line_num|\`$code_snippet\`|Potential XSS"
        done <<< "$violation_details"
    fi
fi

# Medium Security Issues
if grep -q "http://" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "http://" "Insecure HTTP")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "Insecure HTTP URL|$line_num|\`$code_snippet\`|Use HTTPS"
        done <<< "$violation_details"
    fi
fi

echo ""

# Java Analysis
echo "## ☕ Java-Specific Analysis"
echo ""

# Critical Java Issues
if grep -q "\.equals.*null\|null.*\.equals" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "\.equals.*null\|null.*\.equals" "NPE Risk")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "NullPointerException risk|$line_num|\`$code_snippet\`|Use Objects.equals()"
        done <<< "$violation_details"
    fi
fi

if grep -q "catch.*Exception.*{.*}" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "catch.*Exception" "Empty Catch")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "Empty catch block|$line_num|\`$code_snippet\`|Swallows exceptions"
        done <<< "$violation_details"
    fi
fi

# High Java Issues
if grep -q "new Thread(" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "new Thread" "Unmanaged Thread")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "Unmanaged thread creation|$line_num|\`$code_snippet\`|Use ExecutorService"
        done <<< "$violation_details"
    fi
fi

# Medium Java Issues
if grep -q "System\.out\.println\|System\.err\.println" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "System\.out\.println\|System\.err\.println" "System.out")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "System.out usage|$line_num|\`$code_snippet\`|Use Logger"
        done <<< "$violation_details"
    fi
fi

if grep -q "printStackTrace()" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "printStackTrace" "printStackTrace")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "printStackTrace() usage|$line_num|\`$code_snippet\`|Use Logger.error()"
        done <<< "$violation_details"
    fi
fi

# Low Java Issues
if grep -q "@Deprecated" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "@Deprecated" "Deprecated API")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_low_with_code "Deprecated API usage|$line_num|\`$code_snippet\`|Use alternative"
        done <<< "$violation_details"
    fi
fi

echo ""

# React Analysis
echo "## ⚛️ React-Specific Analysis"
echo ""

# Critical React Issues
if grep -q "this\.state\.\w*\s*=" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "this\.state\." "State Mutation")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_critical_with_code "Direct state mutation|$line_num|\`$code_snippet\`|Use this.setState()"
        done <<< "$violation_details"
    fi
fi

# High React Issues
if grep -q "useEffect.*(" "$DIFF_FILE"; then
    if ! grep -q "useEffect.*\[" "$DIFF_FILE"; then
        violation_details=$(get_violation_details "useEffect" "useEffect Issue")
        if [ -n "$violation_details" ]; then
            while IFS='|' read -r line_num code_snippet; do
                add_high_with_code "useEffect without deps array|$line_num|\`$code_snippet\`|Infinite re-renders"
            done <<< "$violation_details"
        fi
    fi
fi

if grep -q "componentWillMount\|componentWillReceiveProps\|componentWillUpdate" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "componentWillMount\|componentWillReceiveProps\|componentWillUpdate" "Deprecated Lifecycle")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "Deprecated lifecycle method|$line_num|\`$code_snippet\`|Migrate to modern"
        done <<< "$violation_details"
    fi
fi

# Low React Issues
if grep -q "var " "$DIFF_FILE"; then
    violation_details=$(get_violation_details "var " "var keyword")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_low_with_code "Using 'var' keyword|$line_num|\`$code_snippet\`|Use const/let"
        done <<< "$violation_details"
    fi
fi

echo ""

# Code Quality
echo "## 📊 Code Quality Analysis"
echo ""

# High Code Quality Issues
if grep -q "debugger;" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "debugger" "Debugger")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "Debugger statement|$line_num|\`$code_snippet\`|Remove before production"
        done <<< "$violation_details"
    fi
fi

# Medium Code Quality Issues
if grep -q "console\.log\|console\.error\|console\.warn" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "console\." "Console")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "Console statements|$line_num|\`$code_snippet\`|Use proper logging"
        done <<< "$violation_details"
    fi
fi

if grep -q "TODO\|FIXME" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "TODO\|FIXME" "TODO/FIXME")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "TODO/FIXME comment|$line_num|\`$code_snippet\`|Address before merge"
        done <<< "$violation_details"
    fi
fi

echo ""

# Performance
echo "## ⚡ Performance Analysis"
echo ""

# High Performance Issues
if grep -q "SELECT \*\|select \*" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "SELECT \*\|select \*" "SELECT *")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_high_with_code "SELECT * query|$line_num|\`$code_snippet\`|Specify columns"
        done <<< "$violation_details"
    fi
fi

# Medium Performance Issues
if grep -q "\.map.*\.map" "$DIFF_FILE"; then
    violation_details=$(get_violation_details "\.map.*\.map" "Nested map")
    if [ -n "$violation_details" ]; then
        while IFS='|' read -r line_num code_snippet; do
            add_medium_with_code "Nested .map() loops|$line_num|\`$code_snippet\`|O(n²) complexity"
        done <<< "$violation_details"
    fi
fi

echo ""
echo "---"
echo ""

# Print Issues by Priority in Tabular Format
echo "## 📋 Detailed Issue Report"
echo ""

if [ $critical_issues -gt 0 ]; then
    echo "### 🚨 CRITICAL ISSUES ($critical_issues)"
    echo ""
    echo "| Issue | Line | Code Snippet | Impact |"
    echo "|-------|------|--------------|--------|"
    for issue in "${critical_list[@]}"; do
        IFS='|' read -r issue_type line_num code_snippet impact <<< "$issue"
        echo "| $issue_type | $line_num | $code_snippet | $impact |"
    done
    echo ""
fi

if [ $high_issues -gt 0 ]; then
    echo "### ⚠️ HIGH PRIORITY ISSUES ($high_issues)"
    echo ""
    echo "| Issue | Line | Code Snippet | Impact |"
    echo "|-------|------|--------------|--------|"
    for issue in "${high_list[@]}"; do
        IFS='|' read -r issue_type line_num code_snippet impact <<< "$issue"
        echo "| $issue_type | $line_num | $code_snippet | $impact |"
    done
    echo ""
fi

if [ $medium_issues -gt 0 ]; then
    echo "### ⚡ MEDIUM PRIORITY ISSUES ($medium_issues)"
    echo ""
    echo "| Issue | Line | Code Snippet | Impact |"
    echo "|-------|------|--------------|--------|"
    for issue in "${medium_list[@]}"; do
        IFS='|' read -r issue_type line_num code_snippet impact <<< "$issue"
        echo "| $issue_type | $line_num | $code_snippet | $impact |"
    done
    echo ""
fi

if [ $low_issues -gt 0 ]; then
    echo "### ℹ️ LOW PRIORITY ISSUES ($low_issues)"
    echo ""
    echo "| Issue | Line | Code Snippet | Impact |"
    echo "|-------|------|--------------|--------|"
    for issue in "${low_list[@]}"; do
        IFS='|' read -r issue_type line_num code_snippet impact <<< "$issue"
        echo "| $issue_type | $line_num | $code_snippet | $impact |"
    done
    echo ""
fi

if [ $info_items -gt 0 ]; then
    echo "### 📝 INFORMATIONAL ($info_items)"
    echo ""
    echo "| Issue | Line | Code Snippet | Note |"
    echo "|-------|------|--------------|------|"
    for item in "${info_list[@]}"; do
        IFS='|' read -r issue_type line_num code_snippet note <<< "$item"
        echo "| $issue_type | $line_num | $code_snippet | $note |"
    done
    echo ""
fi

# Summary
echo "---"
echo ""
echo "## 📊 Summary"
echo ""

total_issues=$((critical_issues + high_issues + medium_issues + low_issues))

echo "| Priority | Count |"
echo "|----------|-------|"
echo "| 🚨 Critical | $critical_issues |"
echo "| ⚠️ High | $high_issues |"
echo "| ⚡ Medium | $medium_issues |"
echo "| ℹ️ Low | $low_issues |"
echo "| 📝 Info | $info_items |"
echo "| **📈 Total** | **$total_issues** |"

echo ""

if [ $total_issues -eq 0 ]; then
    echo "> ✅ **ALL CHECKS PASSED!** No issues found."
else
    if [ $critical_issues -gt 0 ]; then
        echo "> ❌ **CRITICAL:** Must fix before merge!"
    elif [ $high_issues -gt 0 ]; then
        echo "> ⚠️ **HIGH PRIORITY:** Should fix before merge"
    else
        echo "> 💡 **Review and address issues as needed**"
    fi
fi

echo ""
echo "---"
echo ""
echo "*Generated by GitHub PR Review Agent* 🤖"
