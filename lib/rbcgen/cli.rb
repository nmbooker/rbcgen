require 'optparse'

USAGE="Usage: #{File.basename($0)} [options] clsobj prefix method [arg ...]"

module Rbcgen
  class CLI
    def self.do_genmethod
      if ARGV.count < 3 then
        $stderr.puts USAGE
        exit 1
      end

      $clsobj = ARGV[0]
      $prefix = ARGV[1]
      $method = ARGV[2]
      $argnames = ARGV.drop(3)

      $funcname = "#{$prefix}_#{$method}"

      $cargs = $argnames.map{|arg| ", VALUE #{arg}"}.join('')

      puts <<END
//    rb_define_method(#{$clsobj}, "#{$method}", #{$funcname}, #{$argnames.count});
static VALUE #{$funcname}(VALUE self#{$cargs})
{
    // code here
}

END
      
    end

    def self.execute(stdout, arguments=[])

      # NOTE: the option -p/--path= is given as an example, and should be replaced in your application.

      options = {
        :path     => '~'
      }
      mandatory_options = %w(  )

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          This application generates C code stubs for Ruby methods.

          #{USAGE}

          Options are:
        BANNER
        opts.separator ""
        opts.on("-p", "--path PATH", String,
                "This is a sample message.",
                "For multiple lines, add more strings.",
                "Default: ~") { |arg| options[:path] = arg }
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.parse!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      path = options[:path]

      # do stuff
      do_genmethod
    end
  end
end
