;;; Step 1, define enough stuff to be able to define require
(def defmacro
    (macro (name args . bodies)
      `(def ,name (macro ,args ,@bodies))))

(defmacro defun (name args . bodies)
  `(def ,name (fn ,args ,@bodies)))

(defmacro do (. bodies)
  `(let () ,@bodies))

(defmacro unless (con . bodies)
  `(if ,con nil (do ,@bodies)))
(defmacro when (con . bodies)           ; when technically isnt used
  `(if ,con (do ,@bodies) nil))         ; to define require, unless
                                        ; is, and it made sense to put
                                        ; these next to each other

;; load is kind of like a c style include, where it throws the forms
;; in the current location. load-in-env allows you to specify a
;; location to run it from, eg. $toplevel
(defun load-in-env (filepath env)
  (def f (open filepath))
  (defun loop ()
    (def v (read f))
    (unless (eof? v)
            (eval v env)
            (loop)))
  (loop))

(defmacro load (filepath)
  `(load-in-env ,filepath (current-enviroment)))

(defun current-file ()
  (car $file))

(defun dir (filepath)
  (string-join (reverse (cdr (reverse (string-split filepath "/")))) "/"))

(def $tmp nil)
(def $toplevel (current-enviroment))
(def $required (empty-hashmap))
(defun require (filepath)
  (def filepath (if (string-starts-with? filepath "./")
                    (string+ (dir (current-file)) (substring filepath 1))
                    filepath))
  (unless (hashmap-has $required filepath)
    (hashmap-add $required filepath true)
    (load-in-env filepath $toplevel)))


;; Things that idk where to put yet
(defmacro += (val offset) `(set ,val (+ ,val ,offset)))
(defmacro string+= (val offset) `(set ,val (string+ ,val ,offset)))

(require "./src/cadr.jsp")
(require "./src/testing.jsp")
(require "./src/functional.jsp")
(require "./src/lists.jsp")
(require "./src/booleans.jsp")
(require "./src/anaphoric.jsp")
(require "./src/printing.jsp")
(require "./src/reader.jsp")


