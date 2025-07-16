;; Quality Control Contract
;; Controls and monitors cross-dock quality standards

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))

;; Data Variables
(define-data-var next-inspection-id uint u1)
(define-data-var next-standard-id uint u1)

;; Data Maps
(define-map quality-standards
  uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    min-score: uint,
    category: (string-ascii 30),
    active: bool,
    created-by: principal,
    created-at: uint
  }
)

(define-map quality-inspections
  uint
  {
    standard-id: uint,
    inspector: principal,
    facility: (string-ascii 50),
    score: uint,
    notes: (string-ascii 200),
    passed: bool,
    inspection-date: uint
  }
)

(define-map facility-quality-metrics
  (string-ascii 50)
  {
    total-inspections: uint,
    passed-inspections: uint,
    average-score: uint,
    last-inspection: uint
  }
)

;; Read-only functions
(define-read-only (get-quality-standard (standard-id uint))
  (map-get? quality-standards standard-id)
)

(define-read-only (get-quality-inspection (inspection-id uint))
  (map-get? quality-inspections inspection-id)
)

(define-read-only (get-facility-metrics (facility (string-ascii 50)))
  (map-get? facility-quality-metrics facility)
)

(define-read-only (calculate-pass-rate (facility (string-ascii 50)))
  (match (get-facility-metrics facility)
    metrics
    (let
      (
        (total (get total-inspections metrics))
        (passed (get passed-inspections metrics))
      )
      (if (> total u0)
        (some (/ (* passed u100) total))
        (some u0)
      )
    )
    none
  )
)

;; Public functions
(define-public (create-quality-standard (name (string-ascii 50)) (description (string-ascii 200)) (min-score uint) (category (string-ascii 30)))
  (let
    (
      (standard-id (var-get next-standard-id))
    )
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= min-score u0) (<= min-score u100)) ERR-INVALID-INPUT)
    (asserts! (> (len category) u0) ERR-INVALID-INPUT)

    (map-set quality-standards standard-id
      {
        name: name,
        description: description,
        min-score: min-score,
        category: category,
        active: true,
        created-by: tx-sender,
        created-at: block-height
      }
    )

    (var-set next-standard-id (+ standard-id u1))

    (ok standard-id)
  )
)

(define-public (record-inspection (standard-id uint) (facility (string-ascii 50)) (score uint) (notes (string-ascii 200)))
  (let
    (
      (inspection-id (var-get next-inspection-id))
      (standard (unwrap! (get-quality-standard standard-id) ERR-NOT-FOUND))
      (passed (>= score (get min-score standard)))
      (current-metrics (map-get? facility-quality-metrics facility))
    )
    (asserts! (get active standard) ERR-INVALID-INPUT)
    (asserts! (> (len facility) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-INPUT)

    (map-set quality-inspections inspection-id
      {
        standard-id: standard-id,
        inspector: tx-sender,
        facility: facility,
        score: score,
        notes: notes,
        passed: passed,
        inspection-date: block-height
      }
    )

    (match current-metrics
      metrics
      (let
        (
          (new-total (+ (get total-inspections metrics) u1))
          (new-passed (if passed (+ (get passed-inspections metrics) u1) (get passed-inspections metrics)))
          (new-average (/ (+ (* (get average-score metrics) (get total-inspections metrics)) score) new-total))
        )
        (map-set facility-quality-metrics facility
          {
            total-inspections: new-total,
            passed-inspections: new-passed,
            average-score: new-average,
            last-inspection: block-height
          }
        )
      )
      (map-set facility-quality-metrics facility
        {
          total-inspections: u1,
          passed-inspections: (if passed u1 u0),
          average-score: score,
          last-inspection: block-height
        }
      )
    )

    (var-set next-inspection-id (+ inspection-id u1))

    (ok inspection-id)
  )
)

(define-public (update-quality-standard (standard-id uint) (min-score uint))
  (let
    (
      (standard (unwrap! (get-quality-standard standard-id) ERR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get created-by standard))) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= min-score u0) (<= min-score u100)) ERR-INVALID-INPUT)

    (map-set quality-standards standard-id
      (merge standard { min-score: min-score })
    )

    (ok true)
  )
)

(define-public (deactivate-quality-standard (standard-id uint))
  (let
    (
      (standard (unwrap! (get-quality-standard standard-id) ERR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get created-by standard))) ERR-NOT-AUTHORIZED)

    (map-set quality-standards standard-id
      (merge standard { active: false })
    )

    (ok true)
  )
)

(define-public (reactivate-quality-standard (standard-id uint))
  (let
    (
      (standard (unwrap! (get-quality-standard standard-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set quality-standards standard-id
      (merge standard { active: true })
    )

    (ok true)
  )
)
