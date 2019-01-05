#lang racket/base
(require
 racket/match
 racket/date
 racket/path
 racket/list
 racket/set
 markdown
 threading
 (prefix-in xml: xml)
 (prefix-in gg: gregor)
 "../src/blog.rkt")

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
                  (match-define (list* target name _) x)
                  (define attrs (if (string? target)
                                    `([href ,target] [target "_blank"])
                                    `([href ,(format "~a.html" target)])))
                  (define cls (cond
                                [(string? target) "external"]
                                [(eq? target active-pg) "active"]
                                [else "inactive"]))
                  `(li ([class ,cls])
                       (a ,attrs
                          ,name))))))

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

  (define (transform-element e)
    (match e
      ;; "lower" the header tags, and insert meta info after h1
      [`(h3 ,x ...) (list `(h4 ,@x))]
      [`(h2 ,x ...) (list `(h3 ,@x))]
      [`(h1 ,x ...) (list `(h2 ,@x) (blogpost-meta/x bp))]
      [_ (list e)]))

  (define body/x
    `(article ,@(append-map transform-element
                            (blogpost-content bp))))

  (entire-page/x #:title (blogpost-title bp)
                 #:page active-pg
                 body/x))

;; blogpost -> xexpr
(define (blogpost-meta/x bp)
  (define date/pretty
    (gg:~t (blogpost-date bp) DATE-FORMAT))
  (define date/attr
    (gg:~t (blogpost-date bp) "YYYY-MM-dd"))
  `(small
    (time ([datetime ,date/attr]) ,date/pretty)
    " | tagged: "
    ,@(~> (for/list ([t (in-list (blogpost-tags bp))])
            `(a ([class "tag"]
                 [href ,(format "~a.html" t)])
                ,(format "#~a" t)))
          (add-between _ `(span ([class "tag-sep"])
                                "\xb7")))))

;; string -> xexpr
;; string #:collection [listof blogpost] -> xexpr
(define (all-tagged/x t #:collection [bps ALL-BLOGPOSTS])
  (entire-page/x #:title (format "Tagged #~a" t)
                 #:page t
                 `(article
                   (h3 ,(format "Posts tagged \"#~a\"" t))
                   (hr)
                   ,@(for/list ([bp (in-list bps)]
                                #:when (memq t (blogpost-tags bp)))
                       (link-to-blogpost/x bp)))))

;; blogpost -> xexpr
(define (link-to-blogpost/x bp)
  `(div ([class "link-to-post"])
        (a ([href ,(format "~a.html" (blogpost-page-url bp))])
           (h4 ,(blogpost-title bp)))
        ,(blogpost-meta/x bp)))

;; [listof blogpost]
(define ALL-BLOGPOSTS
  (~> (for*/list ([path (in-directory "posts" (λ (dir) #f))]
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
        (blogpost page-url title date tags content))

      ;; sort posts chronologically
      (sort _ gg:date>? #:key blogpost-date)))

(define ALL-TAGS
  (for*/fold ([tags (set)]
              #:result (set->list tags))
             ([bp (in-list ALL-BLOGPOSTS)]
              [t (in-list (blogpost-tags bp))])
    (set-add tags t)))

;; -------------------------------------------------------------------
;; Assemble the site from parts

(define NAV
  `{(index "Home")
    ,@OTHER-PAGES
    ,@OTHER-NAV})

(define ALL-PAGES
  (append
   (list (list 'index
               (~> ALL-BLOGPOSTS
                   (map link-to-blogpost/x _)
                   HOMEPAGE
                   (entire-page/x #:title "Home"
                                  #:page 'index))))

   ;; blogposts
   (for/list ([bp (in-list ALL-BLOGPOSTS)])
     (list (blogpost-page-url bp)
           (blogpost->xexpr bp)))

   ;; tags
   (for/list ([t (in-list ALL-TAGS)])
     (list t (all-tagged/x t)))

   ;; other pages
   (for/list ([x (in-list OTHER-PAGES)])
     (match-define (list pg title content) x)
     (list pg (entire-page/x #:title title
                             #:page pg
                             content)))))

;; -------------------------------------------------------------------
;; Render to files

(for ([x (in-list ALL-PAGES)])
  (match-define (list pg xexpr) x)
  (with-output-to-file
    (format "output/~a.html" pg)
    #:exists 'replace
    (λ ()
      (xml:write-xexpr xexpr))))
