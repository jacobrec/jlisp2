require_relative "./list"

def jcall(sexp, env)
  sexp = sexp.to_list if sexp.class == Array
  cmd = sexp.car
  fn = env.get(cmd)
  raise "Unbound function #{cmd}" if fn.nil?
  fn.call(env, sexp.cdr)
end

def read_while(src, cond)
  str = ""
  while cond.call(str)
    c = src.getc
    break if c.nil?
    str += c
  end
  src.ungetc str[-1]
  str
end

$env.put(:read, ->(env, args) {
          c = jcall(cons(:peekchar, args), env)
          return :EOF if c.nil?
          fn = env.get(:readtable).get(c)
          fn = :readsymbol if fn.nil?
          res = jcall(cons(fn, args), env)
})

$env.put(:peekchar, ->(env, args) {
          src = (args && args[0]) || STDIN
          c = src.getc
          src.ungetc c
          c
})

$env.put(:unreadchar, ->(env, args) {
          ((args && args[1]) || STDIN).ungetc args[0]
})

$env.put(:readchar, ->(env, args) {
          ((args && args[0]) || STDIN).getc
})

$env.put(:readsymbol, ->(env, args) {
          str = read_while(((args && args[0]) || STDIN), ->(str) { str.match?(/\A[^\s|"|'|\(|\)]*\z/) && !str.match?(/\A\.+\z/) })

          str = str[...-1]
          sym = str.to_sym
          return nil if sym == :nil
          return false if sym == :false
          return true if sym == :true
          sym
})

$env.put(:skip1read, ->(env, args) {
          jcall(cons(:readchar, args), env)
          jcall(cons(:read, args), env)
})

$env.put(:readsexp, ->(env, args) {
          mdone = false
          items = []

          jcall(cons(:readchar, args), env)

          env.push
          env.get(:readtable).push

          env.put(:"readsexp done", ->(env, args) { mdone = true })
          env.get(:readtable).put(")", :"readsexp done")

          loop do
            x = jcall(cons(:read, args), env)
            break if mdone
            items.push(x)
          end

          env.get(:readtable).pop
          env.pop
          jcall(cons(:readchar, args), env)

          items.to_list
})

$env.put(:readnumber, ->(env, args) {
          src = (args && args[0]) || STDIN

          str = read_while(src, ->(str) { str.match?(/\A\d*\z/) || str.match?(/\A\d*\.\d*\z/) })

          str = str[...-1]
          str.include?(".") ? str.to_f : str.to_i
})

$env.put(:readdot, ->(env, args) {
           jcall(cons(:readchar, args), env) # skip .
           c = jcall(cons(:peekchar, args), env) # check if " "
           if c.match? /\s/
             :"."
           else
             src = (args && args[0]) || STDIN
             src.ungetc "."
             $env.get(:readnumber).call(env, args)
           end
})

def single_surround_reader(surround)
  ->(env, args) {
    src = (args && args[0]) || STDIN
    jcall(cons(:readchar, args), env)
    [surround, jcall(cons(:read, args), env)].to_list
  }
end

$env.put(:readquote, single_surround_reader(:quote))
$env.put(:readquasiquote, single_surround_reader(:quasiquote))
$env.put(:readunquote, ->(env, args) {
           jcall(cons(:readchar, args), env) # skip ,
           c = jcall(cons(:peekchar, args), env) # check if @
           if c == '@'
             jcall(cons(:readchar, args), env) # skip @
             [:"unquote-splice", jcall(cons(:read, args), env)].to_list
           else
             [:unquote, jcall(cons(:read, args), env)].to_list
           end
})

$env.put(:readstring, ->(env, args) {
          str = ""
          escaped = false
          jcall(cons(:readchar, args), env) # leading "
          loop do
            c = jcall(cons(:readchar, args), env)
            break if c == '"' && !escaped
            if c == "\\"
              escaped = true
            else
              if escaped
                escapes = {
                  "n"=>"\n",
                  "t"=>"\t",
                  "r"=>"\r",
                  "f"=>"\f",
                  "v"=>"\v",
                  "b"=>"\b",
                  "\\"=>"\\",
                }
                if escapes.include? c
                  str += escapes[c]
                end
              else
                str += c
              end
              escaped = false
            end
          end
          str
})

$env.put(:readcomment, ->(env, args) {
          read_while((args && args[0]) || STDIN, ->(str) { !str.match? /\n/ })
          jcall(cons(:read, args), env)
})

$env.get(:readtable).put(";", :readcomment)
$env.get(:readtable).put("\"", :readstring)
$env.get(:readtable).put("'", :readquote)
$env.get(:readtable).put("`", :readquasiquote)
$env.get(:readtable).put(",", :readunquote)
$env.get(:readtable).put(" ", :skip1read)
$env.get(:readtable).put("\n", :skip1read)
$env.get(:readtable).put("(", :readsexp)
$env.get(:readtable).put(".", :readdot) # .2
for x in 0..9
  $env.get(:readtable).put(x.to_s, :readnumber)
end
