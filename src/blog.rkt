#lang racket/base
(provide
 BLOG-TITLE
 STYLESHEETS
 FOOTER
 OTHER-PAGES)

;; -------------------------------------------------------------------
;; General info

(define BLOG-TITLE
  "Milo Turner")

(define FOOTER
  `(footer "\xa9 Milo Turner"))

(define STYLESHEETS
  '("style.css"))

;; -------------------------------------------------------------------
;; Non-blogpost pages

(define about/x
  `(article
    (h2 "About")
    (h3 "WIP")))

(define archive/x
  `(article
    (h2 "Archive")
    (h3 "WIP")))

(define OTHER-PAGES
  `{(archive "Archive" ,archive/x)
    (about "About" ,about/x)})
