#!/usr/bin/env node
/**
 * Enhanced Code Analyzer for PR Review - Java & React
 * With Beautiful Markdown Tables and Code Snippets
 */

const fs = require('fs');
const path = require('path');

const DIFF_FILE = process.argv[2];

if (!DIFF_FILE || !fs.existsSync(DIFF_FILE)) {
    console.error('❌ Error: Diff file not found');
    process.exit(1);
}

const diffContent = fs.readFileSync(DIFF_FILE, 'utf-8');
const diffLines = diffContent.split('\n');

// Parse diff to map line numbers to files
const lineToFile = {};
let currentFile = '';
let currentLineNumber = 0;

diffLines.forEach((line, index) => {
    // Check for file headers: diff --git a/file.java b/file.java
    if (line.startsWith('diff --git')) {
        const match = line.match(/b\/(.+)$/);
        if (match) {
            currentFile = match[1];
        }
    }
    // Check for hunk headers: @@ -10,5 +10,7 @@
    else if (line.startsWith('@@')) {
        const match = line.match(/@@ -\d+,?\d* \+(\d+),?\d* @@/);
        if (match) {
            currentLineNumber = parseInt(match[1]);
        }
    }
    // Track line numbers for added/modified lines
    else if (line.startsWith('+') && !line.startsWith('+++')) {
        lineToFile[index + 1] = { file: currentFile, line: currentLineNumber };
        currentLineNumber++;
    }
    else if (line.startsWith(' ')) {
        currentLineNumber++;
    }
});

// Issue storage
const issues = {
    critical: [],
    high: [],
    medium: [],
    low: [],
    info: []
};

/**
 * Extract code snippet and line number for a pattern
 */
function findViolations(pattern, issueType, priority, impact) {
    const regex = new RegExp(pattern, 'gi');
    
    diffLines.forEach((line, index) => {
        if (regex.test(line)) {
            const diffLineNumber = index + 1;
            const fileInfo = lineToFile[diffLineNumber];
            
            if (fileInfo) {
                // Clean the line - remove +/- and trim, limit to 100 chars
                const cleanLine = line
                    .replace(/^[\+\-]\s*/, '')
                    .trim()
                    .substring(0, 100);
                
                if (cleanLine.length > 0) {
                    issues[priority].push({
                        type: issueType,
                        file: fileInfo.file,
                        line: fileInfo.line,
                        code: cleanLine,
                        impact: impact
                    });
                }
            }
        }
    });
}

/**
 * Check for multiple occurrences and group
 */
function findViolationsGrouped(pattern, issueType, priority, impact) {
    const regex = new RegExp(pattern, 'gi');
    const violations = [];
    
    diffLines.forEach((line, index) => {
        if (regex.test(line)) {
            const diffLineNumber = index + 1;
            const fileInfo = lineToFile[diffLineNumber];
            
            if (fileInfo) {
                const cleanLine = line
                    .replace(/^[\+\-]\s*/, '')
                    .trim()
                    .substring(0, 100);
                
                if (cleanLine.length > 0) {
                    violations.push({ 
                        file: fileInfo.file, 
                        line: fileInfo.line, 
                        cleanLine 
                    });
                }
            }
        }
    });
    
    if (violations.length > 0) {
        violations.slice(0, 3).forEach(v => {
            issues[priority].push({
                type: issueType,
                file: v.file,
                line: v.line,
                code: v.cleanLine,
                impact: impact
            });
        });
    }
}

// ===== SECURITY ANALYSIS =====
console.log('## 🔒 Security Analysis\n');

// Critical Security Issues
findViolationsGrouped(
    'password\\s*=\\s*["\'][^"\']+["\']',
    'Hardcoded password',
    'critical',
    '🔴 Credential exposure'
);

findViolationsGrouped(
    'api[_-]?key\\s*=\\s*["\'][^"\']+["\']',
    'Hardcoded API key',
    'critical',
    '🔴 Unauthorized access'
);

