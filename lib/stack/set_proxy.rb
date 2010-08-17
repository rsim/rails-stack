package :set_proxy do
  description 'Set http_proxy and ftp_proxy environment variables'

  if http_proxy = INSTALL_CONFIG[:http_proxy]
    config = <<-EOS
# rails-stack-set-proxy
http_proxy=#{http_proxy}
https_proxy=#{http_proxy}
ftp_proxy=#{http_proxy}
EOS

    push_text config, "/etc/environment", :sudo => true

    verify do
      config.split(/\n/).all?{|line| file_contains "/etc/environment", line}
    end

    requires :env_keep_http_proxy
  end
end

package :env_keep_http_proxy do
  line = 'Defaults env_keep += "http_proxy https_proxy ftp_proxy"'
  push_text "# rails-stack-set-proxy\n#{line}", "/etc/sudoers", :sudo => true
  verify do
    file_contains "/etc/sudoers", line
  end
end
