(defmacro or_2 (a b)
  `(let ((it ,a))
       (if it it ,b)))
(defmacro and_2 (a b)
  `(let ((it ,a))
       (if it ,b it)))

(defun not (val)
  (if (nil? val) true
      (if (= false val) true
          false)))

(defun and-list (params)
  (if (= 0 (length params)) true
      (if (= 1 (length params)) (car params)
          (and_2 (car params) (and-list (cdr params))))))

(defun and (. params)
  (and-list params))

(defun or-list (params)
  (if (= 0 (length params)) false
      (if (= 1 (length params)) (car params)
          (or_2 (car params) (or-list (cdr params))))))

(defun or (. params)
  (or-list params))

(defmacro cond (. args)
  (if (= 0 (length args))
      'nil
      (let ((opt (car args)))
        `(if ,(car opt)
             ,(car (cdr opt))
             (cond ,@(cdr args))))))

(defmacro case (var . args)
  (def r (reverse args))
  (def else (car r))
  (def items (cdr r))
  (def mapped-items (map (fn (x) `((= ,var ,(car x)) ,(car (cdr x)))) items))
  (def all-items (cons `(true ,else) mapped-items))
  (def reversed-all (reverse all-items))
  (cons 'cond reversed-all))


