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
  (map (fn (x) (emit-lit out x)) args)
  (newline))

(def items toks)
(println items)
(emit-op (ropen "/../tmp" true) 'STRING1 "Hello")

;(repl1)