findViolationsGrouped(
    '(private[_-]?key|secret[_-]?key|token)\\s*=\\s*["\']',
    'Hardcoded secret/token',
    'critical',
    '🔴 Security breach'
);

// High Security Issues
findViolationsGrouped(
    'dangerouslySetInnerHTML',
    'XSS vulnerability',
    'high',
    '⚠️ Cross-site scripting risk'
);

findViolationsGrouped(
    'eval\\s*\\(',
    'Dangerous eval() usage',
    'high',
    '⚠️ Code injection risk'
);

findViolationsGrouped(
    'innerHTML\\s*=',
    'innerHTML usage',
    'high',
    '⚠️ Potential XSS'
);

findViolationsGrouped(
    '(Runtime\\.getRuntime|\\bexec\\(|\\bsystem\\()',
    'System command execution',
    'high',
    '⚠️ Command injection risk'
);

// Medium Security Issues
findViolationsGrouped(
    'http://',
    'Insecure HTTP URL',
    'medium',
    '💡 Use HTTPS instead'
);

// ===== JAVA ANALYSIS =====
console.log('## ☕ Java-Specific Analysis\n');

// Critical Java Issues
findViolationsGrouped(
    '\\.equals\\s*\\(\\s*null\\s*\\)|null\\s*\\.equals',
    'NullPointerException risk',
    'critical',
    '🔴 Use Objects.equals()'
);

findViolationsGrouped(
    'catch\\s*\\([^)]*Exception[^)]*\\)\\s*\\{\\s*\\}',
    'Empty catch block',
    'critical',
    '🔴 Swallows exceptions silently'
);

// High Java Issues
findViolationsGrouped(
    'new\\s+Thread\\s*\\(',
    'Unmanaged thread creation',
    'high',
    '⚠️ Use ExecutorService'
);

// Medium Java Issues
findViolationsGrouped(
    'System\\.(out|err)\\.println',
    'System.out usage',
    'medium',
    '💡 Use Logger (SLF4J/Log4j)'
);

findViolationsGrouped(
    '\\.printStackTrace\\s*\\(',
    'printStackTrace() usage',
    'medium',
    '💡 Use Logger.error()'
);

// Low Java Issues
findViolationsGrouped(
    '@Deprecated',
    'Deprecated API usage',
    'low',
    '📝 Use recommended alternative'
);

// ===== REACT ANALYSIS =====
console.log('## ⚛️ React-Specific Analysis\n');

// Critical React Issues
findViolationsGrouped(
    'this\\.state\\.[a-zA-Z_]+\\s*=',
    'Direct state mutation',
    'critical',
    '🔴 Use this.setState()'
);

findViolationsGrouped(
    'props\\.[a-zA-Z_]+\\s*=',
    'Props mutation',
    'critical',
    '🔴 Props are immutable'
);

// High React Issues
if (diffContent.includes('.map(') && !diffContent.includes('key=')) {
    findViolationsGrouped(
        '\\.map\\s*\\(',
        'Missing key prop in .map()',
        'high',
        '⚠️ Add unique key prop'
    );
}

if (diffContent.includes('useEffect(') && !diffContent.includes('useEffect(')) {
    findViolationsGrouped(
        'useEffect\\s*\\([^)]*\\)(?!.*\\[)',
        'useEffect without deps array',
        'high',
        '⚠️ Causes infinite re-renders'
    );
}

findViolationsGrouped(
    'component(WillMount|WillReceiveProps|WillUpdate)',
    'Deprecated lifecycle method',
    'high',
    '⚠️ Migrate to modern APIs'
);

// Low React Issues
findViolationsGrouped(
    '\\bvar\\s+[a-zA-Z_]',
    "Using 'var' keyword",
    'low',
    '📝 Use const/let instead'
);

// ===== CODE QUALITY =====
console.log('## 📊 Code Quality Analysis\n');

// High Code Quality Issues
findViolationsGrouped(
    'debugger;',
    'Debugger statement',
    'high',
    '⚠️ Remove before production'
);

