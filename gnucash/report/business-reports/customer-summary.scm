;; -*-scheme-*-
;; customer-summary.scm -- Print a summary of profit per customer
;;
;; Created by:  Christian Stimming
;; Copyright (c) 2010 Christian Stimming <christian@cstimming.de>
;; Copyright (c) 2002, 2003 Derek Atkins <warlord@MIT.EDU>
;;
;; This program is free software; you can redistribute it and/or    
;; modify it under the terms of the GNU General Public License as   
;; published by the Free Software Foundation; either version 2 of   
;; the License, or (at your option) any later version.              
;;                                                                  
;; This program is distributed in the hope that it will be useful,  
;; but WITHOUT ANY WARRANTY; without even the implied warranty of   
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    
;; GNU General Public License for more details.                     
;;                                                                  
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, contact:
;;
;; Free Software Foundation           Voice:  +1-617-542-5942
;; 51 Franklin Street, Fifth Floor    Fax:    +1-617-542-2652
;; Boston, MA  02110-1301,  USA       gnu@gnu.org

;; This report is based on the code in owner-report.scm, but it does
;; not only print a summary for one single owner (here: only
;; customers), but instead a table showing all customers.

(define-module (gnucash report customer-summary))

(use-modules (srfi srfi-1))
(use-modules (gnucash gnc-module))
(use-modules (gnucash utilities))                ; for gnc:debug
(use-modules (gnucash gettext))

(gnc:module-load "gnucash/report/report-system" 0)
(use-modules (gnucash report standard-reports))
(use-modules (gnucash report business-reports))

;; Option names
(define optname-from-date (N_ "From"))
(define optname-to-date (N_ "To"))

;; let's define a name for the report-guid's, much prettier
(define customer-report-guid "4166a20981985fd2b07ff8cb3b7d384e")

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define pagename-incomeaccounts (N_ "Income Accounts"))
(define optname-incomeaccounts (N_ "Income Accounts"))
(define opthelp-incomeaccounts
  (N_ "The income accounts where the sales and income was recorded."))

;; The line break in the next expressions will suppress above comment as translator comments.

(define pagename-expenseaccounts
        (N_ "Expense Accounts"))
(define optname-expenseaccounts (N_ "Expense Accounts"))

;; The line break in the next expressions will suppress above comment as translator comments.
(define opthelp-expenseaccounts
        (N_ "The expense accounts where the expenses are recorded which are subtracted from the sales to give the profit."))

(define optname-show-column-expense (N_ "Show Expense Column"))
(define opthelp-show-column-expense (N_ "Show the column with the expenses per customer."))
(define optname-show-own-address (N_ "Show Company Address"))
(define opthelp-show-own-address (N_ "Show your own company's address and the date of printing."))

(define pagename-columndisplay (N_ "Display Columns"))
(define date-header (N_ "Date"))
(define reference-header (N_ "Reference"))
(define type-header (N_ "Type"))
(define desc-header (N_ "Description"))
(define amount-header (N_ "Amount"))

;; The line break in the next expression will suppress above comments as translator comments.

(define optname-show-zero-lines
         (N_ "Show Lines with All Zeros"))
(define opthelp-show-zero-lines (N_ "Show the table lines with customers which did not have any transactions in the reporting period, hence would show all zeros in the columns."))
(define optname-show-inactive (N_ "Show Inactive Customers"))
(define opthelp-show-inactive (N_ "Include customers that have been marked inactive."))

(define optname-sortkey (N_ "Sort Column"))
(define opthelp-sortkey (N_ "Choose the column by which the result table is sorted."))
(define optname-sortascending (N_ "Sort Order"))
(define opthelp-sortascending (N_ "Choose the ordering of the column sort: Either ascending or descending."))


