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
