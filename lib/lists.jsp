(defun length (list)
  (if (nil? list) 0
      (+ 1 (length (cdr list)))))

(defun reverse (list)
  (reduce (fn (x acc) (cons x acc))
          list '()))

(defun index-of (x list)
  (defun index-of-inner (c list)
    (cond
      ((nil? list) nil)
      ((= x (car list)) c)
      (true (index-of-inner (+ 1 c) (cdr list)))))
  (index-of-inner 0 list))

(defun includes? (x list)
  (if list
      (if (= (car list) x)
          true
          (includes? x (cdr list)))
      false))


(defun iota (x)
  (defun iota-inner (x)
    (cond
      ((= 0 x) nil)
      ;((> 0 x) (throw "iota requires a positive integer"))
      (true (cons (minus x 1)
                  (iota-inner (minus x 1))))))
  (reverse (iota-inner x)))

;; alist get
(defun assoc-get (key list)
  (cdr (assoc key list)))
(defun assoc-set (key nval list)
  (def a (assoc key list))
  (cdr-set a nval)
  a)
(defun assoc (key list)
  (if list
    (if (= key (caar list))
        (car list)
        (assoc key (cdr list)))
    nil))
(defun acons (key value list)
  (cons
   (cons key value)
   list))


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
