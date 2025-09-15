#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

module.exports = function(context) {
    // Only run for iOS
    if (context.opts.platforms.indexOf('ios') < 0) return;

    const projectRoot = context.opts.projectRoot || process.cwd();
    const iosPlatformPath = path.join(projectRoot, 'platforms', 'ios');

    // List of frameworks that need the PrivacyInfo.xcprivacy
    const frameworks = [
        'FirebaseCore.framework',
        'nanopb.framework'
    ];

    frameworks.forEach(frameworkName => {
        const frameworkPath = path.join(iosPlatformPath, 'Frameworks', frameworkName);
        if (!fs.existsSync(frameworkPath)) {
            console.warn(`Framework folder not found: ${frameworkPath}`);
            return;
        }

        const srcFile = path.join(projectRoot, 'PrivacyInfo.xcprivacy'); // your privacy file in plugin root
        const destFile = path.join(frameworkPath, 'PrivacyInfo.xcprivacy'); // destination inside framework

        try {
            fs.copyFileSync(srcFile, destFile);
            console.log(`Copied privacy file to: ${destFile}`);
        } catch (err) {
            console.error(`Failed to copy privacy file to ${destFile}:`, err);
        }
    });
};
