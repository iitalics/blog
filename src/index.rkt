#lang racket/base
(provide pages)

(require
 racket/match
 racket/date
 markdown)

;; -------------------------------------------------------------------
;; General page template

(define BLOG-TITLE
  "Milo Turner")

(define FOOTER-TEXT
  "\xa9 Milo Turner")

(define NAV
  `{(index "Home")
    (agda "Agda")
    (rkt "Racket")
    (archive "Archive")
    (about "About")})

;; string xexpr -> xexpr
(define (entire-page/x #:title title
                       #:page [pg #f]
                       content)
  `(html (head (title ,(format "~a - ~a" BLOG-TITLE title))
               (meta ([charset "utf8"]))
               ,@css/x)
         (body (main (header ,title/x ,(nav/x pg))
                     ,content
                     (footer ,FOOTER-TEXT)))))

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

(struct blogpost [page-url title date tags article/x]
  #:transparent)

;; [listof blogpost]
(define blogposts
  (for/list ([path (in-directory "src/posts"
                                 (λ (dir) #f))])
    (define-values [base filename must-be-dir?] (split-path path))
    (define page-url (path-replace-extension filename #""))
    (define meta-path (path-replace-extension path #"meta.rktd"))
    (define meta
      (cond
        [(file-exists? meta-path) (with-input-from-file meta-path read)]
        [else '()]))
    (define content (parse-markdown path))
    (define title "(untitled)")
    (define article/x
      `(article
        ,@(for/list ([el (in-list content)])
            (match el
              [`(h1 ,attrs ,txt ,els ...) (set! title txt) `(h2 ,attrs ,txt ,@els)]
              [`(h2 ,attrs ,els ...) `(h3 ,attrs ,@els)]
              [_ el]))))
    (blogpost page-url
              title
              (current-date)
              '()
              article/x)))

(define (blogpost->xexpr bp
                         #:page [active-pg #f])
  (entire-page/x #:title (blogpost-title bp)
                 #:page active-pg
                 (blogpost-article/x bp)))

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

(define other-pages
  `{(about "About" ,about/x)})

;; -------------------------------------------------------------------

(define homepage-blogpost
  (car blogposts))

(define pages
  (append
   ;; pages that are just index pages for now
   (for/list ([n `{(index "Home")
                   (agda "Agda")
                   (rkt "Racket")
                   (archive "Archive")}])
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
