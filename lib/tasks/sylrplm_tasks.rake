require 'logger'
require 'active_record'
require 'action_controller'
require 'models/sylrplm_common'
require 'models/plm_object'
require 'ruote/sylrplm/sylrplm'
require 'classes/app_classes'
require 'controllers/plm_event'
require 'controllers/plm_lifecycle'
require 'controllers/plm_tree'
require 'controllers/plm_object_controller'

#
require 'rufus/scheduler'

namespace :sylrplm do
#ruby2  task :load_config => :rails_env do
	task :load_config do
		include ::Rails
		#ruby2 ActiveRecord::Base.configurations = Rails::Configuration.new.database_configuration
		#ActiveRecord::Base.configurations = ::Rails::Application::Configuration.database_configuration()
		ActiveRecord::Base.configurations = Rails.application.config.database_configuration
		ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[Rails.env])
		ActiveRecord::Base.connection.reconnect!
		ActiveRecord::Base.logger = Logger.new(STDOUT)
		ActiveRecord::Base.logger.level = Logger::ERROR
		$stdout.puts "Database configuration=#{ActiveRecord::Base.configurations}"
	end
	desc 'run the scheduler'
	task :run_scheduler => [:connect, :environment] do |t, args|

	#p Rufus.parse_time_string '500'      # => 0.5
	#p Rufus.parse_time_string '1000'     # => 1.0
	#p Rufus.parse_time_string '1h'       # => 3600.0
	#p Rufus.parse_time_string '1h10s'    # => 3610.0
	#p Rufus.parse_time_string '1w2d'     # => 777600.0

	#p Rufus.to_time_string 60              # => "1m"
	#p Rufus.to_time_string 3661            # => "1h1m1s"
	#p Rufus.to_time_string 7 * 24 * 3600   # => "1w"

	#mm hh jj MMM JJJ tâche
	#mm représente les minutes (de 0 à 59)
	#    hh représente l'heure (de 0 à 23)
	#    jj représente le numéro du jour du mois (de 1 à 31)
	#    MMM représente l'abréviation du nom du mois (jan, feb, ...) ou bien le numéro du mois (de 1 à 12)
	#    JJJ représente l'abréviation du nom du jour ou bien le numéro du jour dans la semaine :
	#        0 = Dimanche
	#        1 = Lundi
	#        2 = Mardi
	#        ...
	#        6 = Samedi
	#        7 = Dimanche (représenté deux fois pour les deux types de semaine)
	#Pour chaque valeur numérique (mm, hh, jj, MMM, JJJ) les notations possibles sont :
	#    * : à chaque unité (0, 1, 2, 3, 4...)
	#    5,8 : les unités 5 et 8
	#    2-5 : les unités de 2 à 5 (2, 3, 4, 5)
	#    */3 : toutes les 3 unités (0, 3, 6, 9...)
	#   10-20/3 : toutes les 3 unités, entre la dixième et la vingtième (10, 13, 16, 19)
		scheduler = Rufus::Scheduler.start_new
		puts 'Starting Scheduler'
		#scheduler.cron '0 21 * * 1-5' do
		# every day of the week at 21:00
		scheduler.cron '*/15 7-21 * * 1-5' do
		# every 15 mn of each hour during the week
			puts "run task notify"
			Rake::Task[:notify].invoke
		end
	end

	desc 'notify'
	task :notify => [:connect, :environment] do |t, args|
		puts "Notification.notify_all"
		Notification.notify_all(nil)
	end

	desc 'import domain objects : [db/fixtures,admin,site"] or [db/fixtures,mecanic] or [db/fixtures,cooking] '
	task :import_domain, [:path, :domain, :site] => [:connect, :environment] do |t, args|
		args.with_defaults(:site => nil)
		domain = args.domain.to_s
		path = args.path.to_s
		site=args.site.to_s
		fname= "#{self.class.name}.#{__method__}"
		LOG.debug(fname) {"path is #{path}, domain is #{domain}, site is #{site}"}
		fixtures_path = "#{path}/#{domain}"
		unless domain.empty?
			#props= PlmServices.get_properties("sites")
			###truncate
			#Rake::Task["db:fixtures:load FIXTURES_PATH=#{fixtures_path}"].invoke
			ENV["FIXTURES_PATH"] = fixtures_path
			LOG.debug(fname) {"fixtures_path=#{ENV['FIXTURES_PATH']}, metadata loading"}
			begin
				Rake::Task["db:fixtures:load"].invoke
			rescue Exception => e
				LOG.debug(fname) {"ERROR during Rake::Task[db:fixtures:load].invoke : #{e.inspect}"}
			end
			LOG.debug(fname) {"metadata loading terminated"}
			unless site.blank?
				LOG.debug(fname) {"volumes creation"}
				#PlmServices.set_property("sites","central",site)
				Volume.all.each do |vol|
					LOG.debug(fname) {"vol.save:#{vol}"}
					vol.save
				end
			end
			LOG.debug(fname) {"loading of datafiles if needed"}
			# chargement des fichiers
			#PlmServices.set_property("sites","central",site)
			props= PlmServices.get_properties("sites")
			LOG.debug(fname) {"sites=#{props}"}
			Datafile.all.each do |file|
				unless file.filename.nil?
					LOG.debug(fname) {"===import of #{file}"}
					LOG.debug(fname) {"import of #{file.filename} protocol=#{file.volume.protocol} file_field=#{file.file_field}"}
					file.file_import = {}
					file.file_import[:file] = File.new(file.filename)
					file.file_import[:original_filename] = file.filename
					#RAILS 2 st = file.save
					# RAILS 4:
					st = file.save_file(file.filename)
					LOG.debug(fname) {"after save file_field=#{file.file_field}, filename:#{file.filename} = #{st}"}
				else
					LOG.debug(fname) {"import_domain:save file.filename null dans #{file.inspect}"}
				end
			end
			LOG.debug(fname) {"loading of datafiles if needed terminated"}
		else
			$stdout.puts "Path and Domain are mandatory"
		end
	end

	desc 'update access datas'
	task :update_access => [:connect, :environment] do
		::Access.reset
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

	# export of models data
	#
	def export_domain (adomain, fixtures_path)
		fname= "#{self.class.name}.#{__method__}"
		models= load_models
		unless models.nil?
			#
			assocs={}
			FileUtils.remove(Dir.glob("#{fixtures_path}/*"))
			domains = []
			domains << "admin"
			domains << adomain
			stars="*********************************************\n"
			LOG.debug(fname) {stars}
			LOG.debug(fname) {"Domains:#{domains}, #{models.size} modeles"}
			domains.each { |domain|
				LOG.debug(fname) {"Domain:#{domain} -------------------------------"}
				#models=ActiveRecord::Base.subclasses
				models.each { |model|
					begin
					LOG.debug(fname) {".................. Domain:#{domain} , model:#{model} with #{model.count} records"}
					assocs.merge(export_model model , fixtures_path)
					rescue Exception => e
						LOG.error "ERROR:#{e}"
					end
				}
			}
			LOG.debug(fname) {stars  }
			LOG.debug(fname) {"Writing associations" }
			assocs.keys.each do |key|
				export_association key, domain
			end
			LOG.debug(fname) {stars}
			LOG.debug(fname) {"Cleaning empty files"}
			Dir.glob("#{fixtures_path}/*.yml").each do |afile|
				asize = File.size(afile)
				msg = "verify file:#{afile}:#{asize}"
				if asize == 0
				    File.unlink(afile)
					msg+=":deleted"
				end
				puts "Clean: #{msg}"
			end
		end
	end

	def export_associations key

		fname= "#{self.class.name}.#{__method__}"
		out_yml = File.open("#{fixtures_path}/#{key}.yml", "w")
		puts "Opening #{out_yml.inspect} "
		assocs[key].each do |assoc|
		#out_yml.write "#{r.primary_key_name}_#{obj.id}_#{r.association_foreign_key}_#{ext_id}:\n"
			str=""
			head=""
			assoc.keys.each do |akey|
				head<<"_" if head!=""
				head<<"#{akey}_#{assoc[akey]}"
				str << "  #{akey}: #{assoc[akey]}\n"
			end
			out_yml.write "#{head}:\n"
			out_yml.write "#{str}\n"
		#puts "#{head}:\n"
		#puts "#{str}\n"
		end
		out_yml.close unless out_yml.nil?
	end

	def export_model model, fixtures_path
		fname= "#{self.class.name}.#{__method__}"
		assocs = {}
		puts "model= #{model}"
		nl="\n"
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
			#puts "cols=#{model.columns}"
			#model.columns.each do |col|
			#puts "col=#{col}"
			#  cols<<"#{col.name}" unless %w[created_at updated_at].include?(col.name)
			#end
			#
			#isdomaindata = cols.include?("domain")
			#TODO a remettre
			isdomaindata=true
			# take only model with domain attribut and some records
			#if isdomaindata && model.count > 0
			nb=model.all.size
			if nb > 0
				# opening output file
				out_yml = File.open("#{fixtures_path}/#{model.name.underscore}s.yml", "a")
				puts "Opening #{out_yml.inspect}"
				objs=model.all
				objs.each do |obj|
				# only if data is declared on a domain
				#objdomain = obj.send("domain")
				#TODO  if objdomain == domain
					if true
						#LOG.debug(fname) {"data=#{obj.to_yaml}"}
						out_yml.write(nl+obj.ident+":"+nl)
						yml=obj.attributes.to_yaml
						lines=yml.split(nl)
						puts "yml='#{yml} #{lines.size} lines '"
						lines.each { |line|
							out_yml.write("  " +line+nl) if  line != "---"
						}
						reflections.each do |r|
							export_reflection obj,r,fixtures_path,assocs
						end unless reflections.nil?
					else
						puts "#{obj} in domain '#{objdomain}'  <> '#{domain}' "
					end
				end
				#
				out_yml.close
				out_yml = nil
			#
			end
		rescue Exception => e
			puts "Error during export_domain:#{e}"
			stack=""
			e.backtrace.each do |x|
				puts x+"\n"
			end
		end
		out_yml.close unless out_yml.nil?
		assocs
	end

	def export_reflection obj, r,fixtures_path,assocs
		fname= "#{self.class.name}.#{__method__}"
		rname = r.name.to_s
		#puts "reflexion=#{r.inspect} dernier caractere=#{rname[rname.length-1,1]}"
		rname = rname.chop if rname[rname.length-1,1]=="s"
		#puts "**************** rname=#{rname}"
		#ext_ids = obj.send("#{r.association_foreign_key}s")
		ext_ids = obj.send("#{rname}_ids")
		if ext_ids.count>0
			rel_yml = File.open("#{fixtures_path}/#{r.options[:join_table]}.yml", "a")
			ext_ids.each do |ext_id|
				assocs[r.options[:join_table]] =[] if assocs[r.options[:join_table]].nil?
				trouve=false
				assocs[r.options[:join_table]].each do |arel|
					if arel[r.association_foreign_key] == obj.id && arel[r.primary_key_name] == ext_id ||
					arel[r.primary_key_name] == obj.id && arel[r.association_foreign_key] == ext_id
					trouve=true
					end
				end
				unless trouve
					begin
						assocs[r.options[:join_table]] << { r.primary_key_name => obj.id, r.association_foreign_key => ext_id, :domain => domain}
					rescue Exception => e
					end
				end
			rel_yml.write "#{r.primary_key_name}_#{obj.id}_#{r.association_foreign_key}_#{ext_id}:\n"
			rel_yml.write "  #{r.primary_key_name}: #{obj.id}\n"
			rel_yml.write "  #{r.association_foreign_key}: #{ext_id}\n"
			end
		rel_yml.close
		end
	end

	def export_seed
		fname= "#{self.class.name}.#{__method__}"
		models= load_models
		unless models.nil?
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

		models= load_models
		unless models.nil?
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
		fname= "#{self.class.name}.#{__method__}"
		# loading models
		models=[]
		Dir.glob("#{Rails.root}/app/models/*.rb").each { |file|
			begin
				LOG.debug(fname){"file model=#{file}" }
				require file
				fields=file.split("/")
				afile=File.new(file)
				basename=File.basename(file)
				basename=basename.gsub(".rb","")
				LOG.debug(fname){"filename=#{basename}"}
				model=eval basename.camelize
				models<<model
				LOG.debug(fname){"model=#{model}"}
			rescue Exception=>e
				#stack=""
				#e.backtrace.each { |x|
					#stack+= x+"\n"
				#}
				LOG.debug(fname){"Warning loading model(#{file}):#{e}}"}
			end
		}
		LOG.debug(fname){"models=#{models}"}
		return models
	end

end
