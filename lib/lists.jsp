(defun length (list)
  (if (nil? list) 0
      (+ 1 (length (cdr list)))))

(defun reverse (list)
  (reduce (fn (x acc) (cons x acc))
          list '()))

(defun includes? (x list)
  (if list
      (if (= (car list) x)
          true
          (includes? x (cdr list)))
      false))


(defun append (a b)
  (cond
    ((nil? a) b)
    (true (cons (car a) (append (cdr a) b)))))
(defun flatten1 (x)
  (reduce-right (fn (x acc) (if (list? x) (append x acc) (cons x acc) x)) x '()))

(defun list (. items)
  items)

(defmacro rest (x)
  `(cdr x))
(defmacro first (x)
  `(car ,x))
(defmacro second (x)
  `(car (cdr ,x)))
(defmacro third (x)
  `(car (cdr (cdr ,x))))
(defmacro fourth (x)
  `(car (cdr (cdr (cdr ,x)))))
(defmacro fifth (x)
  `(car (cdr (cdr (cdr (cdr ,x))))))
(defmacro sixth (x)
  `(car (cdr (cdr (cdr (cdr (cdr ,x)))))))
(defmacro seventh (x)
  `(car (cdr (cdr (cdr (cdr (cdr (cdr ,x))))))))
(defmacro eighth (x)
  `(car (cdr (cdr (cdr (cdr (cdr (cdr (cdr ,x)))))))))
(defmacro ninth (x)
  `(car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr ,x))))))))))
(defmacro tenth (x)
  `(car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr ,x)))))))))))
