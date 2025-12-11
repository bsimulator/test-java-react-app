#!/bin/bash
# Enhanced Code Analyzer for PR Review - Java & React
# With Priority Levels, Line Numbers, and Color Coding

DIFF_FILE=$1

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

if [ ! -f "$DIFF_FILE" ]; then
    echo -e "${RED}❌ Error: Diff file not found${NC}"
    exit 1
fi

# Initialize counters by priority
critical_issues=0
high_issues=0
medium_issues=0
low_issues=0
info_items=0

# Arrays to store issues
declare -a critical_list
declare -a high_list
declare -a medium_list
declare -a low_list
declare -a info_list

# Function to extract line numbers from diff
get_line_numbers() {
    local pattern=$1
    grep -n "$pattern" "$DIFF_FILE" 2>/dev/null | cut -d: -f1 | head -5 | tr '\n' ',' | sed 's/,$//'
}

# Function to add issues
add_critical() {
    critical_issues=$((critical_issues + 1))
    critical_list+=("$1")
}

add_high() {
    high_issues=$((high_issues + 1))
    high_list+=("$1")
}

add_medium() {
    medium_issues=$((medium_issues + 1))
    medium_list+=("$1")
}

add_low() {
    low_issues=$((low_issues + 1))
    low_list+=("$1")
}

add_info() {
    info_items=$((info_items + 1))
    info_list+=("$1")
}

echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}🔍 ENHANCED PR CODE ANALYSIS REPORT${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}📅 Analysis Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo ""

# Security Analysis
echo -e "${RED}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${RED}${BOLD}🔒 SECURITY ANALYSIS${NC}"
echo -e "${RED}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# Critical Security Issues
if grep -q "password.*=.*['\"]" "$DIFF_FILE"; then
    lines=$(get_line_numbers "password.*=.*['\"]")
    add_critical "Hardcoded password detected | Lines: $lines | Risk: Credential exposure"
fi

if grep -q "api.*key.*=.*['\"]" "$DIFF_FILE"; then
    lines=$(get_line_numbers "api.*key.*=.*['\"]")
    add_critical "Hardcoded API key detected | Lines: $lines | Risk: Unauthorized access"
fi

if grep -q "private.*key\|secret.*key\|token.*=.*['\"]" "$DIFF_FILE"; then
    lines=$(get_line_numbers "private.*key\|secret.*key\|token.*=")
    add_critical "Hardcoded secret/token detected | Lines: $lines | Risk: Security breach"
fi

# High Security Issues
if grep -q "dangerouslySetInnerHTML" "$DIFF_FILE"; then
    lines=$(get_line_numbers "dangerouslySetInnerHTML")
    add_high "XSS vulnerability (dangerouslySetInnerHTML) | Lines: $lines | Risk: Cross-site scripting"
fi

if grep -q "eval.*(" "$DIFF_FILE"; then
    lines=$(get_line_numbers "eval.*(")
    add_high "Dangerous eval usage | Lines: $lines | Risk: Code injection"
fi

if grep -q "innerHTML.*=" "$DIFF_FILE"; then
    lines=$(get_line_numbers "innerHTML.*=")
    add_high "innerHTML usage detected | Lines: $lines | Risk: Potential XSS"
fi

if grep -q "Runtime\.getRuntime\|exec\|system(" "$DIFF_FILE"; then
    lines=$(get_line_numbers "Runtime\.getRuntime\|exec\|system")
    add_high "System command execution | Lines: $lines | Risk: Command injection"
fi

# Medium Security Issues
if grep -q "http://" "$DIFF_FILE"; then
    lines=$(get_line_numbers "http://")
    add_medium "Insecure HTTP URL | Lines: $lines | Recommendation: Use HTTPS"
fi

echo ""

# Java Analysis
echo -e "${ORANGE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${ORANGE}${BOLD}☕ JAVA-SPECIFIC ANALYSIS${NC}"
echo -e "${ORANGE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# Critical Java Issues
if grep -q "\.equals.*null\|null.*\.equals" "$DIFF_FILE"; then
    lines=$(get_line_numbers "\.equals.*null\|null.*\.equals")
    add_critical "NullPointerException risk | Lines: $lines | Use: Objects.equals or null check first"
fi

if grep -q "catch.*Exception.*{.*}" "$DIFF_FILE"; then
    lines=$(get_line_numbers "catch.*Exception")
    add_critical "Empty catch block | Lines: $lines | Issue: Swallows exceptions silently"
fi

# High Java Issues
if grep -q "Connection\|Statement\|ResultSet" "$DIFF_FILE"; then
    if ! grep -q "try-with-resources\|\.close()\|finally" "$DIFF_FILE"; then
        lines=$(get_line_numbers "Connection\|Statement\|ResultSet")
        add_high "Resource leak risk | Lines: $lines | Solution: Use try-with-resources"
    fi
