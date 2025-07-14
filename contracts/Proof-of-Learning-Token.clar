(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-reviewer-not-found (err u103)) 
(define-constant err-already-verified (err u104))
(define-constant err-submission-not-found (err u105))
(define-constant err-invalid-quiz-score (err u106))
(define-constant err-quiz-already-taken (err u107))
(define-constant err-unauthorized (err u108))

(define-fungible-token learning-token)

(define-data-var token-name (string-ascii 32) "Proof-of-Learning-Token")
(define-data-var token-symbol (string-ascii 10) "PLT")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)

(define-map reviewers principal bool)
(define-map quiz-results { learner: principal, quiz-id: (string-ascii 64) } { score: uint, verified: bool, reviewer: (optional principal), timestamp: uint })
(define-map project-submissions { learner: principal, project-hash: (string-ascii 64) } { verified: bool, reviewer: (optional principal), timestamp: uint })
(define-map learner-quiz-count principal uint)
(define-map learner-project-count principal uint)

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-token-owner)
        (ft-transfer? learning-token amount from to)
    )
)

(define-read-only (get-name)
    (ok (var-get token-name))
)

(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance learning-token who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply learning-token))
)

(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

(define-public (add-reviewer (reviewer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set reviewers reviewer true))
    )
)

(define-public (remove-reviewer (reviewer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-delete reviewers reviewer))
    )
)

(define-public (submit-quiz-result (learner principal) (quiz-id (string-ascii 64)) (score uint))
    (begin
        (asserts! (is-some (map-get? reviewers tx-sender)) err-unauthorized)
        (asserts! (and (>= score u0) (<= score u100)) err-invalid-quiz-score)
        (asserts! (is-none (map-get? quiz-results { learner: learner, quiz-id: quiz-id })) err-quiz-already-taken)
        (let
            (
                (current-count (default-to u0 (map-get? learner-quiz-count learner)))
            )
            (map-set quiz-results 
                { learner: learner, quiz-id: quiz-id }
                { score: score, verified: false, reviewer: (some tx-sender), timestamp: stacks-block-height }
            )
            (map-set learner-quiz-count learner (+ current-count u1))
            (ok true)
        )
    )
)

(define-public (verify-quiz-result (learner principal) (quiz-id (string-ascii 64)))
    (begin
        (asserts! (is-some (map-get? reviewers tx-sender)) err-unauthorized)
        (let
            (
                (quiz-data (unwrap! (map-get? quiz-results { learner: learner, quiz-id: quiz-id }) err-submission-not-found))
                (score (get score quiz-data))
            )
            (asserts! (is-eq (get verified quiz-data) false) err-already-verified)
            (map-set quiz-results 
                { learner: learner, quiz-id: quiz-id }
                { score: score, verified: true, reviewer: (some tx-sender), timestamp: stacks-block-height }
            )
            (if (>= score u70)
                (let ((tokens-to-mint (* score u1000000)))
                    (ft-mint? learning-token tokens-to-mint learner)
                )
                (ok true)
            )
        )
    )
)

(define-public (submit-project (learner principal) (project-hash (string-ascii 64)))
    (begin
        (asserts! (is-some (map-get? reviewers tx-sender)) err-unauthorized)
        (let
            (
                (current-count (default-to u0 (map-get? learner-project-count learner)))
            )
            (map-set project-submissions 
                { learner: learner, project-hash: project-hash }
                { verified: false, reviewer: (some tx-sender), timestamp: stacks-block-height }
            )
            (map-set learner-project-count learner (+ current-count u1))
            (ok true)
        )
    )
)

(define-public (verify-project-submission (learner principal) (project-hash (string-ascii 64)))
    (begin
        (asserts! (is-some (map-get? reviewers tx-sender)) err-unauthorized)
        (let
            (
                (project-data (unwrap! (map-get? project-submissions { learner: learner, project-hash: project-hash }) err-submission-not-found))
            )
            (asserts! (is-eq (get verified project-data) false) err-already-verified)
            (map-set project-submissions 
                { learner: learner, project-hash: project-hash }
                { verified: true, reviewer: (some tx-sender), timestamp: stacks-block-height }
            )
            (ft-mint? learning-token u50000000 learner)
        )
    )
)

(define-read-only (get-quiz-result (learner principal) (quiz-id (string-ascii 64)))
    (map-get? quiz-results { learner: learner, quiz-id: quiz-id })
)

(define-read-only (get-project-submission (learner principal) (project-hash (string-ascii 64)))
    (map-get? project-submissions { learner: learner, project-hash: project-hash })
)

(define-read-only (is-reviewer (reviewer principal))
    (is-some (map-get? reviewers reviewer))
)

(define-read-only (get-learner-quiz-count (learner principal))
    (default-to u0 (map-get? learner-quiz-count learner))
)

(define-read-only (get-learner-project-count (learner principal))
    (default-to u0 (map-get? learner-project-count learner))
)

(define-public (mint (amount uint) (to principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-mint? learning-token amount to)
    )
)

(define-public (burn (amount uint) (from principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ft-burn? learning-token amount from)
    )
)

(define-public (set-token-uri (uri (optional (string-utf8 256))))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set token-uri uri))
    )
)

(map-set reviewers contract-owner true)
