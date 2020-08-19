(assert true)
(assert (not false))

(assert (= 3 (when 1 1 2 3)))
(assert (= nil (unless 1 1 2 3)))

(assert (= '(1 2 3) `(1 2 3)))
(assert (= '(1 2 3) `(1 2 ,(+ 1 2))))
(assert (= '(1 2 3) '(1 2 3)))

(assert (aif true it (write "SOMETHING WENT WRONG\n")))
(assert (not (aif false (write "SOMETHING WENT WRONG\n") it)))

(assert (= 30 (let ((a 10)
                    (b 20))
                (+ a b))))

(def testfn (fn (one . rest)
              rest))
(assert (= '(2 3 4) (testfn 1 2 3 4)))

(assert (= '(+ 1 2 3 4 5 6)
           (let ((r '(4 5 6)))
             `(+ 1 2 ,(+ 1 2) ,@r))))

(defun a () '(7 8 9))
(assert (= '(+ 1 2 3 4 5 6 7 8 9)
           (let ((r `(4 ,(+ 2 3) 6 ,@(a))))
             `(+ 1 2 ,(+ 1 2) ,@r))))

(assert= '(1 2 3) `(1 2 3))

(write "All tests finished\n")
