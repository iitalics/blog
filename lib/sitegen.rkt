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

(define NAV
  `{(index "Home")
    ,@OTHER-PAGES
    ,@OTHER-NAV})

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
                     ,footer/x))))

;; -------------------------------------------------------------------
;; Blogposts

;; page-url : string
;; title : string
;; date : date
;; tags : [listof string]
;; content : [listof xexpr]
(struct blogpost [page-url title date tags content]
  #:transparent)

;; Returns xexpr of entire blogpost rendered.
;;
;; blogpost               -> xexpr
;; blogpost #:page symbol -> xexpr
(define (blogpost/x bp #:page [active-pg #f])

  (define (transform-p-element e)
    (match e
      [`(a ,attrs ,txt ...)
       ;; Make links open in new window
       `(a ([target "_blank"] ,@attrs) ,@txt)]
      [_ e]))

  (define (transform-element e)
    (match e
      ;; "lower" the header tags, and insert meta info after h1
      [`(h3 ,x ...) (list `(h4 ,@x))]
      [`(h2 ,x ...) (list `(h3 ,@x))]
      [`(h1 ,x ...) (list `(h2 ,@x) (blogpost-meta/x bp))]
      [`(p ,x ...) (list `(p ,@(map transform-p-element x)))]
      [_ (list e)]))

  (define body/x
    `(article ,@(append-map transform-element
                            (blogpost-content bp))))

  (entire-page/x #:title (blogpost-title bp)
                 #:page active-pg
                 body/x))

;; Returns the xexpr of the meta info line (date, tags) for a blogpost.
;;
;; blogpost -> xexpr
(define (blogpost-meta/x bp)
  (define date/pretty (gg:~t (blogpost-date bp) DATE-FORMAT))
  (define date/attr (gg:~t (blogpost-date bp) "YYYY-MM-dd"))
  `(small
    (time ([datetime ,date/attr]) ,date/pretty)
    " | tagged: "
    ,@(~> (for/list ([t (in-list (blogpost-tags bp))])
            `(a ([class "tag"]
                 [href ,(format "~a.html" t)])
                ,(format "#~a" t)))
          (add-between _ `(span ([class "tag-sep"]) "\xb7")))))

;; Returns the xexpr for the page listing all blogposts with the given tag.
;;
;; symbol -> xexpr
;; symbol #:collection [listof blogpost] -> xexpr
(define (all-tagged/x t #:collection [bps ALL-BLOGPOSTS])
  (entire-page/x #:title (format "Tagged #~a" t)
                 #:page t
                 `(article
                   (h3 ,(format "Posts tagged \"#~a\"" t))
                   (hr)
                   ,@(for/list ([bp (in-list bps)]
                                #:when (memq t (blogpost-tags bp)))
                       (link-to-blogpost/x bp)))))

;; Returns the xexpr element for a large link to the given blogpost.
;;
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
                  #:when (equal? (path-get-extension filename) #".md"))

        ;; load metadata
        (define meta-path
          (path-replace-extension path #".meta.rktd"))
        (define meta
          (if (file-exists? meta-path)
              (with-input-from-file meta-path read)
              '()))

        ;; parse markdown content and extract data from it
        (define content
          (parse-markdown path))
        (define page-url
          (path-replace-extension filename #""))
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

;; [listof symbol]
(define ALL-TAGS
  (for*/fold ([tags (set)]
              #:result (set->list tags))
             ([bp (in-list ALL-BLOGPOSTS)]
              [t (in-list (blogpost-tags bp))])
    (set-add tags t)))

;; -------------------------------------------------------------------
;; Assemble the site from parts

;; Render & save the given xexpr to the file with the given page name.
;;
;; symbol xexpr -> void
(define (render pg xexpr)
  (with-output-to-file
    (format "output/~a.html" pg)
    #:exists 'replace
    (λ ()
      (xml:write-xexpr xexpr))))

;; render index
(render 'index
        (~> ALL-BLOGPOSTS
            (map link-to-blogpost/x _)
            homepage/x
            (entire-page/x #:title "Home"
                           #:page 'index)))

;; render all blogposts
(for ([bp (in-list ALL-BLOGPOSTS)])
  (render (blogpost-page-url bp)
          (blogpost/x bp)))

;; render all tags
(for ([t (in-list ALL-TAGS)])
  (render t (all-tagged/x t)))

;; render any other pages
(for ([x (in-list OTHER-PAGES)])
  (match-define (list* pg title content _) x)
  (render pg (entire-page/x #:title title
                            #:page pg
                            content)))
