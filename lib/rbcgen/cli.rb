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
      options = {:parent => nil}
      parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER.gsub(/^          /,'')
          Generate a class file, its initialisation function, and its header file.

          #{USAGE}

          Options are:
        BANNER
        opts.separator ""
        opts.on("-h", "--help",
                "Show this help message.") { stdout.puts opts; exit }
        opts.on("-pPARENT", "--parent=PARENT") do |parent|
          options[:parent] = parent
        end
        opts.parse!(arguments)
      end

      classname = arguments.fetch(0)
      parent = options[:parent]

      if parent.nil?
        full_classname = classname
        full_cname = classname
        parent_arg = "void"
      else
        full_classname = "#{parent}::#{classname}"
        parent_cname = parent.gsub("::", "_")
        full_cname = "#{parent_cname}_#{classname}"
        parent_arg = "VALUE parent"
      end

      c_varname = "c#{full_cname}"

      hfile_macro = "__#{full_cname}_h__"
      init_function = "get_#{full_cname}_class"
      hfile_name = "#{full_cname}.h"
      cfile_name = "#{full_cname}.c"

      hfile_path = File.join('ext', hfile_name)
      cfile_path = File.join('ext', cfile_name)

      fileexist = false
      if File.exists? hfile_path
        fileexist = true
        $stderr.puts "error: #{hfile_path} already exists"
      end
      if File.exists? cfile_path
        fileexist = true
        $stderr.puts "error: #{cfile_path} already exists"
      end

      exit 2 if fileexist

      hfile = <<-HFILE.gsub(/^        /,'')
        #ifdef #{hfile_macro}
        #define #{hfile_macro}

        #include <ruby.h>

        /**
         * Create and return the class #{full_classname}.
         */
        extern VALUE #{init_function}(#{parent_arg});

        #endif /* #{hfile_macro} */
      HFILE

      if parent.nil?
        new_class_call = "rb_define_class(\"#{classname}\", rb_cObject)"
      else
        new_class_call = "rb_define_class_under(parent, \"#{classname}\", rb_cObject)"
      end

      cfile = <<-CFILE.gsub(/^        /,'')
        /**
         * TODO: Describe #{full_classname} here.
         */

        #include <ruby.h>
        #include "extconf.h"

        #include "#{hfile_name}"

        static VALUE #{c_varname} = Qnil;

        /* TODO: Methods are defined here, and attached to the class in
         *       function #{init_function}.
         */

        VALUE #{init_function}(#{parent_arg})
        {
            /* The class #{c_varname} is a singleton */
            if (#{c_varname} != Qnil) return #{c_varname};

            #{c_varname} = #{new_class_call};

            /* TODO: Add public attributes / methods to class object
                     #{c_varname} */

            return #{c_varname};
        }
      CFILE

      $stderr.puts "Creating header file #{hfile_path}..."
      File.open(hfile_path, 'w') do |file|
        file.write(hfile)
      end
      $stderr.puts "Creating C file #{cfile_path}..."
      File.open(cfile_path, 'w') do |file|
        file.write(cfile)
      end
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