fi

if grep -q "new Thread(" "$DIFF_FILE"; then
    lines=$(get_line_numbers "new Thread")
    add_high "Unmanaged thread creation | Lines: $lines | Use: ExecutorService instead"
fi

# Medium Java Issues
if grep -q "System\.out\.println\|System\.err\.println" "$DIFF_FILE"; then
    lines=$(get_line_numbers "System\.out\.println\|System\.err\.println")
    add_medium "System.out usage | Lines: $lines | Use: Logger (SLF4J/Log4j)"
fi

if grep -q "printStackTrace()" "$DIFF_FILE"; then
    lines=$(get_line_numbers "printStackTrace")
    add_medium "printStackTrace usage | Lines: $lines | Use: Logger.error"
fi

if grep -q "synchronized.*(" "$DIFF_FILE"; then
    lines=$(get_line_numbers "synchronized")
    add_info "Synchronization detected | Lines: $lines | Verify: Thread safety requirements"
fi

# Low Java Issues
if grep -q "@Deprecated" "$DIFF_FILE"; then
    lines=$(get_line_numbers "@Deprecated")
    add_low "Deprecated API usage | Lines: $lines | Update: Use recommended alternative"
fi

echo ""

# React Analysis
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}${BOLD}⚛️  REACT-SPECIFIC ANALYSIS${NC}"
echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# Critical React Issues
if grep -q "this\.state\.\w*\s*=" "$DIFF_FILE"; then
    lines=$(get_line_numbers "this\.state\.")
    add_critical "Direct state mutation | Lines: $lines | Use: this.setState"
fi

if grep -q "props\.\w*\s*=" "$DIFF_FILE"; then
    lines=$(get_line_numbers "props\.")
    add_critical "Props mutation (immutable) | Lines: $lines | Props are read-only"
fi

# High React Issues
if grep -q "\.map.*(" "$DIFF_FILE"; then
    if ! grep -q "key=" "$DIFF_FILE"; then
        lines=$(get_line_numbers "\.map")
        add_high "Missing key prop in .map | Lines: $lines | Add: unique key for each item"
    fi
fi

if grep -q "useEffect.*(" "$DIFF_FILE"; then
    if ! grep -q "useEffect.*\[" "$DIFF_FILE"; then
        lines=$(get_line_numbers "useEffect")
        add_high "useEffect without deps array | Lines: $lines | Causes: Infinite re-renders"
    fi
fi

if grep -q "componentWillMount\|componentWillReceiveProps\|componentWillUpdate" "$DIFF_FILE"; then
    lines=$(get_line_numbers "componentWillMount\|componentWillReceiveProps\|componentWillUpdate")
    add_high "Deprecated lifecycle method | Lines: $lines | Migrate: To modern alternatives"
fi

# Medium React Issues
if grep -q "useState.*useState.*useState" "$DIFF_FILE"; then
    lines=$(get_line_numbers "useState")
    add_medium "Multiple useState calls | Lines: $lines | Consider: useReducer for complex state"
fi

if grep -q "useEffect.*\[\]" "$DIFF_FILE"; then
    lines=$(get_line_numbers "useEffect.*\[\]")
    add_info "useEffect with empty deps | Lines: $lines | Runs: Only once on mount"
fi

# Low React Issues
if grep -q "var " "$DIFF_FILE"; then
    lines=$(get_line_numbers "var ")
    add_low "Using 'var' keyword | Lines: $lines | Modern: Use const/let"
fi

if grep -q "defaultProps.*=" "$DIFF_FILE"; then
    lines=$(get_line_numbers "defaultProps")
    add_info "defaultProps usage | Lines: $lines | Modern: Use default parameters"
fi

echo ""

# Code Quality
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}${BOLD}📊 CODE QUALITY ANALYSIS${NC}"
echo -e "${BLUE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# High Code Quality Issues
if grep -q "debugger;" "$DIFF_FILE"; then
    lines=$(get_line_numbers "debugger")
    add_high "Debugger statement | Lines: $lines | Remove: Before production"
fi

# Medium Code Quality Issues
if grep -q "console\.log\|console\.error\|console\.warn" "$DIFF_FILE"; then
    lines=$(get_line_numbers "console\.")
    add_medium "Console statements | Lines: $lines | Remove: Or use proper logging"
fi

if grep -q "TODO\|FIXME" "$DIFF_FILE"; then
    lines=$(get_line_numbers "TODO\|FIXME")
    add_medium "TODO/FIXME comments | Lines: $lines | Action: Address before merge"
fi

