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

#|
(defun walk (sexp)
  (if (and_2 (list? sexp) (not (nil? sexp)))
      (case (car sexp)
        ('if `(if ,(walk (second sexp))
                  ,(walk (third sexp))
                  ,(walk (fourth sexp))))
        ('quote sexp)
        ('def `(def ,(second sexp) ,(walk (third sexp))))
        ('set `(set ,(second sexp) ,(walk (third sexp))))
        ('let sexp)
        ('let `(let ,(walk (second sexp))
                 ,@(map walk (cddr sexp))))
        ('fn `(fn ,(walk (second sexp))
                 ,@(map walk (cddr sexp))))
        ('macro `(macro ,(walk (second sexp)))
                 ,@(map walk (cddr sexp)))
        ('quasiquote (throw "quasiquote not supported"))
        (map walk sexp)) ; funcalls
      sexp))  ; consts
|#

(defun gen-name (prefix)
  (string+ prefix ";" "test"))

(defun lift-lambdas (forms)
  (def lifted '())
  (defun lift (sexp)
    (if (and_2 (list? sexp) (not (nil? sexp)))
        (case (car sexp)
          ('if `(if ,(lift (second sexp))
                    ,(lift (third sexp))
                    ,(lift (fourth sexp))))
          ('quote sexp)
          ('def `(def ,(second sexp) ,(lift (third sexp))))
          ('set `(set ,(second sexp) ,(lift (third sexp))))
          ('let `(let ,(lift (second sexp))
                   ,@(map lift (cddr sexp))))
          ('fn (do
                (def fun (tag-function sexp))
                (def name (string->symbol (gen-name "fn")))
                (push `(function ,name ,(cdr fun)) lifted)
                `(fn ,name)))
          ('macro sexp)
          ('quasiquote sexp)
          (map lift sexp)) ; funcalls
        sexp))  ; consts
  (def forms (map lift forms))
  (append lifted forms))


(defun compile-if (sexp)
  (def con (compile (second sexp)))
  (def then (compile (third sexp)))
  (def else (compile (fourth sexp)))
  (string+
   con
   ;; JMPF [n] when n is the size of next compile + 1 (for the next jump)
   (emit-op 'JMPF (+ 1 (string-length else)))
   then
   ;; JMP [n] when n is the size of next compile
   (emit-op 'JMP (string-length else))
   else))

(defun compile-function (sexp)
  (def name (second sexp))
  (def properties (third sexp))
  (def arity (assoc-get 'arity properties))
  (def bodies (assoc-get 'body properties))

  (def c-bodies (compile-forms bodies))
  (string+
    (emit-op 'FUNCTION (symbol->string name))
    (emit-lit (+ 1 (string-length c-bodies))) ; size of body
    c-bodies ; compiled bodies
    (emit-op 'RETURN)))

(defun compile-call (sexp)
  (cond
    ((and
      (symbol? (cadar sexp))
      (string-starts-with? (symbol->string (cadar sexp)) "fn;"))
     (def res "")
     (map (fn (x) (string+= res (compile x))) (cdr sexp))
     (string+= res
      (emit-op 'CALL
               (minus (length sexp) 1)
               (symbol->string (cadar sexp))))
     res)))

(defun compile (sexp)
  (if (and_2 (list? sexp) (not (nil? sexp)))
      (case (car sexp)
        ('if (compile-if sexp))
        ('quote (throw "compiler doesn't support quote yet"))
        ('def (throw "compiler doesn't support def yet"))
        ('set (throw "compiler doesn't support set yet"))
        ('let (throw "compiler doesn't support let yet"))
        ('fn  (throw "compiler should have gotten rid of fn")) ; fn has been processed out to function
        ('function (compile-function sexp))
        ('local (emit-op 'LOCAL (second sexp)))
        ('macro (throw "compiler doesn't support macros yet"))
        ('quasiquote (throw "compiler doesn't support quasiquote yet"))
        (compile-call sexp))
      (emit-const sexp)))

(defun compile-forms (lst)
  (reduce (fn (x acc) (string+ acc (compile x))) lst ""))

;(write-bytes (compile '(if 1 2 3)) stdout)

(defun pipe (var . fns)
  (reduce (fn (x acc) (x acc)) fns var))


(def prog
    '(((fn (x) x) 5)))

(pipe prog
      lift-lambdas
      compile-forms
      println)
