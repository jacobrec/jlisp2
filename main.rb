require_relative "./enviroment"
require_relative "./list"

$env = Enviroment.new
$env.put(:readtable, Enviroment.new)

require_relative "./reader"
require_relative "./builtins"
require_relative "./functions"


def quasiquote_transform(args, env)
  handle_list = ->(list) {
    x = list.car
    last = x
    map ->(y){
      last.cdr = y
      last = last.cdr
    }, list.cdr
    x
  }
  fn = ->(x){
    if x.class == List && x.car == :unquote
      cons(jcall(cons(:eval, x.cdr), env), nil)
    elsif x.class == List && x.car == :"unquote-splice"
      jcall(cons(:eval, x.cdr), env)
    elsif x.class == List
      cons handle_list.call(map(fn, x)), nil
    else
      cons x, nil
    end
  }
  handle_list.call(map(fn, args))
end


$env.put(:eval, ->(env, args) {
           env = args[1] if !args[1].nil?
           fn = args.car
           if fn.class == List
             cmd = fn.car

             case cmd
             when :if
               v = jcall([:eval, fn[1]], env)
               if v
                 jcall([:eval, fn[2]], env)
               else
                 jcall([:eval, fn[3]], env)
               end

             when :quote
               fn[1]

             when :def
               sym = fn[1]
               val = jcall([:eval, fn[2]], env)
               env.put(sym, val)
               val.set_name(sym) if val.respond_to? :set_name
               val

             when :set
               sym = fn[1]
               val = jcall([:eval, fn[2]], env)
               env.set(sym, val)
               val

             when :let
               args = fn[1]
               body = fn.cdr.cdr
               if args.nil?
                 env.push
               else
                 mapped_args = map(->(x) {[x[0], jcall([:eval,x[1]], env)]}, args).to_array.to_h
                 env.push(mapped_args)
               end
               v = nil
               map(->(x){ v = jcall([:eval, x], env)}, body)
               env.pop

               v

             when :fn
               Function.new(fn.cdr.car, fn.cdr.cdr, env)

             when :macro
               Macro.new(Function.new(fn.cdr.car, fn.cdr.cdr, env))

             when :quasiquote
               quasiquote_transform fn.cdr.car, env

             else
               if env.get(fn.car).class == Macro
                 jcall([:eval, env.get(fn.car).call(env, fn.cdr)], env)
               else
                 car = fn.car
                 mapped_fn = map(->(x){jcall([:eval, x], env)}, fn.cdr)
                 mapped_fn = cons(car, mapped_fn)
                 jcall(mapped_fn, env)
               end
             end
           elsif fn.class == Symbol
             env.get(fn)
           else
             fn # return value if just value. Eg. string, int
           end

})


def ruby_load(file)
  $env.put(:"$file", [file].to_list)
  f = File.open(file)
  loop do
    sexp = jcall([:read, f], $env)
    break if sexp == :EOF
    x = jcall([:eval, sexp], $env)
  end
end

$env.put(:"$repl", false)
ruby_load(__dir__ + "/core.jsp")
if ARGV.include? "--test"
  ruby_load(__dir__ + "/tests.jsp")
elsif ARGV.include? "--help"
  puts "ruby #{$0} --test to run tests"
  puts "ruby #{$0} FILENAME1 FILENAME2 to run files"
  puts "ruby #{$0} to run a repl"
elsif ARGV.length == 0
  $env.put(:"$file", [].to_list)
  $env.put(:"$repl", true)
  loop do
    print "> "
    sexp = jcall([:read, STDIN], $env)
    if sexp == :EOF
      puts "(exit 0)"
      break
    end
    res = jcall([:eval, sexp], $env)
    print "=> "
    puts res
  end
else # treat each argument as a filename
  ARGV.map { |x|
    if !File.file? File.expand_path(x)
      puts "#{x} is not a valid file"
      exit 1
    end
  }

  ARGV.map { |x| ruby_load(File.expand_path(x)) }
end
