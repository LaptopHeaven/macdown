Pod::Spec.new do |s|
  s.name = 'LibYAML'
  s.version = '0.2.5'
  s.summary = 'LibYAML is a YAML 1.1 parser and emitter written in C.'
  s.homepage = 'https://github.com/yaml/libyaml'
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.authors = 'LibYAML contributors'
  # Upstream nesting-depth fix, before the next stable release.
  s.source = {
    :git => 'https://github.com/yaml/libyaml.git',
    :commit => '51843fe48257c6b7b6e70cdec1db634f64a40818'
  }
  s.source_files = ['config.h', 'include/*.h', 'src/*.{c,h}']
  s.public_header_files = 'include/*.h'
  s.xcconfig = { 'OTHER_CFLAGS' => '-DHAVE_CONFIG_H' }
  s.prepare_command = './bootstrap && ./configure'
  s.requires_arc = false
end
