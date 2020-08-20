;; TODO: expose readtable and finish these functions

;; read

(defun peekchar ((src stdin))
  (let ((x (readchar src)))
     (unreadchar x src)
     x))

;; readchar
;; unreadchar
;; readsymbol

(defun skip1read ((src stdin))
  (readchar src)
  (read src))

;; readsexp
;; readnumber
;; readdot

(defun readquote ((src stdin))
  (readchar src) ; discards the '
  `(quote ,(read src)))
(defun readquasiquote ((src stdin))
  (readchar src) ; discards the `
  `(quasiquote ,(read src)))
;; readunquote

(defun readstring ((src stdin))
  (def str "")
  (def escaped false)
  (readchar src) ; skip leading "
  (defun loop ()
    (def c (readchar src))
    (unless (and (= c "\"") (not escaped))
      (if (= c "\\")
          (set escaped true)
          (do
           (set str
                (string+ str
                         (if escaped
                             (case c
                               ("n" "\n")
                               ("t" "\t")
                               ("r" "\r")
                               ("v" "\v")
                               ("b" "\b")
                               ("\\" "\\")
                               ("\"" "\"")
                               c)
                             c)))
           (set escaped false)))
      (loop)))
  (loop)
  str)

(defun readcomment ((src stdin))
  (defun loop ()
    (if (= "\n" (readchar src))
        (read src)
        (loop)))
  (loop))
