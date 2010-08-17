module Sprinkle
  module Verifiers
    # = yum package Verifier
    #
    # Contains a verifier to check the existance of a yum package.
    # 
    # == Example Usage
    #
    #   verify { has_yum 'ntp' }
    #
    module Yum
      Sprinkle::Verify.register(Sprinkle::Verifiers::Yum)

      # Checks to make sure the apt <tt>package</tt> exists on the remote server.
      def has_yum(package)
        @commands << "yum list #{package} | grep installed"
      end

    end
  end
end