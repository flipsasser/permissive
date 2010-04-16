require 'rake'
require 'spec/rake/spectask'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--colour --format progress --loadby mtime --reverse']
  t.spec_files = FileList['spec/**/*_spec.rb']
end

namespace :spec do
  desc 'Run the specs with Rcov output'
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_files = FileList['spec/**/*.rb']
    t.rcov = true
    t.rcov_opts = ['--exclude', 'spec/*,gems/*']
  end
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "permissive"
    gemspec.summary = "Permissive gives your ActiveRecord models granular permission support"
    gemspec.description = %{Permissive combines a model-based permissions system with bitmasking to
    create a flexible approach to maintaining permissions on your ActiveRecord
    models. It supports an easy-to-use set of methods for accessing and
    determining permissions, including some fun metaprogramming.}
    gemspec.email = "flip@x451.com"
    gemspec.homepage = "http://github.com/flipsasser/permissive"
    gemspec.authors = ["Flip Sasser", "Simon Parsons"]
  end
rescue LoadError
end
