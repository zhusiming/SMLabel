#
#  Be sure to run `pod spec lint SMLabel.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "SMLabel"
  s.version      = "1.1.1"
  s.summary      = "through this class can be achieved by mixed text, text to add a link event, connect the text color settings."

  s.homepage     = "https://github.com/zhusiming/SMLabel"


  s.license     = { :type => "MIT", :file => "LICENSE" }


  s.author             = { "zhusiming" => "siming_zhu@163.com" }

  s.platform     = :ios, "8.0"

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/zhusiming/SMLabel.git", :tag => "v#{s.version}" }

  s.source_files  = "SMLabel/SMLabel/SMLabel.{h,m}"
  s.requires_arc = true
end

# 1.打版本号
# git tag "v1.0.0"
# git push --tags
# git push origin master

# 2.注册CocoaPods
# pod --version
# 版本低于0.33
# sudo gen install cocoapods
# pod setup

# 3.看自己有没有注册
# pod trunk me

# 4.创建podspec文件
# pod spec create SMLabel

# 5.验证.podspec
# pod spec lint SMLabel.podspec --verbose --allow-warnings

# 6.发布
# pod trunk push SMLabel.podspec --allow-warnings

# 7.测试自己的cocoapods
# 这个时候使用pod search搜索的话会提示搜索不到，可以执行以下命令更新本地search_index.json文件
# rm ~/Library/Caches/CocoaPods/search_index.json
# pod search SMLabel




