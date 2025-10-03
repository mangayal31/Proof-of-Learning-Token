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

(define-constant err-invalid-milestone (err u109))
(define-constant milestone-bronze-threshold u3)
(define-constant milestone-silver-threshold u7)  
(define-constant milestone-gold-threshold u15)
(define-constant milestone-platinum-threshold u25)

(define-constant err-no-recent-activity (err u110))
(define-constant streak-bonus-base u5000000)
(define-constant max-streak-bonus-days u30)

(define-constant err-self-recognition (err u111))
(define-constant err-daily-limit-reached (err u112))
(define-constant err-invalid-badge-type (err u113))
(define-constant recognition-token-amount u2000000)
(define-constant max-daily-recognitions u5)

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

(define-map learner-milestones principal 
    { bronze: bool, silver: bool, gold: bool, platinum: bool, last-bonus-block: uint })

(define-private (calculate-learner-score (learner principal))
    (let 
        (
            (quiz-count (get-learner-quiz-count learner))
            (project-count (get-learner-project-count learner))
            (total-score (+ quiz-count (* project-count u2)))
        )
        total-score
    )
)

(define-private (get-milestone-tier (score uint))
    (if (>= score milestone-platinum-threshold) u4
        (if (>= score milestone-gold-threshold) u3
            (if (>= score milestone-silver-threshold) u2
                (if (>= score milestone-bronze-threshold) u1 u0)
            )
        )
    )
)

(define-public (check-milestone-progress (learner principal))
    (let
        (
            (current-score (calculate-learner-score learner))
            (current-tier (get-milestone-tier current-score))
            (existing-data (default-to { bronze: false, silver: false, gold: false, platinum: false, last-bonus-block: u0 } 
                                       (map-get? learner-milestones learner)))
            (bonus-tokens u0)
        )
        (let 
            (
                (updated-data (merge existing-data 
                    {
                        bronze: (or (get bronze existing-data) (>= current-tier u1)),
                        silver: (or (get silver existing-data) (>= current-tier u2)),
                        gold: (or (get gold existing-data) (>= current-tier u3)),
                        platinum: (or (get platinum existing-data) (>= current-tier u4))
                    }))
                (new-achievements (+ 
                    (if (and (>= current-tier u1) (not (get bronze existing-data))) u1 u0)
                    (if (and (>= current-tier u2) (not (get silver existing-data))) u1 u0)
                    (if (and (>= current-tier u3) (not (get gold existing-data))) u1 u0)
                    (if (and (>= current-tier u4) (not (get platinum existing-data))) u1 u0)))
            )
            (map-set learner-milestones learner 
                (merge updated-data { last-bonus-block: stacks-block-height }))
            (if (> new-achievements u0)
                (ft-mint? learning-token (* new-achievements u25000000) learner)
                (ok true)
            )
        )
    )
)

(define-read-only (get-learner-milestones (learner principal))
    (let
        (
            (current-score (calculate-learner-score learner))
            (milestone-data (map-get? learner-milestones learner))
        )
        (ok { 
            current-score: current-score,
            current-tier: (get-milestone-tier current-score),
            milestones: milestone-data
        })
    )
)


(define-map learner-streaks principal 
    { current-streak: uint, longest-streak: uint, last-activity-day: uint, total-bonus-earned: uint })

(define-private (get-day-from-block (height uint))
    (/ height u144)
)

(define-private (calculate-streak-bonus (streak-days uint))
    (if (<= streak-days u0) u0
        (let ((bonus-multiplier (if (> streak-days max-streak-bonus-days) max-streak-bonus-days streak-days)))
            (* streak-bonus-base bonus-multiplier)
        )
    )
)

(define-public (update-learning-streak (learner principal))
    (let
        (
            (current-day (get-day-from-block stacks-block-height))
            (existing-data (default-to 
                { current-streak: u0, longest-streak: u0, last-activity-day: u0, total-bonus-earned: u0 }
                (map-get? learner-streaks learner)))
            (last-day (get last-activity-day existing-data))
            (current-streak (get current-streak existing-data))
            (longest-streak (get longest-streak existing-data))
        )
        (let
            (
                (days-since-last (if (> current-day last-day) (- current-day last-day) u0))
                (new-streak (if (is-eq days-since-last u1) 
                               (+ current-streak u1)
                               (if (is-eq days-since-last u0) current-streak u1)))
                (new-longest (if (> new-streak longest-streak) new-streak longest-streak))
                (streak-bonus (if (and (> new-streak current-streak) (> new-streak u2))
                                 (calculate-streak-bonus new-streak) u0))
            )
            (map-set learner-streaks learner
                { current-streak: new-streak, 
                  longest-streak: new-longest,
                  last-activity-day: current-day,
                  total-bonus-earned: (+ (get total-bonus-earned existing-data) streak-bonus) })
            (if (> streak-bonus u0)
                (ft-mint? learning-token streak-bonus learner)
                (ok true)
            )
        )
    )
)

