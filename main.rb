require_relative "./enviroment"
require_relative "./list"

$env = Enviroment.new
$env.put(:readtable, Enviroment.new)

require_relative "./reader"

class Function
  @arity = nil
  @args = nil
  @body = nil
  def initialize(arglist, body)
    @arity = length(arglist)
    @args = arglist
    @body = body
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
    "(fn #{args} #{body})"
  end

  def call(env, args)
    bl = length @body

    env.push @args.to_array.zip(args.to_array)

    v = nil
    for x in 0...bl
      v = jcall([:eval, @body[x]], env)
    end

    env.pop
    v
  end
  
end

$env.put(:+, ->(env, args) {args.to_array.sum})

$env.put(:eval, ->(env, args) {
           fn = args.car
           if fn.class == List
             cmd = fn.car

             case cmd
             when :if
               v = call([:eval, fn[1]], $env)
               if v
                 call([:eval, fn[2]], $env)
               else
                 call([:eval, fn[3]], $env)
               end

             when :quote
               fn.cdr

             when :def  #TODO: push scope
               sym = fn[1]
               val = call([:eval, fn[2]], $env)
               $env.put(sym, val)
               val

             when :set
               sym = fn[1]
               val = fn[2]
               $env.put(sym, val)
               val

             when :fn
               Function.new(fn.cdr.car, fn.cdr.cdr)

             else
               fn = List.new(cons(:quote, fn.car), fn.cdr)
               mapped_fn = map(->(x){call([:eval, x], $env)}, fn)
               call(mapped_fn, $env)
             end
           elsif fn.class == Symbol
             $env.get(fn)
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




  
f = File.open("tmp.jsp")
for x in 0...2
  x = call([:eval, call([:read, f], $env)], $env)
  puts x
end
