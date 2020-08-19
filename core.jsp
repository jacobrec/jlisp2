(def map (fn (f list)
             (if (nil? list)
                 nil
                 (cons (f (car list))
                       (map f (cdr list))))))
