#
#  Be sure to run `pod spec lint XLLFileDownload.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "XLLFileDownload"
  s.version      = "1.0.0"
  s.summary      = "A short description of XLLFileDownload."
  s.description  = <<-DESC
        XLLFileDownload.
                   DESC

  s.homepage     = "https://github.com/XLLKit/XLLFileDownload"
  # s.license      = "MIT (example)"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "b593771943" => "1593771943@qq.com" }
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/XLLKit/XLLFileDownload.git", :tag => "#{s.version}" }

# s.source_files  = "Classes", "Classes/**/*.{h,m}"
    s.subspec 'Core' do |ss|
# ss.resources = 'OKARecordScreen/Sources/*.png'
        ss.source_files = 'XLLFileAction/*{h,m}'
    end
  s.requires_arc = true

end
