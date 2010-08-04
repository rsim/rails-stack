Sprinkle::Installers::Transfer.class_eval do
  def self.render_template(template, context, prefix)
    require 'tempfile'
    require 'erubis'

    begin
      eruby = Erubis::Eruby.new(template)
      output = eruby.result(context)
    rescue Object => e
      raise TemplateError.new(e, template, context)
    end

    final_tempfile = Tempfile.new(prefix)
    final_tempfile.print(output)
    final_tempfile.close
    final_tempfile
  end
  
  def render_template(template, context, prefix)
    self.class.render_template(template, context, prefix)
  end
  
  def render_template_file(path, context, prefix)
    template = File.read(path)
    tempfile = render_template(template, context, @package.name)
    tempfile
  end

  def process(roles) #:nodoc:
    assert_delivery

    if logger.debug?
      logger.debug "transfer: #{@source} -> #{@destination} for roles: #{roles}\n"
    end

    unless Sprinkle::OPTIONS[:testing]
      pre = pre_commands(:install)
      unless pre.empty?
        # PATCH: pass array of commands to ensure that all are run with sudo
        # sequence = pre; sequence = sequence.join('; ') if sequence.is_a? Array
        sequence = pre.flatten
        # logger.info "#{@package.name} pre-transfer commands: #{sequence} for roles: #{roles}\n"
        logger.info "#{@package.name} pre-transfer commands: #{sequence.join('; ')} for roles: #{roles}\n"
        @delivery.process @package.name, sequence, roles
      end

      recursive = @options[:recursive]

      # PATCH: always render files with .erb extension
      if options[:render] || File.extname(@source) == '.erb'
        if options[:locals]
          context = {}
          options[:locals].each_pair do |k,v|
            if v.respond_to?(:call)
              context[k] = v.call
            else
              context[k] = v
            end
          end
        else
          context = binding()
        end

        tempfile = render_template_file(@source, context, @package.name)
        sourcepath = tempfile.path
        logger.info "Rendering template #{@source} to temporary file #{sourcepath}"
        recursive = false
      else
        sourcepath = @source
      end

      # PATCH: simulate sudo transfer
      if options[:sudo]
        scp_destination = "/tmp/#{File.basename(@destination)}"
      else
        scp_destination = @destination
      end

      logger.info "--> Transferring #{sourcepath} to #{@destination} for roles: #{roles}"
      @delivery.transfer(@package.name, sourcepath, scp_destination, roles, recursive)

      post = post_commands(:install)
      # PATCH: set mode of file
      if options[:mode]
        post.unshift "chmod #{"%04o" % options[:mode]} #{@destination}"
      end
      # PATCH: simulate sudo transfer
      if options[:sudo]
        post = ["cp -#{recursive ? 'r' : nil}f #{scp_destination} #{@destination}",
                "rm -#{recursive ? 'r' : nil}f #{scp_destination}"].concat(post)
      end

      unless post.empty?
        # PATCH: pass array of commands to ensure that all are run with sudo
        # sequence = post; sequence = sequence.join('; ') if sequence.is_a? Array
        sequence = post.flatten
        # logger.info "#{@package.name} post-transfer commands: #{sequence} for roles: #{roles}\n"
        logger.info "#{@package.name} post-transfer commands: #{sequence.join('; ')} for roles: #{roles}\n"
        @delivery.process @package.name, sequence, roles
      end
    end
  end
end
