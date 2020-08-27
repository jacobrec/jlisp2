$env.put(:open, ->(env, args) {File.open(args[0], args[1] ? "w+" : "r")})

$env.put(:"write-byte", ->(env, args) {
           dest = (args && args[1]) || STDOUT
           if args[0].class == String
             dest.print(args[0])
           elsif args[0].class == Integer && args[0] < 255 && args[0] >= 0
             dest.print(args[0].chr)
           else
             raise "#{args[0]} of type #{args[0].class} is not of type to write byte"
           end
})
$env.put(:"write-bytes", ->(env, args) {
           dest = (args && args[1]) || STDOUT
           if args[0].class == String
             dest.print(args[0])
           elsif args[0].class == List
             raise "#{args[0]} of type #{args[0].class} is not of type to write-bytes"
             dest.print(args[0].chr)
           else
             raise "#{args[0]} of type #{args[0].class} is not of type to write-bytes"
           end
})

$env.put(:write, ->(env, args) {
           dest = (args && args[1]) || STDOUT
           if args[0].class == String
             dest.print(args[0].inspect)
           elsif args[0].class == Symbol
             dest.print("'")
             dest.print(args[0])
           elsif args[0].class == NilClass
             dest.print("nil")
           else
             dest.print(args[0])
           end
           dest.flush
           args[0]
})

$env.put(:print, ->(env, args) {
           dest = (args && args[1]) || STDOUT
           dest.print(args[0])
           dest.flush
           args[0]
})

$env.put(:rubytype, ->(env, args) {args[0].class})
$env.put(:function?, ->(env, args) {args[0].class == Function})
$env.put(:macro?, ->(env, args) {args[0].class == Macro})
$env.put(:true?, ->(env, args) {args[0].class == TrueClass})
$env.put(:false?, ->(env, args) {args[0].class == FalseClass})
$env.put(:bool?, ->(env, args) {args[0].class == TrueClass || args[0].class == FalseClass})
$env.put(:eof?, ->(env, args) {args[0] == :EOF})
$env.put(:nil?, ->(env, args) {args[0].nil?})
$env.put(:list?, ->(env, args) {args[0].nil? || args[0].class == List})
$env.put(:string?, ->(env, args) {args[0].class == String})
$env.put(:number?, ->(env, args) {args[0].class == Integer || args[0].class == Float})
$env.put(:int?, ->(env, args) {args[0].class == Integer})
$env.put(:float?, ->(env, args) {args[0].class == Float})
$env.put(:symbol?, ->(env, args) {args[0].class == Symbol})

$env.put(:"car-set", ->(env, args) {args[0].car = args[1]})
$env.put(:"cdr-set", ->(env, args) {args[0].cdr = args[1]})
$env.put(:car, ->(env, args) {args[0].car})
$env.put(:cdr, ->(env, args) {args[0].cdr})
$env.put(:cons, ->(env, args) {cons args[0], args[1]})

$env.put(:throw, ->(env, args) {raise args[0]})
$env.put(:dbg, ->(env, args) {p args[0]})
$env.put(:exit, ->(env, args) {exit args[0]})

$env.put(:reverse, ->(env, args) {args[0].to_array.reverse.to_list})

$env.put(:"current-enviroment", ->(env, args) {env.clone})
$env.put(:"set-current-enviroment", ->(env, args) {env.become(args[0])})

$env.put(:"empty-hashmap", ->(env, args) {Hash.new})
$env.put(:"hashmap-add", ->(env, args) {args[0][args[1]] = args[2]})
$env.put(:"hashmap-remove", ->(env, args) {args[0].delete(args[1])})
$env.put(:"hashmap-get", ->(env, args) {args[0][args[1]]})
$env.put(:"hashmap-has", ->(env, args) {args[0].has_key? args[1]})
$env.put(:"hashmap-size", ->(env, args) {args[0].size})

$env.put(:"+", ->(env, args) {args.to_array.sum})
$env.put(:"minus", ->(env, args) {args.to_array.reduce {|a, x| a - x}})
$env.put(:"<", ->(env, args) {args[0] < args[1]})
$env.put(:">", ->(env, args) {args[0] > args[1]})
$env.put(:"*", ->(env, args) {args.to_array.reduce {|a, x| a * x}})
$env.put(:"=", ->(env, args) {args[0] == args[1]})

$env.put(:"string+", ->(env, args) {args.to_array.join})
$env.put(:"string-starts-with?", ->(env, args) {args[0].start_with? args[1]})
$env.put(:"string->int", ->(env, args) {(args[1] ? -1 : 1) * args[0].to_i})
$env.put(:"string->float", ->(env, args) {(args[1] ? -1 : 1) * args[0].to_f})
$env.put(:"substring", ->(env, args) {args[2] ? args[0][args[1], args[2]] : args[0][args[1]..]})
$env.put(:"string-split", ->(env, args) {args[0].split(args[1]).to_list})
$env.put(:"string-join", ->(env, args) {args[1] ? args[0].to_array.join(args[1]) : args[0].to_array.join})
$env.put(:"string->symbol", ->(env, args) {args[0].to_sym})
$env.put(:"string-at", ->(env, args) {args[0][args[1]]})
$env.put(:"string-length", ->(env, args) {args[0].length})

$env.put(:"char->int", ->(env, args) {args[0].ord})
$env.put(:"int->char", ->(env, args) {args[0].chr})

$env.put(:"env-push", ->(env, args) {args[0].push})
$env.put(:"env-pop", ->(env, args) {args[0].pop})
$env.put(:"env-put", ->(env, args) {args[0].put args[1], args[2]})
$env.put(:"env-get", ->(env, args) {args[0].get args[1]})
$env.put(:"env-set", ->(env, args) {args[0].set args[1], args[2]})

$env.put(:stdout, STDOUT)
$env.put(:stderr, STDERR)
$env.put(:stdin,  STDIN)
$env.put(:"$env",  $env)

