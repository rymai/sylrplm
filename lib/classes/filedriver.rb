# frozen_string_literal: true

require 'zip'

class Filedriver
  include Zip

  private

  def initialize
    puts 'Filedriver.initialize'
  end

  public

  ########################################################################
  # protocol calls begin
  ########################################################################

  ########################################################################
  # protocol calls end
  ########################################################################
  def splitId(id)
    id.gsub('##', '.')
  end

  def buildFileId(id)
    id.gsub('.', '##')
  end

  def self.driver_from_file_id(file_id)
    protocol = protocol_from_file_id(file_id)
    driver_from_procotol(protocol)
  end

  def self.protocol_from_file_id(file_id)
    fields = file_id.split(::SylrplmFile::FILE_SEP_ID)
    fields[0]
  end

  def self.driver_from_procotol(protocol)
    ret = (eval "filedriver_#{protocol}".camelize).instance
  end

  def transform_content(datafile, content)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"debut:size=#{content.length}"}
    # LOG.debug(fname) {"debut:#{content}"}
    begin
      if datafile.volume.compress.blank?
        compress = content
      else
        # compress = zip_content(content, datafile.filename)
        @content = content
        @filename = datafile.filename
        LOG.debug(fname) { "compress filename=#{@filename} content=#{@content.size} code=#{datafile.volume.compress}" }
        compress = eval datafile.volume.compress
        LOG.debug(fname) { "compress:size=#{compress.length}" }
      end
      if datafile.volume.encode.blank?
        content_encode = compress
      else
        # ActiveSupport::Base64.encode64
        # encode_fields=datafile.volume.encode.split(".")
        # content_encode=(eval encode_fields[0]).send(encode_fields[1], compress)
        @content = compress.to_s
        @filename = datafile.filename
        LOG.debug(fname) { "encode filename=#{@filename} content=#{@content.size} code=#{datafile.volume.encode}" }
        content_encode = eval datafile.volume.encode
        # test content_encode = PlmServices.zip_in_stringio(@filename,@content)
        LOG.debug(fname) { "encode:size=#{content_encode.length}" }
      end
    rescue Exception => e
      msg = "Exception during transformation(encode+compress):#{e.message}"
      LOG.error(fname) { msg }
      datafile.errors.add(:base, msg)
      e.backtrace.each { |x| LOG.error x }
      content_encode = nil
    end
    content_encode
  end

  def untransform_content(datafile, data)
    fname = "#{self.class.name}.#{__method__}"
    # LOG.debug(fname) {"data:size=#{data.length}"}
    # LOG.debug(fname) {"data=#{data}"}
    begin
      unless datafile.volume.decode.blank?
        @content = data
        @filename = datafile.filename
        # LOG.debug(fname) {"datafile.volume.decode=#{datafile.volume.decode}"}
        data = eval datafile.volume.decode
        # LOG.debug(fname) {"decode:size=#{data.length}"}
      end
      if datafile.volume.decompress.blank?
        decompress = data
      else
        @content = data
        # LOG.debug(fname) {"datafile.volume.decompress=#{datafile.volume.decompress} , data.length:#{data.length}"}
        LOG.debug(fname) { "@content avant eval =#{@content.size} bloc=#{datafile.volume.decompress}" }
        decompress = eval datafile.volume.decompress
        # decompress = PlmServices.unzip_stringio @content
        LOG.debug(fname) { "after evalsize=#{decompress.nil? ? '0' : decompress.length}" }
      end
    rescue Exception => e
      msg = "Exception during untransformation(decode+decompress):#{e.message}"
      LOG.error(fname) { msg }
      datafile.errors.add(:base, msg)
      e.backtrace.each { |x| LOG.error x }
      decompress = nil
    end
    # LOG.debug(fname) {"decompress=#{decompress}"}
    decompress
  end
end