(define-read-only (get-learner-streak (learner principal))
    (let
        (
            (current-day (get-day-from-block stacks-block-height))
            (streak-data (map-get? learner-streaks learner))
        )
        (match streak-data
            data (let ((days-since (if (> current-day (get last-activity-day data)) 
                                     (- current-day (get last-activity-day data)) u0)))
                     (ok (merge data { days-since-last-activity: days-since,
                                     streak-expired: (> days-since u1) })))
            (ok { current-streak: u0, longest-streak: u0, last-activity-day: u0, 
                  total-bonus-earned: u0, days-since-last-activity: u0, streak-expired: true })
        )
    )
)


(define-map peer-recognitions 
    { recipient: principal, endorser: principal, badge-id: uint }
    { badge-type: (string-ascii 32), token-amount: uint, timestamp: uint, message: (string-utf8 256) })

(define-map recognition-counts principal { given: uint, received: uint })

(define-map daily-recognition-tracker 
    { endorser: principal, day: uint }
    { count: uint })

(define-data-var recognition-nonce uint u0)

(define-private (get-current-day)
    (/ stacks-block-height u144))

(define-private (is-valid-badge-type (badge-type (string-ascii 32)))
    (or (is-eq badge-type "helpful-mentor")
        (or (is-eq badge-type "great-collaborator")
            (or (is-eq badge-type "inspiring-learner")
                (is-eq badge-type "problem-solver")))))

(define-public (grant-peer-recognition 
    (recipient principal) 
    (badge-type (string-ascii 32))
    (message (string-utf8 256)))
    (let
        (
            (endorser tx-sender)
            (current-day (get-current-day))
            (daily-key { endorser: endorser, day: current-day })
            (daily-count (default-to { count: u0 } (map-get? daily-recognition-tracker daily-key)))
            (badge-id (var-get recognition-nonce))
            (recipient-counts (default-to { given: u0, received: u0 } 
                (map-get? recognition-counts recipient)))
            (endorser-counts (default-to { given: u0, received: u0 } 
                (map-get? recognition-counts endorser)))
        )
        (asserts! (not (is-eq endorser recipient)) err-self-recognition)
        (asserts! (< (get count daily-count) max-daily-recognitions) err-daily-limit-reached)
        (asserts! (is-valid-badge-type badge-type) err-invalid-badge-type)
        (asserts! (>= (ft-get-balance learning-token endorser) recognition-token-amount) 
            err-insufficient-balance)
        
        (try! (ft-transfer? learning-token recognition-token-amount endorser recipient))
        
        (map-set peer-recognitions
            { recipient: recipient, endorser: endorser, badge-id: badge-id }
            { badge-type: badge-type, token-amount: recognition-token-amount, 
              timestamp: stacks-block-height, message: message })
        
        (map-set daily-recognition-tracker daily-key 
            { count: (+ (get count daily-count) u1) })
        
        (map-set recognition-counts recipient 
            { given: (get given recipient-counts), 
              received: (+ (get received recipient-counts) u1) })
        
        (map-set recognition-counts endorser 
            { given: (+ (get given endorser-counts) u1), 
              received: (get received endorser-counts) })
        
        (var-set recognition-nonce (+ badge-id u1))
        (ok badge-id)))

(define-read-only (get-recognition-stats (learner principal))
    (ok (default-to { given: u0, received: u0 } 
        (map-get? recognition-counts learner))))

(define-read-only (get-daily-recognition-count (endorser principal))
    (let ((current-day (get-current-day)))
        (ok (get count (default-to { count: u0 } 
            (map-get? daily-recognition-tracker { endorser: endorser, day: current-day }))))))

(define-read-only (get-recognition-details 
    (recipient principal) 
    (endorser principal) 
    (badge-id uint))
    (ok (map-get? peer-recognitions { recipient: recipient, endorser: endorser, badge-id: badge-id })))