(define (options-generator acct-type-list owner-type inv-str reverse?)

  (define options (gnc:new-options))

  (define (add-option new-option)
    (gnc:register-option options new-option))

  (add-option
   (gnc:make-internal-option "__reg" "inv-str" inv-str))

  (add-option
   (gnc:make-simple-boolean-option "__reg" "reverse?" "" "" reverse?))

  (add-option
   (gnc:make-internal-option "__reg" "owner-type" owner-type))

  (gnc:options-add-date-interval!
   options
   gnc:pagename-general optname-from-date optname-to-date
   "b")

  (add-option
   (gnc:make-account-list-option
    pagename-incomeaccounts optname-incomeaccounts
    "b"
    opthelp-incomeaccounts
    ;; This default-getter finds the first account of this type. TODO:
    ;; Find not only the first one, but all of them!
    (lambda ()
      (gnc:filter-accountlist-type 
       (list ACCT-TYPE-INCOME)
       (gnc-account-get-descendants-sorted (gnc-get-current-root-account))))
    #f #t))

  (add-option
   (gnc:make-account-list-option
    pagename-expenseaccounts optname-expenseaccounts
    "b"
    opthelp-expenseaccounts
    ;; This default-getter finds the first account of this type. TODO:
    ;; Find not only the first one, but all of them!
    (lambda ()
      (gnc:filter-accountlist-type 
       (list ACCT-TYPE-EXPENSE)
       (gnc-account-get-descendants-sorted (gnc-get-current-root-account))))
    #f #t))

  (add-option
   (gnc:make-multichoice-option
    gnc:pagename-display optname-sortkey
    "a" opthelp-sortkey
    'customername
    (list
     (vector 'customername
             (N_ "Customer Name")
             (N_ "Sort alphabetically by customer name."))
     (vector 'profit
             (N_ "Profit")
             (N_ "Sort by profit amount."))
     (vector 'markup
             ;; Translators: "Markup" is profit amount divided by sales amount
             (N_ "Markup")
             (N_ "Sort by markup (which is profit amount divided by sales)."))
     (vector 'sales
             (N_ "Sales")
             (N_ "Sort by sales amount."))
     (vector 'expense
             (N_ "Expense")
             (N_ "Sort by expense amount.")))))

  (add-option
   (gnc:make-multichoice-option
    gnc:pagename-display optname-sortascending
    "b" opthelp-sortascending
    'ascend
    (list
     (vector 'ascend
             (N_ "Ascending")
             (N_ "A to Z, smallest to largest."))
     (vector 'descend
             (N_ "Descending")
             (N_ "Z to A, largest to smallest.")))))

  (add-option
   (gnc:make-simple-boolean-option
    gnc:pagename-display optname-show-own-address
    "d" opthelp-show-own-address #t))

  (add-option
   (gnc:make-simple-boolean-option
    gnc:pagename-display optname-show-zero-lines
    "e" opthelp-show-zero-lines #f))

  (add-option
   (gnc:make-simple-boolean-option
    gnc:pagename-display optname-show-inactive
    "f" opthelp-show-inactive #f))

  (add-option
   (gnc:make-simple-boolean-option
    gnc:pagename-display optname-show-column-expense
    "g" opthelp-show-column-expense #t))

  (gnc:options-set-default-section options gnc:pagename-general)

  options)

(define (customer-options-generator)
  (options-generator (list ACCT-TYPE-RECEIVABLE) GNC-OWNER-CUSTOMER
                     (_ "Invoice") #t)) ;; FIXME: reverse?=#t but originally #f


;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (string-expand string character replace-string)
  (with-output-to-string
    (lambda ()
      (string-for-each
       (lambda (c)
         (display
          (if (char=? c character)
              replace-string
              c)))
       string))))

(define (query-toplevel-setup query account-list start-date end-date)
  (xaccQueryAddAccountMatch query account-list QOF-GUID-MATCH-ANY QOF-QUERY-AND)
  (xaccQueryAddDateMatchTT query #t start-date #t end-date QOF-QUERY-AND)
  (qof-query-set-book query (gnc-get-current-book))
  query)

(define (query-owner-setup q owner)
  (let* ((guid (gncOwnerReturnGUID (gncOwnerGetEndOwner owner))))

    (qof-query-add-guid-match
     q 
     (list SPLIT-TRANS INVOICE-FROM-TXN INVOICE-OWNER
           OWNER-PARENTG)
     guid QOF-QUERY-OR)
    (qof-query-add-guid-match
     q 
     (list SPLIT-TRANS INVOICE-FROM-TXN INVOICE-BILLTO
           OWNER-PARENTG)
     guid QOF-QUERY-OR)
;; Apparently those query terms are unneeded because we never take
;; lots into account?!?
;    (qof-query-add-guid-match
;     q
;     (list SPLIT-LOT OWNER-FROM-LOT OWNER-PARENTG)
;     guid QOF-QUERY-OR)
;    (qof-query-add-guid-match
;     q
;     (list SPLIT-LOT INVOICE-FROM-LOT INVOICE-OWNER
;           OWNER-PARENTG)
;     guid QOF-QUERY-OR)
;    (qof-query-add-guid-match
;     q
;     (list SPLIT-LOT INVOICE-FROM-LOT INVOICE-BILLTO
;           OWNER-PARENTG)
;     guid QOF-QUERY-OR)
    (qof-query-set-book q (gnc-get-current-book))
    q))


(define (make-myname-table book date-format)
  (let* ((table (gnc:make-html-table))
         (table-outer (gnc:make-html-table))
         (name (gnc:company-info book gnc:*company-name*))
         (addy (gnc:company-info book gnc:*company-addy*)))

    (gnc:html-table-set-style!
     table "table"
     'attribute (list "border" 0)
     'attribute (list "width" "") ;; this way we force the override of the "100%" below
     'attribute (list "align" "right")
     'attribute (list "valign" "top")
     'attribute (list "cellspacing" 0)
     'attribute (list "cellpadding" 0))

    (gnc:html-table-append-row! table (list (if name name "")))
    (gnc:html-table-append-row! table (list (string-expand
                                             (if addy addy "")
                                             #\newline "<br/>")))
    (gnc:html-table-append-row!
     table (list (gnc-print-time64 (gnc:get-today) date-format)))

    (gnc:html-table-set-style!
     table-outer "table"
     'attribute (list "border" 0)
     'attribute (list "width" "100%")
     'attribute (list "valign" "top")
     'attribute (list "cellspacing" 0)
     'attribute (list "cellpadding" 0))

    (gnc:html-table-append-row! table-outer (list table))

    table-outer))

(define (make-break! document)
  (gnc:html-document-add-object!
   document
   (gnc:make-html-text
    (gnc:html-markup-br))))

(define (markup-percent profit sales)
  (if (zero? sales) 0
      (* 100 (gnc-numeric-div profit sales 1000 GNC-HOW-RND-ROUND))))

(define (query-split-value sub-query toplevel-query)
  (let ((splits (qof-query-run-subquery sub-query toplevel-query)))
    (apply + (map xaccSplitGetValue splits))))

(define (single-query-split-value query)
  (let ((splits (qof-query-run query)))
    (apply + (map xaccSplitGetValue splits))))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (reg-renderer report-obj)
  (define (opt-val section name)
    (gnc:option-value
     (gnc:lookup-option (gnc:report-options report-obj) section name)))

  (let* ((document (gnc:make-html-document))
         (report-title (opt-val gnc:pagename-general gnc:optname-reportname))
         (start-date (gnc:time64-start-day-time 
                      (gnc:date-option-absolute-time
                       (opt-val gnc:pagename-general optname-from-date))))
         (end-date (gnc:time64-end-day-time 
                    (gnc:date-option-absolute-time
                     (opt-val gnc:pagename-general optname-to-date))))
         (print-invoices? #t);;(opt-val gnc:pagename-general optname-invoicelines))
;         (show-txn-table? (opt-val gnc:pagename-display optname-show-txn-table))
         (show-zero-lines? (opt-val gnc:pagename-display optname-show-zero-lines))
         (show-column-expense? (opt-val gnc:pagename-display optname-show-column-expense))
         (table-num-columns (if show-column-expense? 5 4))
         (show-own-address? (opt-val gnc:pagename-display optname-show-own-address))
         (expense-accounts (opt-val pagename-expenseaccounts optname-expenseaccounts))
         (income-accounts (opt-val pagename-incomeaccounts optname-incomeaccounts))
         (all-accounts (append income-accounts expense-accounts))
         (book (gnc-get-current-book))
         (date-format (gnc:options-fancy-date book))
         (type (opt-val "__reg" "owner-type"))
         (reverse? (opt-val "__reg" "reverse?"))
         (ownerlist (gncBusinessGetOwnerList
                        book
                        (gncOwnerTypeToQofIdType type)
                        (opt-val gnc:pagename-display optname-show-inactive)))
         (toplevel-income-query (qof-query-create-for-splits))
         (toplevel-expense-query (qof-query-create-for-splits))
         (toplevel-total-income #f)
         (toplevel-total-expense #f)
         (owner-query (qof-query-create-for-splits))
         (any-valid-owner? #f)
         (type-str "")
         (notification-str "")
         (currency (gnc-default-currency)))

    (cond
     ((eqv? type GNC-OWNER-CUSTOMER)
      (set! type-str (N_ "Customer")))
     ((eqv? type GNC-OWNER-VENDOR)
      (set! type-str (N_ "Vendor")))
     ((eqv? type GNC-OWNER-EMPLOYEE)
      (set! type-str (N_ "Employee"))))

    (gnc:html-document-set-title!
     document (string-append (_ type-str) " " (_ "Report")))

    ;; Set up the toplevel query
    (query-toplevel-setup toplevel-income-query income-accounts start-date end-date)

    ;; Run the query to be able to use the results in a sub-query, and
    ;; also use the amount as the actual grand total (both assigned
    ;; and not assigned to customers)
    (set! toplevel-total-income
          (single-query-split-value toplevel-income-query))
    (if reverse?
        (set! toplevel-total-income (gnc-numeric-neg toplevel-total-income)))

    ;; Total expenses as well
    (query-toplevel-setup toplevel-expense-query expense-accounts start-date end-date)
    (set! toplevel-total-expense
          (single-query-split-value toplevel-expense-query))
    (if reverse?
        (set! toplevel-total-expense (gnc-numeric-neg toplevel-total-expense)))

    ;; Continue if we have non-null accounts
    (if (null? income-accounts)
        
        ;; error condition: no accounts specified
        ;; is this *really* necessary??  i'd be fine with an all-zero
        ;; account summary that would, technically, be correct....
        (gnc:html-document-add-object! 
         document
         (gnc:html-make-no-account-warning 
          report-title (gnc:report-id report-obj)))
        
        ;; otherwise, generate the report...

        (let ((resulttable
               ;; Loop over all owners
               (map
                (lambda (owner)
                  (if
                   (and (gncOwnerIsValid owner)
                        (> (length all-accounts) 0))

                   ;; Now create the line for one single owner
                   (let ((total-income (gnc-numeric-zero))
                         (total-expense (gnc-numeric-zero)))

                     (set! currency (xaccAccountGetCommodity (car all-accounts)))
                     (set! any-valid-owner? #t)

                     ;; Run one query on all income accounts
                     (query-owner-setup owner-query owner)

                     (set! total-income (query-split-value owner-query toplevel-income-query))
                     (if reverse?
                         (set! total-income (gnc-numeric-neg total-income)))

                     ;; Clean up the query
                     (qof-query-clear owner-query)

                     ;; And run one query on all expense accounts
                     (query-owner-setup owner-query owner)

                     (set! total-expense (query-split-value owner-query toplevel-expense-query))
                     (if reverse?
                         (set! total-expense (gnc-numeric-neg total-expense)))

                     ;; Clean up the query
                     (qof-query-clear owner-query)

                     ;; We print the summary now
                     (let* ((profit (gnc-numeric-add-fixed total-income total-expense))
                            (markupfloat (markup-percent profit total-income))
                            )

                       ;; Result of this customer
                       (list owner profit markupfloat total-income total-expense)

                       )

                     ) ;; END let
                   ) ;; END if owner-is-valid
                  )
                ownerlist) ;; END for-each all owners

               ))

          ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          ;; If asked for, we also print the company name
          (if show-own-address?
              (gnc:html-document-add-object!
               document
               (make-myname-table book date-format)))

          ;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          ;; Now print the resulttable here:
          (let ((table (gnc:make-html-table))
                (sort-descending? (eq? (opt-val gnc:pagename-display optname-sortascending) 'descend))
                (sort-key (opt-val gnc:pagename-display optname-sortkey))
                (total-profit (gnc-numeric-zero))
                (total-sales (gnc-numeric-zero))
                (total-expense (gnc-numeric-zero))
                (heading-list
                 (list (_ "Customer") (_ "Profit")
                  ;; Translators: "Markup" is profit amount divided by sales amount
                  (_ "Markup") (_ "Sales"))))

            ;; helper for sorting an owner list
            (define (owner-name<? a b)
              (string<? (gncOwnerGetName a) (gncOwnerGetName b)))

            ;; Heading line
            (if show-column-expense?
                (set! heading-list (append heading-list (list (_ "Expense")))))
            (gnc:html-table-set-col-headers!
             table heading-list)

            ;; Sorting: First sort everything alphabetically
            ;; (ascending) so that we have one stable sorting order
            (set! resulttable
                  (sort resulttable (lambda (a b) (owner-name<? (car a) (car b)))))

            ;; Secondly sort by the actual sort key
            (let ((cmp (if sort-descending? > <))
                  (strcmp (if sort-descending? string>? string<?)))
              (set!
               resulttable
               (sort resulttable
                     (cond
                      ((eq? sort-key 'customername)
                       (lambda (a b)
                         (strcmp (gncOwnerGetName (car a)) (gncOwnerGetName (car b)))))
                      ((eq? sort-key 'profit)
                       (lambda (a b)
                         (cmp (gnc-numeric-compare (cadr a) (cadr b)) 0)))
                      ((eq? sort-key 'markup)
                       (lambda (a b)
                         (cmp (list-ref a 2) (list-ref b 2))))
                      ((eq? sort-key 'sales)
                       (lambda (a b)
                         (cmp (gnc-numeric-compare (list-ref a 3) (list-ref b 3)) 0)))
                      ((eq? sort-key 'expense)
                       (lambda (a b)
                         (cmp (gnc-numeric-compare (list-ref a 4) (list-ref b 4)) 0)))
                      ) ;; END cond
                     ) ;; END sort
               )) ;; END let

            ;; The actual content
            (for-each
             (lambda (row)
               (if
                (eq? (length row) 5)
                (let ((owner (list-ref row 0))
                      (profit (list-ref row 1))
                      (markupfloat (list-ref row 2))
                      (sales (list-ref row 3))
                      (expense (list-ref row 4)))
                  (set! total-profit (gnc-numeric-add-fixed total-profit profit))
                  (set! total-sales (gnc-numeric-add-fixed total-sales sales))
                  (set! total-expense (gnc-numeric-add-fixed total-expense expense))
                  (if (or show-zero-lines?
                          (not (and (gnc-numeric-zero-p profit) (gnc-numeric-zero-p sales))))
                      (let ((row-content
                             (list
                              (gncOwnerGetName owner)
                              (gnc:make-gnc-monetary currency profit)
                              ;;(format #f (if (< (abs markupfloat) 10) "~2.1f%%" "%2.0f%%") markupfloat)
                              (format #f  "~2,0f%" markupfloat)
                              (gnc:make-gnc-monetary currency sales))))
                        (if show-column-expense?
                            (set!
                             row-content
                             (append row-content
                                     (list
                                      (gnc:make-gnc-monetary currency (gnc-numeric-neg expense))))))
                        (gnc:html-table-append-row!
                         table row-content)))
                  )
                (gnc:warn "Oops, encountered a row with wrong length=" (length row))))
             resulttable) ;; END for-each row

            ;; The "No Customer" line
            (let* ((other-sales (gnc-numeric-sub-fixed toplevel-total-income total-sales))
                   (other-expense (gnc-numeric-sub-fixed toplevel-total-expense total-expense))
                   (other-profit (gnc-numeric-add-fixed other-sales other-expense))
                   (markupfloat (markup-percent other-profit other-sales))
                   (row-content
                    (list
                     (_ "No Customer")
                     (gnc:make-gnc-monetary currency other-profit)
                     (format #f  "~2,0f%" markupfloat)
                     (gnc:make-gnc-monetary currency other-sales))))
              (if show-column-expense?
                  (set!
                   row-content
                   (append row-content
                           (list
                            (gnc:make-gnc-monetary currency (gnc-numeric-neg other-expense))))))
              (if (or show-zero-lines?
                      (not (and (gnc-numeric-zero-p other-profit) (gnc-numeric-zero-p other-sales))))

                  (gnc:html-table-append-row!
                   table row-content)))

            ;; One horizontal ruler before the summary
            ;;;(gnc:html-table-append-ruler!
            ;;; table table-num-columns) ;; better use the "noshade" attribute:
            (gnc:html-table-append-row!
             table
             (list
              (gnc:make-html-table-cell/size
               1 table-num-columns
               (gnc:make-html-text (gnc:html-markup/attr/no-end "hr" "noshade")))))

            ;; One summary line
            (let* ((total-profit (gnc-numeric-add-fixed toplevel-total-income toplevel-total-expense))
                   (markupfloat (markup-percent total-profit toplevel-total-income))
                   (row-content
                    (list
                     (_ "Total")
                     (gnc:make-gnc-monetary currency total-profit)
                     ;;(format #f (if (< (abs markupfloat) 10) "~2,1f%" "~2,0f%") markupfloat)
                     (format #f  "~2,0f%" markupfloat)
                     (gnc:make-gnc-monetary currency toplevel-total-income))))
              (if show-column-expense?
                  (set!
                   row-content
                   (append row-content
                           (list
                            (gnc:make-gnc-monetary currency (gnc-numeric-neg toplevel-total-expense))))))
              (gnc:html-table-append-row!
               table
               row-content))

            ;; Set the formatting styles
            (gnc:html-table-set-style!
             table "td"
             'attribute '("align" "right")
             'attribute '("valign" "top"))

            (gnc:html-table-set-col-style!
             table 0 "td"
             'attribute '("align" "left"))

            (gnc:html-table-set-style!
             table "table"
             ;;'attribute (list "border" 1)
             'attribute (list "cellspacing" 2)
             'attribute (list "cellpadding" 4))

            ;; And add the table to the document
            (gnc:html-document-add-object!
             document table)
            )

          ) ;; END let resulttable

        ) ;; END if null? income-accounts

    (if any-valid-owner?
        ;; Report contains valid data
        (let ((headline 
               (format
                #f (_ "~a ~a - ~a")
                report-title
                (qof-print-date start-date)
                (qof-print-date end-date))))
          (gnc:html-document-set-title!
           document headline)

          ;; Check the settings for taking invoice/payment lines into
          ;; account and print the ch
          (make-break! document)
          (gnc:html-document-add-object!
           document
           (gnc:make-html-text notification-str))
          )

        ;; else....
        (gnc:html-document-add-object!
         document
         (gnc:make-html-text
          (string-append
           (cond
            ((eqv? type GNC-OWNER-CUSTOMER)
             (_ "No valid customer selected."))
            ((eqv? type GNC-OWNER-VENDOR)
             (_ "No valid vendor selected."))
            ((eqv? type GNC-OWNER-EMPLOYEE)
             (_ "No valid employee selected.")))
           " "
           (_ "Click on the \"Options\" button to select a company.")))))

    (qof-query-destroy owner-query)
    (qof-query-destroy toplevel-income-query)
    (qof-query-destroy toplevel-expense-query)

    document))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(gnc:define-report
 'version 1
 'name (N_ "Customer Summary")
 'report-guid customer-report-guid
 'menu-path (list gnc:menuname-business-reports)
 'options-generator customer-options-generator
 'renderer reg-renderer
 'in-menu? #t)

