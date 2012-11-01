require 'logger'
require 'active_record'
require 'action_controller'
require 'application_controller'
require 'plugins/acl_system2/lib/caboose/access_control'

#
require 'models/sylrplm_common'
require 'models/plm_object'
require 'ruote_routing'
require 'classes/app_classes'
require 'controllers/plm_event'
require 'controllers/plm_favorites'
require 'controllers/plm_lifecycle'
require 'controllers/plm_tree'
require 'controllers/plm_object_controller_module'

namespace :sylrplm do

  task :load_config => :rails_env do
    ActiveRecord::Base.configurations = Rails::Configuration.new.database_configuration
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::INFO
    $stdout.puts "Database configuration=#{ActiveRecord::Base.configurations}"
  end

  desc 'import domain objects : [db/fixtures,admin"] or [db/fixtures,mecanic] or [db/fixtures,cooking] '
  task :import_domain, [:path, :domain] => [:connect, :environment] do |t, args|
    #args.with_defaults(:domain => :admin)
    domain = args.domain.to_s
    path = args.path.to_s
    puts "path is #{path}, domain is #{domain}"
    fixtures_path = "#{path}/#{domain}"
    unless domain.empty?
      ###truncate
      #Rake::Task["db:fixtures:load FIXTURES_PATH=#{fixtures_path}"].invoke
      ENV["FIXTURES_PATH"] = fixtures_path
      puts "fixtures_path=#{ENV['FIXTURES_PATH']}"
      Rake::Task["db:fixtures:load"].invoke
      ::Access.reset
    else
      $stdout.puts "Path and Domain are mandatory"
    end
  end

  desc "Truncate all tables"
  task :truncate => :connect do
    truncate
  end

  desc 'Export datas of a domain in yaml files : ""=["admin"] or ["mecanic"] or ["cooking"]'
  task :export_domain, [:path, :domain] => [:connect, :environment] do |t, args|
    #args.with_defaults(:domain => :admin)
    domain=args.domain.to_s
    path = args.path.to_s
    puts "path is #{path}, domain is #{domain}"
    unless domain.empty?
      fixtures_path = "#{path}/#{domain}"
      FileUtils.mkdir_p fixtures_path
      export_domain domain, fixtures_path
    else
      $stdout.puts "Domain is mandatory"
    end
  end

  task :connect => :load_config do
    ActiveRecord::Base.establish_connection
  end

  desc "load domain objects : ""=[:admin] or [:mecanic] or [:cooking] (obsolete)"
  task :load_domain_old, [:domain] => :connect do |t, args|
    args.with_defaults(:domain => :admin)
    puts "domain is #{args.domain}"
    if args.domain.empty? || args.domain == "admin"
      fixtures_path="db/fixtures/admin"
    else
      fixtures_path="db/fixtures/domains/#{args.domain}"
    end
    truncate
    require "#{RAILS_ROOT}/config/initializers/sylrplm"
    tables=[]
    Dir.glob("#{fixtures_path}/*.yml").each do |file|
      table = "#{File.basename(file, '.*')}"
      tables << table
    end
    puts "tables=#{tables}"
    Fixtures.create_fixtures(fixtures_path, tables)
  end

  def truncate
    begin
      config = ActiveRecord::Base.configurations[RAILS_ENV]
      case config["adapter"]
      when "mysql"
        ActiveRecord::Base.connection.tables.each do |table|
          ActiveRecord::Base.connection.execute("TRUNCATE #{table}")
        end
      when "sqlite", "sqlite3"
        ActiveRecord::Base.connection.tables.each do |table|
          ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
          ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence where name='#{table}'")
        end
        ActiveRecord::Base.connection.execute("VACUUM")
      end
    rescue
      $stderr.puts "Error while truncating. Make sure you have a valid database.yml file and have created the database tables before running this command. You should be able to run rake db:migrate without an error"
    end
  end

  desc "Export internal datas in seed.rb (obsolete)"
  task :export_internal_data => :connect do
    export_seed
  end

  desc "Import internal datas from seed.rb (obsolete)"
  task :import_internal_data => :connect do
    import_seed
  end

  def export_domain (adomain, fixtures_path)
    if load_models
      #
      
      FileUtils.remove(Dir.glob("#{fixtures_path}/*"))
      assocs = {}
      domains = []
      domains << "admin"
      domains << adomain 
      domains.each do |domain|
        puts "Domain:#{domain} -------------------------------"
        Object.subclasses_of(ActiveRecord::Base).each do |model|
          begin
  
            reflections = model.reflect_on_all_associations(:has_and_belongs_to_many)
           # puts "#{model}.reflections=#{reflections.count}" if reflections.count>0
            # reflections.each do |r|
              # puts "#{r}:#{model} have #{r.macro} to #{r.name} on table=#{r.options[:join_table]}"+
              # " active_record=#{r.active_record} class_name=#{r.class_name}"+
              # " foreign_key=#{r.association_foreign_key} key_name=#{r.primary_key_name}"
            # end
            
            # model attributs list
            cols=[]
            #model.columns.reject{ |c| c.primary}. each do |col|
            model.columns.each do |col|
              cols<<"#{col.name}" unless %w[created_at updated_at].include?(col.name)
            end
            isdomaindata = cols.include?("domain")
            $stdout.puts "Model:#{model}, Domain datas?:#{isdomaindata}, #{model.count} objects"
            #$stdout.puts "Model:#{model}, Domain datas?:#{isdomaindata}, #{model.count} objects, columns:#{model}:#{cols}"
            # take only model with domain attribut
            if isdomaindata && model.count > 0
              # opening output file
              out_yml = File.open("#{fixtures_path}/#{model.name.downcase}s.yml", "a")
              puts "Opening #{out_yml.inspect} ----------------------"
              model.all.each do |obj|
              # only if data is declared on a domain
                if obj.send("domain") == domain
                  out_yml.write( obj.to_yaml)
                  reflections.each do |r|
                    ext_ids = obj.send("#{r.association_foreign_key}s")
                    if ext_ids.count>0
                      #rel_yml = File.open("#{fixtures_path}/#{r.options[:join_table]}.yml", "a")
                      ext_ids.each do |ext_id|
                        assocs[r.options[:join_table]] =[] if assocs[r.options[:join_table]].nil?
                        trouve=false
                        assocs[r.options[:join_table]].each do |arel|
                          if arel[r.association_foreign_key] == obj.id && arel[r.primary_key_name] == ext_id
                            trouve=true
                          end
                        end
                        unless trouve
                        assocs[r.options[:join_table]] << { r.primary_key_name => obj.id, r.association_foreign_key => ext_id}
                        end
                        #rel_yml.write "#{r.primary_key_name}_#{obj.id}_#{r.association_foreign_key}_#{ext_id}:\n"
                        #rel_yml.write "  #{r.primary_key_name}: #{obj.id}\n"
                        #rel_yml.write "  #{r.association_foreign_key}: #{ext_id}\n"
                      end
                      #rel_yml.close
                    end
                  end unless reflections.nil?
                end
              end
              #
              out_yml.close
              out_yml = nil
            #
            end
          rescue Exception => e
            $stderr.puts "Error during export_domain:#{e}"
          out_yml.close unless out_yml.nil?
          rel_yml.close unless rel_yml.nil?
          end
        end
      end
      assocs.keys.each do |key|
        out_yml = File.open("#{fixtures_path}/#{key}.yml", "w")
        puts "Opening #{out_yml.inspect} *********************"
        assocs[key].each do |assoc|   
          #out_yml.write "#{r.primary_key_name}_#{obj.id}_#{r.association_foreign_key}_#{ext_id}:\n"
          str=""
          head=""
          assoc.keys.each do |akey|
            str << "  #{akey}: #{assoc[akey]}\n"
            head<<"_" if head!=""
            head<<"#{akey}_#{assoc[akey]}"
          end
          out_yml.write "#{head}:\n"
          out_yml.write "#{str}\n"
          #puts "#{head}:\n"
          #puts "#{str}\n"
        end
        out_yml.close unless out_yml.nil?
      end
    end
    $stdout.puts "#{__method__}:end"
  end

  def export_seed
    if load_models
      # opening seed file
      seed_file = File.open(RAILS_ROOT + "/db/seeds.rb", "w")
      #
      assocs=""
      Object.subclasses_of(ActiveRecord::Base).each do |model|
        $stdout.puts model.to_s
        begin
        # model attributs list
          cols=[]
          #model.columns.reject{ |c| c.primary}. each do |col|
          model.columns.each do |col|
            cols<<"#{col.name}" unless %w[created_at updated_at].include?(col.name)
          end
          $stdout.puts "#{model}:#{cols}:#{model.count} objets"
          # take only model with internal attribut
          #if cols.include?("internal")

          model.all.each do |obj|

          # only if data is internal
          #   if obj.send("internal")
            id = obj.send("id")
            unless id.nil?
              cols.delete("id")
              params={}
              cols.each do |col|
                val = obj.send(col)
                if col=="date"
                params[col] = val.to_s unless val.nil?
                else
                params[col] = val unless val.nil?
                end
              end
              seed_file.write ("#{model}_#{id}=#{model}.create([#{params}])\n") unless params.empty?
            else
              id_begin = obj.send(cols[0])
              mdl_begin = cols[0].split("_")[0].capitalize
              id_end = obj.send(cols[1])
              mdl_end = cols[1].split("_")[0].capitalize
              assocs << "#{mdl_begin}_#{id_begin} << #{mdl_end}_#{id_end}\n"
            end
          end

        rescue Exception=>e
          $stderr.puts "Error during decoding seed file:#{e}"
        seed_file.close
        return
        end
      #(:name => 'Daley', :city => cities.first)

      end
    seed_file.write (assocs) unless assocs.empty?
    seed_file.close
    end
    $stdout.puts "#{__method__}:end"
  end

  def import_seed
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::DEBUG
    include Classes::AppClasses

    if load_models
      # opening seed file
      ret=""
      begin
        seed_file = File.open(RAILS_ROOT + "/db/seeds.rb", "r")
        contents = ""
        seed_file.each { |line|
          contents << line
        }
        seed_file.close
        $stdout.puts "#{__method__}:#{contents}"
        ret = eval contents
      rescue Exception=>e
        stack=""
        e.backtrace.each do |x|
          stack+= x+"\n"
        end
        $stderr.puts "Error during import seed file:#{e}:stack=\n#{stack}"
        seed_file.close
        return
        $stdout.puts "#{__method__}:end:#{ret}"

      end
    end

  end

  def load_models
    # loading models
    Dir.glob(RAILS_ROOT + '/app/models/*.rb').each { |file|
      begin
        $stdout.puts file
        require file
      rescue Exception=>e
        stack=""
        e.backtrace.each do |x|
          stack+= x+"\n"
        end
        $stderr.puts "Error loading model(#{file}):#{e}:stack=\n#{stack}"
      return false
      end
    }
    return true
  end

end

