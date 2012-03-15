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
    $stdout.puts "Database configuration=#{ActiveRecord::Base.configurations}"
  end

  task :connect => :load_config do
    ActiveRecord::Base.establish_connection
  end

  desc "Truncate all tables"
  task :truncate => :connect do
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

  desc "Export internal datas in seed.rb"
  task :export_internal_data => :connect do
    export_seed
  end

  desc "Import internal datas from seed.rb"
  task :import_internal_data => :connect do
    import_seed
  end

  def export_seed
    if load_models
      # opening seed file
      seed_file = File.open(RAILS_ROOT + "/db/seeds.rb", "w")
      #
      Object.subclasses_of(ActiveRecord::Base).each do |model|
        $stdout.puts model.to_s
        all_params=""

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
          params={}
          first_obj=true
          model.all.each do |obj|
          # only if data is internal
          #   if obj.send("internal")

            if obj.send("id")

              if first_obj
                all_params<<"\n"
              else
                all_params<<",\n"
              end
              cols.each do |col|
                val = obj.send(col)
                if col=="date"
                params[col] = val.to_s unless val.nil?
                else
                params[col] = val unless val.nil?
                end

              end
            all_params << params.to_s
            else
              id_begin = obj.send(cols[0])
              mdl_begin = cols[0].split("_")[0].capitalize
              id_end = obj.send(cols[1])
              mdl_end = cols[1].split("_")[0].capitalize
              seed_file.write ("#{mdl_begin}.find(#{id_begin}) << #{mdl_end}.find(#{id_end})\n")
            end
            first_obj=false
          end
        rescue Exception=>e
          $stderr.puts "Error during decoding seed file:#{e}"
        seed_file.close
        return
        end
        #(:name => 'Daley', :city => cities.first)
        seed_file.write ("#{model}.create([#{all_params}])\n") unless all_params.empty?

      end
    seed_file.close
    end
    $stdout.puts "#{__method__}:end"
  end

  def import_seed
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::DEBUG
    #require RAILS_ROOT + '/config/boot'
    include Classes::AppClasses
    #Boot.run
    @LOG=LOG_SYLRPLM.new
    @LOG.info #("sylrplm"){"Lancement SYLRPLM"}

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

