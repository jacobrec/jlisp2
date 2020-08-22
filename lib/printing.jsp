(defun newline ()
  (print "\n"))
(defun writeln (val . rest)
  (write val)
  (map (fn (x) (print " ") (write x)) rest)
  (newline)
  (if rest
    (cons val rest)
    val))

(defun println (val . rest)
  (print val)
  (map (fn (x) (print " ") (print x)) rest)
  (newline)
  (if rest
    (cons val rest)
    val))

