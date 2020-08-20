$env.put(:open, ->(env, args) {
           write = args[1] ? "w" : "r"
           File.open(args[0], write)
})

$env.put(:write, ->(env, args) {
           dest = (args && args[1]) || STDOUT
           if args[0].class == String
             dest.print(args[0].inspect)
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

$env.put(:bool?, ->(env, args) {args[0].class == TrueClass || args[0].class == FalseClass})
$env.put(:eof?, ->(env, args) {args[0] == :EOF})
$env.put(:nil?, ->(env, args) {args[0].nil?})
$env.put(:list?, ->(env, args) {args[0].nil? || args[0].class == List})

$env.put(:car, ->(env, args) {args[0].car})
$env.put(:cdr, ->(env, args) {args[0].cdr})
$env.put(:cons, ->(env, args) {cons args[0], args[1]})

$env.put(:throw, ->(env, args) {raise args[0]})
$env.put(:dbg, ->(env, args) {p args[0]})
$env.put(:exit, ->(env, args) {exit args[0]})

$env.put(:"current-enviroment", ->(env, args) {env.clone})

$env.put(:"empty-hashmap", ->(env, args) {Hash.new})
$env.put(:"hashmap-add", ->(env, args) {args[0][args[1]] = args[2]})
$env.put(:"hashmap-remove", ->(env, args) {args[0].delete(args[1])})
$env.put(:"hashmap-get", ->(env, args) {args[0][args[1]]})
$env.put(:"hashmap-has", ->(env, args) {args[0].has_key? args[1]})
$env.put(:"hashmap-size", ->(env, args) {args[0].size})

$env.put(:+, ->(env, args) {args.to_array.sum})
$env.put(:"string+", ->(env, args) {args.to_array.join})
$env.put(:"=", ->(env, args) {args[0] == args[1]})
$env.put(:stdout, STDOUT)
$env.put(:stderr, STDERR)
$env.put(:stdin,  STDIN)
