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
                             (if (= c "n") "\n"
                                 (if (= c "t") "\t"
                                     (if (= c "r") "\r"
                                         (if (= c "v") "\v"
                                             (if (= c "b") "\b"
                                                 (if (= c "\\") "\\"
                                                     (if (= c "\"") "\""
                                                         c)))))))
                             c)))
           (set escaped false)))
      (loop)))
  (loop)
  str)

;; readcomment
