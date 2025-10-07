# scripts/podhooks.rb
Pod::HooksManager.register('cordova-plugin-firebase-firestore', :post_install) do |installer|
  installer.pods_project.targets.each do |target|
    # Force minimum deployment target to iOS 12
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end

    # Patch for BoringSSL-GRPC build errors
    if target.name == 'BoringSSL-GRPC'
      target.build_configurations.each do |config|
        # Remove unsupported flags
        flags = config.build_settings['OTHER_CFLAGS'] || []
        flags = flags.reject { |f| f.include?('-G') } # remove problematic flag
        config.build_settings['OTHER_CFLAGS'] = flags

        # Exclude arm64 simulator if needed
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'

        puts "✅ Patched BoringSSL-GRPC for build compatibility."
      end
    end
  end
  puts "✅ Firebase Firestore pods patched for iOS 12."
end
