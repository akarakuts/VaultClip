platform :osx, '10.13'

project 'VaultClip', {
  'Debug' => :debug,
  'Release' => :release,
  'Beta Debug' => :debug,
  'Beta Release' => :release,
  'XCTest' => :debug
}

target 'VaultClip' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for VaultClip
    pod 'Default'
    pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
    pod 'RxSwift', '~> 5'
    pod 'RxCocoa', '~> 5'

    target 'VaultClipTests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end

    target 'VaultClipUITests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 5'
        pod 'RxTest', '~> 5'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 5'
        pod 'RxCocoa', '~> 5'
    end
end

post_install do |installer|
    deployment_target = '10.13'

    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = deployment_target
        end
    end

    login_service_kit = File.join(installer.sandbox.root, 'LoginServiceKit/Lib/LoginServiceKit/LoginServiceKit.swift')
    next unless File.exist?(login_service_kit)

    contents = File.read(login_service_kit)
    snapshot_line = 'let loginItemsListSnapshot: NSArray = LSSharedFileListCopySnapshot(loginItemList, nil).takeRetainedValue()'
    next unless contents.include?(snapshot_line)

    remove_login_items = contents[/static func removeLoginItems.*?return true\n    \}/m]
    login_item = contents[/static func loginItem.*?return nil\n    \}/m]

    if remove_login_items&.include?(snapshot_line)
        contents.sub!(
            remove_login_items,
            remove_login_items.sub(
                snapshot_line,
                "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return false }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()"
            )
        )
    end

    if login_item&.include?(snapshot_line)
        contents.sub!(
            login_item,
            login_item.sub(
                snapshot_line,
                "guard let snapshot = LSSharedFileListCopySnapshot(loginItemList, nil) else { return nil }\n        let loginItemsListSnapshot: NSArray = snapshot.takeRetainedValue()"
            )
        )
    end

    File.write(login_service_kit, contents)
end
