const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// Configuration
const TESTS_DIR = __dirname;
const LOGS_DIR = path.join(TESTS_DIR, 'logs');

// Ensure logs directory exists
if (!fs.existsSync(LOGS_DIR)) {
    fs.mkdirSync(LOGS_DIR);
}

// List of tests to run
const tests = [
    { name: 'audit_users', script: 'audit_users.js' },
    { name: 'audit_owners', script: 'audit_owners.js' },
    { name: 'audit_files', script: 'audit_files.js' },
    { name: 'audit_sessions', script: 'audit_sessions.js' },
];

/**
 * Executes a test script and writes output to a log file.
 * @param {Object} test - The test object containing name and script.
 */
function runTest(test) {
    return new Promise((resolve, reject) => {
        const scriptPath = path.join(TESTS_DIR, test.script);
        const logPath = path.join(LOGS_DIR, `${test.name}.log`);
        const mdLogPath = path.join(LOGS_DIR, `${test.name}_output.md`);

        console.log(`Running ${test.name}...`);

        exec(`node "${scriptPath}"`, { cwd: path.join(TESTS_DIR, '..') }, (error, stdout, stderr) => {
            const timestamp = new Date().toISOString();
            let logContent = `--- Test Run: ${timestamp} ---\n`;

            if (error) {
                logContent += `STATUS: FAILED\n`;
                logContent += `ERROR: ${error.message}\n`;
            } else {
                logContent += `STATUS: SUCCESS\n`;
            }

            logContent += `\n--- STDOUT ---\n${stdout}\n`;

            if (stderr) {
                logContent += `\n--- STDERR ---\n${stderr}\n`;
            }

            logContent += `\n${'-'.repeat(50)}\n`;

            // Write to .log file (append mode)
            fs.appendFileSync(logPath, logContent);

            // Write to .md file (overwrite mode for latest run, with formatting)
            const mdContent = `# Test Output: ${test.name}
**Date**: ${timestamp}
**Status**: ${error ? '❌ FAILED' : '✅ SUCCESS'}

## Output Log
\`\`\`text
${stdout}
\`\`\`

${stderr ? `## Errors\n\`\`\`text\n${stderr}\n\`\`\`` : ''}
`;
            fs.writeFileSync(mdLogPath, mdContent);

            if (error) {
                console.error(`❌ ${test.name} failed. See logs/${test.name}.log`);
                // We resolve anyway to let other tests run, but you could reject to stop.
                resolve({ success: false, name: test.name });
            } else {
                console.log(`✅ ${test.name} completed. Logs saved.`);
                resolve({ success: true, name: test.name });
            }
        });
    });
}

async function runAllTests() {
    console.log('Starting Test Suite...');
    console.log(`Logs will be saved to: ${LOGS_DIR}`);

    const results = [];

    for (const test of tests) {
        const result = await runTest(test);
        results.push(result);
    }

    console.log('\n--- Summary ---');
    results.forEach(r => {
        console.log(`${r.name}: ${r.success ? 'PASS' : 'FAIL'}`);
    });
}

runAllTests();
