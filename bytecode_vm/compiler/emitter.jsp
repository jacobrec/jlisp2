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
(defun emit-string-as-bytes (str)
  (def s "")
  (map (fn (x) (string+= s (emit-lit (char->int (string-at str x)))))
       (iota (string-length str)))
  (string+ s (emit-lit 0)))


(defun emit-lit (x)
  (cond
    ((string? x)
     (string+
       (emit-lit (+ 1 (string-length x)))
       (emit-string-as-bytes x)))
    ((int? x) (if (or (< x 0) (> x 255))
                  (throw (string+ "cannot emit multibyte ints yet: " x))
                  (int->char x)))
    ((float? x) (throw "cannot emit floats yet"))
    (true (write x stderr) (throw "cannot emit unknown type"))))


(defun emit-op (opcode . args)
  (def byte-op (assoc-get opcode toks))
  (def s (int->char byte-op))
  (map (fn (x) (string+= s (emit-lit x))) args)
  s)

(defun emit-const (x)
  (cond
    ((nil? x) (emit-op 'NIL))
    ((symbol? x) (emit-op 'SYMBOL1 (symbol->string x)))
    ((string? x) (emit-op 'STRING1 x))
    ((int? x) (emit-op 'INT1 x))
    ((true? x) (emit-op 'TRUE))
    ((false? x) (emit-op 'FALSE))
    ((float? x) (throw "cannot emit floats yet"))
    (true (println x) (throw "cannot emit unknown type"))))
