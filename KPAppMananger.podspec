#
# Be sure to run `pod lib lint GuardApp.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'KPAppMananger'
    s.version          = '0.1.0'
    s.summary          = '安装器.'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
    s.description      = <<-DESC
                          静默安装，卸载，打开，监听。
                          进程间通信。
                          获取设备UDID。
                          后台保活。
                         DESC
  
    s.homepage         = 'https://github.com/LZRight123'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { '350442340@qq.com' => '350442340@qq.com' }
    s.source           = { :git => 'https://github.com/LZRight123/GuardApp.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
    s.ios.deployment_target = '8.0'
#    s.static_framework = true
  
    s.source_files = 'Classes/**/*.{h,m}'
    
    s.resource_bundles = {
      'KPAppInstall' => ['Assets/*.mp3']
    }
  
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'MobileCoreServices'
    s.vendored_frameworks = 'Frameworks/**/*.framework'

    s.dependency 'AFNetworking'
    s.dependency 'GCDWebServer'

  end
