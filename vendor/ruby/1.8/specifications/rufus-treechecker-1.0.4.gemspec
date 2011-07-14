# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rufus-treechecker}
  s.version = "1.0.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mettraux"]
  s.date = %q{2010-12-21}
  s.description = %q{
    tests strings of Ruby code for unauthorized patterns (exit, eval, ...)
  }
  s.email = ["jmettraux@gmail.com"]
  s.files = ["Rakefile", "lib/rufus/tree_checker.rb", "lib/rufus/treechecker.rb", "lib/rufus-tree_checker.rb", "lib/rufus-treechecker.rb", "spec/high_spec.rb", "spec/low_spec.rb", "spec/misc_spec.rb", "spec/ruleset_spec.rb", "spec/spec_base.rb", "test/bm.rb", "rufus-treechecker.gemspec", "CHANGELOG.txt", "CREDITS.txt", "LICENSE.txt", "README.txt"]
  s.homepage = %q{http://rufus.rubyforge.org}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rufus}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{tests strings of Ruby code for unauthorized patterns (exit, eval, ...)}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby_parser>, [">= 2.0.5"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 2.0"])
    else
      s.add_dependency(%q<ruby_parser>, [">= 2.0.5"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 2.0"])
    end
  else
    s.add_dependency(%q<ruby_parser>, [">= 2.0.5"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 2.0"])
  end
end
