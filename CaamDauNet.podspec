
Pod::Spec.new do |s|
  s.name             = 'CaamDauNet'
  s.version          = '1.2.0'
  s.summary          = 'CaamDau 系列产品：网络层 Alamofire 、SwiftyJSON、Cache、Codable 扩展.'
  s.description      = <<-DESC
  TODO: CaamDau 系列产品：iOS 便捷开发套件 Swift 版：iOS项目开发通用&非通用型模块代码，多功能组件，可快速集成使用以大幅减少基础工作量；便利性扩展&链式扩展、UI排班组件Form、正则表达式扩展RegEx、计时器管理Timer、简易提示窗HUD、AppDelegate解耦方案、分页控制Page、自定义导航栏Net、阿里矢量图标管理IconFonts、MJRefresh扩展、Alamofire扩展......
  附.各种类库使用示例demo.
                       DESC

  s.homepage         = 'https://github.com/CaamDau'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liucaide' => '565726319@qq.com' }
  s.source           = { :git => 'https://github.com/CaamDauNet.git', :tag => s.version }

  s.ios.deployment_target = '9.0'
  s.swift_version = ['4.0', '4.2', '5.0']
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = 'Net/Core/*'
    core.dependency 'Alamofire'
    core.dependency 'CaamDauExtension'
  end
  
  s.subspec 'All' do |all|
    all.dependency 'CaamDauNet/Core'
    all.dependency 'CaamDauNet/SwiftyJSON'
    all.dependency 'CaamDauNet/Cache'
    all.dependency 'CaamDauNet/Codable'
  end
  
  s.subspec 'SwiftyJSON' do |json|
    json.source_files = 'Net/SwiftyJSON/*.{swift}'
    json.dependency 'CaamDauNet/Core'
    json.dependency 'SwiftyJSON'
  end
  
  s.subspec 'Cache' do |cache|
    cache.source_files = 'Net/Cache/*.{swift}'
    cache.dependency 'CaamDauNet/Core'
    cache.dependency 'Cache'
  end
  
  s.subspec 'Codable' do |codable|
    codable.source_files = 'Net/Codable/*.{swift}'
    codable.dependency 'CaamDauNet/Core'
    codable.dependency 'CleanJSON'
  end
  
  s.frameworks = 'Foundation'
end
