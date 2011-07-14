# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rufus-scheduler}
  s.version = "2.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mettraux"]
  s.date = %q{2011-06-25}
  s.description = %q{job scheduler for Ruby (at, cron, in and every jobs).}
  s.email = ["jmettraux@gmail.com"]
  s.files = ["Rakefile", "lib/rufus/otime.rb", "lib/rufus/sc/cronline.rb", "lib/rufus/sc/jobqueues.rb", "lib/rufus/sc/jobs.rb", "lib/rufus/sc/rtime.rb", "lib/rufus/sc/scheduler.rb", "lib/rufus/sc/version.rb", "lib/rufus/scheduler.rb", "lib/rufus-scheduler.rb", "spec/at_in_spec.rb", "spec/at_spec.rb", "spec/blocking_spec.rb", "spec/cron_spec.rb", "spec/cronline_spec.rb", "spec/every_spec.rb", "spec/exception_spec.rb", "spec/in_spec.rb", "spec/job_spec.rb", "spec/rtime_spec.rb", "spec/schedulable_spec.rb", "spec/scheduler_spec.rb", "spec/spec_base.rb", "spec/stress_schedule_unschedule_spec.rb", "spec/timeout_spec.rb", "test/kjw.rb", "test/t.rb", "rufus-scheduler.gemspec", "CHANGELOG.txt", "CREDITS.txt", "dump.txt", "LICENSE.txt", "TODO.txt", "README.rdoc"]
  s.homepage = %q{http://github.com/jmettraux/rufus-scheduler}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rufus}
  s.rubygems_version = %q{1.4.2}
  s.summary = %q{job scheduler for Ruby (at, cron, in and every jobs)}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<tzinfo>, [">= 0.3.23"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 2.0"])
    else
      s.add_dependency(%q<tzinfo>, [">= 0.3.23"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 2.0"])
    end
  else
    s.add_dependency(%q<tzinfo>, [">= 0.3.23"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 2.0"])
  end
end
