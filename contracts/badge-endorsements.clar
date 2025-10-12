(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-authorized (err u301))
(define-constant err-already-endorsed (err u302))
(define-constant err-endorsement-not-found (err u303))
(define-constant err-invalid-weight (err u304))
(define-constant err-self-endorsement (err u305))

(define-map authorized-endorsers principal {weight: uint, active: bool})
(define-map badge-endorsements {badge-id: uint, endorser: principal} {
    endorsed-at: uint,
    endorsement-message: (string-ascii 200),
    weight: uint
})
(define-map badge-endorsement-count {badge-id: uint} uint)
(define-map badge-reputation-score {badge-id: uint} uint)
(define-map endorser-stats principal {total-endorsements: uint, reputation: uint})

(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner))

(define-private (is-authorized-endorser)
    (match (map-get? authorized-endorsers tx-sender)
        endorser-data (get active endorser-data)
        false))

(define-public (add-endorser (endorser principal) (weight uint))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (asserts! (and (>= weight u1) (<= weight u100)) err-invalid-weight)
        (ok (map-set authorized-endorsers endorser {weight: weight, active: true}))))

(define-public (deactivate-endorser (endorser principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (match (map-get? authorized-endorsers endorser)
            endorser-data (ok (map-set authorized-endorsers endorser (merge endorser-data {active: false})))
            err-not-authorized)))

(define-public (endorse-badge (badge-id uint) (message (string-ascii 200)))
    (let ((endorser-data (unwrap! (map-get? authorized-endorsers tx-sender) err-not-authorized))
          (existing-endorsement (map-get? badge-endorsements {badge-id: badge-id, endorser: tx-sender}))
          (current-count (default-to u0 (map-get? badge-endorsement-count {badge-id: badge-id})))
          (current-score (default-to u0 (map-get? badge-reputation-score {badge-id: badge-id})))
          (endorser-total (default-to {total-endorsements: u0, reputation: u50} (map-get? endorser-stats tx-sender))))
        (begin
            (asserts! (get active endorser-data) err-not-authorized)
            (asserts! (is-none existing-endorsement) err-already-endorsed)
            (map-set badge-endorsements 
                {badge-id: badge-id, endorser: tx-sender}
                {endorsed-at: block-height, endorsement-message: message, weight: (get weight endorser-data)})
            (map-set badge-endorsement-count {badge-id: badge-id} (+ current-count u1))
            (map-set badge-reputation-score {badge-id: badge-id} (+ current-score (get weight endorser-data)))
            (map-set endorser-stats tx-sender 
                {total-endorsements: (+ (get total-endorsements endorser-total) u1), 
                 reputation: (get reputation endorser-total)})
            (ok true))))

(define-public (revoke-endorsement (badge-id uint))
    (let ((endorsement (unwrap! (map-get? badge-endorsements {badge-id: badge-id, endorser: tx-sender}) err-endorsement-not-found))
          (current-count (unwrap-panic (map-get? badge-endorsement-count {badge-id: badge-id})))
          (current-score (unwrap-panic (map-get? badge-reputation-score {badge-id: badge-id}))))
        (begin
            (map-delete badge-endorsements {badge-id: badge-id, endorser: tx-sender})
            (map-set badge-endorsement-count {badge-id: badge-id} (- current-count u1))
            (map-set badge-reputation-score {badge-id: badge-id} (- current-score (get weight endorsement)))
            (ok true))))

(define-read-only (get-badge-reputation (badge-id uint))
    (ok {
        endorsement-count: (default-to u0 (map-get? badge-endorsement-count {badge-id: badge-id})),
        reputation-score: (default-to u0 (map-get? badge-reputation-score {badge-id: badge-id}))
    }))

(define-read-only (get-endorsement (badge-id uint) (endorser principal))
    (map-get? badge-endorsements {badge-id: badge-id, endorser: endorser}))

(define-read-only (get-endorser-weight (endorser principal))
    (map-get? authorized-endorsers endorser))
