#lang racket/base
(provide pages)

(require
 racket/match
 racket/date
 racket/path
 racket/list
 markdown)

;; -------------------------------------------------------------------
;; General page template

(define BLOG-TITLE
  "Milo Turner")

(define NAV
  `{(index "Home")
    (agda "Agda")
    (rkt "Racket")
    (archive "Archive")
    (about "About")})

(define footer/x
  "\xa9 Milo Turner")

;; string xexpr -> xexpr
(define (entire-page/x #:title title
                       #:page [pg #f]
                       content)
  `(html (head (title ,(format "~a - ~a" BLOG-TITLE title))
               (meta ([charset "utf8"]))
               ,@css/x)
         (body (main (header ,title/x ,(nav/x pg))
                     ,content
                     (footer ,footer/x)))))

(define css/x
  (list `(link ([href "style.css"]
                [rel "stylesheet"]))))

(define title/x
  `(div ([class "title"])
        (a ([href "index.html"])
           (h1 ,BLOG-TITLE))))

;; symbol -> xexpr
(define (nav/x active-pg)
  `(nav (ul ,@(for/list ([x (in-list NAV)])
                (match-define (list pg title) x)
                (define cls
                  (if (eq? pg active-pg)
                      "active"
                      ""))
                `(li ([class ,cls])
                     (a ([href ,(format "~a.html" pg)])
                        ,title))))))

;; -------------------------------------------------------------------
;; Blogpost pages

;; page-url : string
;; title : string
;; date : date
;; tags : [listof string]
;; content : [listof xexpr]
(struct blogpost [page-url title date tags content]
  #:transparent)

;; [listof blogpost]
(define blogposts
  (for*/list ([path (in-directory "src/posts" (λ (dir) #f))]
              [filename (in-value (let-values ([(b fn dir?) (split-path path)]) fn))]
              #:when (equal? (path-get-extension filename) #".md")
              [page-url (in-value (path-replace-extension filename #""))]
              [meta-path (in-value (path-replace-extension path #".meta.rktd"))]
              [meta (in-value (if (file-exists? meta-path)
                                  (with-input-from-file meta-path read)
                                  '()))])
    (define content (parse-markdown path))
    (blogpost page-url
              (match (assoc 'title meta)
                [(list _ title) title]
                [_ (for/first ([el (in-list content)]
                               #:when (eq? (car el) 'h1))
                     (caddr el))])
              (match (assoc 'date meta)
                [(list _ (list yr mn dy)) (make-date 0 0 0 dy mn yr 0 0 #t 0)]
                [_ (current-date)])
              (match (assoc 'tags meta)
                [(list _ tags) tags]
                [_ '()])
              content)))

(define (blogpost->xexpr bp
                         #:page [active-pg #f])

  ;; xexpr -> [listof xexpr]
  (define (transform-element e)
    (match e
      [`(h3 ,x ...) (list `(h4 ,@x))]
      [`(h2 ,x ...) (list `(h3 ,@x))]
      [`(h1 ,x ...) (list `(h2 ,@x)
                          `(time ([datetime ,date/attr])
                                 ,date/pretty))]
      [_ (list e)]))

  (define date/pretty
    (parameterize ([date-display-format 'american])
      (date->string (blogpost-date bp))))

  (define date/attr
    (parameterize ([date-display-format 'iso-8601])
      (date->string (blogpost-date bp))))

  (define body/x
    `(article ,@(append-map transform-element
                            (blogpost-content bp))))

  (entire-page/x #:title (blogpost-title bp)
                 #:page active-pg
                 body/x))

;; -------------------------------------------------------------------
;; Non-blogpost pages

(define about/x
  `(article
    (h2 "About")
    (h3 "Nothing here.")
    (p "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow
corned beef. Ham hock chicken shoulder brisket tri-tip ground round pig short
ribs sirloin swine cupim fatback tail tenderloin chuck. Ham burgdoggen venison
tenderloin doner brisket pork chop, rump strip steak chuck tail. Salami pork
chop cow, turkey leberkas pancetta swine ham hock ground round shank hamburger
alcatra kielbasa venison. Kielbasa ball tip bacon spare ribs meatloaf
porchetta beef ribs biltong strip steak ground round ribeye. Leberkas shank
venison filet mignon buffalo picanha. Strip steak beef ribs pastrami shank
corned beef.")))

(define archive/x
  `(article
    (h2 "Archive")
    (h3 "Nothing here.")))

(define other-pages
  `{(about "About" ,about/x)
    (archive "Archive" ,archive/x)})

;; -------------------------------------------------------------------

(define homepage-blogpost
  (car blogposts))

(define pages
  (append
   ;; pages that are just index pages for now
   (for/list ([n `{(index "Home")
                   (agda "Agda")
                   (rkt "Racket")}])
     (match-define (list pg title) n)
     (list pg
           title
           (blogpost->xexpr homepage-blogpost
                            #:page pg)))

   ;; blogposts
   (for/list ([bp (in-list blogposts)])
     (list (blogpost-page-url bp)
           (blogpost-title bp)
           (blogpost->xexpr bp)))

   ;; other pages
   (for/list ([x (in-list other-pages)])
     (match-define (list pg title content) x)
     (list pg title (entire-page/x #:title title
                                   #:page pg
                                   content)))))
