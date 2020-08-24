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

(defun free-vars (form)
  (assert= 'fn (first form))
  (def args (second form))
  (def bodies (cddr form))
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

(println (free-vars '(fn (x) (+ x y))))
(println (macroexpand-all '(defun test () 5)))
