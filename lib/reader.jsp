(defun read ((src stdin))
  (def c (peekchar src))
  (if (nil? c) 'EOF
      (eval `(,(or (env-get (env-get $env 'readtable) c) 'readsymbol) src))))

(defun peekchar ((src stdin))
  (let ((x (readchar src)))
     (unreadchar x src)
     x))

(defun skip1read ((src stdin))
  (readchar src)
  (read src))


(defun readsexp ((src stdin))
  (def done false)
  (def items '())
  (readchar src) ; skip leading "("
  ;(env-push $env)
  (env-push (env-get $env 'readtable))
  (env-put (env-get $env 'readtable)  ")" (fn ((src stdin)) (set done true)))

  (defun loop ()
    (def x (read src))
    (unless done
      (set items (cons x items))
      (loop)))
  (loop)

  (env-pop (env-get $env 'readtable))
  (readchar src)
  (reverse items))


(def numeric-chars '("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))
(defun readnumber ((src stdin))
  (def str "")
  (def is-float false)
  (def is-negative false)
  (defun loop ()
    (def c (readchar src))
    ;(println str ":" "[" c "]")
    (cond
      ((includes? c numeric-chars)
       (string+= str c)
       (loop))

      ((and (= c "-") (= str ""))
       (set is-negative (not is-negative))
       (loop))

      ((and (= c ".") (not is-float))
       (set is-float true)
       (string+= str c)
       (loop))

      ((and (= c ".") is-float)
       (throw (string+ "invalid number literal [" str c "]")))

      (true c)))
  (unreadchar (loop) src)

  (if is-float
      (string->float str is-negative)
      (string->int str is-negative)))

(defun readdot ((src stdin))
  (readchar src) ; skip .
  (if (not (includes? (peekchar src) numeric-chars)) '.
      (do (unreadchar "." src)
          (readnumber src))))

(defun readquote ((src stdin))
  `(quote ,(skip1read src)))
(defun readquasiquote ((src stdin))
  `(quasiquote ,(skip1read src)))
(defun readunquote ((src stdin))
  (readchar src) ; discards the ,
  (if (= "@" (peekchar src))
      (do (readchar src)
          (list 'unquote-splice (read src)))
      (list 'unquote (read src))))

(defun readstring ((src stdin))
  (def str "")
  (def escaped false)
  (readchar src) ; skip leading doublequote
  (defun loop ()
    (def c (readchar src))
    (unless (and (= c "\"") (not escaped))
      (if (= c "\\")
          (set escaped true)
          (do
           (set str
                (string+ str
                         (if escaped
                             (case c
                               ("n" "\n")
                               ("t" "\t")
                               ("r" "\r")
                               ("v" "\v")
                               ("f" "\f")
                               ("b" "\b")
                               ("\\" "\\")
                               ("\"" "\"")
                               c)
                             c)))
           (set escaped false)))
      (loop)))
  (loop)
  str)

(defun readhash ((src stdin))
  (readchar src) ; skip #
  (defun readtil2 (to)
    (def first (readchar src))
    (def second (peekchar src))
    (if (= to (string+ first second))
      (readchar src)
      (readtil2 to)))
  (def c (peekchar src))
  (cond
    ((= c "|") (readtil2 "|#"))
    (true (throw (string+ "Unknown hash sequence [#" c "]"))))
  (read src))

(defun readcomment ((src stdin))
  (defun loop ()
    (if (= "\n" (readchar src))
        (read src)
        (loop)))
  (loop))


(defun readsymbol ((src stdin))
  (def invalid-chars '(" " "\n" "\t" "\r" "\v" "\f" "\b" ")" "(" "\""))
  (def str "")
  (defun loop ()
    (def c (readchar src))
    (if (includes? c invalid-chars)
        c
        (do (string+= str c)
            (loop))))
  (unreadchar (loop) src)
  (cond
    ((= "nil" str)   nil)
    ((= "false" str) false)
    ((= "true" str)  true)
    (true            (string->symbol str))))

(defun readline ((src stdin))
  (def str "")
  (defun loop ()
    (def c (readchar src))
    (if (or (= "\n" c) (nil? c) (eof? c)) str
        (do (string+= str c) (loop))))
  (loop))

#| After this file is loaded, the entire reader is written in jlisp
  The only exceptions are readchar and unreadchar which are
  implemented as builtins |#
