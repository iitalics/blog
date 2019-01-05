#lang racket/base
(provide
 BLOG-TITLE
 footer/x
 homepage/x
 STYLESHEETS
 DATE-FORMAT
 OTHER-PAGES
 OTHER-NAV)

;; -------------------------------------------------------------------
;; Options

(define BLOG-TITLE
  "Milo Turner")

(define STYLESHEETS
  '("style.css"))

(define DATE-FORMAT
  "MM/dd/YYYY")

;; -------------------------------------------------------------------
;; X expressions

(define footer/x
  `(footer "\xa9 Milo Turner"))

(define (homepage/x blogpost-links)
  `(article
    (h3 "Archive")
    (hr)
    ,@blogpost-links))

(define about/x
  `(article
    (h2 "About")
    (hr)
    (h3 "WIP")))

;; -------------------------------------------------------------------
;; Nav

(define OTHER-PAGES
  `{(about "About" ,about/x)})

(define OTHER-NAV
  '{(agda "#agda")
    (racket "#racket")
    ("https://github.com/iitalics/" "Github")
    ("http://www.ccs.neu.edu/home/milo/resumeMiloTurner.pdf" "CV")})
