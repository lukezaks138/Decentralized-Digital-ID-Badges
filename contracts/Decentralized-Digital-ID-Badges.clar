(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-badge-exists (err u102))
(define-constant err-badge-not-found (err u103))
(define-constant err-badge-expired (err u104))
(define-constant err-badge-revoked (err u105))
(define-constant err-invalid-issuer (err u106))

(define-map authorized-issuers principal bool)
(define-map badges 
  {badge-id: uint} 
  {
    recipient: principal,
    issuer: principal,
    badge-type: (string-ascii 50),
    issued-at: uint,
    expires-at: (optional uint),
    revoked: bool,
    metadata: (string-ascii 500)
  })
(define-map user-badges principal (list 100 uint))
(define-data-var next-badge-id uint u1)

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner))

(define-private (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer)))

(define-public (add-authorized-issuer (new-issuer principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-set authorized-issuers new-issuer true))))

(define-public (remove-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-delete authorized-issuers issuer))))

(define-public (issue-badge 
  (recipient principal)
  (badge-type (string-ascii 50))
  (expires-at (optional uint))
  (metadata (string-ascii 500)))
  (let 
    ((badge-id (var-get next-badge-id))
     (current-badges (default-to (list) (map-get? user-badges recipient))))
    (begin
      (asserts! (is-authorized-issuer tx-sender) err-not-authorized)
      (asserts! (is-none (map-get? badges {badge-id: badge-id})) err-badge-exists)
      (map-set badges 
        {badge-id: badge-id}
        {
          recipient: recipient,
          issuer: tx-sender,
          badge-type: badge-type,
          issued-at: stacks-block-height,
          expires-at: expires-at,
          revoked: false,
          metadata: metadata
        })
      (map-set user-badges recipient (unwrap-panic (as-max-len? (append current-badges badge-id) u100)))
      (var-set next-badge-id (+ badge-id u1))
      (ok badge-id))))

(define-public (revoke-badge (badge-id uint))
  (let ((badge-data (unwrap! (map-get? badges {badge-id: badge-id}) err-badge-not-found)))
    (begin
      (asserts! (or (is-eq tx-sender (get issuer badge-data)) (is-contract-owner)) err-not-authorized)
      (map-set badges 
        {badge-id: badge-id}
        (merge badge-data {revoked: true}))
      (ok true))))

(define-public (verify-badge (badge-id uint))
  (let ((badge-data (unwrap! (map-get? badges {badge-id: badge-id}) err-badge-not-found)))
    (begin
      (asserts! (not (get revoked badge-data)) err-badge-revoked)
      (match (get expires-at badge-data)
        expires (asserts! (<= stacks-block-height expires) err-badge-expired)
        true)
      (ok {
        recipient: (get recipient badge-data),
        issuer: (get issuer badge-data),
        badge-type: (get badge-type badge-data),
        issued-at: (get issued-at badge-data),
        expires-at: (get expires-at badge-data),
        metadata: (get metadata badge-data)
      }))))

(define-read-only (get-badge (badge-id uint))
  (map-get? badges {badge-id: badge-id}))

(define-read-only (get-user-badges (user principal))
  (map-get? user-badges user))

(define-read-only (is-badge-valid (badge-id uint))
  (match (map-get? badges {badge-id: badge-id})
    badge-data 
      (and 
        (not (get revoked badge-data))
        (match (get expires-at badge-data)
          expires (<= stacks-block-height expires)
          true))
    false))

(define-read-only (get-badge-count)
  (- (var-get next-badge-id) u1))

(define-read-only (is-issuer-authorized (issuer principal))
  (is-authorized-issuer issuer))

(define-public (batch-issue-badges 
  (recipients (list 10 {recipient: principal, badge-type: (string-ascii 50), expires-at: (optional uint), metadata: (string-ascii 500)})))
  (begin
    (asserts! (is-authorized-issuer tx-sender) err-not-authorized)
    (ok (map issue-single-badge recipients))))

(define-private (issue-single-badge 
  (badge-info {recipient: principal, badge-type: (string-ascii 50), expires-at: (optional uint), metadata: (string-ascii 500)}))
  (unwrap-panic (issue-badge 
    (get recipient badge-info)
    (get badge-type badge-info)
    (get expires-at badge-info)
    (get metadata badge-info))))

