# frozen_string_literal: true

require 'tmpdir'
require 'rubygems'
require 'zip'
class Datafile < ActiveRecord::Base
  include Models::PlmObject
  include Models::SylrplmCommon
  include Zip

  attr_accessor :user, :file_field, :file_import
  attr_accessible :id, :owner_id, :typesobject_id, :customer_id, :document_id, :part_id, :project_id, :volume_id
  attr_accessible :ident, :revision, :filename, :content_type, :date, :group_id, :projowner_id, :domain, :type_values

  validates_presence_of :ident, :typesobject_id, :revision, :volume_id, :owner_id, :group_id, :projowner_id
  validates_uniqueness_of :ident, scope: :revision

  belongs_to :customer
  belongs_to :document
  belongs_to :part
  belongs_to :project

  belongs_to :typesobject
  belongs_to :volume
  belongs_to :owner,
             class_name: 'User'
  belongs_to :group
  belongs_to :projowner,
             class_name: 'Project'
  # rails2 before_save :upload_file
  # for rules about fog names
  # http://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
  #
  # pg sql examples
  # DELETE FROM `comments` WHERE `comments`.`post_id` = 11
  # INSERT INTO comments (author, content, email, post_id) VALUES (?, ?, ?, ?);
  # SELECT * FROM posts;
  # SELECT tags.* FROM tags
  # INNER JOIN posts_tags ON tags.id = posts_tags.tag_id
  # WHERE posts_tags.post_id IS ?;
  # SELECT * FROM posts WHERE author IN ('Nicolas', 'Toto') OR title LIKE 'Titre%';
  # ActiveRecord::Base.connection.select_one('SELECT COUNT(*) FROM mytable')
  # ActiveRecord::Base.connection.execute('SELECT * FROM mytable')
   #
  ########################################################################
  # protocol calls begin
  ########################################################################
  #
  def designation
    ident
 end

  def dir_repository
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname) {"ident=#{self.ident}"}
    ret = volume.protocol_driver.dir_datafile(self)
    # LOG.info(fname) {"ret=#{ret}"}
    ret
  end

  # renvoie les differentes revisions du fichier existantes dans le repository
  def revisions_files
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname) {"datafile=#{self} call #{volume.protocol_driver}.revisions_files"}
    ret = volume.protocol_driver.revisions_files(self)
    ret
  end

  #
  # full path of the file
  #
  def repository
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "appel_repository #{volume.protocol_driver}.repository" }
    ret = volume.protocol_driver.repository(self)
    ret
  end

  def read_file
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "appel_read_file #{volume.protocol_driver}.read_file" }
    ret = volume.protocol_driver.read_file(self)
    ret
  end

  # read the file and adapt it for include the content in a tree model file
  def read_file_for_tree
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"content=#{read_file}"}
    code_content = typesobject.get_fields_values_type_only_by_key('build_tree_file_content')
    if code_content.nil?
      # no code to modify the file, we read the file as is
      ret = read_file
    else
      bloc = ''
      bloc << "		content = self.read_file\n"
      bloc << "		unless content.nil?\n"
      bloc << "		  ##puts \">>read_file_for_tree:\#{self.file_fullname} : \#{content.size}\n\#{content}\"\n"
      bloc << "		  #{code_content}\n"
      bloc << "		  ##puts \">>read_file_for_tree:ret=\n\#{ret}\"\n"
      bloc << "		else\n"
      bloc << "			ret=\"\"\n"
      bloc << "		end\n"
      bloc << "\t\tret"
      # LOG.debug(fname) {"****************** bloc=\n#{bloc}\n**********"}
      ret = eval bloc
    end
    # LOG.debug(fname) {"****************** ret=\n#{ret}"}
    ret
  end

  #
  # read the file and adapt it for using the file outside the application
  #
  def read_file_for_download
    fname = "#{self.class.name}.#{__method__}"
    code_content = typesobject.get_fields_values_type_only_by_key('build_file_content')
    if code_content.nil?
      LOG.debug(fname) { 'pas de bloc => read_file' }
      # no code to modify the file, we read the file as is
      ret = read_file
    else
      bloc = ''
      bloc << "		content = self.read_file\n"
      bloc << "		unless content.nil?\n"
      bloc << "		  ##puts \">>read_file_for_download:\#{self.file_fullname} : \#{content.size}\"\n"
      bloc << "		  #{code_content}\n"
      bloc << "		  else\n"
      bloc << "			return nil\n"
      bloc << "		end\n"
      bloc << "		ret\n"
      LOG.debug(fname) { "bloc=\n#{bloc}\n" }
      ret = eval bloc
    end
    ret
  end

  def create_directory
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"appel #{volume.protocol_driver}.create_directory volume=#{volume} protocol=#{volume.protocol}"}
    ret = volume.protocol_driver.create_directory(self)
  end

  def write_file(content)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "content size=#{content.length} volume=#{volume} protocol=#{volume.protocol}" }
    ret = true
    unless content.empty?
      create_directory
      repos = repository
      LOG.debug(fname) { "write_file_appel #{volume.protocol_driver}.write_file" }
      LOG.debug(fname) { "write_file_repository= #{repos}" }
      ret = volume.protocol_driver.write_file(self, content)
    end
    ret
  end

  def m_destroy
    fname = "#{self.class.name}.#{__method__}"
    ret = volume.protocol_driver.remove_files(self)
    customer&.remove_datafile(self)
    document&.remove_datafile(self)
    part&.remove_datafile(self)
    project&.remove_datafile(self)
    destroy
  end

  # TODO: dispatcher dans les drivers
  def move_file(from)
    fname = "#{self.class.name}.#{__method__}"
    File.rename(File.join(repository, from), repository)
  end

  # TODO: dispatcher dans les drivers
  def file_exists?
    fname = "#{self.class.name}.#{__method__}"
    PlmServices.file_exists?(repository)
  end

  # TODO: dispatcher dans les drivers
  def remove_file
    fname = "#{self.class.name}.#{__method__}"
    repos = repository
    if !repos.nil?
      if PlmServices.file_exists?(repos)
        begin
          File.unlink(repos)
        rescue StandardError
          return self
        end
      end
    else
      return nil
    end
    self
  end

  ########################################################################
  # protocol calls end
  ########################################################################

  def self.m_create(params)
    fname = "#{self.class.name}.#{__method__}"
    uploadedfile = params.delete(:uploaded_file)
    datafile = Datafile.new(params[:datafile])
    st = datafile.save
    LOG.debug(fname) { "datafile save : st=#{st}" }
    if st
      st = datafile.create_directory
      LOG.debug(fname) { "datafile .create_directory : st=#{st}" }
      if uploadedfile
        st = datafile.update_attributes(uploaded_file: uploadedfile)
        LOG.debug(fname) { "uploadedfile : st=#{st}" }
      end
    end
    LOG.debug(fname) { "datafile errors =#{datafile.errors.full_messages}" }
    datafile
  end

  def m_update(params, user)
    fname = "#{self.class.name}.#{__method__}"
    update_accessor(user)
    stupd = update_attributes_repos(params, user)
  end

  def self.host=(_args)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"host=#{args.inspect}"}
    # #@@host=args.gsub(".","-")
  end

  def self.host
    fname = "#{self.class.name}.#{__method__}"
    # ret=@@host
    # ret=PlmServices.get_property("central","sites")
    ret = PlmServices.get_property('SITE_CENTRAL')
    # LOG.debug(fname) {"host_name:#{ret}"}
    ret
  end

  def initialize(*args)
    fname = "plm_object:#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "datafile.initialize debut args=#{args.length}:#{args.inspect}" }
    super(args[0])
    self.revision = 1
    LOG.debug(fname) { "datafile.initialize fin args=#{args.length}:#{args.inspect}" }
  end

  def user_obsolete=(user)
    fname = "#{self.class.name}.#{__method__}"
    def_user(user)
    self.volume = user.volume
  end

  def thecustomer=(obj)
    self.customer = obj
  end

  def thedocument=(obj)
    self.document = obj
  end

  def thepart=(obj)
    self.part = obj
  end

  def theproject=(obj)
    self.project = obj
  end

  def update_attributes_repos(params, user)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "update_attributes_repos: params=#{params.inspect}" }
    parameters = params[:datafile]
    uploaded_file = parameters[:uploaded_file]
    parameters[:volume] = user.volume unless parameters[:volume].nil?
    ret = true
    begin
      LOG.debug(fname) { "update_attributes_repos: params[volume_id]=#{params['volume_id']} uploaded_file=#{uploaded_file}" }
      if uploaded_file
        # ##TODO syl ???
        parameters.delete(:uploaded_file)
        #
        LOG.debug(fname) { "update_attributes_repos: uploaded_file:rev=#{revision} next=#{revision.next}" }
        parameters[:revision] = revision.next
        parameters[:filename] = uploaded_file.original_filename
        LOG.debug(fname) { "update_attributes_repos: parameters=#{parameters.inspect}" }
        update_attributes(parameters)
        create_directory
        update_attributes(uploaded_file: uploaded_file)
        LOG.debug(fname) { "update_attributes_repos: uploaded_file: self=#{inspect}" }
      else
        unless params[:restore_file].nil?
          from_rev = Datafile.revision_from_file(params[:restore_file])
          LOG.debug(fname) { "update_attributes_repos: from_rev=#{from_rev} revision=#{revision}" }
          if !from_rev.nil? && from_rev != revision.to_s
            if false
              # on remet la revision demandee active en creant une nouvelle revision
              parameters[:revision] = revision.next
              parameters[:filename] = Datafile.filename_from_file(params[:restore_file])
              LOG.debug(fname) { "update_attributes_repos: parameters=#{parameters.inspect}" }
              update_attributes(parameters)
              move_file(params[:restore_file])
            end
            # on remet la revision demandee active
            parameters[:revision] = from_rev
            parameters[:filename] = Datafile.filename_from_file(params[:restore_file])
            LOG.debug(fname) { "update_attributes_repos: parameters=#{parameters.inspect}" }
            update_attributes(parameters)
          else
            LOG.debug(fname) { "update_attributes_repos: parameters=#{parameters.inspect}" }
            update_attributes(parameters)
          end
        end
      end
    rescue Exception => e
      errors.add(:base, "Error update datafile attributes : #{e}")
      ret = false
      e.backtrace.each { |x| LOG.error x }
    end
    ret
  end

  def volumes
    fname = "#{self.class.name}.#{__method__}"
    ret = owner.group.volumes unless owner.nil?
    LOG.debug(fname) { "volumes=#{ret}" }
    ret
  end

  # obsolete in rails4
  def uploaded_file=(file_field)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "uploaded_file=file_field=#{file_field.inspect} volume=#{volume} protocol=#{volume.protocol}" }
    self.file_field = file_field
  end

  def upload_file(file_field)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "upload_file: filename=#{filename}" }
    LOG.debug(fname) { "upload_file: debut de upload: file_field=#{file_field.inspect}" }
    LOG.debug(fname) { "upload_file: original_filename=#{file_field.original_filename if file_field.respond_to? :original_filename}" }
    LOG.debug(fname) { "upload_file: path=#{file_field.path if file_field.respond_to? :path}" }
    LOG.debug(fname) { "upload_file: datafile=#{inspect}" }
    if file_field.blank?
      if file_import.present?
        self.filename = base_part_of(file_import[:original_filename])
        content = file_import[:file].read
        begin
          ret = write_file(content)
          self.file_field = nil
        rescue Exception => e
          LOG.error(fname) { "Exception 2 during write_file: #{e.inspect} " }
          e.backtrace.each { |x| LOG.error x }
          if e.class == Excon::Errors::SocketError
            LOG.error(fname) { "Probleme potentiel de connection reseau:#{e.class}:#{e.message}" }
          end
          ret = false
          raise Exception, "Error uploaded file 2 #{file_field}:#{e}"
        end
      end
    else
      self.content_type = file_field.content_type.chomp if file_field.respond_to? :content_type
      self.filename = base_part_of(file_field.original_filename) if file_field.respond_to? :original_filename
      LOG.debug(fname) { "upload_file: filename=#{filename} content_type=#{content_type}" }
      content = open(file_field.path, 'rb', &:read)
      LOG.debug(fname) { "content=#{content.size}" }
      # syl saving filename and content_type !
      save
      ret = write_file(content)
      self.file_field = nil
    end
    # LOG.debug(fname){"fin de upload:ret=#{ret}"}
    ret
  end

  def save_file(file_path)
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "save_file file_path=#{file_path}" }
    unless file_path.blank?
      self.filename = base_part_of(file_path)
      LOG.debug(fname) { "save_file: filename=#{filename} content_type=#{content_type}" }
      content = open(file_path, 'rb', &:read)
      LOG.debug(fname) { "save_file: content=#{content.size}" }
      ret = write_file(content)
      save
    end
    # LOG.debug(fname){"fin de upload:ret=#{ret}"}
    ret
  end

  def base_part_of(file_name)
    fname = "#{self.class.name}.#{__method__}"
    PlmServices.file_basename(file_name).gsub(/[^\w._-]/, '')
  end

  def file_path
    PlmServices.file_basename(filename)
  end

  # return the filename without the dir path and the extension
  def file_name
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"filename=#{filename}"}
    PlmServices.file_basename(filename).split('.')[0] unless filename.blank?
  end

  def file_fullname
    ret = file_name
    ext = file_extension
    ret += ".#{ext}" unless ext.blank?
    ret
  end

  # return the extension of the file, nil if no . in the name
  def file_extension
    sp = PlmServices.file_basename(filename).split('.')
    sp[sp.size - 1] if sp.size > 1
  end

  def filename_repository
    fname = "#{self.class.name}.#{__method__}"
    ret = if revision.nil?
            filename.to_s
          else
            current_revision_file
          end
    LOG.info(fname) { "filename_repository=#{ret}" }
    ret
  end

  def self.revision_from_file(_filename)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname) {"_filename=#{_filename}"}
    _filename.split(Volume::FILE_REV_DELIMITER)[1]
  end

  def self.filename_from_file(_filename)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname) {"_filename=#{_filename}"}
    _filename.split(Volume::FILE_REV_DELIMITER)[2]
  end

  def current_revision_file
    fname = "#{self.class.name}.#{__method__}"
    # puts "current_revision_file:"+self.revision.to_s+" filename="+self.filename.to_s
    ret = ''
    unless revision.blank? && filename.blank?
      ret = Volume::FILE_REV_DELIMITER
      ret += revision.to_s
      ret += Volume::FILE_REV_DELIMITER
      ret += filename.to_s
    end
    ret
  end

  def read_file_by_lines
    fname = "#{self.class.name}.#{__method__}"
    if PlmServices.file_exists?(repository)
      data = ''
      f = File.open(repository, 'r')
      f.each_line do |line|
        data += line
        # puts "datafile.read_file a line"
      end
    else
      data = nil
    end
    data
  end

  #
  # ecriture dans un fichier temporaire dans public/tmp pour visu ou edition par un outil externe
  #
  def write_file_tmp
    fname = "#{self.class.name}.#{__method__}"
    content = read_file_for_download
    repos = nil
    unless content.nil? || content.size <= 0
      LOG.debug(fname) { "content.length=#{content.length}" }
      dir_repos = File.join('public', 'tmp')
      FileUtils.mkdir_p(dir_repos) unless PlmServices.file_exists?(dir_repos)
      tmpfilename = repository.tr('/', '_')
      repos = File.join(dir_repos, tmpfilename)
      LOG.debug(fname) { "repository=#{repos} dir_repos=#{dir_repos} exist=#{PlmServices.file_exists?(dir_repos)}" }
      if PlmServices.file_exists?(repos)
        LOG.debug(fname) { "#{repos} already existing, using it" }
      else
        if PlmServices.file_exists?(dir_repos)
          f = File.open(repos, 'wb')
          begin
            f.puts(content)
            LOG.debug(fname) { "file is writed in #{repos}:#{PlmServices.file_exists?(repos)}" }
          rescue Exception => e
            e.backtrace.each { |x| LOG.error x }
            raise Exception, "Error writing in tmp file #{repos}:#{e}"
          end
          f.close
        else
          LOG.error(fname) { "#{dir_repos} does not exist and can t be created" }
        end
      end
      ret = File.join('/tmp', tmpfilename)
    end
    # LOG.info(fname) {"src=#{ret.to_s} exist=#{PlmServices.file_exists?(repos)}"}
    ret
  end

  def find_col_for(strcol)
    fname = "#{self.class.name}.#{__method__}"
    Sequence.find_col_for(modelname, strcol)
  end

  def self.get_conditions(filter)
    fname = "#{self.class.name}.#{__method__}"
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "ident LIKE :v_filter or revision LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD')  LIKE :v_filter or " + qry_owner_id + ' or ' + qry_type + ' or ' + qry_volume
      ret[:values] = { v_filter: filter }
    end
    ret

    # ["ident LIKE ? or "+qry_type+" or revision LIKE ? "+
    #  " or "+qry_owner_id+" or updated_at LIKE ? or "+qry_volume,
  end

  def zipFile
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"datafile=#{self}"}
    tmpname = "datafile.#{id}.#{filename.tr('/', '-').tr('\\', '-')}"
    tmpfile = Tempfile.new("#{tmpname}-#{Time.now}")
    LOG.debug(fname) { "tmpname=#{tmpname}" }
    content = read_file_for_download
    if content.blank?
      size = 0
    else
      size = content.size
      PlmServices.write_ouput_stream(tmpfile, tmpname, content)
    end
    ret = { size: size, file: tmpfile, filename: "#{@filename}.zip", content_type: 'application/zip' }
    # LOG.debug(fname) {"ret=#{ret.inspect}"}
    ret
  end
end
