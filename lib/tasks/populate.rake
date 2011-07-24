# coding: utf-8
# require 'ffaker' if Rails.env.development?

namespace :db do

  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      timed { empty_tables(Part, Document) }
    end

    desc "Load all development fixtures."
    task :all => :environment do
      timed { create_parts }
      timed { create_documents }
    end

    desc "Load Part development fixtures."
    task :parts => :environment do
      timed { empty_tables(Part, Document) }
      timed { create_parts }
    end

    desc "Load Document development fixtures."
    task :documents => :environment do
      timed { empty_tables(Document) }
      timed { create_documents }
    end

  end

end

private

def empty_tables(*tables)
  print "Deleting the content of #{tables.join(', ')}.. => "
  tables.each do |table|
    if table.is_a?(Class)
      table.delete_all
    else
      Site.connection.delete("DELETE FROM #{table} WHERE 1=1")
    end
  end
  puts "#{tables.join(', ')} empty!"
end

def create_parts
  25.times do |i|
    Part.create!(:ident => "part#{i+100000}", :designation => "des part#{i}")
  end
end

def create_documents
  Document.create!(:ident => 'doc1111', :designation => 'des doc1111')
  Document.create!(:ident => 'doc2222', :designation => 'des doc2222')
  Document.create!(:ident => 'img3333', :designation => 'des img3333')

  Part.all.each do |part|
    10.times do |i|
      part.documents.create!(:ident => "doc#{i+1000000+(part.id-1)*10}", :designation => "des document#{i}")
    end
  end
end

def argv(var_name)
  var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
  if var
    var.sub($1, '')
  else
    nil
  end
end

def argv_index(var_name='index', default_index=nil)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_index
  end
end

def argv_count(var_name='count', default_count=5)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_count
  end
end
