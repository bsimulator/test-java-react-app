#!/bin/bash
#
# Simple Code Analyzer for PR Review
# Analyzes code changes for common issues
#

DIFF_FILE=$1

if [ ! -f "$DIFF_FILE" ]; then
    echo "❌ Error: Diff file not found"
    exit 1
fi

echo "================================================"
echo "🔍 PR Code Analysis Report (Java & React)"
echo "================================================"
echo ""

# Initialize counters
security_issues=0
code_quality_issues=0
performance_issues=0
java_issues=0
react_issues=0

# Security checks
echo "🔒 SECURITY ANALYSIS"
echo "-------------------"

if grep -q "eval\|exec\|system\|shell_exec\|Runtime\.getRuntime" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Dangerous function detected (eval/exec/Runtime)"
    security_issues=$((security_issues + 1))
fi

if grep -q "password\s*=\s*['\"]" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Hardcoded password detected"
    security_issues=$((security_issues + 1))
fi

if grep -q "api[_-]?key\s*=\s*['\"]" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Hardcoded API key detected"
    security_issues=$((security_issues + 1))
fi

if grep -q "dangerouslySetInnerHTML" "$DIFF_FILE"; then
    echo "⚠️  WARNING: dangerouslySetInnerHTML usage (XSS risk)"
    security_issues=$((security_issues + 1))
fi

if grep -q "TODO.*security\|FIXME.*security" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Security TODO/FIXME found"
fi

if [ $security_issues -eq 0 ]; then
    echo "✅ No obvious security issues detected"
fi

echo ""

# Java-specific checks
echo "☕ JAVA-SPECIFIC ANALYSIS"
echo "-------------------------"

if grep -q "System\.out\.println\|System\.err\.println" "$DIFF_FILE"; then
    echo "⚠️  WARNING: System.out/err usage (use logging framework)"
    java_issues=$((java_issues + 1))
fi

if grep -q "printStackTrace()" "$DIFF_FILE"; then
    echo "⚠️  WARNING: printStackTrace() usage (use logger)"
    java_issues=$((java_issues + 1))
fi

if grep -q "catch.*Exception.*{\s*}" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Empty catch block detected"
    java_issues=$((java_issues + 1))
fi

if grep -q "\.equals.*null\|null.*\.equals" "$DIFF_FILE"; then
    echo "❗ CRITICAL: Potential NullPointerException"
    java_issues=$((java_issues + 1))
fi

if grep -q "new Thread\|\.start()" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Thread usage detected (verify thread safety)"
    java_issues=$((java_issues + 1))
fi

if grep -q "Connection\|Statement\|ResultSet" "$DIFF_FILE" && ! grep -q "try.*finally\|try-with-resources" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Database resources may not be closed properly"
    java_issues=$((java_issues + 1))
fi

if grep -q "@Deprecated" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Deprecated annotation found"
fi

if [ $java_issues -eq 0 ]; then
    echo "✅ No Java-specific issues detected"
fi

echo ""

# React-specific checks
echo "⚛️  REACT-SPECIFIC ANALYSIS"
echo "---------------------------"

if grep -q "\.map(.*=>" "$DIFF_FILE" && ! grep -q "key=" "$DIFF_FILE"; then
    echo "⚠️  WARNING: .map() without key prop"
    react_issues=$((react_issues + 1))
fi

if grep -q "useState\|useEffect\|useCallback\|useMemo" "$DIFF_FILE"; then
    echo "ℹ️  INFO: React hooks detected - verify rules of hooks"
    
    if grep -q "useEffect.*\[\]" "$DIFF_FILE"; then
        echo "ℹ️  INFO: useEffect with empty deps (runs once)"
    fi
    
    if grep -q "useEffect.*{" "$DIFF_FILE" && ! grep -q "useEffect.*\[" "$DIFF_FILE"; then
        echo "⚠️  WARNING: useEffect without dependency array"
        react_issues=$((react_issues + 1))
    fi
fi

if grep -q "this\.state\.\w*\s*=" "$DIFF_FILE" && ! grep -q "setState" "$DIFF_FILE"; then
    echo "❗ CRITICAL: Direct state mutation detected"
    react_issues=$((react_issues + 1))
fi

if grep -q "componentWillMount\|componentWillReceiveProps\|componentWillUp + java_issues + react_issues))

