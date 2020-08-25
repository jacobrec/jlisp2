(def false false)
(def nil nil)
(def true true)

(defun macroexpand-1 (y)
  (if (nil? y) nil
    (if (not (list? y)) y
      (let ((v (eval (car y))))
        (if (macro? v)
          (proccall (cons v (cdr y)))
          y)))))

(defun macroexpand-all (y)
  (cond
    ((nil? y) nil)
    ((not (list? y)) y)
    (case (car y)
      ('if `(if ,(macroexpand-all (second sexp))
                ,(macroexpand-all (third sexp))
                ,(macroexpand-all (fourth sexp))))
      ('quote y)
      ('def `(def ,(second sexp) ,(macroexpand-all sexp)))
      ('set `(set ,(second sexp) ,(macroexpand-all sexp)))
      ('let 0)
      ('fn `(fn ,(second sexp) ,@(map macroexpand-all (cddr sexp))))
      ('macro (macro ,(second sexp) ,@(map macroexpand-all (cddr sexp))))
      sexp)))

(defun eval1 (sexp (env $env))
  (cond
    ((and (list? sexp) (not (nil? sexp)))
     (def cmd (car sexp))
     (case cmd
       ('if (if (eval1 (second sexp) env)
                (eval1 (third sexp) env)
                (eval1 (fourth sexp) env)))

       ('quote (second sexp))

       ('def (env-put env (second sexp) (eval1 (third sexp))))

       ('set (env-set env (second sexp) (eval1 (third sexp))))

       ('let (let ((args (second sexp))
                   (body (cddr sexp))
                   (v nil))
               (env-push env)
               (map (fn (x) (env-put env (first x) (eval1 (second x)))) args)
               (map (fn (x) (set v (eval1 x))) body)
               (env-pop env)
               v))

       ('fn (make-function (second sexp) (cddr sexp)))

       ('macro (make-macro (make-function (second sexp) (cddr sexp))))

       ('quasiquote (flatten1 (map (fn (x)
                                       (writeln x (list? x))
                                       (cond ((and_2 (list? x) (= 'unquote (car x)))
                                              (list (eval1 (second x))))
                                             ((and_2 (list? x) (= 'unquote-splice (car x)))
                                              (eval1 (second x)))
                                             (true (list x)))) (second sexp))))

       (do
        (if (macro? (eval1 (car sexp)))
          (eval1 (macroexpand sexp))
          (proccall (map (fn (x) (eval1 x)) sexp))))))
    ((false? sexp) false) ; return true or false if true or false
    ((true? sexp) true) ; return true or false if true or false
    ((symbol? sexp) ; lookup value if symbol
     (env-get env sexp))
    (true ; return otherwise, this is like strings, or numbers
     sexp)))

(defun repl1 ()
  (print "1> ")
  (def v (read))
  (unless (eof? v)
    (println "==>" (eval1 v))
    (repl1)))
