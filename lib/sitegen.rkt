#lang racket/base
(require
 racket/match
 xml
 "../src/index.rkt")

(for ([x (in-list ALL-PAGES)])
  (match-define (list pg title xexpr) x)
  (printf "generating: ~v\n" title)
  (with-output-to-file
    (format "output/~a.html" pg)
    #:exists 'replace
    (λ ()
      (write-xexpr xexpr))))
