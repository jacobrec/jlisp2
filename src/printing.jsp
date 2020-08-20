(defun print (x)
  (write x))

(defun println (val . rest)
  (print val)
  (map (fn (x) (print " ") (print x)) rest)
  (print "\n")
  (if rest
    (cons val rest)
    val))
