;; Scheduling Management Contract
;; Manages cross-dock scheduling and time slots

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-INPUT (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-TIME-CONFLICT (err u105))

;; Data Variables
(define-data-var next-schedule-id uint u1)

;; Data Maps
(define-map schedules
  uint
  {
    start-time: uint,
    end-time: uint,
    capacity: uint,
    coordinator: principal,
    facility: (string-ascii 50),
    operation-type: (string-ascii 20),
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map time-slots
  { facility: (string-ascii 50), time-slot: uint }
  {
    available: bool,
    reserved-by: (optional principal),
    capacity-used: uint,
    max-capacity: uint
  }
)

;; Read-only functions
(define-read-only (get-schedule (schedule-id uint))
  (map-get? schedules schedule-id)
)

(define-read-only (get-time-slot (facility (string-ascii 50)) (time-slot uint))
  (map-get? time-slots { facility: facility, time-slot: time-slot })
)

(define-read-only (is-time-slot-available (facility (string-ascii 50)) (time-slot uint))
  (match (get-time-slot facility time-slot)
    slot-info (get available slot-info)
    true
  )
)

(define-read-only (get-schedule-conflicts (facility (string-ascii 50)) (start-time uint) (end-time uint))
  (let
    (
      (time-range (- end-time start-time))
    )
    (> time-range u0)
  )
)

;; Public functions
(define-public (create-schedule (start-time uint) (end-time uint) (capacity uint) (facility (string-ascii 50)) (operation-type (string-ascii 20)))
  (let
    (
      (schedule-id (var-get next-schedule-id))
    )
    (asserts! (< start-time end-time) ERR-INVALID-INPUT)
    (asserts! (> capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len facility) u0) ERR-INVALID-INPUT)
    (asserts! (> (len operation-type) u0) ERR-INVALID-INPUT)

    (map-set schedules schedule-id
      {
        start-time: start-time,
        end-time: end-time,
        capacity: capacity,
        coordinator: tx-sender,
        facility: facility,
        operation-type: operation-type,
        status: "scheduled",
        created-at: block-height
      }
    )

    (var-set next-schedule-id (+ schedule-id u1))

    (ok schedule-id)
  )
)

(define-public (reserve-time-slot (facility (string-ascii 50)) (time-slot uint) (capacity-needed uint))
  (let
    (
      (slot-key { facility: facility, time-slot: time-slot })
      (existing-slot (map-get? time-slots slot-key))
    )
    (asserts! (> (len facility) u0) ERR-INVALID-INPUT)
    (asserts! (> capacity-needed u0) ERR-INVALID-INPUT)

    (match existing-slot
      slot-info
      (begin
        (asserts! (get available slot-info) ERR-TIME-CONFLICT)
        (asserts! (<= (+ (get capacity-used slot-info) capacity-needed) (get max-capacity slot-info)) ERR-INVALID-INPUT)

        (map-set time-slots slot-key
          (merge slot-info
            {
              capacity-used: (+ (get capacity-used slot-info) capacity-needed),
              reserved-by: (some tx-sender)
            }
          )
        )
      )
      (map-set time-slots slot-key
        {
          available: true,
          reserved-by: (some tx-sender),
          capacity-used: capacity-needed,
          max-capacity: u1000
        }
      )
    )

    (ok true)
  )
)

(define-public (update-schedule-status (schedule-id uint) (new-status (string-ascii 20)))
  (let
    (
      (schedule (unwrap! (get-schedule schedule-id) ERR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get coordinator schedule))) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (map-set schedules schedule-id
      (merge schedule { status: new-status })
    )

    (ok true)
  )
)

(define-public (cancel-schedule (schedule-id uint))
  (let
    (
      (schedule (unwrap! (get-schedule schedule-id) ERR-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get coordinator schedule))) ERR-NOT-AUTHORIZED)

    (map-set schedules schedule-id
      (merge schedule { status: "cancelled" })
    )

    (ok true)
  )
)

(define-public (release-time-slot (facility (string-ascii 50)) (time-slot uint))
  (let
    (
      (slot-key { facility: facility, time-slot: time-slot })
      (slot-info (unwrap! (get-time-slot facility time-slot) ERR-NOT-FOUND))
    )
    (asserts! (is-some (get reserved-by slot-info)) ERR-NOT-FOUND)
    (asserts! (is-eq tx-sender (unwrap-panic (get reserved-by slot-info))) ERR-NOT-AUTHORIZED)

    (map-set time-slots slot-key
      (merge slot-info
        {
          available: true,
          reserved-by: none,
          capacity-used: u0
        }
      )
    )

    (ok true)
  )
)

(define-public (set-time-slot-capacity (facility (string-ascii 50)) (time-slot uint) (max-capacity uint))
  (let
    (
      (slot-key { facility: facility, time-slot: time-slot })
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> max-capacity u0) ERR-INVALID-INPUT)

    (map-set time-slots slot-key
      {
        available: true,
        reserved-by: none,
        capacity-used: u0,
        max-capacity: max-capacity
      }
    )

    (ok true)
  )
)
