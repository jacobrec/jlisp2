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

;; readquote
;; readquasiquote
;; readunquote

;; readstring
;; readcomment
