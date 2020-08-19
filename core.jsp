(def defmacro
    (macro (name args . bodies)
      `(def ,name (macro ,args ,@bodies))))

(defmacro defun (name args . bodies)
  `(def ,name (fn ,args ,@bodies)))

(defun map (f list)
  (if (nil? list)
    nil
    (cons (f (car list))
          (map f (cdr list)))))

(defun or_2 (a b)
  (if a a b))
(defun and_2 (a b)
  (if a b a))

(defun not (val)
  (if (or_2 (nil? val)
            (and_2 (bool? val) (= false val)))
    true
    false))

(defmacro do (. bodies)
  `(let () ,@bodies))

(defmacro unless (con . bodies)
  `(if ,con nil (do ,@bodies)))
(defmacro when (con . bodies)
  `(if ,con (do ,@bodies) nil))

(defun load-in-env (filepath env)
  (def f (open filepath))
  (defun loop ()
    (def v (read f))
    (unless (eof? v)
            (eval v env)
            (loop)))
  (loop))

(defmacro load (filepath)
  `(load-in-env ,filepath (current-enviroment)))


;;; Anaphoric Macros
(defmacro aif (condition then else)
  `(let ((it ,condition))
     (if it ,then ,else)))

;;;; Testing
(defmacro assert (expr)
  `(let ((it ,expr))
     (if it it
         (do
           (write "<<<" stderr)
           (write ',expr stderr)
           (write ">>> Did not evaluate to true" stderr)
           (write "\n" stderr)
           (throw "Assert failed")))))

(defmacro assert= (expr1 expr2)
  `(if (= ,expr1 ,expr2) true
       (do
        (write "<<<" stderr)
        (write ',expr1 stderr)
        (write ">>> was not equal to <<<" stderr)
        (write ',expr2 stderr)
        (write ">>> \n" stderr)
        (write "\n" stderr)
        (throw "Assert failed"))))
