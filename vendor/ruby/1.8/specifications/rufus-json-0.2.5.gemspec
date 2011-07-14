# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rufus-json}
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mettraux", "Torsten Schoenebaum"]
  s.date = %q{2010-08-09}
  s.description = %q{
One interface to various JSON ruby libs (yajl, json, json_pure, json-jruby, active_support). Has a preference for yajl.
  }
  s.email = %q{jmettraux@gmail.com}
  s.extra_rdoc_files = ["LICENSE.txt", "README.rdoc"]
  s.files = ["CHANGELOG.txt", "CREDITS.txt", "LICENSE.txt", "README.rdoc", "Rakefile", "lib/rufus-json.rb", "lib/rufus/json.rb", "rufus-json.gemspec", "test/backend_test.rb", "test/do_test.rb", "test/nesting20.rb", "test/test.rb"]
  s.homepage = %q{http://github.com/jmettraux/rufus-json/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rufus}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{One interface to various JSON ruby libs (yajl, json, json_pure, json-jruby, active_support). Has a preference for yajl.}
  s.test_files = ["test/test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_development_dependency(%q<activesupport>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
  end
end