// Medium Code Quality Issues
findViolationsGrouped(
    'console\\.(log|error|warn|debug)',
    'Console statements',
    'medium',
    '💡 Use proper logging'
);

findViolationsGrouped(
    '(TODO|FIXME)',
    'TODO/FIXME comment',
    'medium',
    '💡 Address before merge'
);

// ===== PERFORMANCE =====
console.log('## ⚡ Performance Analysis\n');

// High Performance Issues
findViolationsGrouped(
    'SELECT\\s+\\*|select\\s+\\*',
    'SELECT * query',
    'high',
    '⚠️ Specify needed columns'
);

findViolationsGrouped(
    '[nN]\\+1',
    'N+1 query problem',
    'high',
    '⚠️ Use JOIN or batch loading'
);

// Medium Performance Issues
findViolationsGrouped(
    '\\.map\\([^)]*\\.map\\(',
    'Nested .map() loops',
    'medium',
    '💡 O(n²) complexity - optimize'
);

findViolationsGrouped(
    'for\\s*\\([^)]*\\)\\s*\\{[^}]*for\\s*\\(',
    'Nested for loops',
    'medium',
    '📝 Review algorithm complexity'
);

// ===== GENERATE REPORT =====
console.log('\n---\n');
console.log('## 📋 Detailed Issue Report\n');

const priorityConfig = {
    critical: { emoji: '🚨', label: 'CRITICAL ISSUES', color: 'critical' },
    high: { emoji: '⚠️', label: 'HIGH PRIORITY ISSUES', color: 'high' },
    medium: { emoji: '⚡', label: 'MEDIUM PRIORITY ISSUES', color: 'medium' },
    low: { emoji: 'ℹ️', label: 'LOW PRIORITY ISSUES', color: 'low' },
    info: { emoji: '📝', label: 'INFORMATIONAL', color: 'info' }
};

Object.keys(priorityConfig).forEach(priority => {
    const issueList = issues[priority];
    if (issueList.length > 0) {
        const config = priorityConfig[priority];
        console.log(`### ${config.emoji} ${config.label} (${issueList.length})\n`);
        console.log('| Issue | File:Line | Code Snippet | Impact |');
        console.log('|-------|-----------|--------------|--------|');
        
        issueList.forEach(issue => {
            const codeSnippet = `\`${issue.code.replace(/\|/g, '\\|')}\``;
            const location = `\`${issue.file}:${issue.line}\``;
            console.log(`| ${issue.type} | ${location} | ${codeSnippet} | ${issue.impact} |`);
        });
        
        console.log('');
    }
});

// ===== SUMMARY =====
console.log('---\n');
console.log('## 📊 Summary\n');

const totalCritical = issues.critical.length;
const totalHigh = issues.high.length;
const totalMedium = issues.medium.length;
const totalLow = issues.low.length;
const totalInfo = issues.info.length;
const totalIssues = totalCritical + totalHigh + totalMedium + totalLow;

console.log('| Priority | Count |');
console.log('|----------|-------|');
console.log(`| 🚨 Critical | ${totalCritical} |`);
console.log(`| ⚠️ High | ${totalHigh} |`);
console.log(`| ⚡ Medium | ${totalMedium} |`);
console.log(`| ℹ️ Low | ${totalLow} |`);
console.log(`| 📝 Info | ${totalInfo} |`);
console.log(`| **📈 Total** | **${totalIssues}** |`);

console.log('');

if (totalIssues === 0) {
    console.log('> ✅ **ALL CHECKS PASSED!** No issues found.\n');
} else {
    if (totalCritical > 0) {
        console.log('> ❌ **CRITICAL:** Must fix before merge!\n');
    } else if (totalHigh > 0) {
        console.log('> ⚠️ **HIGH PRIORITY:** Should fix before merge\n');
    } else {
        console.log('> 💡 **Review and address issues as needed**\n');
    }
}

console.log('---\n');
console.log('*Generated by GitHub PR Review Agent* 🤖');
