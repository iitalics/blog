#lang racket/base
(provide
 BLOG-TITLE
 FOOTER
 HOMEPAGE
 STYLESHEETS
 DATE-FORMAT
 OTHER-PAGES
 OTHER-NAV)

;; -------------------------------------------------------------------
;; General info

(define BLOG-TITLE
  "Milo Turner")

(define FOOTER
  `(footer "\xa9 Milo Turner"))

(define STYLESHEETS
  '("style.css"))

(define DATE-FORMAT
  "MM/dd/YYYY")

;; -------------------------------------------------------------------
;; Non-blogpost pages

(define (HOMEPAGE blogpost-links)
  `(article
    (h3 "Archive")
    (hr)
    ,@blogpost-links))

(define about/x
  `(article
    (h2 "About")
    (hr)
    (h3 "WIP")))

(define OTHER-PAGES
  `{(about "About" ,about/x)})

(define OTHER-NAV
  '{(agda "#agda")
    (racket "#racket")
    ("https://github.com/iitalics/" "Github")
    ("http://www.ccs.neu.edu/home/milo/resumeMiloTurner.pdf" "CV")})
