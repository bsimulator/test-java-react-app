#!/bin/bash
# Simple Code Analyzer for PR Review - Java & React

DIFF_FILE=$1

if [ ! -f "$DIFF_FILE" ]; then
    echo "Error: Diff file not found"
    exit 1
fi

echo "========================================"
echo "PR Code Analysis Report"
echo "========================================"
echo ""

# Initialize counters
security_issues=0
java_issues=0
react_issues=0
code_quality_issues=0
performance_issues=0

# Security Analysis
echo "SECURITY ANALYSIS"
echo "-----------------"

if grep -q "password\s*=\s*['\"]" "$DIFF_FILE"; then
    echo "WARNING: Hardcoded password detected"
    security_issues=$((security_issues + 1))
fi

if grep -q "api[_-]?key\s*=\s*['\"]" "$DIFF_FILE"; then
    echo "WARNING: Hardcoded API key detected"
    security_issues=$((security_issues + 1))
fi

if grep -q "dangerouslySetInnerHTML" "$DIFF_FILE"; then
    echo "WARNING: dangerouslySetInnerHTML usage (XSS risk)"
    security_issues=$((security_issues + 1))
fi

if [ $security_issues -eq 0 ]; then
    echo "OK: No security issues"
fi

echo ""

# Java Analysis
echo "JAVA ANALYSIS"
echo "-------------"

if grep -q "System\.out\.println\|System\.err\.println" "$DIFF_FILE"; then
    echo "WARNING: System.out usage (use logging)"
    java_issues=$((java_issues + 1))
fi

if grep -q "printStackTrace()" "$DIFF_FILE"; then
    echo "WARNING: printStackTrace() (use logger)"
    java_issues=$((java_issues + 1))
fi

if grep -q "catch.*Exception.*{\s*}" "$DIFF_FILE"; then
    echo "WARNING: Empty catch block"
    java_issues=$((java_issues + 1))
fi

if grep -q "\.equals.*null" "$DIFF_FILE"; then
    echo "CRITICAL: Potential NullPointerException"
    java_issues=$((java_issues + 1))
fi

if grep -q "Connection\|Statement\|ResultSet" "$DIFF_FILE"; then
    echo "INFO: Database resources - verify proper closure"
fi

if [ $java_issues -eq 0 ]; then
    echo "OK: No Java issues"
fi

echo ""

# React Analysis
echo "REACT ANALYSIS"
echo "--------------"

if grep -q "\.map(.*=>" "$DIFF_FILE"; then
    if ! grep -q "key=" "$DIFF_FILE"; then
        echo "WARNING: map() without key prop"
        react_issues=$((react_issues + 1))
    fi
fi

if grep -q "useEffect" "$DIFF_FILE"; then
    if ! grep -q "useEffect.*\[" "$DIFF_FILE"; then
        echo "WARNING: useEffect without dependency array"
        react_issues=$((react_issues + 1))
    fi
fi

if grep -q "this\.state\.\w*\s*=" "$DIFF_FILE"; then
    echo "CRITICAL: Direct state mutation"
    react_issues=$((react_issues + 1))
fi

if grep -q "componentWillMount\|componentWillReceiveProps" "$DIFF_FILE"; then
    echo "WARNING: Deprecated lifecycle method"
    react_issues=$((react_issues + 1))
fi

if grep -q "var " "$DIFF_FILE"; then
    echo "WARNING: var keyword (use const/let)"
    react_issues=$((react_issues + 1))
fi

if [ $react_issues -eq 0 ]; then
    echo "OK: No React issues"
fi

echo ""

# Code Quality
echo "CODE QUALITY"
echo "------------"

if grep -q "console\.log" "$DIFF_FILE"; then
    echo "INFO: Console statements found"
    code_quality_issues=$((code_quality_issues + 1))
fi

if grep -q "debugger;" "$DIFF_FILE"; then
    echo "WARNING: debugger statement"
    code_quality_issues=$((code_quality_issues + 1))
fi

if [ $code_quality_issues -eq 0 ]; then
    echo "OK: No code quality issues"
fi

echo ""

# Performance
echo "PERFORMANCE"
echo "-----------"

if grep -q "SELECT \*" "$DIFF_FILE"; then
    echo "WARNING: SELECT * query"
    performance_issues=$((performance_issues + 1))
fi

if grep -q "\.map(.*\.map(" "$DIFF_FILE"; then
    echo "INFO: Nested map() detected"
    performance_issues=$((performance_issues + 1))
fi

if [ $performance_issues -eq 0 ]; then
    echo "OK: No performance issues"
fi

echo ""
echo "========================================"
echo "SUMMARY"
echo "========================================"

total_issues=$((security_issues + java_issues + react_issues + code_quality_issues + performance_issues))

echo "Security Issues: $security_issues"
echo "Java Issues: $java_issues"
echo "React Issues: $react_issues"
echo "Code Quality: $code_quality_issues"
echo "Performance: $performance_issues"
echo "Total Issues: $total_issues"

if [ $total_issues -eq 0 ]; then
    echo ""
    echo "All checks passed!"
fi

echo "========================================"
