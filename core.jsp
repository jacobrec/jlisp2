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

(defmacro assert (expr)
  `(if ,expr
     ,expr
     (throw "Assert failed")))

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
     (if it ,then ,else))) ; Hello
