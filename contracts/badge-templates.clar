(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-template-exists (err u201))
(define-constant err-template-not-found (err u202))
(define-constant err-not-authorized (err u203))

(define-map badge-templates 
  {template-id: uint}
  {
    name: (string-ascii 50),
    badge-type: (string-ascii 50),
    default-duration: (optional uint),
    metadata-schema: (string-ascii 300),
    creator: principal,
    active: bool
  })

(define-map authorized-template-creators principal bool)
(define-data-var next-template-id uint u1)

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner))

(define-private (is-authorized-creator)
  (or (is-contract-owner) 
      (default-to false (map-get? authorized-template-creators tx-sender))))

(define-public (authorize-template-creator (creator principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-set authorized-template-creators creator true))))

(define-public (revoke-template-creator (creator principal))
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (ok (map-delete authorized-template-creators creator))))

(define-public (create-template 
  (name (string-ascii 50))
  (badge-type (string-ascii 50))
  (default-duration (optional uint))
  (metadata-schema (string-ascii 300)))
  (let ((template-id (var-get next-template-id)))
    (begin
      (asserts! (is-authorized-creator) err-not-authorized)
      (asserts! (is-none (map-get? badge-templates {template-id: template-id})) err-template-exists)
      (map-set badge-templates 
        {template-id: template-id}
        {
          name: name,
          badge-type: badge-type,
          default-duration: default-duration,
          metadata-schema: metadata-schema,
          creator: tx-sender,
          active: true
        })
      (var-set next-template-id (+ template-id u1))
      (ok template-id))))

(define-public (deactivate-template (template-id uint))
  (let ((template-data (unwrap! (map-get? badge-templates {template-id: template-id}) err-template-not-found)))
    (begin
      (asserts! (or (is-eq tx-sender (get creator template-data)) (is-contract-owner)) err-not-authorized)
      (map-set badge-templates 
        {template-id: template-id}
        (merge template-data {active: false}))
      (ok true))))

(define-read-only (get-template (template-id uint))
  (map-get? badge-templates {template-id: template-id}))

(define-read-only (get-template-count)
  (- (var-get next-template-id) u1))

(define-read-only (is-template-active (template-id uint))
  (match (map-get? badge-templates {template-id: template-id})
    template-data (get active template-data)
    false))

(define-public (get-template-config (template-id uint))
  (let ((template-data (unwrap! (map-get? badge-templates {template-id: template-id}) err-template-not-found)))
    (begin
      (asserts! (get active template-data) err-template-not-found)
      (ok {
        badge-type: (get badge-type template-data),
        default-duration: (get default-duration template-data),
        metadata-schema: (get metadata-schema template-data)
      }))))