echo "Security Issues: $security_issues"
echo "Java-Specific Issues: $java_issues"
echo "React-Specific Issues: $react_issues"
echo "Code Quality Issues: $code_quality_issues"
echo "Performance Issues: $performance_issues"
echo "---"
echo "Total Issues: $total_issues"

if [ $total_issues -eq 0 ]; then
    echo ""
    echo "✅ All automated checks passed!"
else
    echo ""
    echo "⚠️  Please review the issues above"
fi

echo ""
echo "💡 Note: This is a basic automated analysis for Java & React."
echo "   AI review will provide deeper, context-aware
if [ $react_issues -eq 0 ]; then
    echo "✅ No React-specific issues detected"
fi

echo ""

# General Code Quality checks
echo "📊 CODE QUALITY ANALYSIS"
echo "------------------------"

if grep -q "console\.log\|console\.error\|console\.warn" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Console statements found (remove before production)"
    code_quality_issues=$((code_quality_issues + 1))
fi

if grep -q "debugger;" "$DIFF_FILE"; then
    echo "⚠️  WARNING: debugger statement found"
    code_quality_issues=$((code_quality_issues + 1))
fi

if grep -q "TODO\|FIXME\|XXX\|HACK" "$DIFF_FILE"; then
    echo "ℹ️  INFO: TODO/FIXME comments found"
    code_quality_issues=$((code_quality_issues + 1))
fi

if grep -q "any\s*;" "$DIFF_FILE"; then
    echo "⚠️  WARNING: TypeScript 'any' type usage (reduce type safety)"
    code_quality_issues=$((code_quality_issues + 1))
fi

if [ $code_quality_issues -eq 0 ]; then
    echo "✅ No code quality issues detected"
fi

echo ""

# Performance checks
echo "⚡ PERFORMANCE ANALYSIS"
echo "----------------------"

if grep -q "SELECT \*\|select \*" "$DIFF_FILE"; then
    echo "⚠️  WARNING: SELECT * query detected (specify columns)"
    performance_issues=$((performance_issues + 1))
fi

if grep -q "N+1\|n\+1" "$DIFF_FILE"; then
    echo "⚠️  WARNING: Potential N+1 query issue mentioned"
    performance_issues=$((performance_issues + 1))
fi

if grep -q "\.map(.*\.map(" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Nested .map() detected (verify O(n²) is acceptable)"
    performance_issues=$((performance_issues + 1))
fi

if grep -q "useEffect.*setInterval\|useEffect.*setTimeout" "$DIFF_FILE"; then
    echo "ℹ️  INFO: Timer in useEffect (verify cleanup function)"
fi

if grep -q "JSON\.parse.*JSON\.stringify" "$DIFF_FILE"; then
    echo "ℹ️  INFO: JSON parse/stringify for deep clone (consider alternatives)"
fi

if [ $performance_issues -eq 0 ]; then
    echo "✅ No performance issues detected"
fi

echo ""

# File size check
echo "📁 FILE SIZE ANALYSIS"
echo "---------------------"

large_files=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | while read file; do
    if [ -f "$file" ]; then
        size=$(wc -l < "$file" 2>/dev/null || echo 0)
        if [ "$size" -gt 500 ]; then
            echo "⚠️  $file: $size lines (consider splitting)"
        fi
    fi
done)

if [ -z "$large_files" ]; then
    echo "✅ No excessively large files"
else
    echo "$large_files"
fi

echo ""

# Summary
echo "================================================"
echo "📋 SUMMARY"
echo "================================================"
total_issues=$((security_issues + code_quality_issues + performance_issues + java_issues + react_issues))

echo "Security Issues: $security_issues"
echo "Java-Specific Issues: $java_issues"
echo "React-Specific Issues: $react_issues"
echo "Code Quality Issues: $code_quality_issues"
echo "Performance Issues: $performance_issues"
echo "---"
echo "Total Issues: $total_issues"

if [ $total_issues -eq 0 ]; then
    echo ""
    echo "✅ All automated checks passed!"
else
    echo ""
    echo "⚠️  Please review the issues above"
fi

echo ""
echo "💡 Note: This is a basic automated analysis for Java & React."
echo "   Manual review recommended for complex issues."
echo "================================================"
