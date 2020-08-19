(defun length (list)
  (if (nil? list) 0
      (+ 1 (length (cdr list)))))

(defun reverse (list)
  (reduce (fn (x acc) (cons x acc))
          list '()))
