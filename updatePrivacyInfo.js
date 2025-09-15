#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

module.exports = function(context) {
  const iosPlatformPath = path.join(context.opts.projectRoot, 'platforms', 'ios');
  const frameworks = ['FirebaseCore.framework', 'nanopb.framework'];

  frameworks.forEach(fw => {
    const targetFolder = path.join(iosPlatformPath, 'Turtle Slap', 'Frameworks', fw);
    if (fs.existsSync(targetFolder)) {
      fs.copyFileSync(
        path.join(context.opts.projectRoot, 'PrivacyInfo.xcprivacy'),
        path.join(targetFolder, 'PrivacyInfo.xcprivacy')
      );
      console.log(`Copied PrivacyInfo.xcprivacy into ${fw}`);
    } else {
      console.warn(`Framework folder not found: ${fw}`);
    }
  });
};
