(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-authorized (err u401))
(define-constant err-milestone-not-found (err u402))
(define-constant err-already-claimed (err u403))
(define-constant err-requirements-not-met (err u404))
(define-constant err-invalid-threshold (err u405))

(define-map milestones
  {milestone-id: uint}
  {
    name: (string-ascii 100),
    description: (string-ascii 300),
    badge-type-filter: (optional (string-ascii 50)),
    threshold: uint,
    reward-metadata: (string-ascii 200),
    creator: principal,
    active: bool
  })

(define-map milestone-achievements
  {user: principal, milestone-id: uint}
  {achieved-at: uint, badge-count-at-achievement: uint})

(define-map user-achievement-count principal uint)

(define-data-var next-milestone-id uint u1)

(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner))

(define-public (create-milestone
  (name (string-ascii 100))
  (description (string-ascii 300))
  (badge-type-filter (optional (string-ascii 50)))
  (threshold uint)
  (reward-metadata (string-ascii 200)))
  (let ((milestone-id (var-get next-milestone-id)))
    (begin
      (asserts! (is-contract-owner) err-owner-only)
      (asserts! (> threshold u0) err-invalid-threshold)
      (map-set milestones
        {milestone-id: milestone-id}
        {
          name: name,
          description: description,
          badge-type-filter: badge-type-filter,
          threshold: threshold,
          reward-metadata: reward-metadata,
          creator: tx-sender,
          active: true
        })
      (var-set next-milestone-id (+ milestone-id u1))
      (ok milestone-id))))

(define-public (toggle-milestone (milestone-id uint))
  (let ((milestone-data (unwrap! (map-get? milestones {milestone-id: milestone-id}) err-milestone-not-found)))
    (begin
      (asserts! (is-contract-owner) err-owner-only)
      (map-set milestones
        {milestone-id: milestone-id}
        (merge milestone-data {active: (not (get active milestone-data))}))
      (ok true))))

(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones {milestone-id: milestone-id}))

(define-read-only (get-user-achievements (user principal))
  (default-to u0 (map-get? user-achievement-count user)))

(define-read-only (has-achieved-milestone (user principal) (milestone-id uint))
  (is-some (map-get? milestone-achievements {user: user, milestone-id: milestone-id})))

(define-read-only (get-achievement-details (user principal) (milestone-id uint))
  (map-get? milestone-achievements {user: user, milestone-id: milestone-id}))

(define-read-only (get-milestone-count)
  (- (var-get next-milestone-id) u1))
