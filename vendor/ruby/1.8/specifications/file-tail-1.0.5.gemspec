# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{file-tail}
  s.version = "1.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = %q{2010-03-25}
  s.default_executable = %q{rtail}
  s.description = %q{Library to tail files in Ruby}
  s.email = %q{flori@ping.de}
  s.executables = ["rtail"]
  s.extra_rdoc_files = ["README"]
  s.files = ["CHANGES", "bin/rtail", "VERSION", "README", "make_doc.rb", "Rakefile", "examples/pager.rb", "examples/tail.rb", "lib/file/tail/version.rb", "lib/file/tail.rb", "tests/test_file-tail.rb", "COPYING", "install.rb"]
  s.homepage = %q{http://flori.github.com/file-tail}
  s.rdoc_options = ["--main", "README", "--title", "File::Tail - Tailing files in Ruby"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{file-tail}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{File::Tail for Ruby}
  s.test_files = ["tests/test_file-tail.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<spruz>, [">= 0.1.0"])
    else
      s.add_dependency(%q<spruz>, [">= 0.1.0"])
    end
  else
    s.add_dependency(%q<spruz>, [">= 0.1.0"])
  end
end
