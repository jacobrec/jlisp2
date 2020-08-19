require_relative "./enviroment"
require_relative "./list"

$env = Enviroment.new
$env.put(:readtable, Enviroment.new)

require_relative "./reader"

class Macro
  def initialize(fn)
    @fn = fn
  end
  def call(env, args)
    @fn.call(env, args)
  end
end

class Function
  @arity = nil
  @args = nil
  @restargs = nil
  @body = nil
  def initialize(arglist, body, env)
    @arity = length(arglist)
    @body = body
    @args = []
    defaults = {}
    puts arglist
    loop do
      break if arglist.nil?
      x = arglist.car
      if x.class == List # default argument
        defaults[x[0]] = x[1]
        @args.push(x[0])
      elsif x == :"."
        @restargs = arglist.cdr.car
        break
      else # regular argument
        @args.push(x)
      end
      arglist = arglist.cdr
    end

    @default_after = @args.length - defaults.size
    @defaults = @args[@default_after..].map { |x| jcall([:eval, defaults[x]], env) }
  end

  def body
    @body
  end
  def args
    @args
  end
  def arity
    @arity
  end

  def to_s
    "(fn #{args} #{body.to_s_no_outer})"
  end

  def call(env, args)
    oargs = args
    bl = length @body
    if args.nil? && @args.length == 0
      env.push
    else
      args = args.to_array if !args.nil?
      args = [] if args.nil?
      argcount = args.length
      diff = @args.length - argcount
      if diff < 0 && !@restargs
        raise "Too many arguments to function. Expected #{@args.length} and got #{argcount}"
      elsif diff < 0 && @restargs # rest arguments and no defaults needed
        env.push @args.zip(args)
      elsif diff > @defaults.size
        raise "Not enough arguments to function. Expected #{@args.length} and got #{argcount}"
      else
        env.push @args.zip(args.concat(@defaults.last(diff)))
      end

      if @restargs
        restargs = oargs
        for x in 0...@args.length
          restargs = restargs.cdr
        end
        env.put(@restargs, restargs)
      end
    end

    v = nil
    for x in 0...bl
      v = jcall([:eval, @body[x]], env)
    end

    env.pop
    v
  end
end

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

             when :def  #TODO: push scope
               sym = fn[1]
               val = jcall([:eval, fn[2]], env)
               env.put(sym, val)
               val

             when :set
               sym = fn[1]
               val = fn[2]
               env.put(sym, val)
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

$env.put(:open, ->(env, args) {
           write = args[1] ? "w" : "r"
           File.open(args[0], write)
})

$env.put(:write, ->(env, args) {
           dest = (args && args[1]) || STDOUT
           dest.print(args[0])
           dest.flush
           args[0]
})

$env.put(:bool?, ->(env, args) {
           args[0].class == TrueClass || args[0].class == FalseClass
})
$env.put(:eof?, ->(env, args) {
           args[0] == :EOF
})
$env.put(:nil?, ->(env, args) {
           args[0].nil?
})
$env.put(:list?, ->(env, args) {
           args[0].nil? || args[0].class == List
})

$env.put(:car, ->(env, args) {
           args[0].car
})
$env.put(:cdr, ->(env, args) {
           args[0].cdr
})
$env.put(:cons, ->(env, args) {
           cons args[0], args[1]
})

$env.put(:throw, ->(env, args) {
           raise args[0]
})

$env.put(:dbg, ->(env, args) {
           p args[0]
})

$env.put(:exit, ->(env, args) {
           exit args[0]
})

$env.put(:"current-enviroment", ->(env, args) {
           env.clone
})

$env.put(:"empty-hashmap", ->(env, args) {
           Hash.new
})
$env.put(:"hashmap-add", ->(env, args) {
           args[0][args[1]] = args[2]
})
$env.put(:"hashmap-remove", ->(env, args) {
           args[0].delete(args[1])
})
$env.put(:"hashmap-get", ->(env, args) {
           args[0][args[1]]
})
$env.put(:"hashmap-has", ->(env, args) {
           args[0].has_key? args[1]
})
$env.put(:"hashmap-size", ->(env, args) {
           args[0].size
})

$env.put(:+, ->(env, args) {args.to_array.sum})
$env.put(:"string+", ->(env, args) {args.to_array.join})
$env.put(:"=", ->(env, args) {args[0] == args[1]})
$env.put(:stdout, STDOUT)
$env.put(:stderr, STDERR)
$env.put(:stdin,  STDIN)


def ruby_load(file)
  f = File.open(file)
  loop do
    sexp = jcall([:read, f], $env)
    break if sexp == :EOF
    x = jcall([:eval, sexp], $env)
  end
end

$env.put(:"$repl", false)
ruby_load("core.jsp")
if ARGV.include? "--test"
  ruby_load("tests.jsp")
elsif ARGV.include? "--help"
  puts "ruby #{$0} --test to run tests"
  puts "ruby #{$0} FILENAME1 FILENAME2 to run files"
  puts "ruby #{$0} to run a repl"
elsif ARGV.length == 0
  $env.put(:"$repl", true)
  jcall([:repl], $env)
else # treat each argument as a filename
  ARGV.map { |x|
    if !File.file? x
      puts "#{x} is not a valid file"
      exit 1
    end
  }

  ARGV.map { |x| ruby_load(x) }
end
