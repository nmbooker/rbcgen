require 'optparse'

USAGE="Usage: #{File.basename($0)} newmethod [options] clsobj prefix method [arg ...]"

module Rbcgen
  class CLI
    def self.do_newmethod(stdout, arguments)
      options = {:funbody => nil}
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Generate a method function and its registration call in a Ruby C extension.

          #{USAGE}

          Options are:
        BANNER
        opts.separator ""
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.on("-b", "--body", "Include C function body from stdin.") {
                options[:funbody] = $stdin.read.chomp
                }
        opts.parse!(arguments)
      end

      if ARGV.count < 3 then
        $stderr.puts USAGE
        exit 1
      end

      clsobj = ARGV[0]
      prefix = ARGV[1]
      method = ARGV[2]
      argnames = ARGV.drop(3)

      default_return = 'Qnil'

      if method == "initialize"
        default_return = 'self'
      end

      funcname = "#{prefix}_#{method}"

      cargs = argnames.map{|arg| ", VALUE #{arg}"}.join('')
      if options[:funbody].nil?
        body = "    // TODO: code here\n    return #{default_return};"
      else
        body = options[:funbody]
      end
      puts <<END
//    rb_define_method(#{clsobj}, "#{method}", #{funcname}, #{argnames.count});
static VALUE #{funcname}(VALUE self#{cargs})
{
#{body}
}

END
      
    end

    def self.do_newclass(stdout, arguments)
    end

    def self.execute(stdout, arguments=[])

      options = {
        :funbody => nil
      }
      mandatory_options = %w(  )

      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Usage: #{File.basename($0)} [globaloptions] subcommand [-h|args...]"

          subcommands are:
            newmethod -- Generate a new method stub and its registration call
            nm        -- Alias for newmethod
            newclass  -- Generate C files for a new class.
            nc        -- Alias for newclass.

          Global options are:
        BANNER
        opts.separator ""
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.order!(arguments)

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          stdout.puts opts; exit
        end
      end

      # do stuff
      subcommand = arguments.shift
      if ["newmethod", "nm"].include?(subcommand)
        do_newmethod(stdout, arguments)
      elsif ["newclass", "nc"].include?(subcommand)
        do_newclass(stdout, arguments)
      else
        stdout.puts "Invalid subcommand.  Use -h to get list."
        exit 1
      end

    end
  end
end
