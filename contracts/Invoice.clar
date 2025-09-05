(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVOICE_NOT_FOUND (err u101))
(define-constant ERR_INVOICE_ALREADY_PAID (err u102))
(define-constant ERR_INVOICE_CANCELLED (err u103))
(define-constant ERR_INSUFFICIENT_AMOUNT (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_CANNOT_CANCEL_PAID_INVOICE (err u106))
(define-constant ERR_INVOICE_OVERDUE (err u107))
(define-constant ERR_RECURRING_NOT_FOUND (err u108))
(define-constant ERR_RECURRING_PAUSED (err u109))
(define-constant ERR_INVALID_INTERVAL (err u110))

(define-constant STATUS_PENDING u0)
(define-constant STATUS_PAID u1)
(define-constant STATUS_CANCELLED u2)
(define-constant STATUS_OVERDUE u3)

(define-constant INTERVAL_WEEKLY u604800)
(define-constant INTERVAL_MONTHLY u2629746)
(define-constant INTERVAL_YEARLY u31556952)

(define-data-var invoice-counter uint u0)
(define-data-var recurring-counter uint u0)

(define-map invoices
  uint
  {
    creator: principal,
    recipient: principal,
    amount: uint,
    description: (string-ascii 256),
    due-date: uint,
    created-at: uint,
    paid-at: (optional uint),
    status: uint
  }
)

(define-map invoice-payments
  uint
  {
    payer: principal,
    amount: uint,
    paid-at: uint
  }
)

(define-map user-invoices
  principal
  (list 100 uint)
)

(define-map user-received-invoices
  principal
  (list 100 uint)
)

(define-map recurring-invoices
  uint
  {
    creator: principal,
    recipient: principal,
    amount: uint,
    description: (string-ascii 256),
    interval: uint,
    created-at: uint,
    next-due: uint,
    last-generated: uint,
    is-active: bool
  }
)

(define-map user-recurring-invoices
  principal
  (list 50 uint)
)

(define-map recurring-invoice-history
  uint
  (list 100 uint)
)

(define-private (get-next-invoice-id)
  (begin
    (var-set invoice-counter (+ (var-get invoice-counter) u1))
    (var-get invoice-counter)
  )
)

(define-private (get-next-recurring-id)
  (begin
    (var-set recurring-counter (+ (var-get recurring-counter) u1))
    (var-get recurring-counter)
  )
)

(define-private (is-invoice-overdue (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (match (get-stacks-block-info? time stacks-block-height)
              current-time (and 
                            (is-eq (get status invoice) STATUS_PENDING)
                            (> current-time (get due-date invoice)))
              false)
    false
  )
)

(define-private (update-invoice-status (invoice-id uint))
  (if (is-invoice-overdue invoice-id)
    (match (map-get? invoices invoice-id)
      invoice (begin
                (map-set invoices invoice-id (merge invoice { status: STATUS_OVERDUE }))
                true)
      false)
    true
  )
)

(define-private (add-to-user-invoices (user principal) (invoice-id uint))
  (let ((current-invoices (default-to (list) (map-get? user-invoices user))))
    (map-set user-invoices user (unwrap! (as-max-len? (append current-invoices invoice-id) u100) false))
  )
)

(define-private (add-to-user-received-invoices (user principal) (invoice-id uint))
  (let ((current-invoices (default-to (list) (map-get? user-received-invoices user))))
    (map-set user-received-invoices user (unwrap! (as-max-len? (append current-invoices invoice-id) u100) false))
  )
)

(define-private (add-to-user-recurring-invoices (user principal) (recurring-id uint))
  (let ((current-recurring (default-to (list) (map-get? user-recurring-invoices user))))
    (map-set user-recurring-invoices user (unwrap! (as-max-len? (append current-recurring recurring-id) u50) false))
  )
)

(define-private (add-to-recurring-history (recurring-id uint) (invoice-id uint))
  (let ((current-history (default-to (list) (map-get? recurring-invoice-history recurring-id))))
    (map-set recurring-invoice-history recurring-id (unwrap! (as-max-len? (append current-history invoice-id) u100) false))
  )
)

(define-public (create-invoice (recipient principal) (amount uint) (description (string-ascii 256)) (due-date uint))
  (let ((invoice-id (get-next-invoice-id))
        (current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> due-date current-time) ERR_INVALID_AMOUNT)
    
    (map-set invoices invoice-id {
      creator: tx-sender,
      recipient: recipient,
      amount: amount,
      description: description,
      due-date: due-date,
      created-at: current-time,
      paid-at: none,
      status: STATUS_PENDING
    })
    
    (add-to-user-invoices tx-sender invoice-id)
    (add-to-user-received-invoices recipient invoice-id)
    
    (ok invoice-id)
  )
)

(define-public (pay-invoice (invoice-id uint))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND))
        (current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
    
    (update-invoice-status invoice-id)
    
    (asserts! (not (is-eq (get status invoice) STATUS_PAID)) ERR_INVOICE_ALREADY_PAID)
    (asserts! (not (is-eq (get status invoice) STATUS_CANCELLED)) ERR_INVOICE_CANCELLED)
    
    (try! (stx-transfer? (get amount invoice) tx-sender (get creator invoice)))
    
    (map-set invoices invoice-id (merge invoice { 
      status: STATUS_PAID,
      paid-at: (some current-time)
    }))
    
    (map-set invoice-payments invoice-id {
      payer: tx-sender,
      amount: (get amount invoice),
      paid-at: current-time
    })
    
    (ok true)
  )
)

(define-public (cancel-invoice (invoice-id uint))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq (get status invoice) STATUS_PAID)) ERR_CANNOT_CANCEL_PAID_INVOICE)
    
    (map-set invoices invoice-id (merge invoice { status: STATUS_CANCELLED }))
    
    (ok true)
  )
)

