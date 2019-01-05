#lang racket/base
(require
 racket/match
 racket/date
 racket/path
 racket/list
 markdown
 threading
 (prefix-in xml: xml)
 (prefix-in gg: gregor)
 "../src/index.rkt")

;; -------------------------------------------------------------------
;; General page template

;; xexpr -> xexpr
;;   #:title string
;;   [#:page symbol]

(define (entire-page/x #:title title
                       #:page [active-pg #f]
                       content)

  (define meta/x
    `(head (title ,(format "~a - ~a" BLOG-TITLE title))
           (meta ([charset "utf8"]))
           ,@(for/list ([ss (in-list STYLESHEETS)])
               `(link ([href ,ss] [rel "stylesheet"])))))

  (define title/x
    `(div ([class "title"])
          (a ([href "index.html"])
             (h1 ,BLOG-TITLE))))

  (define nav/x
    `(nav (ul ,@(for/list ([x (in-list NAV)])
                  (match-define (list* pg title _) x)
                  (define cls
                    (if (eq? pg active-pg)
                        "active"
                        ""))
                  `(li ([class ,cls])
                       (a ([href ,(format "~a.html" pg)])
                          ,title))))))

  `(html ,meta/x
         (body (main (header ,title/x ,nav/x)
                     ,content
                     ,FOOTER))))

;; -------------------------------------------------------------------
;; Blogposts

;; page-url : string
;; title : string
;; date : date
;; tags : [listof string]
;; content : [listof xexpr]
(struct blogpost [page-url title date tags content]
  #:transparent)

;; blogpost               -> xexpr
;; blogpost #:page symbol -> xexpr
(define (blogpost->xexpr bp #:page [active-pg #f])

  ;; xexpr -> [listof xexpr]
  (define (transform-element e)
    (match e
      ;; "lower" the header tags, and insert timestring after h1
      [`(h3 ,x ...) (list `(h4 ,@x))]
      [`(h2 ,x ...) (list `(h3 ,@x))]
      [`(h1 ,x ...) (list `(h2 ,@x)
                          `(time ([datetime ,date/attr])
                                 ,date/pretty))]
      [_ (list e)]))

  (define date/pretty
    (gg:~t (blogpost-date bp) "MMMM dd, YYYY"))
  (define date/attr
    (gg:~t (blogpost-date bp) "YYYY-MM-dd"))

  (define body/x
    `(article ,@(append-map transform-element
                            (blogpost-content bp))))

  (entire-page/x #:title (blogpost-title bp)
                 #:page active-pg
                 body/x))

;; [listof blogpost]
(define ALL-BLOGPOSTS
  (for*/list ([path (in-directory "src/posts" (λ (dir) #f))]
              [filename (in-value (let-values ([(b fn dir?) (split-path path)]) fn))]
              #:when (equal? (path-get-extension filename) #".md")
              [page-url (in-value (path-replace-extension filename #""))]
              [meta-path (in-value (path-replace-extension path #".meta.rktd"))]
              [meta (in-value (if (file-exists? meta-path)
                                  (with-input-from-file meta-path read)
                                  '()))])
    (define content
      (parse-markdown path))
    (define title
      (match (assoc 'title meta)
        [(list _ title) title]
        [_ (for/first ([el (in-list content)]
                       #:when (eq? (car el) 'h1))
             (caddr el))]))
    (define date
      (match (assoc 'date meta)
        [(list _ (list yr mn dy)) (gg:date yr mn dy)]
        [_ (error "no date specified in metadata")]))
    (define tags
      (match (assoc 'tags meta)
        [(list _ tags) tags]
        [_ '()]))
    (blogpost page-url title date tags content)))

(define HOMEPAGE-BLOGPOST
  (argmax (λ~> blogpost-date gg:->jdn)
          ALL-BLOGPOSTS))

;; -------------------------------------------------------------------
;; Assemble the site from parts

(define NAV
  (cons (list 'index "Home")
        OTHER-PAGES))

(define ALL-PAGES
  (append
   (list (list 'index
               (blogpost-title HOMEPAGE-BLOGPOST)
               (blogpost->xexpr HOMEPAGE-BLOGPOST
                                #:page 'index)))

   ;; blogposts
   (for/list ([bp (in-list ALL-BLOGPOSTS)])
     (list (blogpost-page-url bp)
           (blogpost-title bp)
           (blogpost->xexpr bp)))

   ;; other pages
   (for/list ([x (in-list OTHER-PAGES)])
     (match-define (list pg title content) x)
     (list pg title (entire-page/x #:title title
                                   #:page pg
                                   content)))))

;; -------------------------------------------------------------------
;; Render to files

(for ([x (in-list ALL-PAGES)])
  (match-define (list pg title xexpr) x)
  (printf "generating: ~v\n" title)
  (with-output-to-file
    (format "output/~a.html" pg)
    #:exists 'replace
    (λ ()
      (xml:write-xexpr xexpr))))
