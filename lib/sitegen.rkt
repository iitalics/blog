#lang racket/base
(require
 racket/match
 xml
 "../src/index.rkt")

(for ([x (in-list pages)])
  (match-define (list title pg gen-fn) x)
  (printf "generating: ~v\n" title)
  (with-output-to-file
    (format "output/~a.html" pg)
    #:exists 'replace
    (λ ()
      (write-xexpr (gen-fn)))))
