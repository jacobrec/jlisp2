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

;;; Hashmap tests
(def h (empty-hashmap))
(assert= h (empty-hashmap))
(assert= 0 (hashmap-size h))

(hashmap-add h 'hi 4)
(assert= 1 (hashmap-size h))
(assert (hashmap-has h 'hi))

(hashmap-add h 'hello 5)
(assert= 4 (hashmap-get h 'hi))
(assert (hashmap-has h 'hi))
(assert= 5 (hashmap-get h 'hello))
(assert= 2 (hashmap-size h))

(hashmap-add h 'hi 5)
(assert= 5 (hashmap-get h 'hi))
(assert= 2 (hashmap-size h))
(assert (hashmap-has h 'hi))

(hashmap-remove h 'hi)
(assert= 1 (hashmap-size h))
(assert= nil (hashmap-get h 'hi))
(assert (not (hashmap-has h 'hi)))
(assert= nil (hashmap-get h 'aahhhahah))

(assert= 3 (length '(1 2 3)))
(assert= 0 (length nil))
(assert= 0 (length '()))
(assert= nil '())

(assert (and))
(assert= 2 (and 1 2))
(assert= 5 (and 1 2 3 4 5))
(assert= false (and 1 false 3 4 5))

(assert (not (or)))
(assert= 1 (or 1 2))
(assert= 2 (or nil 2 3 4 5))
(assert= false (or nil false))

(assert= '(4 5 6) (map (fn (x) (+ 3 x)) '(1 2 3)))
(assert= '(3 3 3) (filter (fn (x) (= 3 x)) '(1 2 3 1 2 3 1 2 3)))
(assert= 18       (reduce + '(1 2 3 1 2 3 1 2 3) 0))
(assert= "abcde"  (reduce-right string+ '("a" "b" "c" "d" "e") ""))
(assert= "edcba"  (reduce-left string+ '("a" "b" "c" "d" "e") ""))
(assert= "edcba"  (reduce string+ '("a" "b" "c" "d" "e") ""))

(assert= '(1 2 3 4) (reverse '(4 3 2 1)))

(defun test ((a 1) (b 2) . c)
  `(,(+ a b) ,@c))

(defun testscope-1 ()
  (let ((a 2))
    (assert= a 2)
    (let ((x 5))
      (assert= a 2)
      (set a 5)
      (assert= a 5))
    (assert= a 5)))

(defun testscope-2 ()
  (set a 5) ; sets global variable
  (def a 1) ; define local
  (assert= a 1)
  (set a 6); set local
  (assert= a 6))

(defun testscope-a (val)
  (assert= val a))

(def a 1)
(assert= a 1)
(testscope-1)
(assert= a 1)
(testscope-2)  ; modifies global variable
(assert= a 5)
(testscope-a 5)
(let ((a 4))
  (testscope-a 5))





(write "All tests finished\n")
