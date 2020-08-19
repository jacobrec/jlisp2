;;;; Functional programming stuff
;;; map, reduce, filter, etc

(defun map (f list)
  (if (nil? list)
    nil
    (cons (f (car list))
          (map f (cdr list)))))
