#!/bin/bash
# Simple Code Analyzer for PR Review

DIFF_FILE=$1

if [ ! -f "$DIFF_FILE" ]; then
    echo "Error: Diff file not found"
    exit 1
fi

echo "================================================"
echo "PR Code Analysis Report"
echo "================================================"
echo ""

# Initialize counters
security_issues=0
java_issues=0
react_issues=0
quality_issues=0

# Security checks
echo "SECURITY ANALYSIS"
echo "-------------------"

grep -q "password.*=" "$DIFF_FILE" && echo "WARNING: Hardcoded password detected" && security_issues=$((security_issues + 1))
grep -q "api.*key.*=" "$DIFF_FILE" && echo "WARNING: Hardcoded API key detected" && security_issues=$((security_issues + 1))
grep -q "dangerouslySetInnerHTML" "$DIFF_FILE" && echo "WARNING: XSS risk" && security_issues=$((security_issues + 1))

[ $security_issues -eq 0 ] && echo "OK: No security issues detected"
echo ""

# Java checks
echo "JAVA ANALYSIS"
echo "-------------"

grep -q "System.out.println" "$DIFF_FILE" && echo "WARNING: Use logging framework" && java_issues=$((java_issues + 1))
grep -q "printStackTrace" "$DIFF_FILE" && echo "WARNING: Use logger" && java_issues=$((java_issues + 1))

[ $java_issues -eq 0 ] && echo "OK: No Java issues detected"
echo ""

# React checks
echo "REACT ANALYSIS"
echo "--------------"

grep -q "\.map(" "$DIFF_FILE" && ! grep -q "key=" "$DIFF_FILE" && echo "WARNING: Missing key prop" && react_issues=$((react_issues + 1))

[ $react_issues -eq 0 ] && echo "OK: No React issues detected"
echo ""

# Code quality
echo "CODE QUALITY"
echo "------------"

grep -q "console\.log" "$DIFF_FILE" && echo "INFO: Console statements found" && quality_issues=$((quality_issues + 1))
grep -q "debugger" "$DIFF_FILE" && echo "WARNING: Debugger statement" && quality_issues=$((quality_issues + 1))

[ $quality_issues -eq 0 ] && echo "OK: No quality issues detected"
echo ""

# Summary
echo "================================================"
echo "SUMMARY"
echo "================================================"
total=$((security_issues + java_issues + react_issues + quality_issues))
echo "Security: $security_issues"
echo "Java: $java_issues"
echo "React: $react_issues"
echo "Quality: $quality_issues"
echo "Total: $total"
echo ""

if [ $total -eq 0 ]; then
    echo "All checks passed!"
else
    echo "Please review the issues above"
fi
echo "================================================"
