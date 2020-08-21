;; TODO: expose readtable and finish these functions

;; read
(defun read ((src stdin))
  (def c (peekchar src))
  (if (nil? c) 'EOF
      (eval `(,(or (env-get (env-get $env 'readtable) c) 'readsymbol) src))))

(defun peekchar ((src stdin))
  (let ((x (readchar src)))
     (unreadchar x src)
     x))

;; readchar
;; unreadchar
;; readsymbol

(defun skip1read ((src stdin))
  (readchar src)
  (read src))


;; readsexp
(defun treadnumber ((src stdin))
  (def str "")
  (def is-float false)
  (def is-negative false)
  (defun loop ()
    (def c (readchar src))
    ;(println str ":" "[" c "]")
    (cond
      ((includes? c '("0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))
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
  (unreadchar (loop) stdin)

  (if is-float
      (string->float str is-negative)
      (string->int str is-negative)))
;; readdot

(defun readquote ((src stdin))
  (readchar src) ; discards the '
  `(quote ,(read src)))
(defun readquasiquote ((src stdin))
  (readchar src) ; discards the `
  `(quasiquote ,(read src)))
;; readunquote

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
                               ("b" "\b")
                               ("\\" "\\")
                               ("\"" "\"")
                               c)
                             c)))
           (set escaped false)))
      (loop)))
  (loop)
  str)

(defun readcomment ((src stdin))
  (defun loop ()
    (if (= "\n" (readchar src))
        (read src)
        (loop)))
  (loop))
