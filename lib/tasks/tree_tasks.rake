 desc "Explaining what the task does"
 task :tree do
   FileUtils.cp(File.dirname(__FILE__) + "/../public/javascripts/tree.js", RAILS_ROOT + '/public/javascripts/')
 end


