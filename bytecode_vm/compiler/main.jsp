(println "Hello, World!")

; relative open
(defun ropen (relpath (for-writeing false))
  (open (string+ (dir (current-file)) relpath) for-writeing))

(defun load-tokenlist ()
  (def file (ropen "/../tokens"))
  (def items '())
  (def i 0)
  (defun loop ()
    (def c (readline file))
    (unless (= "" c)
      (set items (acons (string->symbol c) i items))
      (+= i 1)
      (loop)))
  (loop)
  items)

(def toks (load-tokenlist))
(defun emit-string-as-bytes (out str)
  (map (fn (x) (emit-lit out (char->int (string-at str x))))
       (iota (string-length str)))
  (emit-lit out 0))


(defun emit-lit (out x)
  (cond
    ((string? x)
     (emit-lit out (+ 1 (string-length x)))
     (emit-string-as-bytes out x))
    ((int? x) (if (or (< x 0) (> x 255))
                  (throw (string+ "cannot emit multibyte ints yet: " x))
                  (write-byte x out)))
    ((float? x) (throw "cannot emit floats yet"))
    (true (throw "cannot emit unknown type"))))


(defun emit-op (out opcode . args)
  (def byte-op (assoc-get opcode toks))
  (write-byte byte-op out)
  (map (fn (x) (emit-lit out x)) args))

(def items toks)
(println items)
(emit-op (ropen "/../tmp" true) 'STRING1 "Hello")

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
                          form
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

(println (tag-function '(fn (x) x))) ; => LOCAL1 0; RETURN
(println (tag-function '(fn (x) (if x (+ x y) 10))))
(println (tag-function '(fn (a b c) (+ a b c))))
;(println (macroexpand-all '(case 4 (1 'a) (2 'b) (3 'c) (4 'd) 5)))
(println (map type-of '(if true (do (+ 1 2) (println "hello")) (or nil false 4.5))))
