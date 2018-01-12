# frozen_string_literal: true

require 'rubygems'
require 'fog'
require 'classes/filedrivers'
require 'pathname'

class Volume < ActiveRecord::Base
  include Models::SylrplmCommon

  attr_accessible :id, :name, :directory, :protocol, :encode, :decode, :compress, :decompress, :designation, :description, :domain

  validates_presence_of :name, :protocol
  validates_format_of :name, with: /\A([a-z]|[A-Z]|[0-9]||[.])+\Z/
  validates_uniqueness_of :name

  has_many :users
  has_and_belongs_to_many :groups, join_table: :groups_volumes
  has_many :datafiles

  before_save :before_save_
  after_save :after_save_

  PROTOCOL_FILE_SYSTEM = 'file_system'
  PROTOCOL_FOG = 'fog'
  PROTOCOL_DATABASE_TEXT = 'database_text'
  PROTOCOL_DATABASE_BINARY = 'database_binary'
  FILE_REV_DELIMITER = '_._'
  DIR_DELIMITER = '_'
  #
  ########################################################################
  # protocol calls begin
  ########################################################################
  #
  def protocol_driver
    fname = "#{self.class.name}.#{__method__}"
    ret = (eval "filedriver_#{protocol}".camelize).instance
    # LOG.debug(fname)  {"volume=#{name} protocol=#{protocol} driver=#{ret}"}
    ret
  end

  def revisable?
    false
  end

  #
  # definit et cree le repertoire du  volume, celui ci depend du protocol
  # - file_systeme: directory=repertoire sur le disque du serveur: /home/syl/trav/rubyonrails/sylrplm-data-development/vol-local-01/
  # - fog: string composee pour etre unique sur le cloud
  # - database: directory=nom de la table
  #
  def set_directory
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"debut old_dir_name=#{@old_dir_name}"}
    dir = protocol_driver.create_volume_dir(self, @old_dir_name)
    if dir.nil?
      ret = false
      errors.add :base, I18n.t(:ctrl_object_not_created, typeobj: I18n.t(:ctrl_volume), ident: name, msg: nil)
    else
      ret = true
    end
    # LOG.debug(fname) {"fin dir=#{dir} ret=#{ret}"}
    ret
  end

  def destroy_volume
    fname = "#{self.class.name}.#{__method__}"
    if !is_used?
      # LOG.debug(fname) {"not used, protocol=#{protocol}"}
      ret = protocol_driver.delete_volume_dir(self)
      if ret
        ret = destroy
      else
        errors.add(:base, I18n.t(:check_volume_is_used, ident: name))
      end
    else
      errors.add(:base, I18n.t(:check_volume_is_used, ident: name))
      ret = false
    end
    LOG.info(fname) { "ret=#{ret} errors=#{errors.inspect}" }
    ret
  end

  ########################################################################
  # protocol calls end
  ########################################################################

  def self.get_all_files(purge = false)
    fname = "#{self.class.name}.#{__method__}"
    files_system = {}
    files_database = {}
    Volume.get_all.each do |vol|
      files_system[vol.name] = vol.protocol_driver.files_list(vol, purge) if vol.protocol == ::Volume::PROTOCOL_FILE_SYSTEM
      files_database[vol.name] = vol.protocol_driver.files_list(vol, purge) if vol.protocol == ::Volume::PROTOCOL_DATABASE_TEXT || vol.protocol == ::Volume::PROTOCOL_DATABASE_BINARY
    end
    fogfiles = {}
    fogfiles['unknown'] = FiledriverFog.instance.files_list(purge)
    #
    all_files = {}
    all_files[:fog_files] = fogfiles
    all_files[:file_system_files] = files_system
    all_files[:database_files] = files_database
    # LOG.debug(fname) {"files_database=#{files_database}"}
    # LOG.debug(fname) {"files_system=#{files_system}"}
    # LOG.debug(fname) {"fogfiles=#{fogfiles}"}
    all_files
  end

  def validate
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"protocol=#{protocol} directory=#{directory} old_dir_name=#{@old_dir_name}"}
    errors.add :base, I18n.t('valid_volume_directory_needed', protocol: protocol) if [PROTOCOL_FILE_SYSTEM].include? protocol && directory.blank?
  end

  def initialize(params_volume = nil)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"params=#{params_volume}"}
    super
    if params_volume.nil?
      self.directory = ::SYLRPLM::VOLUME_DIRECTORY_DEFAULT
      set_default_values(1)
    end
    self
  end

  def ident
    name
  end

  def self.protocol_values
    [PROTOCOL_FILE_SYSTEM, PROTOCOL_DATABASE_TEXT, PROTOCOL_DATABASE_BINARY, PROTOCOL_FOG].sort
  end

  def self.get_all
    fname = "#{self.class.name}.#{__method__}"
    # rails2 find(:all, :order=>"name")
    ret = all.order(:name)
    LOG.debug(fname) { "all volumes#{ret.inspect}" }
    ret
  end

  def self.find_first
    order(:name).first
  end

  def is_used?
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"users.count=#{users.count} datafiles.count=#{datafiles.count}"}
    users.count > 0 || datafiles.count > 0
  end

  def before_save_
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { 'debut' }
    ret = set_directory
    LOG.debug(fname) { "fin: ret=#{ret}" }
    ret
  end

  def update_attributes(params_volume)
    fname = "#{self.class.name}.#{__method__}"
    @old_dir_name = dir_name
    # LOG.debug(fname) {"debut old_dir_name=#{@old_dir_name} params=#{params_volume}"}
    ret = super(params_volume)
    # LOG.debug(fname) {"fin apres super  old_dir_name=#{@old_dir_name} ret=#{ret}"}
    ret
  end

  def after_save_
    fname = "#{self.class.name}.#{__method__}"
    LOG.debug(fname) { "volume=#{inspect}" }
  end

  #
  # /home/syl/trav/rubyonrails/sylrplm-data-development/vollocal01/Datafile/
  # self.directory=/home/syl/trav/rubyonrails/sylrplm-data-development
  # env=
  def dir_name
    fname = "#{self.class.name}.#{__method__}"
    env = ::Volume.rails_env
    unless env.nil?
      ret = if directory.blank?
              env
            else
              File.join(directory, env)
            end
      ret = File.join(ret, name)
    end
    LOG.debug(fname) { "env=#{env} dir_name=#{ret}" }
    ret
  end

  def self.rails_env
    fname = "Volume.#{__method__}"
    host = Datafile.host
    LOG.debug(fname) { "Datafile::host=#{host} Rails.env=#{Rails.env}" }
    File.join(Datafile.host, Rails.env[0, 4]) unless host.nil?
  end

  def self.get_conditions(filter)
    filter = filters.tr('*', '%')
    ret = {}
    unless filter.nil?
      ret[:qry] = "name LIKE :v_filter or description LIKE :v_filter or directory LIKE :v_filter or protocol LIKE :v_filter or to_char(updated_at, 'YYYY/MM/DD') LIKE :v_filter"
      ret[:values] = { v_filter: filter }
    end
    ret
    # conditions = ["name LIKE ? or description LIKE ? or directory LIKE ? or protocol LIKE ?"
  end

  private

  def _list_files_
    if protocol == PROTOCOL_FOG
      ret = 'files are stored in cloud by fog'
    elsif protocol == PROTOCOL_DATABASE_TEXT
      ret = 'files are stored in table'
    elsif protocol == PROTOCOL_DATABASE_BINARY
      ret = 'files are stored in table'
    else
      dir = File.join(directory, name)
      ret = ''
      if PlmServices.file_exists?(dir)
        Dir.foreach(dir) do |objectdir|
          if objectdir != '.' && objectdir != '..'
            dirobject = File.join(dir, objectdir)
          end
          if File.directory?(dirobject)
            Dir.foreach(dirobject) do |iddir|
              if iddir != '.' && iddir != '..'
                dirid = File.join(dirobject, iddir)
                ret += "\ndirid=" + iddir + '=' + dirid
                files = Dir.entries(dirid) if File.directory?(dirid)
                if files.size > 2
                  ret += ':nb=' + files.size.to_s + ':id=' + iddir
                  for f in files
                    ret += ':' + f
                  end
                else
                  ret += "\nbad file:" + dirid
                end
              end
            end
          else
            ret += "\nbad file:" + dirobject
          end
        end
      end
    end
    ret
  end
end
