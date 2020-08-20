;;;; Testing
(defmacro assert (expr)
  `(let ((it ,expr))
     (if it it
         (do
           (print "<" stderr)
           (print ',expr stderr)
           (print ">[" stderr)
           (write ,expr stderr)
           (print "] did not evaluate to true\n" stderr)
           (exit 1)
           (throw "Assert failed")))))

(defmacro assert= (expr1 expr2 (reason ""))
  `(if (= ,expr1 ,expr2) true
       (do
        (print "<" stderr)
        (print ',expr1 stderr)
        (print ">[" stderr)
        (print ,expr1 stderr)
        (print "]was not equal to <" stderr)
        (write ',expr2 stderr)
        (print ">[" stderr)
        (write ,expr2 stderr)
        (print "]" stderr)
        (print ,reason stderr)
        (print "\n" stderr)
        (exit 1)
        (throw "Assert failed"))))

