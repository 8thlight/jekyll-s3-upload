Gem::Specification.new do |spec|
  spec.name          = 'jekyll-s3-upload'
  spec.version       = '0.0.1'
  spec.authors       = ['Myles Megyesi']
  spec.summary       = 'Upload a Jekyll site to Amazon S3.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/mylesmegyesi/jekyll-s3-upload'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'dotenv', '~> 2.0.1'
  spec.add_runtime_dependency 'rack', '~> 1.6.1'
  spec.add_runtime_dependency 'aws-sdk', '~> 2.0.45'
  spec.add_runtime_dependency 'activesupport', '>= 3.0.0 '
  spec.add_development_dependency 'bundler', '~> 1.7'
end