# Low Code Quality Issues
if grep -q "any\s*;" "$DIFF_FILE"; then
    lines=$(get_line_numbers "any")
    add_low "TypeScript 'any' type | Lines: $lines | Improve: Use specific types"
fi

if grep -q "//.*console\.log" "$DIFF_FILE"; then
    lines=$(get_line_numbers "//.*console\.log")
    add_low "Commented debug code | Lines: $lines | Clean up: Remove dead code"
fi

echo ""

# Performance
echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}${BOLD}⚡ PERFORMANCE ANALYSIS${NC}"
echo -e "${PURPLE}${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

# High Performance Issues
if grep -q "SELECT \*\|select \*" "$DIFF_FILE"; then
    lines=$(get_line_numbers "SELECT \*\|select \*")
    add_high "SELECT * query | Lines: $lines | Optimize: Specify needed columns"
fi

if grep -q "N+1\|n+1.*query\|n+1.*problem" "$DIFF_FILE"; then
    lines=$(get_line_numbers "N+1\|n+1")
    add_high "N+1 query problem | Lines: $lines | Solution: Use JOIN or batch loading"
fi

# Medium Performance Issues
if grep -q "\.map.*\.map" "$DIFF_FILE"; then
    lines=$(get_line_numbers "\.map.*\.map")
    add_medium "Nested .map loops | Lines: $lines | Complexity: O(n²) - optimize if large"
fi

if grep -q "for.*for" "$DIFF_FILE"; then
    lines=$(get_line_numbers "for.*for")
    add_medium "Nested for loops | Lines: $lines | Review: Algorithm complexity"
fi

# Low Performance Issues
if grep -q "JSON\.parse.*JSON\.stringify" "$DIFF_FILE"; then
    lines=$(get_line_numbers "JSON\.parse.*JSON\.stringify")
    add_low "JSON deep clone | Lines: $lines | Alternative: structuredClone or library"
fi

if grep -q "setTimeout.*0" "$DIFF_FILE"; then
    lines=$(get_line_numbers "setTimeout.*0")
    add_info "setTimeout with 0ms | Lines: $lines | Note: Defers to next tick"
fi

echo ""

# Print Issues by Priority
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📋 DETAILED ISSUE REPORT${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

if [ $critical_issues -gt 0 ]; then
    echo -e "${RED}${BOLD}🚨 CRITICAL ISSUES ($critical_issues)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for issue in "${critical_list[@]}"; do
        echo -e "${RED}  ● ${issue}${NC}"
    done
    echo ""
fi

if [ $high_issues -gt 0 ]; then
    echo -e "${ORANGE}${BOLD}⚠️  HIGH PRIORITY ISSUES ($high_issues)${NC}"
    echo -e "${ORANGE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for issue in "${high_list[@]}"; do
        echo -e "${ORANGE}  ● ${issue}${NC}"
    done
    echo ""
fi

if [ $medium_issues -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}⚡ MEDIUM PRIORITY ISSUES ($medium_issues)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for issue in "${medium_list[@]}"; do
        echo -e "${YELLOW}  ● ${issue}${NC}"
    done
    echo ""
fi

if [ $low_issues -gt 0 ]; then
    echo -e "${BLUE}${BOLD}ℹ️  LOW PRIORITY ISSUES ($low_issues)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for issue in "${low_list[@]}"; do
        echo -e "${BLUE}  ● ${issue}${NC}"
    done
    echo ""
fi

if [ $info_items -gt 0 ]; then
    echo -e "${CYAN}${BOLD}📝 INFORMATIONAL ($info_items)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    for item in "${info_list[@]}"; do
        echo -e "${CYAN}  ● ${item}${NC}"
    done
    echo ""
fi

# Summary
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📊 SUMMARY${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
echo ""

total_issues=$((critical_issues + high_issues + medium_issues + low_issues))

echo -e "${RED}🚨 Critical: ${critical_issues}${NC}"
echo -e "${ORANGE}⚠️  High:     ${high_issues}${NC}"
echo -e "${YELLOW}⚡ Medium:   ${medium_issues}${NC}"
echo -e "${BLUE}ℹ️  Low:      ${low_issues}${NC}"
echo -e "${CYAN}📝 Info:     ${info_items}${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}📈 Total Issues: ${total_issues}${NC}"

echo ""

if [ $total_issues -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ALL CHECKS PASSED! No issues found.${NC}"
else
    if [ $critical_issues -gt 0 ]; then
        echo -e "${RED}${BOLD}❌ CRITICAL: Must fix before merge!${NC}"
    elif [ $high_issues -gt 0 ]; then
        echo -e "${ORANGE}${BOLD}⚠️  HIGH PRIORITY: Should fix before merge${NC}"
    else
        echo -e "${YELLOW}${BOLD}💡 Review and address issues as needed${NC}"
    fi
fi

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════${NC}"
