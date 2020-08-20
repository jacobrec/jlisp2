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
  @env = nil
  def initialize(arglist, body, env)
    @arity = length(arglist)
    @body = body
    @args = []
    defaults = {}
    @env = env.clone
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
    env = @env
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