(define-public (update-invoice-description (invoice-id uint) (new-description (string-ascii 256)))
  (let ((invoice (unwrap! (map-get? invoices invoice-id) ERR_INVOICE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator invoice)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status invoice) STATUS_PENDING) ERR_INVOICE_ALREADY_PAID)
    
    (map-set invoices invoice-id (merge invoice { description: new-description }))
    
    (ok true)
  )
)

(define-read-only (get-invoice (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (ok invoice)
    ERR_INVOICE_NOT_FOUND
  )
)

(define-read-only (get-invoice-payment (invoice-id uint))
  (map-get? invoice-payments invoice-id)
)

(define-read-only (get-user-invoices (user principal))
  (default-to (list) (map-get? user-invoices user))
)

(define-read-only (get-user-received-invoices (user principal))
  (default-to (list) (map-get? user-received-invoices user))
)

(define-read-only (get-invoice-status (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (if (is-invoice-overdue invoice-id)
              (ok STATUS_OVERDUE)
              (ok (get status invoice)))
    ERR_INVOICE_NOT_FOUND
  )
)

(define-read-only (get-total-invoices)
  (var-get invoice-counter)
)

(define-read-only (is-invoice-paid (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (ok (is-eq (get status invoice) STATUS_PAID))
    ERR_INVOICE_NOT_FOUND
  )
)

(define-read-only (get-invoice-amount (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (ok (get amount invoice))
    ERR_INVOICE_NOT_FOUND
  )
)

(define-read-only (get-pending-invoices-for-user (user principal))
  (filter is-pending-invoice (get-user-received-invoices user))
)

(define-private (is-pending-invoice (invoice-id uint))
  (match (map-get? invoices invoice-id)
    invoice (is-eq (get status invoice) STATUS_PENDING)
    false
  )
)

(define-read-only (get-overdue-invoices-for-user (user principal))
  (filter is-overdue-invoice-check (get-user-received-invoices user))
)

(define-private (is-overdue-invoice-check (invoice-id uint))
  (is-invoice-overdue invoice-id)
)

(define-public (create-recurring-invoice (recipient principal) (amount uint) (description (string-ascii 256)) (interval uint))
  (let ((recurring-id (get-next-recurring-id))
        (current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (or (is-eq interval INTERVAL_WEEKLY) 
                  (or (is-eq interval INTERVAL_MONTHLY) 
                      (is-eq interval INTERVAL_YEARLY))) ERR_INVALID_INTERVAL)
    
    (map-set recurring-invoices recurring-id {
      creator: tx-sender,
      recipient: recipient,
      amount: amount,
      description: description,
      interval: interval,
      created-at: current-time,
      next-due: (+ current-time interval),
      last-generated: u0,
      is-active: true
    })
    
    (add-to-user-recurring-invoices tx-sender recurring-id)
    
    (ok recurring-id)
  )
)

(define-public (generate-recurring-invoice (recurring-id uint))
  (let ((recurring (unwrap! (map-get? recurring-invoices recurring-id) ERR_RECURRING_NOT_FOUND))
        (current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
    
    (asserts! (get is-active recurring) ERR_RECURRING_PAUSED)
    (asserts! (>= current-time (get next-due recurring)) ERR_INVALID_AMOUNT)
    
    (let ((new-invoice-id (unwrap! (create-invoice 
                                     (get recipient recurring)
                                     (get amount recurring)
                                     (get description recurring)
                                     (+ current-time (* (get interval recurring) u2))) (err u999))))
      
      (map-set recurring-invoices recurring-id (merge recurring {
        next-due: (+ (get next-due recurring) (get interval recurring)),
        last-generated: current-time
      }))
      
      (add-to-recurring-history recurring-id new-invoice-id)
      
      (ok new-invoice-id)
    )
  )
)

(define-public (pause-recurring-invoice (recurring-id uint))
  (let ((recurring (unwrap! (map-get? recurring-invoices recurring-id) ERR_RECURRING_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get creator recurring)) ERR_NOT_AUTHORIZED)
    
    (map-set recurring-invoices recurring-id (merge recurring { is-active: false }))
    
    (ok true)
  )
)

(define-public (resume-recurring-invoice (recurring-id uint))
  (let ((recurring (unwrap! (map-get? recurring-invoices recurring-id) ERR_RECURRING_NOT_FOUND))
        (current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
    (asserts! (is-eq tx-sender (get creator recurring)) ERR_NOT_AUTHORIZED)
    
    (map-set recurring-invoices recurring-id (merge recurring { 
      is-active: true,
      next-due: (+ current-time (get interval recurring))
    }))
    
    (ok true)
  )
)

(define-read-only (get-recurring-invoice (recurring-id uint))
  (match (map-get? recurring-invoices recurring-id)
    recurring (ok recurring)
    ERR_RECURRING_NOT_FOUND
  )
)

(define-read-only (get-user-recurring-invoices (user principal))
  (default-to (list) (map-get? user-recurring-invoices user))
)

(define-read-only (get-recurring-invoice-history (recurring-id uint))
  (default-to (list) (map-get? recurring-invoice-history recurring-id))
)

(define-read-only (get-due-recurring-invoices (user principal))
  (filter is-recurring-due (get-user-recurring-invoices user))
)

(define-private (is-recurring-due (recurring-id uint))
  (match (map-get? recurring-invoices recurring-id)
    recurring (let ((current-time (default-to u0 (get-stacks-block-info? time stacks-block-height))))
                (and (get is-active recurring)
                     (>= current-time (get next-due recurring))))
    false
  )
)

(define-read-only (get-total-recurring-invoices)
  (var-get recurring-counter)
)
