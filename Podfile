platform :ios, '16.1'

target 'AgoraPIPAndSystemScreenShare' do
  use_frameworks!

  pod 'AgoraRtcEngine_iOS', '4.1.0'
end

target 'PIPScreenShareExtension' do
  use_frameworks!

  pod 'AgoraRtcEngine_iOS', '4.1.0'
end

post_install do |installer|
    installer.aggregate_targets.each do |aggregate_target|
        puts aggregate_target.name
        if aggregate_target.name == 'Pods-AgoraPIPAndSystemScreenShare'
            aggregate_target.xcconfigs.each do |config_name, config_file|
                aggregate_target.pod_targets.each do |pod_target|
                    pod_target.specs.each do |spec|
                        if spec.attributes_hash['ios'] != nil
                            frameworkPaths = spec.attributes_hash['ios']['vendored_frameworks']
                        else
                            frameworkPaths = spec.attributes_hash['vendored_frameworks']
                        end
                        if frameworkPaths != nil
                            frameworkNames = Array(frameworkPaths).map(&:to_s).map do |filename|
                                extension = File.extname filename
                                File.basename filename, extension
                            end
                            frameworkNames.each do |name|
                                puts "Removing #{name} from OTHER_LDFLAGS"
                                config_file.frameworks.delete(name)
                            end
                        end
                    end
                end
                xcconfig_path = aggregate_target.xcconfig_path(config_name)
                config_file.save_as(xcconfig_path)
            end
        end
    end
end
