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
  def initialize(arglist, body)
    @arity = length(arglist)
    @body = body
    @args = []
    loop do
      break if arglist.nil?
      x = arglist.car
      if x == :"."
        @restargs = arglist.cdr.car
        break
      end
      @args.push(x)
      arglist = arglist.cdr

      break if x.nil?
    end
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
    bl = length @body
    if args.nil?
      env.push
    elsif @restargs
      env.push @args.zip(args.to_array)
      restargs = args
      for x in 0...@args.length
        restargs = restargs.cdr
      end
      env.put(@restargs, restargs)
    else
      env.push @args.zip(args.to_array)
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
               Function.new(fn.cdr.car, fn.cdr.cdr)

             when :macro
               Macro.new(Function.new(fn.cdr.car, fn.cdr.cdr))

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

$env.put(:+, ->(env, args) {args.to_array.sum})
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

ruby_load("core.jsp")
ruby_load("tests.jsp")
