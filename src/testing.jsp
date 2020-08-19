;;;; Testing
(defmacro assert (expr)
  `(let ((it ,expr))
     (if it it
         (do
           (write "<" stderr)
           (write ',expr stderr)
           (write ">[" stderr)
           (write ,expr stderr)
           (write "] did not evaluate to true\n" stderr)
           (throw "Assert failed")))))

(defmacro assert= (expr1 expr2)
  `(if (= ,expr1 ,expr2) true
       (do
        (write "<" stderr)
        (write ',expr1 stderr)
        (write ">[" stderr)
        (write ,expr1 stderr)
        (write "]was not equal to <" stderr)
        (write ',expr2 stderr)
        (write ">[" stderr)
        (write ,expr2 stderr)
        (write "]" stderr)
        (write "\n" stderr)
        (throw "Assert failed"))))

