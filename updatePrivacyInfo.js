#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

module.exports = function(context) {
    try {
        const iosPlatformPath = path.join(context.opts.projectRoot, 'platforms', 'ios');

        // Find the first folder inside 'platforms/ios' that ends with '.xcodeproj' removed
        const appFolders = fs.readdirSync(iosPlatformPath).filter(f => {
            const fullPath = path.join(iosPlatformPath, f);
            return fs.statSync(fullPath).isDirectory() && fs.existsSync(path.join(fullPath, `${f}.xcodeproj`));
        });

        if (appFolders.length === 0) {
            console.warn('No iOS app folder found in', iosPlatformPath);
            return;
        }

        const appFolder = path.join(iosPlatformPath, appFolders[0]);
        const privacyFilePath = path.join(appFolder, 'PrivacyInfo.xcprivacy');

        if (!fs.existsSync(privacyFilePath)) {
            console.warn('PrivacyInfo.xcprivacy not found at', privacyFilePath);
            return;
        }

        const newContent = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>Device ID</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>App Functionality</string>
        <string>Analytics</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>User ID</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>App Functionality</string>
        <string>Analytics</string>
      </array>
    </dict>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>Email Address</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <true/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>App Functionality</string>
        <string>Analytics</string>
      </array>
    </dict>
  </array>
</dict>
</plist>`;

        fs.writeFileSync(privacyFilePath, newContent, { encoding: 'utf8' });
        console.log('✅ PrivacyInfo.xcprivacy successfully updated in', appFolder);
    } catch (err) {
        console.error('❌ Failed to update PrivacyInfo.xcprivacy:', err);
    }
};
