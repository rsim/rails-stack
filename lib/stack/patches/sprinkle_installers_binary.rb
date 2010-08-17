Sprinkle::Installers::Binary.class_eval do
  def extract_command(archive_name = @binary_archive.split("/").last)
    case archive_name
    when /(tar.gz)|(tgz)$/
      'tar xzf'
    when /(tar.bz2)|(tb2)$/
      'tar xjf'
    when /tar$/
      'tar xf'
    # PATCH: use -o option to overwrite existing files without prompt
    when /zip$/
      'unzip -o'
    else
      raise "Unknown binary archive format: #{archive_name}"
    end
  end
end
