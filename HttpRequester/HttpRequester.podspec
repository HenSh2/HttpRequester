
Pod::Spec.new do |s|

  s.name          = "HttpRequester"
  s.version       = "1.0.0"
  s.summary       = "Helper for http requests in swift."
  s.description   = "Helper for all your http requests. fast and super easy to use"
  s.homepage      = "https://github.com/HenSh2/HttpRequester"
  s.license       = "MIT"
  s.author        = { "HenSh" => "hensh2@gmail.com" }
  s.platform      = :ios, "10.0"
  s.source        = { :git => "https://github.com/HenSh2/HttpRequester.git", :tag => "1.0.0" }
  s.source_files  = "HttpRequester/**/*.swift"
  s.swift_version = "4.2"

end
