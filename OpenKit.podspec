
Pod::Spec.new do |s|
  s.name         = "OpenKit"
  s.version      = "2.0a"
  s.summary      = "Open source backend for game developers."
  s.homepage     = "http://openkit.io"
  s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }
  s.author       = 'Manu Mtz-Almeida', 'Lou Zell', 'Suneet', 'Todd Hamilton'
  s.platform     = :ios, '6.0'
  s.source       = { :git => "https://github.com/OpenKit/openkit-ios.git", :tag => "v2.0a" }

  s.source_files  = 'OpenKit/**/*.{h,m}'
  s.public_header_files = 'OpenKit/**/*.h' 
  s.resource  = "OpenKit/ok_wildcard.der"

  s.frameworks = 'UIKit', 'Foundation', 'Security', 'CoreGraphics', 'QuartzCore', 'GameKit'
  s.libraries = 'z', 'sqlite3'

  s.requires_arc = true
  s.dependency 'Facebook-iOS-SDK'

end
