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

(assert true)
(assert (not false))
