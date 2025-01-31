;;; Copyright 2021 Mitchell Kember. Subject to the CC BY-SA 4.0 License.

#!r6rs

(library (src sicp chapter-2)
  (export register-chapter-2)
  (import (rnrs base (6))
          (src lang sicp))

(SICP register-chapter-2

(Chapter :2 "Building Abstractions with Data")

(Section :2.1 "Introduction to Data Abstraction")

(Section :2.1.1 "Example: Arithmetic Operations for Rational Numbers")

(define (add-rat x y)
  (make-rat (+ (* (numer x) (denom y))
               (* (numer y) (denom x)))
            (* (denom x) (denom y))))
(define (sub-rat x y)
  (make-rat (- (* (numer x) (denom y))
               (* (numer y) (denom x)))
            (* (denom x) (denom y))))
(define (mul-rat x y)
  (make-rat (* (numer x) (numer y))
            (* (denom x) (denom y))))
(define (div-rat x y)
  (make-rat (* (numer x) (denom y))
            (* (denom x) (numer y))))
(define (equal-rat? x y)
  (= (* (numer x) (denom y))
     (* (numer y) (denom x))))

;; Pairs:

(define x (cons 1 2))
(car x) => 1
(cdr x) => 2

(define y (cons 3 4))
(define z (cons x y))
(car (car z)) => 1
(car (cdr z)) => 3

;; Representing rational numbers:

(define (make-rat n d) (cons n d))
(define (numer x) (car x))
(define (denom x) (cdr x))

(define (print-rat x)
  (newline)
  (display (numer x))
  (display "/")
  (display (denom x)))

(define one-half (make-rat 1 2))
(print-rat one-half) =$> ["1/2"]

(define one-third (make-rat 1 3))
(add-rat one-half one-third) => '(5 . 6)
(mul-rat one-half one-third) => '(1 . 6)
(add-rat one-third one-third) => '(6 . 9)

;; Reducing to lowest terms:

(define (make-rat n d)
  (let ((g (gcd n d)))
    (cons (/ n g) (/ d g))))

(add-rat one-third one-third) => '(2 . 3)

(Exercise ?2.1)

(define (sgn x)
  (cond ((positive? x) 1)
        ((zero? x) 0)
        ((negative? x) -1)))

(define (make-rat n d)
  (let ((g (gcd n d))
        (s (* (sgn n) (sgn d))))
    (cons (* s (/ (abs n) g))
          (/ (abs d) g))))

(make-rat 5 10) => '(1 . 2)
(make-rat -5 10) => '(-1 . 2)
(make-rat -5 -10) => '(1 . 2)
(make-rat 5 -10) => '(-1 . 2)

(Section :2.1.2 "Abstraction Barriers")

(define (make-rat n d) (cons n d))
(define (numer x)
  (let ((g (gcd (car x) (cdr x))))
    (/ (car x) g)))
(define (denom x)
  (let ((g (gcd (car x) (cdr x))))
    (/ (cdr x) g)))

(Exercise ?2.2)

(define make-point cons)
(define x-point car)
(define y-point cdr)

(define make-segment cons)
(define start-segment car)
(define end-segment cdr)

(define (midpoint-segment seg)
  (let ((a (start-segment seg))
        (b (end-segment seg)))
    (make-point
     (/ (+ (x-point a) (x-point b)) 2)
     (/ (+ (y-point a) (y-point b)) 2))))

(midpoint-segment
 (make-segment (make-point 6 5) (make-point 12 13)))
=> '(9 . 9)

(Exercise ?2.3
  (use (?2.2 make-point x-point y-point)))

(define (perimeter rect)
  (* 2 (+ (width-rect rect) (height-rect rect))))
(define (area rect)
  (* (width-rect rect) (height-rect rect)))

;; First representation: two corners.

(define make-rect cons)
(define p1-rect car)
(define p2-rect cdr)
(define (width-rect rect)
  (abs (- (x-point (p1-rect rect))
          (x-point (p2-rect rect)))))
(define (height-rect rect)
  (abs (- (y-point (p1-rect rect))
          (y-point (p2-rect rect)))))

(define rect (make-rect (make-point 1 2) (make-point 6 5)))
(perimeter rect) => 16
(area rect) => 15

;; Second representation: corner and dimensions.

(define (make-rect p w h) (cons p (cons w h)))
(define point-rect car)
(define width-rect cadr)
(define height-rect cddr)

(define rect (make-rect (make-point 1 2) 5 3))
(perimeter rect) => 16
(area rect) => 15

(Section :2.1.3 "What Is Meant by Data?")

(define (cons x y)
  (define (dispatch m)
    (cond ((= m 0) x)
          ((= m 1) y)
          (else (error 'cons "argument not 0 or 1" m))))
  dispatch)

(define (car z) (z 0))
(define (cdr z) (z 1))

(car (cons 'a 'b)) => 'a
(cdr (cons 'a 'b)) => 'b

(Exercise ?2.4)

(define (cons x y) (lambda (m) (m x y)))
(define (car z) (z (lambda (x y) x)))
(define (cdr z) (z (lambda (x y) y)))

(car (cons 'a 'b)) => 'a
(cdr (cons 'a 'b)) => 'b

(Exercise ?2.5)

;; Due to the [fundamental theorem of arithmetic][ftoa], $2^a3^b$ will always
;; produce a unique product given a unique pair of integers $a$ and $b$.
;;
;; [ftoa]: https://en.wikipedia.org/wiki/Fundamental_theorem_of_arithmetic

(define (cons x y) (* (expt 2 x) (expt 3 y)))

(define (count-divides a b)
  (define (count a n)
    (let ((q (/ a b)))
      (if (integer? q)
          (count q (+ n 1))
          n)))
  (count a 0))

(define (car z) (count-divides z 2))
(define (cdr z) (count-divides z 3))

(car (cons 7 12)) => 7
(cdr (cons 7 12)) => 12

(Exercise ?2.6)

(define zero (lambda (f) (lambda (x) x)))
(define (add1 n)
  (lambda (f) (lambda (x) (f ((n f) x)))))

(define one (lambda (f) (lambda (x) (f x))))
(define two (lambda (f) (lambda (x) (f (f x)))))

(define (add a b)
  (lambda (f) (lambda (x) ((a f) ((b f) x)))))

(define (church->number n)
  ((n (lambda (x) (+ x 1))) 0))

(church->number zero) => 0
(church->number one) => 1
(church->number two) => 2
(church->number (add1 two)) => 3
(church->number (add one zero)) => 1
(church->number (add zero two)) => 2
(church->number (add one two)) => 3
(church->number (add two two)) => 4

(Section :2.1.4 "Extended Exercise: Interval Arithmetic"
  (use (?2.7 lower-bound make-interval upper-bound)))

(define (add-interval x y)
  (make-interval (+ (lower-bound x) (lower-bound y))
                 (+ (upper-bound x) (upper-bound y))))

(define (mul-interval x y)
  (let ((p1 (* (lower-bound x) (lower-bound y)))
        (p2 (* (lower-bound x) (upper-bound y)))
        (p3 (* (upper-bound x) (lower-bound y)))
        (p4 (* (upper-bound x) (upper-bound y))))
    (make-interval (min p1 p2 p3 p4)
                   (max p1 p2 p3 p4))))

(define (div-interval x y)
  (mul-interval
   x
   (make-interval (/ 1.0 (upper-bound y))
                  (/ 1.0 (lower-bound y)))))

(Exercise ?2.7)

(define (make-interval a b) (cons a b))
(define (lower-bound x) (car x))
(define (upper-bound x) (cdr x))

(Exercise ?2.8
  (use (?2.7 lower-bound make-interval upper-bound)))

;; The difference between two intervals reaches a minimum at the minuend's lower
;; bound minus the subtrahend's upper bound. It reaches a maximum at the
;; minuend's upper bound minus the subtrahend's lower bound.
(define (sub-interval x y)
  (make-interval (- (lower-bound x) (upper-bound y))
                 (- (upper-bound x) (lower-bound y))))

(Exercise ?2.9
  (use (:2.1.4 add-interval div-interval mul-interval)
       (?2.7 lower-bound make-interval upper-bound) (?2.8 sub-interval)))

(define (width x)
  (/ (- (upper-bound x) (lower-bound x)) 2))

;; Consider arbitrary intervals `x` and `y`:

(define x1 (random 1000))
(define x2 (random 1000))
(define y1 (random 1000))
(define y2 (random 1000))

(define x (make-interval x1 x2))
(define y (make-interval y1 y2))

(width x) => (/ (- x2 x1) 2)
(width y) => (/ (- y2 y1) 2)

;; The width of the sum is the sum of the widths:

(width (add-interval x y))
=> (width (make-interval (+ x1 y1) (+ x2 y2)))
=> (/ (- (+ x2 y2) (+ x1 y1)) 2)
=> (/ (+ (- x2 x1) (- y2 y1)) 2)
=> (+ (/ (- x2 x1) 2) (/ (- y2 y1) 2))
=> (+ (width x) (width y))

;; The width of the difference is also the sum of the widths:

(width (sub-interval x y))
=> (width (make-interval (- x1 y2) (- x2 y1)))
=> (/ (- (- x2 y1) (- x1 y2)) 2)
=> (/ (+ (- x2 x1) (- y2 y1)) 2)
=> (+ (/ (- x2 x1) 2) (/ (- y2 y1) 2))
=> (+ (width x) (width y))

;; The width of a product or quotient is not a function of the widths of the
;; intervals being multiplied or divided. Here is a counterexample:

(define x (make-interval 0 10))
(define y (make-interval 4 6))
(width x) => 5
(width y) => 1
(width (mul-interval x y)) => 30
(width (div-interval x y)) ~> 1.25

(define x (make-interval -5 5))
(define y (make-interval -1 1))
(width x) => 5
(width y) => 1
(width (mul-interval x y)) => 5
(width (div-interval x y)) ~> 5.0

;; In both cases the input widths are 5 and 1, but the product widths are
;; different (30 and 5), as are the quotient widths (1.25 and 5).

(Exercise ?2.10
  (use (:2.1.4 mul-interval) (?2.7 lower-bound make-interval upper-bound)))

(define (div-interval x y)
  (let ((y1 (lower-bound y))
        (y2 (upper-bound y)))
    (if (<= y1 0 y2)
        (error 'div-interval "can't divide by an interval spanning zero" y)
        (mul-interval x (make-interval (/ y2) (/ y1))))))

(div-interval (make-interval 1 2) (make-interval 3 4)) => '(1/4 . 2/3)
(div-interval (make-interval 1 2) (make-interval -1 1)) =!> "can't divide"

(Exercise ?2.11
  (use (?2.7 lower-bound make-interval upper-bound)))

(define (mul-interval x y)
  (let ((x1 (lower-bound x))
        (x2 (upper-bound x))
        (y1 (lower-bound y))
        (y2 (upper-bound y)))
    (cond ((> x1 0)
           (cond ((> y1 0) (make-interval (* x1 y1) (* x2 y2)))
                 ((< y2 0) (make-interval (* x2 y1) (* x1 y2)))
                 (else (make-interval (* x2 y1) (* x2 y2)))))
          ((< x2 0)
           (cond ((> y1 0) (make-interval (* x1 y2) (* x2 y1)))
                 ((< y2 0) (make-interval (* x2 y2) (x1 y1)))
                 (else (make-interval (* x1 y2) (* x1 y1)))))
          (else
           (cond ((> y1 0) (make-interval (* x1 y2) (* x2 y2)))
                 ((< y2 0) (make-interval (* x2 y1) (* x1 y1)))
                 (else (make-interval (min (* x1 y2) (x2 y1))
                                      (max (* x1 y1) (x2 y2)))))))))

(mul-interval (make-interval 1 2) (make-interval 3 4)) => '(3 . 8)

(Exercise ?2.12
  (use (:1.1.7 average) (?2.7 lower-bound make-interval upper-bound)))

(define (make-center-width c w)
  (make-interval (- c w) (+ c w)))
(define (center x)
  (average (lower-bound x) (upper-bound x)))
(define (width x)
  (/ (- (upper-bound x) (lower-bound x)) 2))

(define (make-center-percent c p)
  (make-center-width c (* c (/ p 100))))
(define (percent x)
  (* 100 (/ (width x) (center x))))

(define x (make-interval 9 11))
(width x) => 1
(center x) => 10
(percent x) => 10

(Exercise ?2.13
  (use (:2.1.4 mul-interval) (?2.12 make-center-percent percent)))

;; Under the assumption of small percentage tolerances, there is a simple
;; formula for the approximate percent tolerance of the product of two intervals
;; in terms of the tolerances of the factors: their sum. Consider two intervals
;; $i$ and $j$, represented both in lower-upper bound form and in
;; center-tolerance form:
;;
;; $$
;; \begin{aligned}
;; i &= [a_i,b_i] = [c_i(1-t_i),c_i(1+t_i)], \\
;; j &= [a_j,b_j] = [c_j(1-t_j),c_j(1+t_j)].
;; \end{aligned}
;; $$
;;
;; Assuming all numbers are positive, their product is
;;
;; $$
;; \begin{aligned}
;; ij &= [a_ia_j,b_ib_j] \\
;;    &= [c_ic_j(1-t_i)(1-t_j),c_ic_j(1+t_i)(1+t_j)] \\
;;    &= [c_ic_j(1-t_i-t_j+t_it_j),c_ic_j(1+t_i+t_j+t_it_j)].
;; \end{aligned}
;; $$
;;
;; Since $t_i$ and $t_j$ are small, their product $t_it_j$ is negligible, so we
;; can approximate:
;;
;; $$ij \approx [c_ic_j(1-(t_i+t_j)),c_ic_j(1+(t_i+t_j))]$$
;;
;; A simple test bears out this approximation:

(define i (make-center-percent 30 1))
(define j (make-center-percent 25 3))
(define i*j (mul-interval i j))
(+ (percent i) (percent j)) => 4
(percent i*j) ~> 3.9988003598920323

(Exercise ?2.14
  (use (:2.1.4 add-interval div-interval mul-interval) (?2.7 make-interval)
       (?2.12 center make-center-percent percent)))

(define (par1 r1 r2)
  (div-interval (mul-interval r1 r2)
                (add-interval r1 r2)))

(define (par2 r1 r2)
  (let ((one (make-interval 1 1)))
    (div-interval
     one
     (add-interval (div-interval one r1)
                   (div-interval one r2)))))

;; Lem is right. The resulting uncertainty is different for mathematically
;; equivalent expressions calculated by `par1` and `par2`:

(define r1 (make-center-percent 10000 5))
(define r2 (make-center-percent 330 10))
(percent (par1 r1 r2)) ~> 19.931607019958708
(percent (par2 r1 r2)) ~> 9.841433938087881

;; When we divide an interval by itself, we should get exactly one. Instead, we
;; get an interval whose center is approximately one, with a fair amount of
;; uncertainty.

(define i (make-center-percent 5000 2))
(define j (make-center-percent 2500 1))
(center (div-interval i i)) ~> 1.0008003201280510 ; ideally should be 1
(percent (div-interval i i)) ~> 3.998400639744109 ; ideally should be 0%
(center (div-interval i j)) ~> 2.0006000600060000 ; correct
(percent (div-interval i j)) ~> 2.999400119975999 ; correct

(Exercise ?2.15)

;; Yes, Eva is right. When the expressions are written in such a form that no
;; uncertain variable is repeated, the uncertainty of the result is smaller, and
;; this is the more correct value. When an uncertain variable is repeated, the
;; interval arithmetic procedures have no way of knowing that they are dealing
;; with the same value twice, so they combine uncertainties as if they were
;; separate measurements. For example, If we manipulate an algebraic expression
;; by dividing a value by itself, we introduce error because the interval
;; arithmetic division does not produce exactly one.

(Exercise ?2.16)

;; In general, equivalent expressions may lead to different answers because
;; identical intervals are treated indepedently even if they represent the same
;; measurement. This is called the [dependency problem][dp]. For complicated
;; functions, it is not always possible to eliminate repetitions of an interval
;; in the expression, so there is an unwanted expansion in the resulting
;; intervals. It is impossible to completely avoid this shortcoming. The best we
;; can do is attempt to rewrite expressions so that intervals are not repeated.
;;
;; [dp]: https://en.wikipedia.org/wiki/Interval_arithmetic#Dependency_problem

(Section :2.2 "Hierarchical Data and the Closure Property")

(Section :2.2.1 "Representing Sequences")

(define one-through-four (list 1 2 3 4))

one-through-four => '(1 2 3 4)
(car one-through-four) => 1
(cdr one-through-four) => '(2 3 4)
(car (cdr one-through-four)) => 2
(cons 10 one-through-four) => '(10 1 2 3 4)
(cons 5 one-through-four) => '(5 1 2 3 4)

(Section :2.2.1.1 "List operations")

;; Iterative `list-ref`:

(define (list-ref items n)
  (if (= n 0)
      (car items)
      (list-ref (cdr items) (- n 1))))

(define squares (list 1 4 9 16 25))
(list-ref squares 3) => 16

;; Recursive `length`:

(define (length items)
  (if (null? items)
      0
      (+ 1 (length (cdr items)))))

(define odds (list 1 3 5 7))
(length odds) => 4

;; Iterative `length`:

(define (length items)
  (define (iter a count)
    (if (null? a)
        count
        (iter (cdr a) (+ 1 count))))
  (iter items 0))

(length odds) => 4

;; Recursive `append`:

(define (append list1 list2)
  (if (null? list1)
      list2
      (cons (car list1)
            (append (cdr list1) list2))))

(append squares odds) => '(1 4 9 16 25 1 3 5 7)
(append odds squares) => '(1 3 5 7 1 4 9 16 25)

(Exercise ?2.17)

(define (last-pair xs)
  (if (null? (cdr xs))
      xs
      (last-pair (cdr xs))))

(last-pair (list 23 72 149 34)) => '(34)

(Exercise ?2.18)

(define (reverse xs)
  (define (iter xs ys)
    (if (null? xs)
        ys
        (iter (cdr xs)
              (cons (car xs) ys))))
  (iter xs '()))

(reverse (list 1 4 9 16 25)) => '(25 16 9 4 1)

(Exercise ?2.19)

;; Generalizing `count-change` from [](:1.2.2.1) to work with any currency:

(define us-coins (list 50 25 10 5 1))
(define uk-coins (list 100 50 20 10 5 2 1 1/2))

(define (cc amount coins)
  (cond ((= amount 0) 1)
        ((< amount 0) 0)
        ((no-more? coins) 0)
        (else
         (+ (cc amount
                (except-first-denom coins))
            (cc (- amount (first-denom coins))
                coins)))))

(define first-denom car)
(define except-first-denom cdr)
(define no-more? null?)

(cc 20 uk-coins) => 293

;; The order of the coin list does not affect the answer produced by `cc`:

(cc 100 us-coins) => 292
(cc 100 (reverse us-coins)) => 292
(cc 100 (list 5 50 1 25 10)) => 292

;; The tree recursion will explore every possible combination. It makes no
;; difference if you start with combinations that prefer fewer, larger coins, or
;; with the combination that only uses pennies, or anything in between.

(Exercise ?2.20)

(define (same-parity . xs)
  (define (helper pred xs)
    (cond ((null? xs) xs)
          ((pred (car xs))
           (cons (car xs)
                 (helper pred (cdr xs))))
          (else (helper pred (cdr xs)))))
  (cond ((null? xs) xs)
        ((even? (car xs)) (helper even? xs))
        (else (helper odd? xs))))

(same-parity 1 2 3 4 5 6 7) => '(1 3 5 7)
(same-parity 2 3 4 5 6 7) => '(2 4 6)

(Section :2.2.1.2 "Mapping over lists")

(define (scale-list items factor)
  (if (null? items)
      '()
      (cons (* (car items) factor)
            (scale-list (cdr items) factor))))
(scale-list (list 1 2 3 4 5) 10) => '(10 20 30 40 50)

(define (map proc items)
  (if (null? items)
      '()
      (cons (proc (car items))
            (map proc (cdr items)))))

(define (scale-list items factor)
  (map (lambda (x) (* x factor)) items))
(scale-list (list 1 2 3 4 5) 10) => '(10 20 30 40 50)

(Exercise ?2.21
  (use (:1.1.4 square)))

(define (square-list xs)
  (if (null? xs)
      '()
      (cons (square (car xs))
            (square-list (cdr xs)))))
(square-list (list 1 2 3 4)) => '(1 4 9 16)

(define (square-list xs) (map square xs))
(square-list (list 1 2 3 4)) => '(1 4 9 16)

(Exercise ?2.22
  (use (:1.1.4 square)))

(define (square-list items)
  (define (iter things answer)
    (if (null? things)
        answer
        (iter (cdr things)
              (cons (square (car things))
                    answer))))
  (iter items '()))

(square-list (list 1 2 3 4)) => '(16 9 4 1)

;; Louis's procedure reverses the order of the list because of the way he builds
;; the result. His first iteration creates a pair whose `car` is `(square (car
;; things))` and whose `cdr` is the empty list, and further recursions prepend
;; to this list. So the last item of the result is the first item of the
;; original list, and vice versa.

(define (square-list items)
  (define (iter things answer)
    (if (null? things)
        answer
        (iter (cdr things)
              (cons answer
                    (square (car things))))))
  (iter items '()))

(square-list (list 1 2 3 4 5)) => '(((((() . 1) . 4) . 9) . 16) . 25)

;; Interchanging the arguments to `cons` doesn't work because now each `cdr` is
;; a number, not a pair. The result is not a proper list, so Scheme prints it in
;; explicit `(car . cdr)` notation. It is essentially the same reversed list as
;; before, just the roles of `car` and `cdr` have been swapped.

(Exercise ?2.23)

(define (for-each f xs)
  (unless (null? xs)
    (f (car xs))
    (for-each f (cdr xs))))

(for-each
 (lambda (x)
   (newline)
   (display x))
 (list 57 321 88))
=$> ["57" "321" "88"]

(Section :2.2.2 "Hierarchical Structures")

(define (count-leaves x)
  (cond ((null? x) 0)
        ((not (pair? x)) 1)
        (else (+ (count-leaves (car x))
                 (count-leaves (cdr x))))))

(define x (cons (list 1 2) (list 3 4)))
(length x) => 3
(count-leaves x) => 4

(list x x) => '(((1 2) 3 4) ((1 2) 3 4))
(length (list x x)) => 2
(count-leaves (list x x)) => 8

(Exercise ?2.24)

(list 1 (list 2 (list 3 4))) => '(1 (2 (3 4)))

;; Box-and-pointer structure:
;;
;; ```diagram
;;      .---+---.    .---+--+.
;; ---->| * | *-+--->| * | / +
;;      '-|-+---'    '-|-++--'
;;        |            |
;;        v            v
;;      .---.      .---+---.    .---+--+.
;;      | 1 |      | * | *-+--->| * | / |
;;      '---'      '-|-+---'    '-|-++--'
;;                   |            |
;;                   v            v
;;                 .---.      .---+---.    .---+--+.
;;                 | 2 |      | * | *-+--->| * | / |
;;                 '---'      '-|-+---'    '-|-++--'
;;                              |            |
;;                              v            v
;;                            .---.        .---.
;;                            | 3 |        | 4 |
;;                            '---'        '---'
;; ```
;;
;; Tree interpretation:
;;
;; ```diagram
;;  "(1 (2 (3 4)))"
;;        +
;;       / \
;;      /   \ "(2 (3 4))"
;;           +
;;     1    / \
;;         /   \ "(3 4)"
;;              +
;;        2    / \
;;            /   \
;;
;;           3     4
;; ```

(Exercise ?2.25)

(car (cdr (car (cdr (cdr '(1 3 (5 7) 9))))))
=> 7

(car (car '((7))))
=> 7

(car (cdr (car (cdr (car (cdr (car (cdr (car (cdr (car (cdr
  '(1 (2 (3 (4 (5 (6 7)))))))))))))))))) ; NOALIGN
=> 7

(Exercise ?2.26)

(define x (list 1 2 3))
(define y (list 4 5 6))

(append x y) => '(1 2 3 4 5 6)
(cons x y) => '((1 2 3) 4 5 6)
(list x y) => '((1 2 3) (4 5 6))

(Exercise ?2.27)

(define (deep-reverse x)
  (if (pair? x)
      (map deep-reverse (reverse x))
      x))

(define x '((1 2) (3 4)))
(reverse x) => '((3 4) (1 2))
(deep-reverse x) => '((4 3) (2 1))

(Exercise ?2.28)

(define (fringe t)
  (cond ((null? t) t)
        ((pair? (car t))
         (append (fringe (car t))
                 (fringe (cdr t))))
        (else (cons (car t)
                    (fringe (cdr t))))))

(define x '((1 2) (3 4)))
(fringe x) => '(1 2 3 4)
(fringe (list x x)) => '(1 2 3 4 1 2 3 4)
(fringe '((((5) 2) ((3 2) 9)))) => '(5 2 3 2 9)

(Exercise ?2.29)

(define (make-mobile left right) (list left right))
(define (make-branch length structure) (list length structure))

;; (a) Selectors:

(define left-branch car)
(define right-branch cadr)
(define branch-length car)
(define branch-structure cadr)

;; (b) Total weight:

(define (mobile-weight mobile)
  (+ (branch-weight (left-branch mobile))
     (branch-weight (right-branch mobile))))

(define (branch-weight branch)
  (let ((struct (branch-structure branch)))
    (if (number? struct)
        struct
        (mobile-weight struct))))

;; (c) Balance:

(define (torque branch)
  (* (branch-length branch)
     (branch-weight branch)))

(define (mobile-balanced? mobile)
  (and (= (torque (left-branch mobile))
          (torque (right-branch mobile)))
       (branch-balanced? (left-branch mobile))
       (branch-balanced? (right-branch mobile))))

(define (branch-balanced? branch)
  (let ((struct (branch-structure branch)))
    (or (number? struct)
        (mobile-balanced? struct))))

;; (d) If `make-mobile` and `make-branch` use `cons` instead of `list`, all we
;;     need to do is change the `right-branch` and `branch-structure` selectors:

(define make-mobile cons)
(define make-branch cons)

(define right-branch cdr)
(define branch-structure cdr)

(Section :2.2.2.1 "Mapping over trees")

(define (scale-tree tree factor)
  (cond ((null? tree) '())
        ((not (pair? tree)) (* tree factor))
        (else (cons (scale-tree (car tree) factor)
                    (scale-tree (cdr tree) factor)))))

(scale-tree '(1 (2 (3 4) 5) (6 7)) 10) => '(10 (20 (30 40) 50) (60 70))

(define (scale-tree tree factor)
  (map (lambda (sub-tree)
         (if (pair? sub-tree)
             (scale-tree sub-tree factor)
             (* sub-tree factor)))
       tree))

(scale-tree '(1 (2 (3 4) 5) (6 7)) 10) => '(10 (20 (30 40) 50) (60 70))

(Exercise ?2.30
  (use (:1.1.4 square)))

(define tree '(1 (2 (3 4) 5) (6 7)))
(define squared-tree '(1 (4 (9 16) 25) (36 49)))

;; Direct recursion:

(define (square-tree t)
  (cond ((null? t) '())
        ((not (pair? t)) (square t))
        (else (cons (square-tree (car t))
                    (square-tree (cdr t))))))

(square-tree tree) => squared-tree

;; Using `map`:

(define (square-tree t)
  (map (lambda (t)
         (if (pair? t)
             (square-tree t)
             (square t)))
       t))

(square-tree tree) => squared-tree

(Exercise ?2.31
  (use (:1.1.4 square) (?2.30 squared-tree tree)))

;; Direct recursion:

(define (tree-map f t)
  (cond ((null? t) '())
        ((not (pair? t)) (f t))
        (else (cons (tree-map f (car t))
                    (tree-map f (cdr t))))))

(define (square-tree tree) (tree-map square tree))
(square-tree tree) => squared-tree

;; Using `map`:

(define (tree-map f t)
  (map (lambda (t)
         (if (pair? t)
             (tree-map f t)
             (f t)))
       t))

(define (square-tree tree) (tree-map square tree))
(square-tree tree) => squared-tree

(Exercise ?2.32)

;; The set of all subsets, or powerset, is defined recursively for finite sets:
;;
;; - For the empty set, $\powerset{\varnothing}=\{\varnothing\}$.
;; - Given a set $S$ and any $x$, $\powerset{S\cup\{x\}} = \powerset{S}
;;   \cup \{R\cup\{x\} \mid R\in\powerset{S}\}$.
;;
;; This leads to the following implementation:

(define (subsets s)
  (if (null? s)
      (list '())
      (let ((first-item (car s))
            (subsets-rest (subsets (cdr s))))
        (append subsets-rest
                (map (lambda (set) (cons first-item set))
                     subsets-rest)))))

(subsets '()) => '(())
(subsets '(1)) => '(() (1))
(subsets '(1 2)) => '(() (2) (1) (1 2))
(subsets '(1 2 3)) => '(() (3) (2) (2 3) (1) (1 3) (1 2) (1 2 3))

(Section :2.2.3 "Sequences as Conventional Interfaces"
  (use (:1.1.4 square) (?1.19 fib)))

(define (sum-odd-squares tree)
  (cond ((null? tree) 0)
        ((not (pair? tree))
         (if (odd? tree) (square tree) 0))
        (else (+ (sum-odd-squares (car tree))
                 (sum-odd-squares (cdr tree))))))

(sum-odd-squares '((1 2 3) (4 (5 6)))) => 35

(define (even-fibs n)
  (define (next k)
    (if (> k n)
        '()
        (let ((f (fib k)))
          (if (even? f)
              (cons f (next (+ k 1)))
              (next (+ k 1))))))
  (next 0))

(even-fibs 10) => '(0 2 8 34)

(Section :2.2.3.1 "Sequence operations"
  (use (:1.1.4 square) (?1.19 fib)))

(map square (list 1 2 3 4 5)) => '(1 4 9 16 25)

(define (filter pred xs)
  (cond ((null? xs) '())
        ((pred (car xs))
         (cons (car xs) (filter pred (cdr xs))))
        (else (filter pred (cdr xs)))))

(filter odd? (list 1 2 3 4 5)) => '(1 3 5)

(define (accumulate op initial xs)
  (if (null? xs)
      initial
      (op (car xs)
          (accumulate op initial (cdr xs)))))

(accumulate + 0 (list 1 2 3 4 5)) => 15
(accumulate * 1 (list 1 2 3 4 5)) => 120
(accumulate cons '() (list 1 2 3 4 5)) => '(1 2 3 4 5)

(define (enumerate-interval low high)
  (if (> low high)
      '()
      (cons low (enumerate-interval (+ low 1) high))))

(enumerate-interval 2 7) => '(2 3 4 5 6 7)

(define (enumerate-tree tree)
  (cond ((null? tree) '())
        ((not (pair? tree)) (list tree))
        (else (append (enumerate-tree (car tree))
                      (enumerate-tree (cdr tree))))))

(enumerate-tree (list 1 (list 2 (list 3 4)) 5)) => '(1 2 3 4 5)

(define (sum-odd-squares tree)
  (accumulate + 0 (map square (filter odd? (enumerate-tree tree)))))

(sum-odd-squares '((1 2 3) (4 (5 6)))) => 35

(define (even-fibs n)
  (accumulate cons '() (filter even? (map fib (enumerate-interval 0 n)))))

(even-fibs 10) => '(0 2 8 34)

(define (list-fib-squares n)
  (accumulate cons '() (map square (map fib (enumerate-interval 0 n)))))

(list-fib-squares 10) => '(0 1 1 4 9 25 64 169 441 1156 3025)

(define (product-of-squares-of-odd-elements sequence)
  (accumulate * 1 (map square (filter odd? sequence))))

(product-of-squares-of-odd-elements (list 1 2 3 4 5)) => 225

(Exercise ?2.33
  (use (:2.2.3.1 accumulate)))

(define (map f xs)
  (accumulate (lambda (x y) (cons (f x) y)) '() xs))
(define (append xs ys)
  (accumulate cons ys xs))
(define (length xs)
  (accumulate (lambda (x n) (+ n 1)) 0 xs))

(Exercise ?2.34
  (use (:2.2.3.1 accumulate)))

(define (horner-eval x coefs)
  (accumulate (lambda (coef higher-terms)
                (+ (* higher-terms x) coef))
              0
              coefs))

(define x 2)
(horner-eval x '(1 3 0 5 0 1))
=> (+ 1 (* 3 x) (* 5 (expt x 3)) (expt x 5))
=> 79

(Exercise ?2.35
  (use (:2.2.3.1 accumulate enumerate-tree)))

(define (count-leaves t)
  (accumulate + 0 (map (lambda (x) 1)
                       (enumerate-tree t))))

(count-leaves '(1 2 (3 (4) 5) (6 7))) => 7

(Exercise ?2.36
  (use (:2.2.3.1 accumulate)))

(define (accumulate-n op init seqs)
  (if (null? (car seqs))
      '()
      (cons (accumulate op init (map car seqs))
            (accumulate-n op init (map cdr seqs)))))

(accumulate-n + 0 '((1 2 3) (4 5 6) (7 8 9) (10 11 12))) => '(22 26 30)

(Exercise ?2.37
  (use (:2.2.3.1 accumulate) (?2.36 accumulate-n)))

(define (dot-product v w)
  (accumulate + 0 (map * v w)))

(define (matrix-*-vector m v)
  (map (lambda (u) (dot-product u v)) m))

(define (transpose mat)
  (accumulate-n cons '() mat))

(define (matrix-*-matrix m n)
  (let ((cols (transpose n)))
    (map (lambda (r)
           (map (lambda (c)
                  (dot-product r c))
                cols))
         m)))

(define mat '((1 2 3) (4 5 6) (7 8 9)))
(define identity '((1 0 0) (0 1 0) (0 0 1)))
(matrix-*-vector mat (car identity)) => (map car mat)
(matrix-*-matrix mat identity) => mat
(matrix-*-matrix identity mat) => mat

(Exercise ?2.38
  (use (:2.2.3.1 accumulate)))

(define fold-right accumulate)

(define (fold-left op init xs)
  (define (iter result rest)
    (if (null? rest)
        result
        (iter (op result (car rest))
              (cdr rest))))
  (iter init xs))

(fold-right / 1 (list 1 2 3)) => 3/2
(fold-left / 1 (list 1 2 3)) => 1/6
(fold-right list '() (list 1 2 3)) => '(1 (2 (3 ())))
(fold-left list '() (list 1 2 3)) => '(((() 1) 2) 3)

;; For `fold-left` and `fold-right` to produce the same value on any sequence,
;; `op` must satisfy the commutative property `(= (op x y) (op y x))`.

(Exercise ?2.39
  (use (?2.38 fold-left fold-right)))

(define (reverse xs)
  (fold-right (lambda (x y) (append y (list x))) '() xs))

(reverse (list 1 2 3 4 5)) => '(5 4 3 2 1)

(define (reverse xs)
  (fold-left (lambda (x y) (cons y x)) '() xs))

(reverse (list 1 2 3 4 5)) => '(5 4 3 2 1)

(Section :2.2.3.2 "Nested mappings"
  (use (:2.2.3.1 accumulate enumerate-interval filter) (?1.23 prime?)))

(define (flatmap proc seq)
  (accumulate append '() (map proc seq)))

(define (prime-sum? pair)
  (prime? (+ (car pair) (cadr pair))))

(define (make-pair-sum pair)
  (list (car pair) (cadr pair) (+ (car pair) (cadr pair))))

(define (prime-sum-pairs n)
  (map make-pair-sum
       (filter prime-sum?
               (flatmap (lambda (i)
                          (map (lambda (j) (list i j))
                               (enumerate-interval 1 (- i 1))))
                        (enumerate-interval 1 n)))))

(prime-sum-pairs 5) => '((2 1 3) (3 2 5) (4 1 5) (4 3 7) (5 2 7))

(define (permutations s)
  (if (null? s)
      (list '())
      (flatmap (lambda (x)
                 (map (lambda (p) (cons x p))
                      (permutations (remove x s))))
               s)))

(define (remove item sequence)
  (filter (lambda (x) (not (equal? x item))) sequence))

(permutations '(a b c)) => '((a b c) (a c b) (b a c) (b c a) (c a b) (c b a))

(Exercise ?2.40
  (use (:2.2.3.1 enumerate-interval filter)
       (:2.2.3.2 flatmap make-pair-sum prime-sum?)))

(define (unique-pairs n)
  (flatmap (lambda (i)
             (map (lambda (j) (list i j))
                  (enumerate-interval 1 (- i 1))))
           (enumerate-interval 1 n)))

(define (prime-sum-pairs n)
  (map make-pair-sum (filter prime-sum? (unique-pairs n))))

(prime-sum-pairs 5) => '((2 1 3) (3 2 5) (4 1 5) (4 3 7) (5 2 7))

(Exercise ?2.41
  (use (:2.2.3.1 enumerate-interval filter) (:2.2.3.2 flatmap)))

(define (unique-triples n)
  (flatmap (lambda (i)
             (flatmap (lambda (j)
                        (map (lambda (k) (list i j k))
                             (enumerate-interval 1 (- j 1))))
                      (enumerate-interval 1 (- i 1))))
           (enumerate-interval 1 n)))

(define (triple-sums n s)
  (filter (lambda (t)
            (= s (+ (car t) (cadr t) (caddr t))))
          (unique-triples n)))

(triple-sums 8 10) => '((5 3 2) (5 4 1) (6 3 1) (7 2 1))

(Exercise ?2.42
  (use (:2.2.3.1 enumerate-interval filter) (:2.2.3.2 flatmap)))

(define make-position list)
(define get-row car)
(define get-col cadr)

(define empty-board '())
(define (adjoin-position row col board)
  (cons (make-position row col) board))

(define (safe? positions)
  (let ((row1 (get-row (car positions))))
    (define (helper rest-of-queens cols-apart)
      (or (null? rest-of-queens)
          (let ((row2 (get-row (car rest-of-queens))))
            (and (not (= row1 row2))
                 (not (= row1 (- row2 cols-apart)))
                 (not (= row1 (+ row2 cols-apart)))
                 (helper (cdr rest-of-queens) (+ cols-apart 1))))))
    (helper (cdr positions) 1)))

;; I've moved `queen-cols` to the top level so that [](?2.43) can access it.
(define (queen-cols k board-size)
  (if (= k 0)
      (list empty-board)
      (filter safe?
              (flatmap
               (lambda (rest-of-queens)
                 (map (lambda (new-row)
                        (adjoin-position new-row k rest-of-queens))
                      (enumerate-interval 1 board-size)))
               (queen-cols (- k 1) board-size)))))

(define (queens board-size)
  (queen-cols board-size board-size))

(queens 0) => '(())
(queens 1) => '(((1 1)))

;; The number of solution for each board size matches [OEIS sequence
;; A000170](https://oeis.org/A000170):

(map (lambda (n) (length (queens n))) (enumerate-interval 0 8))
=> '(1 1 0 0 2 10 4 40 92)

;; Here is the first solution (out of 92) it gives for the eight-queens puzzle:

(car (queens 8)) => '((4 8) (2 7) (7 6) (3 5) (6 4) (8 3) (5 2) (1 1))

;; Plotting it on a chess board, we can see that no queen is under attack:
;;
;; ```diagram
;;     1   2   3   4   5   6   7   8
;;   +---+---+---+---+---+---+---+---+
;; 1 | Q |   |   |   |   |   |   |   |
;;   +---+---+---+---+---+---+---+---+
;; 2 |   |   |   |   |   |   | Q |   |
;;   +---+---+---+---+---+---+---+---+
;; 3 |   |   |   |   | Q |   |   |   |
;;   +---+---+---+---+---+---+---+---+
;; 4 |   |   |   |   |   |   |   | Q |
;;   +---+---+---+---+---+---+---+---+
;; 5 |   | Q |   |   |   |   |   |   |
;;   +---+---+---+---+---+---+---+---+
;; 6 |   |   |   | Q |   |   |   |   |
;;   +---+---+---+---+---+---+---+---+
;; 7 |   |   |   |   |   | Q |   |   |
;;   +---+---+---+---+---+---+---+---+
;; 8 |   |   | Q |   |   |   |   |   |
;;   +---+---+---+---+---+---+---+---+
;; ```

(Exercise ?2.43
  (use (?2.42 queen-cols)))

;; Interchanging the nested mappings slows down the program because the
;; `queen-cols` recursion gets re-evaluated for every `enumerate-interval`
;; result. If the recursive call was bound outside the mappings using `let`,
;; then either nesting would be fine.
;;
;; To quantify how much slower it is, we will analyze both solutions. Let $T_k$
;; and $T'_k$ be the number of operations performed by `(queen-cols k 8)` using
;; the original program and Louis's program, respectively, and let $N_k$ be the
;; number of results it returns. In the base case, $T_0=T'_0=C_0$ for some
;; constant $C_0$. For $k≥1$, we have $T_k=T_{k-1}+W_k$ where $T_{k-1}$ is due
;; to the recursive call and $W_k$ represents the other work done by
;; `queen-cols`. Since Louis's program repeats the recursive call, it takes
;; $T'_k=8T'_{k-1}+W_k$ operations. $W_k$ includes $C_1$ constant work; $C_2$
;; for each of the $8N_{k-1}$ candidate boards it maps and filters; and $C_3$ in
;; `safe?` for each of the $k$ positions in all the boards. Put together, we
;; have
;;
;; $$W_k = C_1 + (C_2 + C_3k)8N_{k-1}.$$
;;
;; Let's implement these equations in Scheme:

(define C0) (define C1) (define C2) (define C3)

(define (T k) (if (= k 0) C0 (+ (T (- k 1)) (W k))))
(define (T-louis k) (if (= k 0) C0 (+ (* 8 (T-louis (- k 1))) (W k))))

(define (W k) (+ C1 (* (+ C2 (* C3 k)) 8 (N (- k 1)))))
(define (N k) (length (queen-cols k 8)))

;; To estimate how much slower Louis's program is, all we have to do is choose
;; reasonable values for the constants and then divide $T'_8$ by $T_8$:

(define (louis-slowdown v0 v1 v2 v3)
  (set! C0 v0) (set! C1 v1) (set! C2 v2) (set! C3 v3)
  (inexact (/ (T-louis 8) (T 8))))

(louis-slowdown 1 1 01 01) ~> 1598.2301736709533
(louis-slowdown 1 3 10 15) ~> 1355.8443654944654
(louis-slowdown 0 5 10 05) ~> 1667.9916268313882

;; Louis's program is slower than the original by three orders of magnitude.

(Section :2.2.4 "Example: A Picture Language")

(Section :2.2.4.1 "The picture language"
  (use (:2.2.4.5 beside flip-vert) (?2.44 up-split) (?2.49 wave)
       (?2.50 flip-horiz) (?2.51 below)))

(define wave2 (beside wave (flip-vert wave)))
(define wave4 (below wave2 wave2))

(define (flipped-pairs painter)
  (let ((painter2 (beside painter (flip-vert painter))))
    (below painter2 painter2)))

(define (right-split painter n)
  (if (= n 0)
      painter
      (let ((smaller (right-split painter (- n 1))))
        (beside painter (below smaller smaller)))))

(define (corner-split painter n)
  (if (= n 0)
      painter
      (let ((up (up-split painter (- n 1)))
            (right (right-split painter (- n 1))))
        (let ((top-left (beside up up))
              (bottom-right (below right right))
              (corner (corner-split painter (- n 1))))
          (beside (below painter top-left)
                  (below bottom-right corner))))))

(define (square-limit painter n)
  (let ((quarter (corner-split painter n)))
    (let ((half (beside (flip-horiz quarter) quarter)))
      (below (flip-vert half) half))))

(Exercise ?2.44
  (use (:2.2.4.5 beside) (?2.51 below)))

(define (up-split painter n)
  (if (= n 0)
      painter
      (let ((smaller (up-split painter (- n 1))))
        (below painter (beside smaller smaller)))))

(Section :2.2.4.2 "Higher-order operations"
  (use (:2.2.4.1 corner-split) (:2.2.4.5 beside flip-vert identity)
       (?2.50 flip-horiz rotate180) (?2.51 below)))

(define (square-of-four tl tr bl br)
  (lambda (painter)
    (let ((top (beside (tl painter) (tr painter)))
          (bottom (beside (bl painter)
                          br painter)))
      (below bottom top))))

(define (flipped-pairs painter)
  (let ((combine4 (square-of-four identity flip-vert
                                  identity flip-vert)))
    (combine4 painter)))

(define (square-limit painter n)
  (let ((combine4 (square-of-four flip-horiz identity
                                  rotate180 flip-vert)))
    (combine4 (corner-split painter n))))

(Exercise ?2.45
  (use (:2.2.4.5 beside) (?2.51 below)))

(define (split comb split-comb)
  (define (splitter painter n)
    (if (= n 0)
        painter
        (let ((smaller (splitter painter (- n 1))))
          (comb painter (split-comb smaller smaller)))))
  splitter)

(define right-split (split beside below))
(define up-split (split below beside))

(Section :2.2.4.3 "Frames"
  (use (?2.46 add-vect scale-vect xcor-vect ycor-vect)
       (?2.47 edge1-frame edge2-frame origin-frame)))

(define (frame-coord-map frame)
  (lambda (v)
    (add-vect
     (origin-frame frame)
     (add-vect (scale-vect (xcor-vect v) (edge1-frame frame))
               (scale-vect (ycor-vect v) (edge2-frame frame))))))

(Exercise ?2.46)

(define make-vect cons)
(define xcor-vect car)
(define ycor-vect cdr)

(define (add-vect u v)
  (make-vect (+ (xcor-vect u) (xcor-vect v))
             (+ (ycor-vect u) (ycor-vect v))))
(define (sub-vect u v)
  (make-vect (- (xcor-vect u) (xcor-vect v))
             (- (ycor-vect u) (ycor-vect v))))
(define (scale-vect s v)
  (make-vect (* s (xcor-vect v))
             (* s (ycor-vect v))))

(add-vect (make-vect 1 2) (make-vect 3 4)) => (make-vect 4 6)
(sub-vect (make-vect 1 2) (make-vect 3 4)) => (make-vect -2 -2)
(scale-vect 2 (make-vect 1 2)) => (make-vect 2 4)

(Exercise ?2.47)

;; First representation:

(define (make-frame origin edge1 edge2)
  (list origin edge1 edge2))

(define origin-frame car)
(define edge1-frame cadr)
(define edge2-frame caddr)

;; Second representation:

(define (make-frame origin edge1 edge2)
  (cons origin (cons edge1 edge2)))

(define origin-frame car)
(define edge1-frame cadr)
(define edge2-frame cddr)

(Section :2.2.4.4 "Painters"
  (use (:2.2.4.3 frame-coord-map) (?2.48 end-segment start-segment)))

(define (draw-line p1 p2)
  (display (format "Line from ~s to ~s\n" p1 p2)))

(define (segments->painter segment-list)
  (lambda (frame)
    (for-each
     (lambda (segment)
       (draw-line ((frame-coord-map frame)
                   (start-segment segment))
                  ((frame-coord-map frame)
                   (end-segment segment))))
     segment-list)))

(Exercise ?2.48)

(define make-segment cons)
(define start-segment car)
(define end-segment cdr)

(Exercise ?2.49
  (use (:2.2.4.4 segments->painter) (?2.46 make-vect) (?2.48 make-segment)))

;; (a) The painter that draws the outline of the designated frame:
(define outline
  (segments->painter
   (list (make-segment (make-vect 0 0) (make-vect 1 0))
         (make-segment (make-vect 0 1) (make-vect 1 1))
         (make-segment (make-vect 0 0) (make-vect 0 1))
         (make-segment (make-vect 1 0) (make-vect 1 1)))))

;; (b) The painter that draws an "X" by connecting opposite corners of the
;;     frame:
(define x
  (segments->painter
   (list (make-segment (make-vect 0 0) (make-vect 1 1))
         (make-segment (make-vect 0 1) (make-vect 1 0)))))

;; (c) The painter that draws a diamond shape by connecting the midpoints of the
;;     sides of the frame:
(define diamond
  (segments->painter
   (list (make-segment (make-vect 0.5 0.0) (make-vect 1.0 0.5))
         (make-segment (make-vect 0.0 0.5) (make-vect 0.5 1.0))
         (make-segment (make-vect 0.0 0.5) (make-vect 0.5 0.0))
         (make-segment (make-vect 0.5 1.0) (make-vect 1.0 0.5)))))

;; (d) The `wave` painter:
(define wave-segments
  (list (make-segment (make-vect 0.46 0.00) (make-vect 0.37 0.22))
        (make-segment (make-vect 0.37 0.22) (make-vect 0.46 0.34))
        (make-segment (make-vect 0.46 0.34) (make-vect 0.37 0.33))
        (make-segment (make-vect 0.37 0.33) (make-vect 0.22 0.45))
        (make-segment (make-vect 0.22 0.45) (make-vect 0.00 0.28))
        (make-segment (make-vect 0.00 0.33) (make-vect 0.22 0.55))
        (make-segment (make-vect 0.22 0.55) (make-vect 0.39 0.42))
        (make-segment (make-vect 0.39 0.42) (make-vect 0.31 1.00))
        (make-segment (make-vect 0.54 0.00) (make-vect 0.63 0.22))
        (make-segment (make-vect 0.63 0.22) (make-vect 0.54 0.34))
        (make-segment (make-vect 0.54 0.34) (make-vect 0.63 0.33))
        (make-segment (make-vect 0.63 0.33) (make-vect 1.00 0.67))
        (make-segment (make-vect 1.00 0.72) (make-vect 0.61 0.42))
        (make-segment (make-vect 0.61 0.42) (make-vect 0.69 1.00))
        (make-segment (make-vect 0.39 1.00) (make-vect 0.50 0.68))
        (make-segment (make-vect 0.50 0.68) (make-vect 0.61 1.00))))
(define wave
  (segments->painter wave-segments))

(Section :2.2.4.5 "Transforming and combining painters"
  (use (:2.2.4.3 frame-coord-map) (?2.46 make-vect sub-vect)
       (?2.47 make-frame)))

(define (transform-painter painter origin corner1 corner2)
  (lambda (frame)
    (let ((m (frame-coord-map frame)))
      (let ((new-origin (m origin)))
        (painter (make-frame new-origin
                             (sub-vect (m corner1) new-origin)
                             (sub-vect (m corner2) new-origin)))))))

(define (identity painter) painter)

(define (flip-vert painter)
  (transform-painter
   painter
   (make-vect 0 1)
   (make-vect 1 1)
   (make-vect 0 0)))

(define (shrink-to-upper-right painter)
  (transform-painter
   painter
   (make-vect 0.5 0.5)
   (make-vect 1 0.5)
   (make-vect 0.5 1)))

(define (rotate90 painter)
  (transform-painter
   painter
   (make-vect 1 0)
   (make-vect 1 1)
   (make-vect 0 0)))

(define (squash-inwards painter)
  (transform-painter
   painter
   (make-vect 0 0)
   (make-vect 0.65 0.35)
   (make-vect 0.35 0.65)))

(define (beside painter1 painter2)
  (let ((split-point (make-vect 0.5 0)))
    (let ((paint-left
           (transform-painter
            painter1
            (make-vect 0 0)
            split-point
            (make-vect 0 1)))
          (paint-right
           (transform-painter
            painter2
            split-point
            (make-vect 1 0)
            (make-vect 0.5 1))))
      (lambda (frame)
        (paint-left frame)
        (paint-right frame)))))

(Exercise ?2.50
  (use (:2.2.4.5 transform-painter) (?2.46 make-vect)))

(define (flip-horiz painter)
  (transform-painter
   painter
   (make-vect 1 0)
   (make-vect 0 0)
   (make-vect 1 1)))

(define (rotate180 painter)
  (transform-painter
   painter
   (make-vect 1 1)
   (make-vect 0 1)
   (make-vect 1 0)))

(define (rotate270 painter)
  (transform-painter
   painter
   (make-vect 0 1)
   (make-vect 0 0)
   (make-vect 1 1)))

(Exercise ?2.51
  (use (:2.2.4.5 beside rotate90 transform-painter) (?2.46 make-vect)
       (?2.50 rotate270)))

;; Analogous to the `beside` procedure:
(define (below painter1 painter2)
  (let ((split-point (make-vect 0 0.5)))
    (let ((paint-bottom
           (transform-painter
            painter1
            (make-vect 0 0)
            (make-vect 1 0.5)
            split-point))
          (paint-top
           (transform-painter
            painter2
            split-point
            (make-vect 1 0.5)
            (make-vect 0 1))))
      (lambda (frame)
        (paint-bottom frame)
        (paint-top frame)))))

;; In terms of `beside` and rotations:
(define (below painter1 painter2)
  (rotate90
   (beside (rotate270 painter1)
           (rotate270 painter2))))

(Exercise ?2.52
  (use (:2.2.4.1 right-split) (:2.2.4.2 square-of-four)
       (:2.2.4.4 segments->painter) (:2.2.4.5 beside) (?2.44 up-split)
       (?2.46 make-vect) (?2.48 make-segment) (?2.49 wave-segments)
       (?2.50 flip-horiz) (?2.51 below)))

;; (a) I changed `wave` to add a smile:
(define smile-segments
  (list (make-segment (make-vect 0.46 0.13) (make-vect 0.46 0.17))
        (make-segment (make-vect 0.46 0.24) (make-vect 0.50 0.27))
        (make-segment (make-vect 0.54 0.13) (make-vect 0.54 0.17))
        (make-segment (make-vect 0.54 0.24) (make-vect 0.50 0.27))))
(define wave
  (segments->painter (append wave-segments smile-segments)))

;; (b) I changed `corner-split` to use only one copy of the `up-split` and
;;     `right-split` images instead of two:
(define (corner-split painter n)
  (if (= n 0)
      painter
      (let ((up (up-split painter (- n 1)))
            (right (right-split painter (- n 1)))
            (corner (corner-split painter (- n 1))))
        (beside (below painter up)
                (below right corner)))))

;; (c) I changed `square-limit` to orient the corners differently:
(define (square-limit painter n)
  (let ((quarter (corner-split painter n)))
    (let ((flipped (flip-horiz quarter)))
      (square-of-four flipped quarter flipped quarter))))

(Section :2.3 "Symbolic Data")

(Section :2.3.1 "Quotation")

(define a 1)
(define b 2)

(list a b) => '(1 2)
(list 'a 'b) => '(a b)
(list 'a b) => '(a 2)

(car '(a b c)) => 'a
(cdr '(a b c)) => '(b c)

(define (memq item x)
  (cond ((null? x) #f)
        ((eq? item (car x)) x)
        (else (memq item (cdr x)))))

(memq 'apple '(pear banana prune)) => #f
(memq 'apple '(x (apple sauce) y apple pear)) => '(apple pear)

(Exercise ?2.53
  (use (:2.3.1 memq)))

(list 'a 'b 'c) => '(a b c)
(list (list 'george)) => '((george))
(cdr '((x1 x2) (y1 y2))) => '((y1 y2))
(cadr '((x1 x2) (y1 y2))) => '(y1 y2)
(pair? (car '(a short list))) => #f
(memq 'red '((red shoes) (blue socks))) => #f
(memq 'red '(red shoes blue socks)) => '(red shoes blue socks)

(Exercise ?2.54)

(define (equal? list1 list2)
  (cond ((null? list1) (null? list2))
        ((not (pair? list1)) (eq? list1 list2))
        (else (and (pair? list2)
                   (equal? (car list1) (car list2))
                   (equal? (cdr list1) (cdr list2))))))

(equal? '(this is a list) '(this is a list)) => #t
(equal? '(this (is a) list) '(this (is a) list)) => #t
(equal? '(this is a list) '(this (is a) list)) => #f

(Exercise ?2.55)

;; This happens because the Lisp reader expands each `'«exp»` to `(quote «exp»)`
;; before evaluation, so `''abracadabra` evaluates to a list of two symbols:

(car ''abracadabra)
=> (car (quote (quote abracadabra)))
=> (car '(quote abracadabra))
=> 'quote

(Section :2.3.2 "Example: Symbolic Differentiation")

(define (deriv expr var)
  (cond ((number? expr) 0)
        ((variable? expr)
         (if (same-variable? expr var) 1 0))
        ((sum? expr)
         (make-sum (deriv (addend expr) var)
                   (deriv (augend expr) var)))
        ((product? expr)
         (make-sum (make-product (multiplier expr)
                                 (deriv (multiplicand expr) var))
                   (make-product (deriv (multiplier expr) var)
                                 (multiplicand expr))))
        (else (error 'deriv "unknown expr type" expr))))

(define (variable? x) (symbol? x))
(define (same-variable? v1 v2)
  (and (variable? v1) (variable? v2) (eq? v1 v2)))

(define (make-sum a1 a2) (list '+ a1 a2))
(define (make-product m1 m2) (list '* m1 m2))

(define (sum? expr)
  (and (pair? expr) (eq? (car expr) '+)))
(define addend cadr)
(define augend caddr)

(define (product? expr)
  (and (pair? expr) (eq? (car expr) '*)))
(define multiplier cadr)
(define multiplicand caddr)

(deriv '(+ x 3) 'x)
=> '(+ 1 0)
(deriv '(* x y) 'x)
=> '(+ (* x 0) (* 1 y))
(deriv '(* (* x y) (+ x 3)) 'x)
=> '(+ (* (* x y) (+ 1 0))
       (* (+ (* x 0) (* 1 y))
          (+ x 3)))

(define (=number? expr num)
  (and (number? expr) (= expr num)))

(define (make-sum a1 a2)
  (cond ((=number? a1 0) a2)
        ((=number? a2 0) a1)
        ((and (number? a1) (number? a2)) (+ a1 a2))
        (else (list '+ a1 a2))))

(define (make-product m1 m2)
  (cond ((or (=number? m1 0) (=number? m2 0)) 0)
        ((=number? m1 1) m2)
        ((=number? m2 1) m1)
        ((and (number? m1) (number? m2)) (* m1 m2))
        (else (list '* m1 m2))))

(deriv '(+ x 3) 'x) => 1
(deriv '(* x y) 'x) => 'y
(deriv '(* (* x y) (+ x 3)) 'x) => '(+ (* x y) (* y (+ x 3)))

(Exercise ?2.56
  (use (:2.3.2 =number? addend augend make-product make-sum multiplicand
               multiplier product? same-variable? sum? variable?)))

(define (deriv expr var)
  (cond ((number? expr) 0)
        ((variable? expr)
         (if (same-variable? expr var) 1 0))
        ((sum? expr)
         (make-sum (deriv (addend expr) var)
                   (deriv (augend expr) var)))
        ((product? expr)
         (make-sum (make-product (multiplier expr)
                                 (deriv (multiplicand expr) var))
                   (make-product (deriv (multiplier expr) var)
                                 (multiplicand expr))))
        ((exponentiation? expr)
         (make-product
          (exponent expr)
          (make-product (make-exponentiation (base expr) (- (exponent expr) 1))
                        (deriv (base expr) var))))
        (else (error 'deriv "unknown expr type" expr))))

(define (make-exponentiation b e)
  (cond ((=number? e 0) 1)
        ((=number? e 1) b)
        ((=number? b 1) 1)
        (else (list '** b e))))

(define (exponentiation? expr)
  (and (pair? expr) (eq? (car expr) '**)))
(define base cadr)
(define exponent caddr)

(deriv '(* 3 (** x 5)) 'x) => '(* 3 (* 5 (** x 4)))

(Exercise ?2.57
  (use (:2.2.3.1 accumulate)
       (:2.3.2 make-product make-sum product? same-variable? sum? variable?)))

(paste (:2.3.2 deriv))

(define addend cadr)
(define (augend sum)
  (accumulate make-sum 0 (cddr sum)))
(define multiplier cadr)
(define (multiplicand product)
  (accumulate make-product 1 (cddr product)))

(deriv '(* x y (+ x 3)) 'x) => '(+ (* x y) (* y (+ x 3)))

(Exercise ?2.58
  (use (:2.3.1 memq) (:2.3.2 =number? same-variable? variable?)))

(paste (:2.3.2 deriv))

;; (a) Fully parenthesized infix form:

(define (make-sum a1 a2)
  (cond ((=number? a1 0) a2)
        ((=number? a2 0) a1)
        ((and (number? a1) (number? a2)) (+ a1 a2))
        (else (list a1 '+ a2))))

(define (make-product m1 m2)
  (cond ((or (=number? m1 0) (=number? m2 0)) 0)
        ((=number? m1 1) m2)
        ((=number? m2 1) m1)
        ((and (number? m1) (number? m2)) (* m1 m2))
        (else (list m1 '* m2))))

(define (sum? expr)
  (and (pair? expr) (eq? (cadr expr) '+)))
(define addend car)
(define augend caddr)

(define (product? expr)
  (and (pair? expr) (eq? (cadr expr) '*)))
(define multiplier car)
(define multiplicand caddr)

(deriv '(x + (3 * (x + (y + 2)))) 'x) => 4

;; (b) Standard algebraic notation:

(define (has op expr)
  (and (pair? expr) (memq op expr)))

(define (unwrap expr)
  (if (and (pair? expr) (null? (cdr expr)))
      (car expr)
      expr))

(define (before op expr)
  (define (iter expr)
    (if (eq? op (car expr))
        '()
        (cons (car expr) (iter (cdr expr)))))
  (unwrap (iter expr)))

(define (after op expr)
  (unwrap (cdr (memq op expr))))

(define (sum? expr) (has '+ expr))
(define (addend expr) (before '+ expr))
(define (augend expr) (after '+ expr))

(define (product? expr) (and (not (sum? expr)) (has '* expr)))
(define (multiplier expr) (before '* expr))
(define (multiplicand expr) (after '* expr))

(deriv '(x + 3 * (x + y + 2)) 'x) => 4
(deriv '(3 * (x + y * 2) + x + 1) 'x) => 4

(Section :2.3.3 "Example: Representing Sets")

(Section :2.3.3.1 "Sets as unordered lists")

(define (element-of-set? x set)
  (and (not (null? set))
       (or (equal? x (car set))
           (element-of-set? x (cdr set)))))

(define (adjoin-set x set)
  (if (element-of-set? x set)
      set
      (cons x set)))

(define (intersection-set set1 set2)
  (cond ((null? set1) '())
        ((null? set2) '())
        ((element-of-set? (car set1) set2)
         (cons (car set1)
               (intersection-set (cdr set1) set2)))
        (else (intersection-set (cdr set1) set2))))

(adjoin-set 1 '()) => '(1)
(adjoin-set 1 '(1)) => '(1)
(adjoin-set 1 '(2 3)) => '(1 2 3)

(element-of-set? 1 '()) => #f
(element-of-set? 1 '(1)) => #t
(element-of-set? 1 '(3 2 1)) => #t

(intersection-set '() '(1 2)) => '()
(intersection-set '(1) '(1 2)) => '(1)
(intersection-set '(2) '(1 2)) => '(2)
(intersection-set '(2 1) '(1 2)) => '(2 1)

(Exercise ?2.59
  (use (:2.2.3.1 accumulate) (:2.3.3.1 adjoin-set)))

(define (union-set set1 set2)
  (accumulate adjoin-set set2 set1))

(union-set '() '(1 2 3)) => '(1 2 3)
(union-set '(1 2 3) '()) => '(1 2 3)
(union-set '(1 2) '(2 3)) => '(1 2 3)

(Exercise ?2.60)

;; To allow duplicates, we only need to change `adjoin-set` and `union-set`:

(define adjoin-set cons)
(define union-set append)

;; To compare the efficiency of each representation, let $n$ be the number of
;; unique elements in the set, and let $k$ be the duplication factor (so the
;; list contains $kn$ elements in total).
;;
;; Procedure           Non-duplicate  Duplicate
;; ------------------  -------------  ---------
;; `adjoin-set`        $Θ(n)$         $O(1)$
;; `union-set`         $Θ(n^2)$       $O(kn)$
;; `element-of-set?`   $Θ(n)$         $O(kn)$
;; `intersection-set`  $Θ(n^2)$       $O((kn)^2)$
;;
;; Which representation is more efficient depends on $k$. If it's small, meaning
;; inserting a duplicate is rare, then allowing duplicates is more efficient.
;; For general use, it's best to disallow duplicates because $k$ is unbounded
;; and we cannot predict it.

(Section :2.3.3.2 "Sets as ordered lists")

(define (element-of-set? x set)
  (and (not (null? set))
       (<= (car set) x)
       (or (= (car set) x)
           (element-of-set? x (cdr set)))))

(define (intersection-set set1 set2)
  (if (or (null? set1) (null? set2))
      '()
      (let ((x1 (car set1))
            (x2 (car set2)))
        (cond ((= x1 x2) (cons x1 (intersection-set (cdr set1) (cdr set2))))
              ((< x1 x2) (intersection-set (cdr set1) set2))
              (else (intersection-set set1 (cdr set2)))))))

(element-of-set? 2 '()) => #f
(element-of-set? 2 '(2)) => #t
(element-of-set? 2 '(1 2 3)) => #t

(intersection-set '() '(1 2)) => '()
(intersection-set '(1) '(1 2)) => '(1)
(intersection-set '(2) '(1 2)) => '(2)
(intersection-set '(1 2) '(1 2)) => '(1 2)

(Exercise ?2.61)

(define (adjoin-set x set)
  (cond ((null? set) (list x))
        ((= x (car set)) set)
        ((< x (car set)) (cons x set))
        (else (cons (car set) (adjoin-set x (cdr set))))))

(adjoin-set 1 '()) => '(1)
(adjoin-set 1 '(1)) => '(1)
(adjoin-set 2 '(1)) => '(1 2)
(adjoin-set 2 '(1 3)) => '(1 2 3)

(Exercise ?2.62)

(define (union-set set1 set2)
  (cond ((null? set1) set2)
        ((null? set2) set1)
        (else
         (let ((x1 (car set1))
               (x2 (car set2)))
           (cond ((= x1 x2) (cons x1 (union-set (cdr set1) (cdr set2))))
                 ((< x1 x2) (cons x1 (union-set (cdr set1) set2)))
                 (else (cons x2 (union-set set1 (cdr set2)))))))))

(union-set '() '(1 2 3)) => '(1 2 3)
(union-set '(1 2 3) '()) => '(1 2 3)
(union-set '(1 2) '(2 3)) => '(1 2 3)

(Section :2.3.3.3 "Sets as binary trees")

(define make-tree list)
(define entry car)
(define left-branch cadr)
(define right-branch caddr)

(define (element-of-set? x set)
  (and (not (null? set))
       (or (= x (entry set))
           (and (< x (entry set))
                (element-of-set? x (left-branch set)))
           (and (> x (entry set))
                (element-of-set? x (right-branch set))))))

(define (adjoin-set x set)
  (cond ((null? set) (make-tree x '() '()))
        ((= x (entry set)) set)
        ((< x (entry set))
         (make-tree (entry set)
                    (adjoin-set x (left-branch set))
                    (right-branch set)))
        ((> x (entry set))
         (make-tree (entry set)
                    (left-branch set)
                    (adjoin-set x (right-branch set))))))

(adjoin-set 1 '()) => '(1 () ())
(adjoin-set 1 '(1 () ())) => '(1 () ())
(adjoin-set 1 '(2 () (3 () ()))) => '(2 (1 () ()) (3 () ()))

(element-of-set? 1 '()) => #f
(element-of-set? 1 '(1 () ())) => #t
(element-of-set? 1 '(2 (1 () ()) (3 () ()))) => #t

(Exercise ?2.63
  (use (:2.3.3.3 entry left-branch right-branch)))

(define (tree->list-1 tree)
  (if (null? tree)
      '()
      (append (tree->list-1 (left-branch tree))
              (cons (entry tree)
                    (tree->list-1 (right-branch tree))))))

(define (tree->list-2 tree)
  (define (copy-to-list tree result-list)
    (if (null? tree)
        result-list
        (copy-to-list (left-branch tree)
                      (cons (entry tree)
                            (copy-to-list (right-branch tree)
                                          result-list)))))
  (copy-to-list tree '()))

;; Here are the trees from Figure 2.16, all representing the set
;; $\{1,3,5,7,9,11\}$:
(define t1 '(7 (3 (1 () ()) (5 () ())) (9 () (11 () ()))))
(define t2 '(3 (1 () ()) (7 (5 () ()) (9 () (11 () ())))))
(define t3 '(5 (3 (1 () ()) ()) (9 (7 () ()) (11 () ()))))

;; (a) Yes, the two procedures produce the same result for every tree. In
;;     particular, they produce the ordered list representation of the set. The
;;     first performs an in-order traversal and appends intermediate results
;;     (left to right), while the second performs a reverse in-order traversal
;;     and prepends elements to the result (right to left).

(tree->list-1 t1)
=> (tree->list-2 t1)
=> (tree->list-1 t2)
=> (tree->list-2 t2)
=> (tree->list-1 t3)
=> (tree->list-2 t3)
=> '(1 3 5 7 9 11)

;; (b) The first procedure does linear work at each node, so it grows as
;;     $Θ(n\log n)$ for a balanced tree. The second procedure does constant work
;;     at each node, so it grows as $Θ(n)$ for any tree whether balanced or not.
;;     The second procedure is more efficient.

(Exercise ?2.64
  (use (:2.3.3.3 make-tree)))

(define (list->tree elements)
  (car (partial-tree elements (length elements))))

(define (partial-tree elts n)
  (if (= n 0)
      (cons '() elts)
      (let* ((left-size (quotient (- n 1) 2))
             (left-result (partial-tree elts left-size))
             (left-tree (car left-result))
             (non-left-elts (cdr left-result))
             (this-entry (car non-left-elts))
             (right-size (- n (+ left-size 1)))
             (right-result (partial-tree (cdr non-left-elts) right-size))
             (right-tree (car right-result))
             (remaining-elts (cdr right-result)))
        (cons (make-tree this-entry left-tree right-tree)
              remaining-elts))))

(list->tree '(1 3 5 7 9 11))
=> '(5 (1 () (3 () ())) (9 (7 () ()) (11 () ())))

;; (a) The procedure `partial-tree` works by partitioning the first `n` elements
;;     of `elts` around a central element and recursively producing left and
;;     right subtrees. It uses truncated division to work when `n` is even or
;;     odd. It passes on the list of remaining elements to avoid re-traversing
;;     the list. Here is the tree it produces for the example:
;;
;;     ```diagram
;;           5
;;          / \
;;         /   \
;;        1     9
;;         \   / \
;;          + +   +
;;          3 7   11
;;     ```
;;
;; (b) The procedure `list->tree` does constant work at each node, so it grows
;;     as $Θ(n)$.

(Exercise ?2.65
  (use (:2.3.3.2 intersection-set) (?2.62 union-set) (?2.63 tree->list-2)
       (?2.64 list->tree)))

;; We can convert the balanced binary tree to an ordered list, use the
;; `union-set` and `intersection-set` we already implemented for ordered lists,
;; and then convert back to a tree. This is $Θ(n)$ because each step is linear.

(define (union-tree set1 set2)
  (list->tree (union-set (tree->list-2 set1) (tree->list-2 set2))))

(define (intersection-tree set1 set2)
  (list->tree (intersection-set (tree->list-2 set1) (tree->list-2 set2))))

(define t1 '(1 () ()))
(define t2 '(2 () ()))
(define t23 '(2 () (3 () ())))
(define t123 '(2 (1 () ()) (3 () ())))

(union-tree '() t123) => t123
(union-tree t123 '()) => t123
(union-tree t123 t123) => t123
(union-tree t1 t23) => t123
(union-tree t2 t23) => t23
(union-tree t23 t123) => t123

(intersection-tree '() t123) => '()
(intersection-tree t123 '()) => '()
(intersection-tree t1 t123) => t1
(intersection-tree t2 t123) => t2
(intersection-tree t123 t123) => t123
(intersection-tree t23 t123) => t23

(Section :2.3.3.4 "Sets and information retrieval")

(define (lookup given-key set-of-records)
  (cond ((null? set-of-records) #f)
        ((equal? given-key (key (car set-of-records)))
         (car set-of-records))
        (else (lookup given-key (cdr set-of-records)))))

(define key car)

(lookup 3 '((1 flour) (2 water) (3 salt))) => '(3 salt)

(Exercise ?2.66
  (use (:2.3.3.3 entry left-branch right-branch) (:2.3.3.4 key)))

(define (lookup given-key set-of-records)
  (if (null? set-of-records)
      #f
      (let* ((record (entry set-of-records))
             (rec-key (key record)))
        (cond ((= given-key rec-key) record)
              ((< given-key rec-key)
               (lookup given-key (left-branch set-of-records)))
              ((> given-key rec-key)
               (lookup given-key (right-branch set-of-records)))))))

(lookup 3 '((2 water) ((1 flour) () ()) ((3 salt) () ()))) => '(3 salt)

(Section :2.3.4 "Example: Huffman Encoding Trees")

(Section :2.3.4.1 "Representing Huffman trees")

(define (make-leaf symbol weight) (list 'leaf symbol weight))
(define (leaf? object) (eq? (car object) 'leaf))
(define symbol-leaf cadr)
(define weight-leaf caddr)

(define (make-code-tree left right)
  (list left
        right
        (append (symbols left) (symbols right))
        (+ (weight left) (weight right))))
(define left-branch car)
(define right-branch cadr)

(define (symbols tree)
  (if (leaf? tree)
      (list (symbol-leaf tree))
      (caddr tree)))
(define (weight tree)
  (if (leaf? tree)
      (weight-leaf tree)
      (cadddr tree)))

(Section :2.3.4.2 "The decoding procedure"
  (use (:2.3.4.1 leaf? left-branch right-branch symbol-leaf)))

(define (decode bits tree)
  (define (decode-1 bits current-branch)
    (if (null? bits)
        '()
        (let ((next-branch (choose-branch (car bits) current-branch)))
          (if (leaf? next-branch)
              (cons (symbol-leaf next-branch)
                    (decode-1 (cdr bits) tree))
              (decode-1 (cdr bits) next-branch)))))
  (decode-1 bits tree))

(define (choose-branch bit branch)
  (cond ((= bit 0) (left-branch branch))
        ((= bit 1) (right-branch branch))
        (else (error 'choose-branch "bit should be 0 or 1" bit))))

(Section :2.3.4.3 "Sets of weighted elements"
  (use (:2.3.4.1 make-leaf weight)))

(define (adjoin-set x set)
  (cond ((null? set) (list x))
        ((< (weight x) (weight (car set)))
         (cons x set))
        (else (cons (car set)
                    (adjoin-set x (cdr set))))))

(define (make-leaf-set pairs)
  (if (null? pairs)
      '()
      (let ((pair (car pairs)))
        (adjoin-set (make-leaf (car pair) (cadr pair))
                    (make-leaf-set (cdr pairs))))))

(Exercise ?2.67
  (use (:2.3.4.1 make-code-tree make-leaf) (:2.3.4.2 decode)))

(define sample-tree
  (make-code-tree (make-leaf 'A 4)
                  (make-code-tree (make-leaf 'B 2)
                                  (make-code-tree (make-leaf 'D 1)
                                                  (make-leaf 'C 1)))))

(define sample-message '(0 1 1 0 0 1 0 1 0 1 1 1 0))
(define sample-decoded '(A D A B B C A))

(decode sample-message sample-tree) => sample-decoded
(decode '(0 1 2) sample-tree) =!> "bit should be 0 or 1: 2"

(Exercise ?2.68
  (use (:2.3.3.1 element-of-set?)
       (:2.3.4.1 leaf? left-branch right-branch symbols)
       (?2.67 sample-decoded sample-message sample-tree)))

(define (encode message tree)
  (if (null? message)
      '()
      (append (encode-symbol (car message) tree)
              (encode (cdr message) tree))))

(define (encode-symbol symbol tree)
  (cond ((leaf? tree) '())
        ((element-of-set? symbol (symbols (left-branch tree)))
         (cons 0 (encode-symbol symbol (left-branch tree))))
        ((element-of-set? symbol (symbols (right-branch tree)))
         (cons 1 (encode-symbol symbol (right-branch tree))))
        (else (error 'encode-symbol "symbol not in tree" symbol))))

(encode sample-decoded sample-tree) => sample-message
(encode '(Z) sample-tree) =!> "symbol not in tree: Z"

(Exercise ?2.69
  (use (:2.3.4.1 make-code-tree) (:2.3.4.3 adjoin-set make-leaf-set)
       (?2.68 encode-symbol)))

(define (generate-huffman-tree pairs)
  (successive-merge (make-leaf-set pairs)))

(define (successive-merge set)
  (if (null? (cdr set))
      (car set)
      (successive-merge
       (adjoin-set (make-code-tree (car set) (cadr set))
                   (cddr set)))))

(define abcd-tree (generate-huffman-tree '((A 5) (B 10) (C 2) (D 1))))
(encode-symbol 'A abcd-tree) => '(0 1)
(encode-symbol 'B abcd-tree) => '(1)
(encode-symbol 'C abcd-tree) => '(0 0 1)
(encode-symbol 'D abcd-tree) => '(0 0 0)

(Exercise ?2.70
  (use (?2.68 encode) (?2.69 generate-huffman-tree)))

(define rock-tree
  (generate-huffman-tree
   '((a 2) (boom 1) (get 2) (job 2) (na 16) (sha 3) (yip 9) (wah 1))))

(define song
  '(get a job sha na na na na na na na na
    get a job sha na na na na na na na na
    wah yip yip yip yip yip yip yip yip yip
    sha boom))

(define encoded-song (encode song rock-tree))
(length encoded-song) => 84
encoded-song
=> '(1 1 1 1 1 1 1 0 0 1 1 1 1 0 1 1 1 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 0 0 1 1 1
     1 0 1 1 1 0 0 0 0 0 0 0 0 0 1 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1
     1 1 0 1 1 0 1 1)

;; This encoding requires 84 bits. A fixed-length code for the eight-symbol
;; alphabet would require $\log_2 8 = 3$ bits per symbol, and the song uses 36
;; symbols, so the fixed-length coded message would need at least $3 \times 36 =
;; 108$ bits. Using the variable-length encoding saves about 22% storage.

(Exercise ?2.71
  (use (?2.68 encode-symbol) (?2.69 generate-huffman-tree)))

;; Given an alphabet of $n$ symbols whose relative frequencies are consecutive
;; powers of two, the Huffman tree will have a diagonal shape with every right
;; branch going to a leaf. Here are the trees with leaf weights shown for 5 and
;; 10 symbols:
;;
;; ```diagram
;;     "n=5"            "n=10"
;;
;;      /\               /\
;;     /\ 16            /\ 512
;;    /\ 8             /\ 256
;;   /\ 4             /\ 128
;;  1  2             /\ 64
;;                  /\ 32
;;                 /\ 16
;;                /\ 8
;;               /\ 4
;;              1  2
;; ```
;;
;; The tree looks like this because the merging algorithm ends up accumulating
;; everything into one tree. At each stage, the weight of the tree is less than
;; the weight of the next leaf. For example, $1+2<4$, and in general
;; $2^0+\cdots+2^{k-1}=2^k-1<2^k$.
;;
;; In this encoding, the most frequent symbol requires one bit and the least
;; frequent symbol requires $n-1$ bits. We can verify this for a random $n$:

(define (alphabet-frequencies n)
  (define (helper i)
    (if (> i n)
        '()
        (cons (list i (expt 2 (- n i))) (helper (+ i 1)))))
  (helper 1))

(alphabet-frequencies 5)
=> '((1 16) (2 8) (3 4) (4 2) (5 1))

(define n (+ 2 (random 25)))
(define tree (generate-huffman-tree (alphabet-frequencies n)))

(encode-symbol 1 tree) => '(1)
(length (encode-symbol n tree)) => (- n 1)

;; In the special case where $n=1$, the lone symbol requires zero bits:

(define tree (generate-huffman-tree (alphabet-frequencies 1)))
(encode-symbol 1 tree) => '()

(Exercise ?2.72)

;; The `encode-symbol` procedure from [](?2.68) grows as $Θ(1)$ in the best
;; case, when taking the first left branch to a leaf, and $Θ(n^2)$ in the worst
;; case, when visiting every non-leaf node. Assuming a tree as described in
;; [](?2.71), it is $Θ(n)$ for the most frequent symbol due to scanning the left
;; branch's symbols first, and $Θ(n^2)$ for the least frequent symbol as this is
;; the worst case just described.

(Section :2.4 "Multiple Representations for Abstract Data")

(Section :2.4.1 "Representations for Complex Numbers"
  (use (:1.1.4 square)))

(define (add-complex z1 z2)
  (make-from-real-imag
   (+ (real-part z1) (real-part z2))
   (+ (imag-part z1) (imag-part z2))))
(define (sub-complex z1 z2)
  (make-from-real-imag
   (- (real-part z1) (real-part z2))
   (- (imag-part z1) (imag-part z2))))
(define (mul-complex z1 z2)
  (make-from-mag-ang
   (* (magnitude z1) (magnitude z2))
   (+ (angle z1) (angle z2))))
(define (div-complex z1 z2)
  (make-from-mag-ang
   (/ (magnitude z1) (magnitude z2))
   (- (angle z1) (angle z2))))

;; Ben's representation (rectangular form):
(define real-part car)
(define imag-part cdr)
(define (magnitude z)
  (sqrt (+ (square (real-part z))
           (square (imag-part z)))))
(define (angle z)
  (atan (imag-part z) (real-part z)))
(define make-from-real-imag cons)
(define (make-from-mag-ang r a)
  (cons (* r (cos a)) (* r (sin a))))

;; Rectangular form can give exact answers for addition and subtraction.
(define z1 (add-complex (make-from-real-imag 1 2) (make-from-real-imag 3 4)))
(define z2 (mul-complex (make-from-mag-ang 5 1) (make-from-mag-ang 6 2)))
(real-part z1) => 4
(imag-part z1) => 6
(magnitude z2) ~> 30
(angle z2) ~> 3

;; Alyssa's representation (polar form):
(define (real-part z) (* (magnitude z) (cos (angle z))))
(define (imag-part z) (* (magnitude z) (sin (angle z))))
(define magnitude car)
(define angle cdr)
(define (make-from-real-imag x y)
  (cons (sqrt (+ (square x) (square y)))
        (atan y x)))
(define make-from-mag-ang cons)

;; Polar form can give exact answers for multiplication and division.
(define z1 (add-complex (make-from-real-imag 1 2) (make-from-real-imag 3 4)))
(define z2 (mul-complex (make-from-mag-ang 5 1) (make-from-mag-ang 6 2)))
(real-part z1) ~> 4
(imag-part z1) ~> 6
(magnitude z2) => 30
(angle z2) => 3

(Section :2.4.2 "Tagged Data"
  (use (:1.1.4 square)))

(define (attach-tag type-tag contents)
  (cons type-tag contents))
(define (type-tag datum)
  (if (pair? datum)
      (car datum)
      (error 'type-tag "bad tagged datum" datum)))
(define (contents datum)
  (if (pair? datum)
      (cdr datum)
      (error 'contents "bad tagged datum" datum)))
(define (rectangular? z) (eq? (type-tag z) 'rectangular))
(define (polar? z) (eq? (type-tag z) 'polar))

;; Ben's representation (rectangular form):
(define real-part-rectangular car)
(define imag-part-rectangular cdr)
(define (magnitude-rectangular z)
  (sqrt (+ (square (real-part-rectangular z))
           (square (imag-part-rectangular z)))))
(define (angle-rectangular z)
  (atan (imag-part-rectangular z)
        (real-part-rectangular z)))
(define (make-from-real-imag-rectangular x y)
  (attach-tag 'rectangular (cons x y)))
(define (make-from-mag-ang-rectangular r a)
  (attach-tag 'rectangular
              (cons (* r (cos a))
                    (* r (sin a)))))

;; Alyssa's representation (polar form):
(define (real-part-polar z)
  (* (magnitude-polar z) (cos (angle-polar z))))
(define (imag-part-polar z)
  (* (magnitude-polar z) (sin (angle-polar z))))
(define magnitude-polar car)
(define angle-polar cdr)
(define (make-from-real-imag-polar x y)
  (attach-tag 'polar
              (cons (sqrt (+ (square x) (square y)))
                    (atan y x))))
(define (make-from-mag-ang-polar r a)
  (attach-tag 'polar (cons r a)))

;; Generic selectors:
(define (real-part z)
  (cond ((rectangular? z)
         (real-part-rectangular (contents z)))
        ((polar? z)
         (real-part-polar (contents z)))
        (else (error 'real-part "unknown type" z))))
(define (imag-part z)
  (cond ((rectangular? z)
         (imag-part-rectangular (contents z)))
        ((polar? z)
         (imag-part-polar (contents z)))
        (else (error 'imag-part "unknown type" z))))
(define (magnitude z)
  (cond ((rectangular? z)
         (magnitude-rectangular (contents z)))
        ((polar? z)
         (magnitude-polar (contents z)))
        (else (error 'magnitude "unknown type" z))))
(define (angle z)
  (cond ((rectangular? z)
         (angle-rectangular (contents z)))
        ((polar? z)
         (angle-polar (contents z)))
        (else (error 'angle "unknown type" z))))

;; Generic constructors:
(define make-from-real-imag make-from-real-imag-rectangular)
(define make-from-mag-ang make-from-mag-ang-polar)

;; Generic operations:
(paste (:2.4.1 add-complex div-complex mul-complex sub-complex))

;; Now we can get exact answers for all operations:
(define z1 (add-complex (make-from-real-imag 1 2) (make-from-real-imag 3 4)))
(define z2 (mul-complex (make-from-mag-ang 5 1) (make-from-mag-ang 6 2)))
z1 => (make-from-real-imag 4 6)
z2 => (make-from-mag-ang 30 3)

(Section :2.4.3 "Data-Directed Programming and Additivity"
  (use (:1.1.4 square) (:2.4.2 attach-tag contents type-tag)
       (:3.3.3.3 get put reset)))

;; The textbook calls these procedures `install-rectangular-package` and
;; `install-polar-package`. I shorten them to `rectangular-pkg` and `polar-pkg`
;; since there are many of these procedures and the long names tend to bloat
;; import lists.

(define (rectangular-pkg)
  ;; Internal procedures
  (define real-part car)
  (define imag-part cdr)
  (define make-from-real-imag cons)
  (define (magnitude z)
    (sqrt (+ (square (real-part z))
             (square (imag-part z)))))
  (define (angle z)
    (atan (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (* r (cos a)) (* r (sin a))))

  ;; Interface to the rest of the system
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a) (tag (make-from-mag-ang r a)))))

(define (polar-pkg)
  ;; Internal procedures
  (define magnitude car)
  (define angle cdr)
  (define make-from-mag-ang cons)
  (define (real-part z)
    (* (magnitude z) (cos (angle z))))
  (define (imag-part z)
    (* (magnitude z) (sin (angle z))))
  (define (make-from-real-imag x y)
    (cons (sqrt (+ (square x) (square y)))
          (atan y x)))

  ;; Interface to the rest of the system
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a) (tag (make-from-mag-ang r a)))))

;; Helpers to apply generic operations:

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (proc (get op type-tags)))
    (if proc
        (apply proc (map contents args))
        (error 'apply-generic "no method for argument types" op type-tags))))

(define (apply-specific op type . args)
  (let ((proc (get op type)))
    (if proc
        (apply proc args)
        (error op "no method for type" op type))))

;; Generic selectors:
(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))

;; Generic constructors:
(define (make-from-real-imag x y)
  (apply-specific 'make-from-real-imag 'rectangular x y))
(define (make-from-mag-ang r a)
  (apply-specific 'make-from-mag-ang 'polar r a))

;; Generic operations:
(paste (:2.4.1 add-complex div-complex mul-complex sub-complex))

;; Helper procedure to run installers with a clean slate:
(define (using . installers)
  (reset)
  (for-each (lambda (f) (f)) installers))

;; Putting it all together:

(using rectangular-pkg polar-pkg)

(define z1 (add-complex (make-from-real-imag 1 2) (make-from-real-imag 3 4)))
(define z2 (mul-complex (make-from-mag-ang 5 1) (make-from-mag-ang 6 2)))
z1 => (make-from-real-imag 4 6)
z2 => (make-from-mag-ang 30 3)

(Exercise ?2.73
  (use (:2.2.3.1 accumulate)
       (:2.3.2 make-product make-sum same-variable? variable?)
       (:2.4.3 apply-specific using) (:3.3.3.3 put)
       (?2.56 make-exponentiation)))

(define (deriv expr var)
  (cond ((number? expr) 0)
        ((variable? expr) (if (same-variable? expr var) 1 0))
        (else (apply-specific 'deriv (operator expr) (operands expr) var))))
(define operator car)
(define operands cdr)

;; (a) We rewrote `deriv` to dispatch based on the operator of the expression.
;;     However, it still uses explicit case analysis for numbers and variables.
;;     We can't assimilate those into the data-directed dispatch because they
;;     have nothing that can be used as a type tag. Scheme only provides
;;     predicates like `number?`, not a procedure like `(type expr)` that could
;;     return `'number`. We can write our own, but this just moves the case
;;     anaylsis somewhere else:

(define (type expr)
  (cond ((number? expr) 'number)
        ((variable? expr) 'variable)
        (else (operator expr))))

;; (b) Packages for sum and product differentiation:

(define (sum-pkg)
  (define (deriv-sum terms var)
    (accumulate make-sum 0 (map (lambda (t) (deriv t var)) terms)))
  (put 'deriv '+ deriv-sum))

(define (product-pkg)
  (define multiplier car)
  (define (multiplicand product)
    (accumulate make-product 1 (cdr product)))
  (define (deriv-product product var)
    (make-sum (make-product (multiplier product)
                            (deriv (multiplicand product) var))
              (make-product (deriv (multiplier product) var)
                            (multiplicand product))))
  (put 'deriv '* deriv-product))

;;     Note that we can't reuse the selectors `multiplier` and `multiplicand`
;;     from [](?2.57) because they assume the list includes the operator.

;; (c) Package for power differentiation:

(define (power-pkg)
  (define base car)
  (define exponent cadr)
  (define (deriv-power power var)
    (make-product
     (make-product (exponent power)
                   (make-exponentiation
                    (base power)
                    (make-sum (exponent power) -1)))
     (deriv (base power) var)))
  (put 'deriv '** deriv-power))

;;     Note that we can't reuse the selectors `base` and `exponent` from
;;     [](?2.56) because they assume the list includes the operator.

;; (d) If we wanted to index the procedures in the opposite way, we would simply
;;     need to swap the first two arguments to `put` in all the package
;;     installation procedures.

;; Let's test the new system:

(using sum-pkg product-pkg power-pkg)

(deriv '(+ x 3) 'x) => 1
(deriv '(* x y) 'x) => 'y
(deriv '(* (* x y) (+ x 3)) 'x) => '(+ (* x y) (* y (+ x 3)))
(deriv '(* 3 (** x 5)) 'x) => '(* 3 (* 5 (** x 4)))

(Exercise ?2.74
  (use (:2.4.2 attach-tag contents type-tag) (:2.4.3 apply-specific using)
       (:3.3.3.3 put)))

;; (a) Each division should tag their file with a symbol such as `'marketing`,
;;     and install an implementation of `get-record` that deals with their
;;     internal record structure.

(define (get-record file employee-name)
  (let* ((tag (type-tag file))
         (record
          (apply-specific 'get-record tag (contents file) employee-name)))
    (and record (attach-tag tag record))))

;; (b) Since our generic `get-record` reattaches the division tag to the
;;     returned record, there is no need for divisions to tag records or do
;;     anything special. They just need to install an implementation of
;;     `get-salary`.

(define (get-salary record)
  (apply-specific 'get-salary (type-tag record) (contents record)))

;; (c) Procedure to find an employee's record across all files:

(define (find-employee-record employee-name files)
  (if (null? files)
      #f
      (or (get-record (car files) employee-name)
          (find-employee-record employee-name (cdr files)))))

;; (d) When they take over a new company, they must tag its file and install
;;     implementations of `get-record` and `get-salary` for it.

;; Here is an example of a company with two divisions:

(define files
  (list (attach-tag 'marketing
                    '("Alice" "Bob"))
        (attach-tag 'sales
                    '(("Joe" 40) ("Jane" 60)))))

(define (company-pkg)
  (define (get-record-marketing records name)
    (cond ((null? records) #f)
          ((equal? (car records) name) name)
          (else (get-record-marketing (cdr records) name))))
  (define (get-salary-marketing record) 50)
  (define (get-record-sales records name)
    (cond ((null? records) #f)
          ((equal? (caar records) name) (car records))
          (else (get-record-sales (cdr records) name))))
  (define get-salary-sales cadr)
  (put 'get-record 'marketing get-record-marketing)
  (put 'get-salary 'marketing get-salary-marketing)
  (put 'get-record 'sales get-record-sales)
  (put 'get-salary 'sales get-salary-sales))

(using company-pkg)

(find-employee-record "Nobody" files) => #f
(get-salary (find-employee-record "Alice" files)) => 50
(get-salary (find-employee-record "Bob" files)) => 50
(get-salary (find-employee-record "Joe" files)) => 40
(get-salary (find-employee-record "Jane" files)) => 60

(Section :2.4.3.1 "Message passing"
  (use (:1.1.4 square)))

(define (make-from-real-imag x y)
  (lambda (op)
    (cond ((eq? op 'real-part) x)
          ((eq? op 'imag-part) y)
          ((eq? op 'magnitude) (sqrt (+ (square x) (square y))))
          ((eq? op 'angle) (atan y x))
          (else (error 'make-from-real-imag "unknown op" op)))))

(define (apply-generic op arg) (arg op))

(apply-generic 'real-part (make-from-real-imag 3 4)) => 3
(apply-generic 'magnitude (make-from-real-imag 0 1)) ~> 1

(Exercise ?2.75
  (use (:2.4.3.1 apply-generic)))

(define (make-from-mag-ang r a)
  (lambda (op)
    (cond ((eq? op 'real-part) (* r (cos a)))
          ((eq? op 'imag-part) (* r (sin a)))
          ((eq? op 'magnitude) r)
          ((eq? op 'angle) a)
          (else (error 'make-from-mag-ang "unknown op" op)))))

(apply-generic 'magnitude (make-from-mag-ang 15 0.5)) => 15
(apply-generic 'imag-part (make-from-mag-ang 1 0)) ~> 0

(Exercise ?2.76)

;; - Generic operations with explicit dispatch
;;     - _New type_
;;         - Add a new clause to all generic procedures.
;;     - _New operation_
;;         - Write a generic procedure that handles all types.
;; - Data-directed style
;;     - _New type_
;;         - Install implementations of every operation.
;;     - _New operation_
;;         - Install implementations for every type.
;;         - Write a wrapper that invokes `apply-generic`.
;; - Message-passing style
;;     - _New type_
;;         - Write a procedure that handles all operations.
;;     - _New operation_
;;         - Add a new clause to the method dispatch of all types.
;;
;; All three styles allow adding new types and operations, but they are
;; optimized for different use cases. Generic operations with explicit dispatch
;; is best when mostly adding new operations, while message passing is best when
;; mostly adding new types. In each case, you can implement the new
;; functionality in a self-contained piece of code, whereas using the other
;; system requires editing many disparate pieces of code.
;;
;; The data-directed style is best when adding a mix of types and operations,
;; since it works equally well for both. It can also be used all the time
;; instead of the other two systems. Its main drawback is the complexity of
;; global mutable state (discussed more in [](:3)) used for the table. Without
;; knowing the contents of the table, you cannot be sure what will happen when
;; invoking a generic procedure in the data-directed style.

(Section :2.5 "Systems with Generic Operations")

(Section :2.5.1 "Generic Arithmetic Operations"
  (use (:2.1.1 add-rat denom div-rat mul-rat numer sub-rat) (:2.4.2 attach-tag)
       (:2.4.3 add-complex apply-generic apply-specific div-complex
               make-from-mag-ang make-from-real-imag mul-complex polar-pkg
               rectangular-pkg sub-complex using)
       (:3.3.3.3 put) (?2.1 make-rat)))

(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))

(define (scheme-number-pkg)
  (define (tag x) (attach-tag 'scheme-number x))
  (put 'add '(scheme-number scheme-number) (lambda (x y) (tag (+ x y))))
  (put 'sub '(scheme-number scheme-number) (lambda (x y) (tag (- x y))))
  (put 'mul '(scheme-number scheme-number) (lambda (x y) (tag (* x y))))
  (put 'div '(scheme-number scheme-number) (lambda (x y) (tag (/ x y))))
  (put 'make 'scheme-number tag))

(define (make-scheme-number n)
  (apply-specific 'make 'scheme-number n))

(define (rational-pkg)
  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational) (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational) (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational) (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational) (lambda (x y) (tag (div-rat x y))))
  (put 'make 'rational (lambda (n d) (tag (make-rat n d)))))

(define (make-rational n d)
  (apply-specific 'make 'rational n d))

(define (complex-pkg)
  (define (tag z) (attach-tag 'complex z))
  (rectangular-pkg)
  (polar-pkg)
  (put 'add '(complex complex) (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex) (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex) (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex) (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'make-from-real-imag 'complex
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex
       (lambda (r a) (tag (make-from-mag-ang r a)))))

(define (make-complex-from-real-imag x y)
  (apply-specific 'make-from-real-imag 'complex x y))
(define (make-complex-from-mag-ang r a)
  (apply-specific 'make-from-mag-ang 'complex r a))

(define (numeric-pkg)
  (scheme-number-pkg)
  (rational-pkg)
  (complex-pkg))

(using numeric-pkg)

(add (make-scheme-number 1) (make-scheme-number 2))
=> (make-scheme-number 3)

(mul (make-rational 1 2) (make-rational 3 4))
=> (make-rational 3 8)

(sub (make-complex-from-mag-ang 1 0) (make-complex-from-real-imag 1 1))
=> (make-complex-from-real-imag 0 -1)

(Exercise ?2.77
  (use (:1.1.4 square)
       (:2.4.3 angle apply-generic imag-part magnitude real-part using)
       (:2.5.1 complex-pkg make-complex-from-real-imag) (:3.3.3.3 get put)))

(define (complex-components-pkg)
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle))

;; This works because these selectors were defined in [](:2.4.3) using
;; `apply-generic`, so now they will dispatch back to themselves when given a
;; data object tagged `'complex`. In other words, we are telling the system to
;; strip off the type tag and try again.

(using complex-pkg complex-components-pkg)

(define z (make-complex-from-real-imag 3 4))

(magnitude z)
=> (magnitude '(complex rectangular 3 . 4))
=> (apply-generic 'magnitude '(complex rectangular 3 . 4))    ; 1st call
=> (apply (get 'magnitude '(complex)) '((rectangular 3 . 4)))
=> (magnitude '(rectangular 3 . 4))
=> (apply-generic 'magnitude '(rectangular 3 . 4))            ; 2nd call
=> (apply (get 'magnitude '(rectangular)) '((3 . 4)))
=> (sqrt (+ (square 3) (square 4)))
=> (sqrt (+ 9 16))
=> (sqrt 25)
=> 5

;; In this example, `apply-generic` is invoked twice: once on the outer
;; `'complex` object and again on the inner `'rectangular` object. Each
;; invocation strips off one type tag.

(Exercise ?2.78
  (use (:2.4.3 using) (:3.3.3.3 get put)))

(define (attach-tag type-tag contents)
  (if (eq? type-tag 'scheme-number)
      contents
      (cons type-tag contents)))
(define (type-tag datum)
  (cond ((pair? datum) (car datum))
        ((number? datum) 'scheme-number)
        (else (error 'type-tag "bad tagged datum" datum))))
(define (contents datum)
  (cond ((pair? datum) (cdr datum))
        ((number? datum) datum)
        (else (error 'contents "bad tagged datum" datum))))

(attach-tag 'foo 'a) => '(foo . a)
(attach-tag 'scheme-number 1) => 1
(type-tag '(foo . a)) => 'foo
(type-tag 1) => 'scheme-number
(contents '(foo . a)) => 'a
(contents 1) => 1

(paste (:2.4.3 apply-generic) (:2.5.1 add div mul scheme-number-pkg sub))

(using scheme-number-pkg)

(add 1 2) => 3
(mul 3 4) => 12

(Exercise ?2.79
  (use (:2.1.1 denom numer) (:2.4.3 apply-generic imag-part real-part using)
       (:2.5.1 make-complex-from-mag-ang make-complex-from-real-imag
               make-rational make-scheme-number numeric-pkg)
       (:3.3.3.3 put)))

;; In addition to Scheme numbers, rationals, and complex numbers, we'll also
;; make it work for integers and reals. This will be used to implement `drop` in
;; [](?2.85).

(define (equ-pkg)
  (put 'equ? '(scheme-number scheme-number) =)
  (put 'equ? '(integer integer) =)
  (put 'equ? '(real real) =)
  (put 'equ? '(rational rational)
       (lambda (x y)
         (and (= (numer x) (numer y))
              (= (denom x) (denom y)))))
  (put 'equ? '(complex complex)
       (lambda (z1 z2)
         (and (= (real-part z1) (real-part z2))
              (= (imag-part z1) (imag-part z2))))))

(define (equ? x y) (apply-generic 'equ? x y))

(using numeric-pkg equ-pkg)

(equ? (make-scheme-number 1) (make-scheme-number 1)) => #t
(equ? (make-scheme-number 1) (make-scheme-number 2)) => #f
(equ? (make-rational 1 2) (make-rational 2 4)) => #t
(equ? (make-rational 1 3) (make-rational 2 4)) => #f
(equ? (make-complex-from-real-imag 1 0) (make-complex-from-mag-ang 1 0)) => #t
(equ? (make-complex-from-real-imag 1 1) (make-complex-from-mag-ang 1 0)) => #f

(Exercise ?2.80
  (use (:2.1.1 numer) (:2.4.3 apply-generic imag-part real-part using)
       (:2.5.1 make-complex-from-mag-ang make-complex-from-real-imag
               make-rational make-scheme-number numeric-pkg)
       (:3.3.3.3 put)))

(define (zero-pkg)
  (put '=zero? '(scheme-number) zero?)
  (put '=zero? '(rational)
       (lambda (x) (zero? (numer x))))
  (put '=zero? '(complex)
       (lambda (x) (and (zero? (real-part x))
                        (zero? (imag-part x))))))

(define (=zero? n) (apply-generic '=zero? n))

(using numeric-pkg zero-pkg)

(=zero? (make-scheme-number 0)) => #t
(=zero? (make-scheme-number 1)) => #f
(=zero? (make-rational 0 1)) => #t
(=zero? (make-rational 1 1)) => #f
(=zero? (make-complex-from-mag-ang 0 2)) => #t
(=zero? (make-complex-from-real-imag 0 1)) => #f

(Section :2.5.2 "Combining Data of Different Types"
  (use (:2.4.2 contents type-tag) (:2.4.3 using)
       (:2.5.1 make-complex-from-real-imag make-scheme-number numeric-pkg)
       (:3.3.3.3 get put)))

(define (get-coercion type1 type2)
  (get 'coerce (list type1 type2)))
(define (put-coercion type1 type2 coerce)
  (put 'coerce (list type1 type2) coerce))

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (proc (get op type-tags)))
    (define (err)
      (error 'apply-generic "no method for types" op type-tags))
    (if proc
        (apply proc (map contents args))
        (if (= (length args) 2)
            (let* ((type1 (car type-tags))
                   (type2 (cadr type-tags))
                   (a1 (car args))
                   (a2 (cadr args))
                   (t1->t2 (get-coercion type1 type2))
                   (t2->t1 (get-coercion type2 type1)))
              (cond (t1->t2 (apply-generic op (t1->t2 a1) a2))
                    (t2->t1 (apply-generic op a1 (t2->t1 a2)))
                    (else (err))))
            (err)))))

(paste (:2.5.1 add div mul sub))

(define (scheme-number-to-complex-pkg)
  (define (coerce n)
    (make-complex-from-real-imag (contents n) 0))
  (put-coercion 'scheme-number 'complex coerce))

(using numeric-pkg scheme-number-to-complex-pkg)

(add (make-scheme-number 1) (make-complex-from-real-imag 0 1))
=> (add (make-complex-from-real-imag 0 1) (make-scheme-number 1))
=> (make-complex-from-real-imag 1 1)

(Exercise ?2.81
  (use (:2.4.2 attach-tag contents type-tag) (:2.4.3 using)
       (:2.5.1 complex-pkg make-complex-from-real-imag)
       (:2.5.2 apply-generic get-coercion put-coercion) (:3.3.3.3 get put)))

(define (identity-pkg)
  (put-coercion 'scheme-number 'scheme-number (lambda (x) x))
  (put-coercion 'complex 'complex (lambda (x) x)))

(define (exp-pkg)
  (define (tag x) (attach-tag 'scheme-number x))
  (put 'exp '(scheme-number scheme-number) (lambda (x y) (tag (expt x y)))))

(define (exp x y) (apply-generic 'exp x y))

;; (a) If we call `exp` with two complex numbers, it will enter an infinite
;;     recursion because it will keep trying to unnecessarily coerce the first
;;     argument to the type of the second.

(using complex-pkg identity-pkg exp-pkg)

(define z (make-complex-from-real-imag 0 0))
(exp z z) =>...

;; (b) Louis is wrong: nothing needs to be done about coercion with arguments of
;;     the same type. As long as we don't install any self-coercions as tried
;;     above, `apply-generic` will fail to find a coercion and report an error.

;; (c) This implementation doesn't coerce two arguments of the same type:

(define (new-apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (proc (get op type-tags)))
    (define (err)
      (error 'new-apply-generic "no method for types" op type-tags))
    (if proc
        (apply proc (map contents args))
        (if (= (length args) 2)
            (let ((type1 (car type-tags))
                  (type2 (cadr type-tags)))
              (if (eq? type1 type2)
                  (err)
                  (let ((a1 (car args))
                        (a2 (cadr args))
                        (t1->t2 (get-coercion type1 type2))
                        (t2->t1 (get-coercion type2 type1)))
                    (cond (t1->t2 (new-apply-generic op (t1->t2 a1) a2))
                          (t2->t1 (new-apply-generic op a1 (t2->t1 a2)))
                          (else (err))))))
            (err)))))

(define (exp x y) (new-apply-generic 'exp x y))

(exp z z) =!> "no method for types"

(Exercise ?2.82
  (use (:2.4.2 attach-tag contents type-tag) (:2.4.3 add-complex using)
       (:2.5.1 make-complex-from-real-imag make-scheme-number numeric-pkg)
       (:2.5.2 add get-coercion scheme-number-to-complex-pkg)
       (:3.3.3.3 get put)))

(define (get-coercion-or-id from to)
  (if (eq? from to)
      (lambda (x) x)
      (get-coercion from to)))
(define (all-good? xs)
  (or (null? xs)
      (and (car xs)
           (all-good? (cdr xs)))))
(define (coerce-all vals types to)
  (let ((cs (map (lambda (from) (get-coercion-or-id from to)) types)))
    (if (all-good? cs)
        (map (lambda (c v) (c v)) cs vals)
        #f)))

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (proc (get op type-tags)))
    (define (try tt)
      (when (null? tt)
        (error 'apply-generic "no method for types" op type-tags))
      (let* ((try-type (car tt))
             (coerced-args (coerce-all args type-tags try-type))
             (new-type-tags (map (lambda (x) try-type) type-tags))
             (proc (get op new-type-tags)))
        (if proc
            (apply proc (map contents coerced-args))
            (try (cdr tt)))))
    (if proc
        (apply proc (map contents args))
        (try type-tags))))

(define (add3c-pkg)
  (define (tag z) (attach-tag 'complex z))
  (put 'add3c '(complex complex complex)
       (lambda (z1 z2 z3)
         (tag (add-complex z1 (add-complex z2 z3))))))

(define (add3c z1 z2 z3) (apply-generic 'add3c z1 z2 z3))

(using numeric-pkg scheme-number-to-complex-pkg add3c-pkg)

(add3c (make-scheme-number 1)
       (make-complex-from-real-imag 1 1)
       (make-scheme-number 1))
=> (make-complex-from-real-imag 3 1)

;; This won't work if two complex numbers are supplied and the operation takes
;; one real number and one complex number. It only works for operations given
;; the exact types they need, or for operations that take arguments that are all
;; of the same type (assuming all the necessary coercions are possible).

(Exercise ?2.83
  (use (:2.1.1 denom numer) (:2.4.2 attach-tag)
       (:2.4.3 apply-generic apply-specific using)
       (:2.5.1 add complex-pkg div make-complex-from-real-imag make-rational
               rational-pkg)
       (:3.3.3.3 put)))

(define (integer-pkg)
  (define (tag x) (attach-tag 'integer x))
  (put 'add '(integer integer) (lambda (x y) (tag (+ x y))))
  (put 'sub '(integer integer) (lambda (x y) (tag (- x y))))
  (put 'mul '(integer integer) (lambda (x y) (tag (* x y))))
  (put 'div '(integer integer)
       (lambda (x y)
         (let ((z (/ x y)))
           (if (integer? z) (tag z) (make-rational x y)))))
  (put 'make 'integer tag))

(define (make-integer x) (apply-specific 'make 'integer x))

(define (real-pkg)
  (define (tag x) (attach-tag 'real x))
  (put 'add '(real real) (lambda (x y) (tag (+ x y))))
  (put 'sub '(real real) (lambda (x y) (tag (- x y))))
  (put 'mul '(real real) (lambda (x y) (tag (* x y))))
  (put 'div '(real real) (lambda (x y) (tag (/ x y))))
  (put 'make 'real tag))

(define (make-real x) (apply-specific 'make 'real x))

;; The `extended-numeric-pkg` is like `numeric-pkg` from [](:2.5.1), but it
;; splits `'scheme-number` into `'integer` and `'real`.
(define (extended-numeric-pkg)
  (integer-pkg)
  (rational-pkg)
  (real-pkg)
  (complex-pkg))

(define (raise-pkg)
  (define (integer->rational n)
    (make-rational n 1))
  (define (rational->real x)
    (make-real (inexact (/ (numer x) (denom x)))))
  (define (real->complex n)
    (make-complex-from-real-imag n 0))
  (put 'raise '(integer) integer->rational)
  (put 'raise '(rational) rational->real)
  (put 'raise '(real) real->complex))

(define (raise x) (apply-generic 'raise x))

(using extended-numeric-pkg raise-pkg)

(add (make-integer 1) (make-integer 2)) => (make-integer 3)
(div (make-integer 10) (make-integer 2)) => (make-integer 5)
(div (make-integer 1) (make-integer 2)) => (make-rational 1 2)

(raise (make-integer 1)) => (make-rational 1 1)
(raise (make-rational 1 2)) => (make-real 0.5)
(raise (make-real 0.5)) => (make-complex-from-real-imag 0.5 0)

(Exercise ?2.84
  (use (:2.4.2 contents type-tag) (:2.4.3 using)
       (:2.5.1 make-complex-from-real-imag make-rational) (:3.3.3.3 get)
       (?2.83 extended-numeric-pkg make-integer make-real raise raise-pkg)))

(define numeric-tower
  '(integer rational real complex))

(define (tower-bottom? type) (eq? type 'integer))
(define (tower-top? type) (eq? type 'complex))

(define (tower-position type)
  (define (iter tower n)
    (cond ((null? tower) #f)
          ((eq? type (car tower)) n)
          (else (iter (cdr tower) (+ n 1)))))
  (iter numeric-tower 0))

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (vals (map contents args))
         (proc (get op type-tags)))
    (define (err)
      (error 'apply-generic "no method for types" op type-tags))
    (cond (proc (apply proc vals))
          ((null? args) (err))
          ((null? (cdr args))
           (if (tower-top? (car type-tags))
               (err)
               (apply-generic op (raise (car args)))))
          ((null? (cddr args))
           (let ((a1 (car args))
                 (a2 (cadr args))
                 (p1 (tower-position (car type-tags)))
                 (p2 (tower-position (cadr type-tags))))
             (cond ((or (not p1) (not p2) (= p1 p2)) (err))
                   ((< p1 p2) (apply-generic op (raise a1) a2))
                   (else (apply-generic op a1 (raise a2))))))
          (else (err)))))

(paste (:2.5.1 add div mul sub))

(using extended-numeric-pkg raise-pkg)

(add (make-integer 1) (make-complex-from-real-imag 2.0 3.0))
=> (make-complex-from-real-imag 3.0 3.0)

(add (make-rational 1 2) (make-real 0.5))
=> (make-real 1.0)

(div (make-real 1) (make-integer 2))
=> (make-real 0.5)

(Exercise ?2.85
  (use (:2.1.1 denom numer) (:2.4.2 contents type-tag) (:2.4.3 real-part using)
       (:2.5.1 make-complex-from-real-imag make-rational) (:3.3.3.3 get put)
       (?2.79 equ-pkg equ?)
       (?2.83 extended-numeric-pkg make-integer make-real raise raise-pkg)
       (?2.84 tower-bottom? tower-position tower-top?)))

;; Projection from reals to rationals is the hardest. Instead of designing an
;; algorithm to find the nearest rational, we'll cheat and use the procedures
;; `exact`, `numerator`, and `denominator` which deal with Scheme's built-in
;; rational numbers.

(define (project-pkg)
  (define (complex->real x)
    (make-real (real-part x)))
  (define (real->rational x)
    (let ((y (exact x)))
      (make-rational (numerator y) (denominator y))))
  (define (rational->integer r)
    (make-integer (quotient (numer r) (denom r))))
  (put 'project '(complex) complex->real)
  (put 'project '(real) real->rational)
  (put 'project '(rational) rational->integer))

(define (project x) (apply-generic 'project x))

(define (drop x)
  (let ((type (type-tag x)))
    (if (tower-bottom? type)
        x
        (let* ((down (project x))
               (down-up (raise down)))
          (if (equ? x down-up) (drop down) x)))))

(define (apply-generic op . args)
  (let* ((type-tags (map type-tag args))
         (vals (map contents args))
         (proc (get op type-tags)))
    (define (err)
      (error 'apply-generic "no method for types" op type-tags))
    (cond (proc
           (let ((result (apply proc vals)))
             (if (and (pair? result)
                      (tower-position (type-tag result))
                      (not (or (eq? op 'raise) (eq? op 'project))))
                 (drop result)
                 result)))
          ((null? args) (err))
          ((null? (cdr args))
           (if (tower-top? (car type-tags))
               (err)
               (apply-generic op (raise (car args)))))
          ((null? (cddr args))
           (let ((a1 (car args))
                 (a2 (cadr args))
                 (p1 (tower-position (car type-tags)))
                 (p2 (tower-position (cadr type-tags))))
             (cond ((or (not p1) (not p2) (= p1 p2)) (err))
                   ((< p1 p2) (apply-generic op (raise a1) a2))
                   (else (apply-generic op a1 (raise a2))))))
          (else (err)))))

(paste (:2.5.1 add div mul sub))

(using extended-numeric-pkg equ-pkg raise-pkg project-pkg)

(div (make-real 1) (make-complex-from-real-imag 2 0)) => (make-rational 1 2)
(add (make-complex-from-real-imag 1 0) (make-integer 1)) => (make-integer 2)
(mul (make-rational 3 2) (make-real 8)) => (make-integer 12)
(sub (make-real 2) (make-real 0.5)) => (make-rational 3 2)

(Exercise ?2.86
  (use (:2.1.1 denom numer) (:2.4.2 attach-tag contents type-tag)
       (:2.4.3 angle apply-specific imag-part magnitude make-from-mag-ang
               make-from-real-imag real-part using)
       (:2.5.1 make-complex-from-mag-ang make-complex-from-real-imag
               make-rational rational-pkg)
       (:3.3.3.3 put) (?2.79 equ-pkg)
       (?2.83 integer-pkg make-integer make-real raise raise-pkg real-pkg)
       (?2.85 add apply-generic div mul project-pkg sub)))

;; To support complex numbers whose components are themselves tagged data
;; objects, we must rewrite all the complex number operations using generic
;; procedures like `add` instead of specific procedures like `+`. Before we can
;; do that, we need generic procedures for squares, square roots, and
;; trigonometric functions. Thanks to the automatic coercion in [](?2.85)'s
;; `apply-generic`, we only need to define them for `'real`.

(define (square x) (mul x x))

(define (sqrt-trig-pkg)
  (define (tag x) (attach-tag 'real x))
  (put 'square-root '(real) (lambda (x) (tag (sqrt x))))
  (put 'sine '(real) (lambda (x) (tag (sin x))))
  (put 'cosine '(real) (lambda (x) (tag (cos x))))
  (put 'atan2 '(real real) (lambda (y x) (tag (atan y x)))))

(define (square-root x) (apply-generic 'square-root x))
(define (sine x) (apply-generic 'sine x))
(define (cosine x) (apply-generic 'cosine x))
(define (atan2 x y) (apply-generic 'atan2 x y))

;; Now we can rewrite the rectangular and polar packages:

(define (rectangular-pkg)
  (define real-part car)
  (define imag-part cdr)
  (define make-from-real-imag cons)
  (define (magnitude z)
    (square-root (add (square (real-part z))
                      (square (imag-part z)))))
  (define (angle z)
    (atan2 (imag-part z) (real-part z)))
  (define (make-from-mag-ang r a)
    (cons (mul r (cosine a)) (mul r (sine a))))
  (define (tag x) (attach-tag 'rectangular x))
  (put 'real-part '(rectangular) real-part)
  (put 'imag-part '(rectangular) imag-part)
  (put 'magnitude '(rectangular) magnitude)
  (put 'angle '(rectangular) angle)
  (put 'make-from-real-imag 'rectangular
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'rectangular
       (lambda (r a) (tag (make-from-mag-ang r a)))))

(define (polar-pkg)
  (define magnitude car)
  (define angle cdr)
  (define make-from-mag-ang cons)
  (define (real-part z)
    (mul (magnitude z) (cosine (angle z))))
  (define (imag-part z)
    (mul (magnitude z) (sine (angle z))))
  (define (make-from-real-imag x y)
    (cons (square-root (add (square x) (square y)))
          (atan2 y x)))
  (define (tag x) (attach-tag 'polar x))
  (put 'real-part '(polar) real-part)
  (put 'imag-part '(polar) imag-part)
  (put 'magnitude '(polar) magnitude)
  (put 'angle '(polar) angle)
  (put 'make-from-real-imag 'polar
       (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'polar
       (lambda (r a) (tag (make-from-mag-ang r a)))))

;; Next, we will rewrite the complex package:

(define (add-complex z1 z2)
  (make-from-real-imag (add (real-part z1) (real-part z2))
                       (add (imag-part z1) (imag-part z2))))
(define (sub-complex z1 z2)
  (make-from-real-imag (sub (real-part z1) (real-part z2))
                       (sub (imag-part z1) (imag-part z2))))
(define (mul-complex z1 z2)
  (make-from-mag-ang (mul (magnitude z1) (magnitude z2))
                     (add (angle z1) (angle z2))))
(define (div-complex z1 z2)
  (make-from-mag-ang (div (magnitude z1) (magnitude z2))
                     (sub (angle z1) (angle z2))))

(paste (:2.5.1 complex-pkg))

;; Finally, we need to fix some procedures in other packages that assumed a
;; complex number's real part and imaginary part were plain Scheme numbers.
;; Fixing `equ?` is tricky because the `equ?` from [](?2.79) used the old
;; `apply-generic` without coercion. That was fine since we only use it in
;; `drop` on `x` and `(raise (project x))`, which must be the same type. But
;; now, if they are complex numbers, their component types might be different.
;; So in the new `'complex` implementation of `equ?`, we need to recursively
;; invoke a version of `equ?` that supports coercion.
(define (complex-patch-pkg)
  (define (equ-with-coercion? x y) (apply-generic 'equ? x y))
  (put 'equ? '(complex complex)
       (lambda (z1 z2)
         (and (equ-with-coercion? (real-part z1) (real-part z2))
              (equ-with-coercion? (imag-part z1) (imag-part z2)))))
  (put 'raise '(real)
       (lambda (x) (make-complex-from-real-imag (make-real x) (make-real 0))))
  (put 'project '(complex)
       (lambda (x)
         (let ((r (real-part x)))
           (case (type-tag r)
             ((real) r)
             ((rational) (raise r))
             ((integer) (raise (raise r))))))))

;; Putting it all together:

(define (final-numeric-pkg)
  (integer-pkg)
  (rational-pkg)
  (real-pkg)
  (complex-pkg)
  (sqrt-trig-pkg)
  (equ-pkg)
  (raise-pkg)
  (project-pkg)
  (complex-patch-pkg))

(using final-numeric-pkg)

(add (make-complex-from-mag-ang (make-rational 1 2) (make-integer 0))
     (make-complex-from-real-imag (make-rational 3 4) (make-real 2)))
=> (make-complex-from-real-imag (make-rational 5 4) (make-integer 2))

(div (make-complex-from-mag-ang (make-integer 3) (make-real 1))
     (make-complex-from-mag-ang (make-rational 1 2) (make-real 1)))
=> (make-integer 6)

(Section :2.5.3 "Example: Symbolic Algebra")

(Section :2.5.3.1 "Arithmetic on polynomials"
  (use (:2.3.2 same-variable?)
       (:2.5.3.2 adjoin-term coeff empty-termlist? first-term make-term order
                 rest-terms the-empty-termlist)
       (:3.3.3.3 put) (?2.78 add attach-tag mul)))

;; We are following [](@2.5.fn58) and using the generic arithmetic system from
;; [](?2.78), where Scheme numbers are not explicitly tagged.

(define make-poly cons)
(define variable car)
(define term-list cdr)

(define (polynomial-pkg)
  (define (add-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (add-terms (term-list p1) (term-list p2)))
        (error 'add-poly "polys not in same var" p1 p2)))
  (define (mul-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1)
                   (mul-terms (term-list p1) (term-list p2)))
        (error 'mul-poly "polys not in same var" p1 p2)))
  (define (tag p) (attach-tag 'polynomial p))
  (put 'make 'polynomial (lambda (var terms) (tag (make-poly var terms))))
  (put 'add '(polynomial polynomial) (lambda (p1 p2) (tag (add-poly p1 p2))))
  (put 'mul '(polynomial polynomial) (lambda (p1 p2) (tag (mul-poly p1 p2)))))

(define (add-terms l1 l2)
  (cond ((empty-termlist? l1) l2)
        ((empty-termlist? l2) l1)
        (else
         (let ((t1 (first-term l1))
               (t2 (first-term l2)))
           (cond ((> (order t1) (order t2))
                  (adjoin-term t1
                               (add-terms (rest-terms l1) l2)))
                 ((< (order t1) (order t2))
                  (adjoin-term t2
                               (add-terms l1 (rest-terms l2))))
                 (else
                  (adjoin-term (make-term (order t1)
                                          (add (coeff t1) (coeff t2)))
                               (add-terms (rest-terms l1)
                                          (rest-terms l2)))))))))

(define (mul-terms l1 l2)
  (if (empty-termlist? l1)
      (the-empty-termlist)
      (add-terms (mul-term-by-all-terms (first-term l1) l2)
                 (mul-terms (rest-terms l1) l2))))

(define (mul-term-by-all-terms t1 l)
  (if (empty-termlist? l)
      (the-empty-termlist)
      (let ((t2 (first-term l)))
        (adjoin-term (make-term (+ (order t1) (order t2))
                                (mul (coeff t1) (coeff t2)))
                     (mul-term-by-all-terms t1 (rest-terms l))))))

(Section :2.5.3.2 "Representing term lists"
  (use (:2.4.3 apply-specific) (:3.3.3.3 put) (?2.78 apply-generic attach-tag)))

;; We have to use `apply-generic` below because importing `=zero?` from
;; [](?2.87) would cause an import cycle.
(define (adjoin-term term term-list)
  (if (apply-generic '=zero? (coeff term))
      term-list
      (cons term term-list)))

(define (the-empty-termlist) '())
(define first-term car)
(define rest-terms cdr)
(define empty-termlist? null?)

(define make-term list)
(define order car)
(define coeff cadr)

(define (make-polynomial var terms)
  (apply-specific 'make 'polynomial var terms))

;; This package is used in [](?2.90):
(define (sparse-termlist-pkg)
  (define (tag tl) (attach-tag 'sparse-termlist tl))
  (put 'make 'sparse-termlist tag)
  ;; Curried so that it only dispatches on the term list, not the term.
  (put 'adjoin-term '(sparse-termlist)
       (lambda (tl) (lambda (t) (tag (adjoin-term t tl)))))
  (put 'the-empty-termlist 'sparse-termlist
       (lambda () (tag (the-empty-termlist))))
  (put 'first-term '(sparse-termlist) first-term)
  (put 'rest-terms '(sparse-termlist) (lambda (tl) (tag (rest-terms tl))))
  (put 'empty-termlist? '(sparse-termlist) empty-termlist?))

(Exercise ?2.87
  (use (:2.4.3 using) (:2.5.3.1 polynomial-pkg term-list)
       (:2.5.3.2 coeff empty-termlist? first-term make-polynomial rest-terms)
       (:3.3.3.3 put) (?2.78 add apply-generic mul scheme-number-pkg)))

(define (zero-pkg)
  (define (poly-zero? p)
    (define (all-zero? terms)
      (or (empty-termlist? terms)
          (and (=zero? (coeff (first-term terms)))
               (all-zero? (rest-terms terms)))))
    (all-zero? (term-list p)))
  (put '=zero? '(scheme-number) zero?)
  (put '=zero? '(polynomial) poly-zero?))

(define (=zero? n) (apply-generic '=zero? n))

(using scheme-number-pkg polynomial-pkg zero-pkg)

(=zero? (make-polynomial 'x '())) => #t
(=zero? (make-polynomial 'x '((2 0)))) => #t
(=zero? (make-polynomial 'x '((2 1) (1 0)))) => #f

(add (make-polynomial 'x '((100 1) (2 3)))
     (make-polynomial 'x '((3 1) (2 2) (0 5))))
=> (make-polynomial 'x '((100 1) (3 1) (2 5) (0 5)))

(mul (make-polynomial 'x '((2 1) (0 1)))
     (make-polynomial 'x '((1 2))))
=> (make-polynomial 'x '((3 2) (1 2)))

(add (make-polynomial 'x '()) (make-polynomial 'y '()))
=!> "polys not in same var"

(Exercise ?2.88
  (use (:2.4.3 using) (:2.5.3.1 polynomial-pkg term-list variable)
       (:2.5.3.2 adjoin-term coeff empty-termlist? first-term make-polynomial
                 make-term order rest-terms the-empty-termlist)
       (:3.3.3.3 put) (?2.78 add apply-generic scheme-number-pkg)
       (?2.87 zero-pkg)))

(define (negate-terms tl)
  (if (empty-termlist? tl)
      (the-empty-termlist)
      (let* ((term (first-term tl))
             (new-term (make-term (order term) (negate (coeff term)))))
        (adjoin-term new-term
                     (negate-terms (rest-terms tl))))))

(define (negate-pkg)
  (put 'negate '(scheme-number) -)
  (put 'negate '(polynomial)
       (lambda (p)
         (make-polynomial (variable p) (negate-terms (term-list p))))))

(define (negate x) (apply-generic 'negate x))
(define (sub x y) (add x (negate y)))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg)

(negate 1) => -1
(sub 5 2) => 3

(negate (make-polynomial 'x '((2 1))))
=> (make-polynomial 'x '((2 -1)))

(sub (make-polynomial 'x '((3 1) (1 2)))
     (make-polynomial 'x '((2 2) (1 1) (0 -1))))
=> (make-polynomial 'x '((3 1) (2 -2) (1 1) (0 1)))

(Exercise ?2.89
  (use (:2.5.3.2 coeff empty-termlist? make-term order rest-terms
                 the-empty-termlist)
       (:3.3.3.3 put) (?2.78 attach-tag) (?2.87 =zero?)))

;; As mentioned in [](@2.5.fn59), we are assuming that `adjoin-term` is always
;; called with a higher-order term than appears in the list.

(define (adjoin-term term term-list)
  (let ((o (order term)))
    (define (iter term-list len)
      (cond ((< len o) (iter (cons 0 term-list) (+ len 1)))
            ((= len o) (cons (coeff term) term-list))
            (else (error 'adjoin-term "term list already has order" o))))
    (if (=zero? (coeff term))
        term-list
        (iter term-list (length term-list)))))

(define (first-term term-list)
  (make-term (- (length term-list) 1)
             (car term-list)))

(adjoin-term (make-term 3 1) (the-empty-termlist)) => '(1 0 0 0)
(first-term '(1 0 0 0)) => (make-term 3 1)

(adjoin-term (make-term 0 1) '(2)) =!> "term list already has order: 0"

;; This package is used in [](?2.90):
(define (dense-termlist-pkg)
  (define (tag tl) (attach-tag 'dense-termlist tl))
  (put 'make 'dense-termlist tag)
  ;; Curried so that it only dispatches on the term list, not the term.
  (put 'adjoin-term '(dense-termlist)
       (lambda (tl) (lambda (t) (tag (adjoin-term t tl)))))
  (put 'the-empty-termlist 'dense-termlist
       (lambda () (tag (the-empty-termlist))))
  (put 'first-term '(dense-termlist) first-term)
  (put 'rest-terms '(dense-termlist) (lambda (tl) (tag (rest-terms tl))))
  (put 'empty-termlist? '(dense-termlist) empty-termlist?))

(Exercise ?2.90
  (use (:2.3.2 same-variable?) (:2.4.3 apply-specific using)
       (:2.5.3.1 make-poly term-list variable)
       (:2.5.3.2 coeff make-polynomial make-term order sparse-termlist-pkg)
       (:3.3.3.3 put) (?2.78 add apply-generic attach-tag mul scheme-number-pkg)
       (?2.87 =zero?) (?2.88 negate sub) (?2.89 dense-termlist-pkg)))

;; To allow sparse and dense representations of polynomials to coexist, we must
;; redefine the arithmetic operations using generic term list selectors:

(define (the-empty-termlist)
  (apply-specific 'the-empty-termlist 'sparse-termlist))
(define (empty-termlist? tl) (apply-generic 'empty-termlist? tl))
(define (first-term tl) (apply-generic 'first-term tl))
(define (rest-terms tl) (apply-generic 'rest-terms tl))
(define (adjoin-term term tl) ((apply-generic 'adjoin-term tl) term))

(paste (:2.5.3.1 add-terms mul-term-by-all-terms mul-terms polynomial-pkg)
       (?2.87 zero-pkg) (?2.88 negate-pkg negate-terms))

(using sparse-termlist-pkg dense-termlist-pkg scheme-number-pkg polynomial-pkg
       zero-pkg negate-pkg)

;; Let's define some polynomials using a helper that infers the representation:

(define (poly var terms)
  (let ((type (if (or (null? terms) (pair? (car terms)))
                  'sparse-termlist
                  'dense-termlist)))
    (apply-specific 'make 'polynomial var (apply-specific 'make type terms))))

(define sparse-a (poly 'x '((3 3) (0 1))))
(define dense-a (poly 'x '(3 0 0 1)))

(define sparse-b (poly 'x '((2 3) (1 3) (0 2))))
(define dense-b (poly 'x '(0 3 3 2)))

(define sparse-a+b (poly 'x '((3 3) (2 3) (1 3) (0 3))))
(define dense-a+b (poly 'x '(3 3 3 3)))

(define sparse-a*b (poly 'x '((5 9) (4 9) (3 6) (2 3) (1 3) (0 2))))
(define dense-a*b (poly 'x '(9 9 6 3 3 2)))

;; Make sure the sparse and dense versions are equal:
(=zero? (sub sparse-a dense-a)) => #t
(=zero? (sub sparse-b dense-b)) => #t
(=zero? (sub sparse-a+b dense-a+b)) => #t
(=zero? (sub sparse-a*b dense-a*b)) => #t

;; For addition, the second argument determines the result's representation:
(add sparse-a sparse-b) => sparse-a+b
(add dense-a sparse-b) => sparse-a+b
(add dense-a dense-b) => dense-a+b
(add sparse-a dense-b) => dense-a+b

;; For multiplication, the result is always sparse:
(mul sparse-a sparse-b) => sparse-a*b
(mul dense-a sparse-b) => sparse-a*b
(mul dense-a dense-b) => sparse-a*b
(mul sparse-a dense-b) => sparse-a*b

(Exercise ?2.91
  (use (:2.3.2 same-variable?) (:2.4.3 using)
       (:2.5.3.1 add-terms mul-term-by-all-terms polynomial-pkg term-list
                 variable)
       (:2.5.3.2 adjoin-term coeff empty-termlist? first-term make-polynomial
                 make-term order the-empty-termlist)
       (:3.3.3.3 put) (?2.78 apply-generic div scheme-number-pkg)
       (?2.87 zero-pkg) (?2.88 negate-pkg negate-terms sub)))

(define (div-terms l1 l2)
  (if (empty-termlist? l1)
      (list (the-empty-termlist)
            (the-empty-termlist))
      (let ((t1 (first-term l1))
            (t2 (first-term l2)))
        (if (> (order t2) (order t1))
            (list (the-empty-termlist) l1)
            (let* ((new-c (div (coeff t1) (coeff t2)))
                   (new-o (sub (order t1) (order t2)))
                   (new-term (make-term new-o new-c))
                   (multiplied (mul-term-by-all-terms new-term l2))
                   (new-l1 (add-terms l1 (negate-terms multiplied)))
                   (rest-of-result (div-terms new-l1 l2)))
              (list (adjoin-term new-term (car rest-of-result))
                    (cadr rest-of-result)))))))

(define (polynomial-div-pkg)
  (define (div-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (let ((var (variable p1))
              (result (div-terms (term-list p1) (term-list p2))))
          (list (make-polynomial var (car result))
                (make-polynomial var (cadr result))))
        (error 'div-poly "polys not in same var" p1 p2)))
  (put 'div '(polynomial polynomial) div-poly))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg polynomial-div-pkg)

;; Now we can test the example given in the exercise:
;;
;; $$\frac{x^5 - 1}{x^2 - 1} = x^3 + x,\;\text{remainder}\;x - 1.$$
(div (make-polynomial 'x '((5 1) (0 -1)))
     (make-polynomial 'x '((2 1) (0 -1))))
=> (list (make-polynomial 'x '((3 1) (1 1)))
         (make-polynomial 'x '((1 1) (0 -1))))

;; And some other examples:

(div (make-polynomial 'x '((2 2)))
     (make-polynomial 'x '((1 2))))
=> (list (make-polynomial 'x '((1 1)))
         (make-polynomial 'x '()))

(div (make-polynomial 'x '((1 2)))
     (make-polynomial 'x '((2 2))))
=> (list (make-polynomial 'x '())
         (make-polynomial 'x '((1 2))))

(Section :2.5.3.3 "Hierarchies of types in symbolic algebra")

(Exercise ?2.92
  (use (:2.3.2 same-variable? variable?) (:2.4.3 using)
       (:2.5.3.1 add-terms make-poly mul-term-by-all-terms mul-terms term-list
                 variable)
       (:2.5.3.2 adjoin-term coeff empty-termlist? first-term make-polynomial
                 make-term order rest-terms the-empty-termlist)
       (:3.3.3.3 put)
       (?2.78 add attach-tag contents mul scheme-number-pkg type-tag)
       (?2.87 zero-pkg)))

;; To add or multiply of polynomials in different variables, we first need to
;; coerce them to a common variable. We'll choose the variable that comes first
;; alphabetically.
;;
;; Suppose we're coercing a polynomial from $y$ to $x$. For a term with a
;; numerical coefficient like $5y^2$, we'll change it to a constant term with a
;; polynomial coefficient: $(5y^2)x^0$. For a term with a polynomial coefficient
;; like $(3x+1)y^2$, we'll first coerce the coefficient to $x$ (already done)
;; and then multiply it by $(y^2)x^0$, resulting in $(3y^2)x^1+(y^2)x^0$. For
;; this to work, we need to support adding and multiplying Scheme numbers with
;; polynomials, since coefficients can be a mix of the two.

(define (polynomial-pkg)
  (define (singleton t)
    (adjoin-term t (the-empty-termlist)))
  (define (constant-term var term)
    (make-term 0 (make-polynomial var (singleton term))))
  (define (variable<? a b)
    (string<? (symbol->string a) (symbol->string b)))
  (define (principal-variable v1 v2)
    (if (variable<? v1 v2) v1 v2))
  (define (coerce-term t from to)
    (case (type-tag (coeff t))
      ((scheme-number) (singleton (constant-term from t)))
      ((polynomial)
       (let ((tl (term-list (coerce-poly (contents (coeff t)) to))))
         (if (zero? (order t))
             tl
             (mul-term-by-all-terms
              (constant-term from (make-term (order t) 1))
              tl))))
      (else (error 'coerce-term "invalid coeff type" (coeff t)))))
  (define (coerce-termlist tl from to)
    (if (empty-termlist? tl)
        tl
        (add-terms
         (coerce-term (first-term tl) from to)
         (coerce-termlist (rest-terms tl) from to))))
  (define (coerce-poly p var)
    (if (same-variable? (variable p) var)
        p
        (make-poly var (coerce-termlist (term-list p) (variable p) var))))
  (define (binary-op term-fn)
    (lambda (p1 p2)
      (let ((var (principal-variable (variable p1) (variable p2))))
        (make-poly var (term-fn (term-list (coerce-poly p1 var))
                                (term-list (coerce-poly p2 var)))))))
  (define add-poly (binary-op add-terms))
  (define mul-poly (binary-op mul-terms))
  (define (add-mixed x p)
    (make-poly (variable p)
               (add-terms (singleton (make-term 0 x)) (term-list p))))
  (define (mul-mixed x p)
    (make-poly (variable p)
               (map (lambda (t) (make-term (order t) (mul x (coeff t))))
                    (term-list p))))
  (define (tag p) (attach-tag 'polynomial p))
  (put 'make 'polynomial (lambda (var terms) (tag (make-poly var terms))))
  (put 'add '(polynomial polynomial) (lambda (p1 p2) (tag (add-poly p1 p2))))
  (put 'mul '(polynomial polynomial) (lambda (p1 p2) (tag (mul-poly p1 p2))))
  (put 'add '(scheme-number polynomial) (lambda (x p) (tag (add-mixed x p))))
  (put 'add '(polynomial scheme-number) (lambda (p x) (tag (add-mixed x p))))
  (put 'mul '(scheme-number polynomial) (lambda (x p) (tag (mul-mixed x p))))
  (put 'mul '(polynomial scheme-number) (lambda (p x) (tag (mul-mixed x p)))))

(using scheme-number-pkg polynomial-pkg zero-pkg)

;; Here's a simple test:
;;
;; $$x + y = y + x = 1x^1 + \left(1y^1\right)x^0.$$
(add (make-polynomial 'x '((1 1))) (make-polynomial 'y '((1 1))))
=> (add (make-polynomial 'y '((1 1))) (make-polynomial 'x '((1 1))))
=> (make-polynomial 'x `((1 1) (0 ,(make-polynomial 'y '((1 1))))))

;; Here's a more complicated test:
;;
;; $$
;; \begin{aligned}
;; &\phantom{=} (yx^3 + 2)(y + x^2 + 1) \\
;; &= \left(1y^1\right)x^5 + \left(1y^2 + 1y^1\right)x^3 + 2x^2
;; + \left(2y^1 + 2y^0\right)x^0.
;; \end{aligned}
;; $$
(mul (make-polynomial 'x `((3 ,(make-polynomial 'y '((1 1)))) (0 2)))
     (make-polynomial 'y `((1 1) (0 ,(make-polynomial 'x '((2 1) (0 1)))))))
=> (make-polynomial 'x `((5 ,(make-polynomial 'y '((1 1))))
                         (3 ,(make-polynomial 'y '((2 1) (1 1))))
                         (2 2)
                         (0 ,(make-polynomial 'y '((1 2) (0 2))))))

(Section :2.5.3.4 "Extended exercise: Rational functions")

(Exercise ?2.93
  (use (:2.1.1 denom numer) (:2.4.3 using) (:2.5.1 make-rational)
       (:2.5.3.1 polynomial-pkg) (:2.5.3.2 make-polynomial) (:3.3.3.3 put)
       (?2.78 add attach-tag div mul scheme-number-pkg sub) (?2.87 zero-pkg)))

(define (make-rat n d) (cons n d))

(define (add-rat x y)
  (make-rat (add (mul (numer x) (denom y))
                 (mul (numer y) (denom x)))
            (mul (denom x) (denom y))))
(define (sub-rat x y)
  (make-rat (sub (mul (numer x) (denom y))
                 (mul (numer y) (denom x)))
            (mul (denom x) (denom y))))
(define (mul-rat x y)
  (make-rat (mul (numer x) (numer y))
            (mul (denom x) (denom y))))
(define (div-rat x y)
  (make-rat (mul (numer x) (denom y))
            (mul (denom x) (numer y))))

(paste (:2.5.1 rational-pkg))

(using scheme-number-pkg zero-pkg polynomial-pkg rational-pkg)

;; This gives a correct answer, but does not reduce it to lowest terms:
;;
;; $$
;; \frac{x^3 + 1}{x^2 + 1} + \frac{x^3 + 1}{x^2 + 1}
;; = \frac{2x^5 + 2x^3 + 2x^2 + 2}{x^4 + 2x^2 + 1}.
;; $$

(define p1 (make-polynomial 'x '((2 1) (0 1))))
(define p2 (make-polynomial 'x '((3 1) (0 1))))
(define rf (make-rational p2 p1))

(add rf rf)
=> (make-rational (make-polynomial 'x '((5 2) (3 2) (2 2) (0 2)))
                  (make-polynomial 'x '((4 1) (2 2) (0 1))))

(Exercise ?2.94
  (use (:2.3.2 same-variable?) (:2.4.3 using)
       (:2.5.3.1 polynomial-pkg term-list variable)
       (:2.5.3.2 empty-termlist? make-polynomial) (:3.3.3.3 put)
       (?2.78 apply-generic scheme-number-pkg) (?2.87 zero-pkg)
       (?2.88 negate-pkg) (?2.91 div-terms)))

(define (remainder-terms l1 l2)
  (cadr (div-terms l1 l2)))

(define (gcd-terms a b)
  (if (empty-termlist? b)
      a
      (gcd-terms b (remainder-terms a b))))

(define (greatest-common-divisor-pkg)
  (define (gcd-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (let ((tl (gcd-terms (term-list p1) (term-list p2))))
          (make-polynomial (variable p1) tl))
        (error 'gcd-poly "polys not in same var" p1 p2)))
  (put 'greatest-common-divisor '(scheme-number scheme-number) gcd)
  (put 'greatest-common-divisor '(polynomial polynomial) gcd-poly))

(define (greatest-common-divisor a b)
  (apply-generic 'greatest-common-divisor a b))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg
       greatest-common-divisor-pkg)

;; Now it works for integers:
(greatest-common-divisor 128 40) => 8

;; And for polynomials:

(define p1 (make-polynomial 'x '((4 1) (3 -1) (2 -2) (1 2))))
(define p2 (make-polynomial 'x '((3 1) (1 -1))))

(greatest-common-divisor p1 p2)
=> (make-polynomial 'x '((2 -1) (1 1)))

(Exercise ?2.95
  (use (:2.4.2 contents) (:2.4.3 using) (:2.5.3.1 polynomial-pkg term-list)
       (:2.5.3.2 make-polynomial the-empty-termlist)
       (?2.78 mul scheme-number-pkg) (?2.87 zero-pkg) (?2.88 negate-pkg)
       (?2.91 polynomial-div-pkg)
       (?2.94 gcd-terms greatest-common-divisor greatest-common-divisor-pkg
              remainder-terms)))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg polynomial-div-pkg
       greatest-common-divisor-pkg)

(define p1 (make-polynomial 'x '((2 1) (1 -2) (0 1))))
(define p2 (make-polynomial 'x '((2 11) (0 7))))
(define p3 (make-polynomial 'x '((1 13) (0 5))))
(define q1 (mul p1 p2))
(define q2 (mul p1 p3))

;; For brevity, we'll give names to the term lists of $Q_1$ and $Q_2$:
(define q1-tl (term-list (contents q1)))
(define q2-tl (term-list (contents q2)))

;; Tracing through the GCD calculation, we see that it reduces to the remainder
;; of dividing the original two polynomials:
(gcd-terms q1-tl q2-tl)
=> (gcd-terms q2-tl (remainder-terms q1-tl q2-tl))
=> (gcd-terms (remainder-terms q1-tl q2-tl)
              (remainder-terms q2-tl (remainder-terms q1-tl q2-tl)))
=> (gcd-terms (remainder-terms q1-tl q2-tl)
              (the-empty-termlist))
=> (remainder-terms q1-tl q2-tl)
=> '((2 1458/169) (1 -2916/169) (0 1458/169))

;; The problem is that `div-terms` from [](?2.91) calls `div` on coefficients,
;; so they end up as fractions. In this case, we have to multiply by a factor of
;; $169/1458$ to get the desired answer, $P_1$:
(mul (greatest-common-divisor q1 q2)
     (make-polynomial 'x '((0 169/1458))))
=> p1

(Exercise ?2.96
  (use (:2.2.3.1 accumulate) (:2.3.2 same-variable?) (:2.4.3 using)
       (:2.5.3.1 mul-term-by-all-terms polynomial-pkg term-list variable)
       (:2.5.3.2 coeff empty-termlist? first-term make-polynomial make-term
                 order rest-terms)
       (:3.3.3.3 put) (?2.78 mul scheme-number-pkg) (?2.87 zero-pkg)
       (?2.88 negate-pkg) (?2.91 div-terms polynomial-div-pkg)
       (?2.94 greatest-common-divisor remainder-terms) (?2.95 p1 q1 q2)))

(paste (?2.94 greatest-common-divisor-pkg))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg polynomial-div-pkg
       greatest-common-divisor-pkg)

;; (a) Polynomial GCD with integer coefficients:

(define (pseudoremainder-terms l1 l2)
  (let* ((o1 (order (first-term l1)))
         (o2 (order (first-term l2)))
         (c (coeff (first-term l2)))
         (integerizing-factor (expt c (+ 1 o1 (- o2))))
         (term (make-term 0 integerizing-factor))
         (ml1 (mul-term-by-all-terms term l1)))
    (remainder-terms ml1 l2)))

(define (gcd-terms a b)
  (if (empty-termlist? b)
      a
      (gcd-terms b (pseudoremainder-terms a b))))

(greatest-common-divisor q1 q2)
=> (make-polynomial 'x '((2 1458) (1 -2916) (0 1458)))
=> (mul p1 (make-polynomial 'x '((0 1458))))

;; (b) Polynomial GCD with reduced integer coefficients:

(define (termlist-coeffs tl)
  (if (empty-termlist? tl)
      '()
      (cons (coeff (first-term tl))
            (termlist-coeffs (rest-terms tl)))))

(define (gcd-terms a b)
  (if (empty-termlist? b)
      (let* ((cs (termlist-coeffs a))
             (coeff-gcd (accumulate gcd (car cs) (cdr cs))))
        (mul-term-by-all-terms (make-term 0 (/ coeff-gcd)) a))
      (gcd-terms b (pseudoremainder-terms a b))))

(greatest-common-divisor q1 q2)
=> (make-polynomial 'x '((2 1) (1 -2) (0 1)))
=> p1

(Exercise ?2.97
  (use (:2.1.1 denom numer) (:2.2.3.1 accumulate) (:2.3.2 same-variable?)
       (:2.4.3 using) (:2.5.1 make-rational)
       (:2.5.3.1 mul-term-by-all-terms polynomial-pkg term-list variable)
       (:2.5.3.2 coeff first-term make-polynomial make-term order)
       (:3.3.3.3 put)
       (?2.78 add apply-generic attach-tag div mul scheme-number-pkg sub)
       (?2.87 zero-pkg) (?2.88 negate-pkg) (?2.91 div-terms polynomial-div-pkg)
       (?2.96 gcd-terms termlist-coeffs)))

;; (a) Reducing a rational function to lowest terms:

(define (termlist-order tl) (order (first-term tl)))
(define (quotient-terms l1 l2) (car (div-terms l1 l2)))

(define (reduce-terms n d)
  (let* ((nd-gcd (gcd-terms n d))
         (leading-coeff (coeff (first-term nd-gcd)))
         (exponent (+ 1
                      (max (termlist-order n) (termlist-order d))
                      (- (termlist-order nd-gcd))))
         (integerizing-factor (expt leading-coeff exponent))
         (term1 (make-term 0 integerizing-factor))
         (n/gcd (quotient-terms (mul-term-by-all-terms term1 n) nd-gcd))
         (d/gcd (quotient-terms (mul-term-by-all-terms term1 d) nd-gcd))
         (all-coeffs (append (termlist-coeffs n/gcd)
                             (termlist-coeffs d/gcd)))
         (coeff-gcd (accumulate gcd (car all-coeffs) (cdr all-coeffs)))
         (term2 (make-term 0 (/ coeff-gcd)))
         (nn (mul-term-by-all-terms term2 n/gcd))
         (dd (mul-term-by-all-terms term2 d/gcd)))
    (list nn dd)))

(define (reduce-poly n d)
  (if (same-variable? (variable n) (variable d))
      (let ((var (variable n))
            (reduced (reduce-terms (term-list n) (term-list d))))
        (list (make-polynomial var (car reduced))
              (make-polynomial var (cadr reduced))))
      (error 'reduce-poly "polys not in same var" n d)))

;; (b) Rational arithmetic system supporting integers and polynomials:

(define (reduce-integers n d)
  (let ((g (gcd n d)))
    (list (/ n g) (/ d g))))

(define (reduce-pkg)
  (put 'reduce '(scheme-number scheme-number) reduce-integers)
  (put 'reduce '(polynomial polynomial) reduce-poly))

(define (reduce n d) (apply-generic 'reduce n d))

(define (make-rat n d)
  (let ((reduced (reduce n d)))
    (cons (car reduced) (cadr reduced))))

(paste (:2.5.1 rational-pkg) (?2.93 add-rat div-rat mul-rat sub-rat))

(using scheme-number-pkg polynomial-pkg zero-pkg negate-pkg polynomial-div-pkg
       rational-pkg reduce-pkg)

;;     Now it works for integers: $\displaystyle\frac{4}{7} + \frac{30}{33}
;;     = \frac{114}{77}.$
(add (make-rational 4 7) (make-rational 30 33))
=> (make-rational 114 77)

;;     And for polynomials: $\displaystyle\frac{x + 1}{x^3 - 1}
;;     + \frac{x}{x^2 - 1} = \frac{x^3 + 2x^2 + 3x + 1}{x^4 + x^3 - x - 1}.$

(define p1 (make-polynomial 'x '((1 1) (0 1))))
(define p2 (make-polynomial 'x '((3 1) (0 -1))))
(define p3 (make-polynomial 'x '((1 1))))
(define p4 (make-polynomial 'x '((2 1) (0 -1))))

(define rf1 (make-rational p1 p2))
(define rf2 (make-rational p3 p4))

(add rf1 rf2)
=> (make-rational (make-polynomial 'x '((3 1) (2 2) (1 3) (0 1)))
                  (make-polynomial 'x '((4 1) (3 1) (1 -1) (0 -1))))

) ; end of SICP
) ; end of library
