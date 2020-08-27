(require "./emitter.jsp")

(defmacro push (val list)
  `(set ,list (cons ,val ,list)))

(def special-forms '(quote if def set let do fn macro))
(defun free-vars (args bodies)
  (def free '())
  (defun check-free (form)
    (cond
      ((nil? form) nil)
      ((symbol? form)
       (unless (includes? form args)
         (push form free)))
      ((not (list? form)) nil)
      ((= 'quote (car form)) nil)
      (true
       (do (check-free (car form))
           (check-free (cdr form))))))
  (check-free bodies)
  free)

(defun tag-free (freelist bodies)
  (defun check-free (form)
    (cond
      ((nil? form) nil)
      ((symbol? form)
       (aif (index-of form freelist)
         (list 'free it)
         form))
      ((not (list? form)) form)
      ((= 'quote (car form)) form)
      ((= 'fn (car form)) form) ; TODO: deal with nested lambdas
      (true
       (cons (check-free (car form))
             (check-free (cdr form))))))
  (check-free bodies))

(defun tag-locals (args bodies)
  (defun check-local (form)
    (cond
      ((nil? form) nil)
      ((symbol? form)
       (aif (index-of form args)
         (list 'local it)
         form))
      ((not (list? form)) form)
      ((= 'quote (car form)) form)
      ((= 'fn (car form)) form) ; TODO: deal with nested lambdas
      (true
       (cons (check-local (car form))
             (check-local (cdr form))))))
  (check-local bodies))

(defun tag-constants (bodies)
  (defun check-consts (form)
    (cond
      ((nil? form) nil)
      ((symbol? form) form)
      ((not (list? form)) (list 'const form))
      ((= 'quote (car form)) form)
      ((= 'fn (car form)) form) ; TODO: deal with nested lambdas
      (true
       (cons (check-consts (car form))
             (check-consts (cdr form))))))
  (check-consts bodies))

(defun tag-forms (bodies)
  (defun check-forms (form)
    (cond
      ((nil? form) nil)
      ((symbol? form) (if (includes? form special-forms)
                          (list 'form form)
                          form))
      ((not (list? form)) form)
      ((= 'quote (car form)) form)
      ((= 'fn (car form)) form) ; TODO: deal with nested lambdas
      (true
       (cons (check-forms (car form))
             (check-forms (cdr form))))))
  (check-forms bodies))

(defun tag-function (form)
  (assert= 'fn (first form))
  (def args (second form))
  (def bodies (cddr form))
  (def free (free-vars args bodies))
  (def tagged-body
      (tag-free free
                (tag-locals args
                            (tag-forms
                             (tag-constants bodies)))))
  (def info (acons 'free free
                   (acons 'body tagged-body
                          (acons 'arity (length (second form)) '()))))
  (cons 'fn info))

(defun type-of (x)
  (cond
    ((nil? x) "nil")
    ((bool? x) "bool")
    ((string? x) "string")
    ((int? x) "int")
    ((float? x) "float")
    ((and (symbol? x) (includes? x special-forms)) "form")
    ((symbol? x) "symbol")
    ((list? x) (map type-of x))
    (true "unknown")))

;(println (tag-function '(fn (x) x))) ; => LOCAL1 0; RETURN
;(println (tag-function '(fn (x) (if x (+ x y) 10))))
;(println (tag-function '(fn (a b c) (+ a b c))))
;(println (macroexpand-all '(case 4 (1 'a) (2 'b) (3 'c) (4 'd) 5)))
;(println (map type-of '(if true (do (+ 1 2) (println "hello")) (or nil false 4.5))))


(defun compile-if (sexp)
  (def con (compile (second sexp)))
  (def then (compile (third sexp)))
  (def else (compile (fourth sexp)))
  (string+
   con
   ;; JMPF [n] when n is the size of next compile + 2 (for the next jump)
   (emit-op 'JMPF (+ 2 (string-length else)))
   then
   ;; JMP [n] when n is the size of next compile
   (emit-op 'JMP (string-length else))
   else))

(defun compile (sexp)
  (if (and_2 (list? sexp) (not (nil? sexp)))
      (case (car sexp)
        ('if (compile-if sexp))

        ('quote (throw)) "compiler doesn't support quote yet"

        ('def (throw "compiler doesn't support def yet"))

        ('set (throw "compiler doesn't support set yet"))

        ('let (throw "compiler doesn't support let yet"))

        ('fn (throw "compiler doesn't support functions yet"))

        ('macro (throw "compiler doesn't support macros yet"))

        ('quasiquote (throw "compiler doesn't support quasiquote yet"))

        (throw "compiler doesn't support function calls yet"))

      (emit-const sexp)))

(def output (ropen "/../tmp" true))

(write-bytes (compile-if '(if 1 2 3)) stdout)
