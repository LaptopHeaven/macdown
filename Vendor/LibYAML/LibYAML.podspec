Pod::Spec.new do |s|
  s.name = 'LibYAML'
  s.version = '0.2.5'
  s.summary = 'LibYAML is a YAML 1.1 parser and emitter written in C.'
  s.homepage = 'https://github.com/yaml/libyaml'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = 'LibYAML contributors'
  s.source = {
    :http => 'https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz',
    :sha256 => 'c642ae9b75fee120b2d96c712538bd2cf283228d2337df2cf2988e3c02678ef4'
  }
  s.source_files = ['config.h', 'include/*.h', 'src/*.{c,h}']
  s.public_header_files = 'include/*.h'
  s.xcconfig = { 'OTHER_CFLAGS' => '-DHAVE_CONFIG_H' }
  s.prepare_command = './configure'
  s.requires_arc = false
end
