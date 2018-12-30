#lang racket/base
(require
 racket/match
 racket/date)

(define BLOG-TITLE
  "Milo Turner")

(define FOOTER-TEXT
  "\xa9 Milo Turner")

;; string symbol -> xexpr
(define (make-page title pg)
  `(html
    (head
     (title ,(format "~a - ~a" BLOG-TITLE title))
     (meta ((charset "utf8")))
     (link ((href "style.css")
            (rel "stylesheet"))))
    (body
     (main
      (header ,(blogtitle) ,(nav pg))
      ,(post "Sample Post"
             (current-date)
             '(h3 "Subheader one")
             '(p "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow corned beef. Ham hock
                  chicken shoulder brisket tri-tip ground round pig short ribs sirloin swine cupim fatback
                  tail tenderloin chuck. Ham burgdoggen venison tenderloin doner brisket pork chop, rump
                  strip steak chuck tail. Salami pork chop cow, turkey leberkas pancetta swine ham hock
                  ground round shank hamburger alcatra kielbasa venison. Kielbasa ball tip bacon spare ribs
                  meatloaf porchetta beef ribs biltong strip steak ground round ribeye. Leberkas shank
                  venison filet mignon buffalo picanha. Strip steak beef ribs pastrami shank corned beef.")
             '(pre "
function code() {
  code.code[code]();
}")
             '(p "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow corned beef. Ham hock
                  chicken shoulder brisket tri-tip ground round pig short ribs sirloin swine cupim fatback
                  tail tenderloin chuck. Ham burgdoggen venison tenderloin doner brisket pork chop, rump
                  strip steak chuck tail. ")
             '(blockquote "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow corned beef. Ham hock
                  chicken shoulder brisket tri-tip ground round pig short ribs sirloin swine cupim fatback
                  tail tenderloin chuck. Ham burgdoggen venison tenderloin doner brisket pork chop, rump
                  strip steak chuck tail. ")
             '(p "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow corned beef. Ham hock
                  chicken shoulder brisket tri-tip ground round pig short ribs sirloin swine cupim fatback
                  tail tenderloin chuck. Ham burgdoggen venison tenderloin doner brisket pork chop, rump
                  strip steak chuck tail. ")
             '(h3 "Subheader two")
             '(p "Bacon ipsum dolor amet tongue pastrami jerky spare ribs boudin cow corned beef. Ham hock
                  chicken shoulder brisket tri-tip ground round pig short ribs sirloin swine cupim fatback
                  tail tenderloin chuck. Ham burgdoggen venison tenderloin doner brisket pork chop, rump
                  strip steak chuck tail. "))
      (footer ,FOOTER-TEXT)))))

;; -> xexpr
(define (blogtitle)
  `(div ((class "title"))
        (a ((href "index.html"))
           (h1 ,BLOG-TITLE))))

;; string -> xexpr
(define (nav active-pg)
  `(nav
    (ul
     ,@(for/list ([x (in-list pages)])
         (match-define `(,title ,pg ,_) x)
         (define cls
           (if (eq? pg active-pg)
               "active"
               ""))
         (define url
           (format "~a.html" pg))
         `(li ((class ,cls))
              (a ((href ,url))
                 ,title))))))

;; string date xexpr ... -> xexpr
(define (post name datetime . content)
  `(article
    (h2 ,name)
    (time ((datetime ,(parameterize ([date-display-format 'iso-8601])
                        (date->string datetime))))
          ,(parameterize ([date-display-format 'american])
             (date->string datetime)))
    ,@content))

(define pages
  (for/list ([x (in-list `{("Home" index)
                           ("Agda" agda)
                           ("Racket" rkt)
                           ("Archive" archive)
                           ("About" about)})])
    (list (car x)
          (cadr x)
          (λ () (make-page (car x) (cadr x))))))

(provide pages)
