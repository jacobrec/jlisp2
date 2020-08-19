(defun length (list)
  (if (nil? list) 0
      (+ 1 (length (cdr list)))))
