;;; Anaphoric Macros
(defmacro aif (condition then else)
  `(let ((it ,condition))
     (if it ,then ,else)))
