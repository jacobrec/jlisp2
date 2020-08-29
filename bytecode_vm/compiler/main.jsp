(require "./emitter.jsp")

(defmacro push (val list)
  `(set ,list (cons ,val ,list)))

(def special-forms '(quote if def set let do fn macro builtin))
(defun free-vars (args bodies)
  (def free '())
  (defun walk (sexp)
    (if (and_2 (list? sexp) (not (nil? sexp)))
        (case (car sexp)
          ('if `(if ,(walk (second sexp))
                    ,(walk (third sexp))
                    ,(walk (fourth sexp))))
          ('quote sexp)
          ('def `(def ,(second sexp) ,(walk (third sexp))))
          ('set `(set ,(second sexp) ,(walk (third sexp))))
          ('let `(let ,(walk (second sexp))
                   ,@(map walk (cddr sexp))))
          ('closure `(closure ,(second sexp) ,(walk (third sexp))))
          ('fn `(fn ,(walk (second sexp))
                   ,@(map walk (cddr sexp))))
          ('macro `(macro ,(walk (second sexp)))
                   ,@(map walk (cddr sexp)))
          ('builtin sexp)
          ('quasiquote (throw "quasiquote not supported"))
          (map walk sexp)) ; funcalls
        (cond
          ((symbol? sexp)
           (unless (or (includes? sexp args)
                       (includes? sexp free))
             (push sexp free)))
          (true sexp))))  ; consts
  (walk bodies)
  free)


(defun tag-locals (args free bodies)
  (defun check-local (form)
    (cond
      ((nil? form) nil)
      ((and_2 (symbol? form) (not (includes? form special-forms)))
       (aif (index-of form args)
            (list 'local it)
            (aif (index-of form free)
                 (list 'local (+ (length args) it))
                 form)))
      ((not (list? form)) form)
      ((= 'quote (car form)) form)
      ((= 'fn (car form)) form) ; TODO: deal with nested lambdas
      (true
       (cons (check-local (car form))
             (check-local (cdr form))))))
  (check-local bodies))

(defun tag-function (add-lambda form)
  (assert= 'fn (first form))
  (def args (second form))
  (def bodies (lift-lambdas (cddr form) add-lambda))
  (def free (free-vars args bodies))
  (def tagged-body
      (tag-locals args free bodies))
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

(defun gen-name ()
  (string+
   (int->char (+ 97 (random 0 26)))
   (int->char (+ 97 (random 0 26)))
   (int->char (+ 97 (random 0 26)))
   (int->char (+ 97 (random 0 26)))))

(defun convert-closure (fun name)
  (aif (assoc-get 'free (cdr fun))
      (do
       `(closure ,name ,it))
      `(fn ,name)))

;; TODO: nested lambdas
(defun lift-lambdas (forms (lifter nil))
  (def lifted '())
  (defun add-lambda (x)
    (push x lifted))
  (set lifter (or lifter add-lambda))
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
                (def fun (tag-function lifter sexp))
                (def name (string->symbol (gen-name)))
                (lifter `(function ,name ,(cdr fun)))
                (convert-closure fun name)))
          ('builtin sexp)
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
    (emit-lit arity)
    (emit-lit (+ 1 (string-length c-bodies))) ; size of body
    c-bodies ; compiled bodies
    (emit-op 'RETURN)))

(defun compile-call (sexp)
  (def res "")
  (map (fn (x) (string+= res (compile x))) (cdr sexp))
  (string+= res (compile (car sexp)))
  (string+= res (emit-op 'CALL (minus (length sexp) 1)))
  res)

(defun compile-closure (sexp)
  (def name (second sexp))
  (def fun (compile `(fn ,name)))
  (def frees (third sexp))
  (def res "")
  (map (fn (x) (string+= res (compile x))) frees) ;; add free variables
  (string+= res fun)
  (string+= res (emit-op 'MAKE_CLOSURE (length frees)))
  res)

(defun compile-builtin (sexp)
  (def forms (cdr sexp))
  (reduce
   (fn (x acc)
       (string+ acc (eval `(emit-op ',(car x) ,@(cdr x)))))
   forms
   ""))

(defun compile (sexp)
  ;(println sexp)
  (if (and_2 (list? sexp) (not (nil? sexp)))
      (case (car sexp)
        ('if (compile-if sexp))
        ('quote (throw "compiler doesn't support quote yet"))
        ('def (throw "compiler doesn't support def yet"))
        ('set (throw "compiler doesn't support set yet"))
        ('let (throw "compiler doesn't support let yet"))
        ('function (compile-function sexp))
        ('closure (compile-closure sexp))
        ('fn  (emit-op 'FUNCTION_POINTER (symbol->string (second sexp)))) ; fn has been processed out to function fn is now always (fn fn;name)
        ('local (emit-op 'LOCAL (second sexp)))
        ('macro (throw "compiler doesn't support macros yet"))
        ('quasiquote (throw "compiler doesn't support quasiquote yet"))
        ('builtin (compile-builtin sexp))
        (compile-call sexp))
      (emit-const sexp)))

(defun compile-forms (lst)
  (reduce (fn (x acc) (string+ acc (compile x))) lst ""))

;(write-bytes (compile '(if 1 2 3)) stdout)

(defun pipe (var . fns)
  (reduce (fn (x acc) (x acc)) fns var))


(def prog '(
            ((fn (x y)
              (builtin
                (LOCAL 0)
                (LOCAL 1)
                (ADD)))
             40 9)))

(defun printlines-and-pass (x)
  (map println x)
  x)
(defun print-end (x)
  (print x)
  (print (emit-op 'END)))
(pipe prog
      lift-lambdas
      ;printlines-and-pass
      compile-forms
      print-end)
