;;;; Functional programming stuff
;;; map, reduce, filter, etc

(defun map (f list)
  (if (nil? list)
    nil
    (cons (f (car list))
          (map f (cdr list)))))

(defun filter (f list)
  (if (nil? list)
    nil
    (if (f (car list))
      (cons (car list)
            (filter f (cdr list)))
      (filter f (cdr list)))))

(defun reduce-left (f list start)
  (if (nil? list)
    start
    (reduce-left f (cdr list) (f (car list) start))))

(defun reduce-right (f list start)
  (if (nil? list) start
    (f (car list)
       (reduce-right f (cdr list) start))))

(def reduce reduce-left)
