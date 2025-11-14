(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_NOT_FOUND (err u404))
(define-constant ERR_INVALID_AMOUNT (err u400))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_ALREADY_EXISTS (err u409))
(define-constant ERR_MIRROR_EXPIRED (err u403))
(define-constant ERR_INVALID_REFLECTION (err u405))
(define-constant ERR_MIRROR_INACTIVE (err u406))

(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var total-mirrors uint u0)
(define-data-var total-reflections uint u0)
(define-data-var global-reflection-rate uint u100)
(define-data-var mirror-fee uint u1000)
(define-data-var reflection-pool uint u0)

(define-map mirrors
    { mirror-id: uint }
    {
        creator: principal,
        original-asset: uint,
        mirror-asset: uint,
        reflection-multiplier: uint,
        created-at: uint,
        expires-at: uint,
        is-active: bool,
        total-reflections: uint
    }
)

(define-map user-mirrors
    { user: principal }
    {
        owned-mirrors: (list 100 uint),
        total-created: uint,
        reputation-score: uint
    }
)

(define-map reflections
    { reflection-id: uint }
    {
        mirror-id: uint,
        reflector: principal,
        amount: uint,
        timestamp: uint,
        reward-earned: uint,
        is-claimed: bool
    }
)

(define-map asset-registry
    { asset-id: uint }
    {
        owner: principal,
        value: uint,
        mirror-count: uint,
        total-reflected: uint,
        metadata: (string-ascii 256)
    }
)

(define-map user-balances
    { user: principal }
    {
        mirror-tokens: uint,
        reflection-rewards: uint,
        staked-amount: uint
    }
)

(define-map mirror-reflectors
    { mirror-id: uint, reflector: principal }
    {
        total-reflected: uint,
        last-reflection: uint,
        reward-multiplier: uint
    }
)

(define-read-only (get-mirror (mirror-id uint))
    (map-get? mirrors { mirror-id: mirror-id })
)

(define-read-only (get-user-mirrors (user principal))
    (map-get? user-mirrors { user: user })
)

(define-read-only (get-reflection (reflection-id uint))
    (map-get? reflections { reflection-id: reflection-id })
)

(define-read-only (get-asset (asset-id uint))
    (map-get? asset-registry { asset-id: asset-id })
)

(define-read-only (get-user-balance (user principal))
    (map-get? user-balances { user: user })
)

(define-read-only (get-mirror-reflector (mirror-id uint) (reflector principal))
    (map-get? mirror-reflectors { mirror-id: mirror-id, reflector: reflector })
)

(define-read-only (get-total-mirrors)
    (var-get total-mirrors)
)

(define-read-only (get-total-reflections)
    (var-get total-reflections)
)

(define-read-only (get-reflection-pool)
    (var-get reflection-pool)
)

(define-read-only (get-global-reflection-rate)
    (var-get global-reflection-rate)
)

(define-read-only (calculate-reflection-reward (amount uint) (multiplier uint))
    (/ (* amount multiplier) u10000)
)

(define-read-only (is-mirror-active (mirror-id uint))
    (match (get-mirror mirror-id)
        mirror (and 
            (get is-active mirror)
            (> (get expires-at mirror) stacks-block-height)
        )
        false
    )
)

(define-public (register-asset (asset-id uint) (value uint) (metadata (string-ascii 256)))
    (let ((existing-asset (get-asset asset-id)))
        (asserts! (is-none existing-asset) ERR_ALREADY_EXISTS)
        (asserts! (> value u0) ERR_INVALID_AMOUNT)
        (ok (map-set asset-registry
            { asset-id: asset-id }
            {
                owner: tx-sender,
                value: value,
                mirror-count: u0,
                total-reflected: u0,
                metadata: metadata
            }
        ))
    )
)

(define-public (create-mirror (original-asset uint) (mirror-asset uint) (reflection-multiplier uint) (duration uint))
    (let (
        (mirror-id (+ (var-get total-mirrors) u1))
        (current-height stacks-block-height)
        (expires-at (+ current-height duration))
        (user-data (default-to { owned-mirrors: (list), total-created: u0, reputation-score: u0 } 
                               (get-user-mirrors tx-sender)))
    )
        (asserts! (is-some (get-asset original-asset)) ERR_NOT_FOUND)
        (asserts! (is-some (get-asset mirror-asset)) ERR_NOT_FOUND)
        (asserts! (> reflection-multiplier u0) ERR_INVALID_AMOUNT)
        (asserts! (> duration u0) ERR_INVALID_AMOUNT)
        
        (map-set mirrors
            { mirror-id: mirror-id }
            {
                creator: tx-sender,
                original-asset: original-asset,
                mirror-asset: mirror-asset,
                reflection-multiplier: reflection-multiplier,
                created-at: current-height,
                expires-at: expires-at,
                is-active: true,
                total-reflections: u0
            }
        )
        
        (map-set user-mirrors
            { user: tx-sender }
            {
                owned-mirrors: (unwrap-panic (as-max-len? (append (get owned-mirrors user-data) mirror-id) u100)),
                total-created: (+ (get total-created user-data) u1),
                reputation-score: (+ (get reputation-score user-data) u10)
            }
        )
        
        (var-set total-mirrors mirror-id)
        (ok mirror-id)
    )
)

(define-public (create-reflection (mirror-id uint) (amount uint))
    (let (
        (mirror (unwrap! (get-mirror mirror-id) ERR_NOT_FOUND))
        (reflection-id (+ (var-get total-reflections) u1))
        (current-balance (default-to { mirror-tokens: u0, reflection-rewards: u0, staked-amount: u0 } 
                                    (get-user-balance tx-sender)))
        (reward-amount (calculate-reflection-reward amount (get reflection-multiplier mirror)))
        (existing-reflector (default-to { total-reflected: u0, last-reflection: u0, reward-multiplier: u100 }
                                       (get-mirror-reflector mirror-id tx-sender)))
    )
        (asserts! (is-mirror-active mirror-id) ERR_MIRROR_INACTIVE)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= (get mirror-tokens current-balance) amount) ERR_INSUFFICIENT_BALANCE)
        
        (map-set reflections
            { reflection-id: reflection-id }
            {
                mirror-id: mirror-id,
                reflector: tx-sender,
                amount: amount,
                timestamp: stacks-block-height,
                reward-earned: reward-amount,
                is-claimed: false
            }
        )
        
        (map-set user-balances
            { user: tx-sender }
            {
                mirror-tokens: (- (get mirror-tokens current-balance) amount),
                reflection-rewards: (+ (get reflection-rewards current-balance) reward-amount),
                staked-amount: (get staked-amount current-balance)
            }
        )
        
        (map-set mirror-reflectors
            { mirror-id: mirror-id, reflector: tx-sender }
            {
                total-reflected: (+ (get total-reflected existing-reflector) amount),
                last-reflection: stacks-block-height,
                reward-multiplier: (if (< (+ (get reward-multiplier existing-reflector) u5) u200) (+ (get reward-multiplier existing-reflector) u5) u200)
            }
        )
        
        (map-set mirrors
            { mirror-id: mirror-id }
            (merge mirror { total-reflections: (+ (get total-reflections mirror) u1) })
        )
        
        (var-set total-reflections reflection-id)
        (var-set reflection-pool (+ (var-get reflection-pool) amount))
        (ok reflection-id)
    )
)

(define-public (claim-reflection-reward (reflection-id uint))
    (let ((reflection (unwrap! (get-reflection reflection-id) ERR_NOT_FOUND)))
        (asserts! (is-eq (get reflector reflection) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (not (get is-claimed reflection)) ERR_ALREADY_EXISTS)
        
        (map-set reflections
            { reflection-id: reflection-id }
            (merge reflection { is-claimed: true })
        )
        
        (let ((current-balance (default-to { mirror-tokens: u0, reflection-rewards: u0, staked-amount: u0 } 
                                          (get-user-balance tx-sender))))
            (map-set user-balances
                { user: tx-sender }
                {
                    mirror-tokens: (+ (get mirror-tokens current-balance) (get reward-earned reflection)),
                    reflection-rewards: (- (get reflection-rewards current-balance) (get reward-earned reflection)),
                    staked-amount: (get staked-amount current-balance)
                }
            )
        )
        (ok true)
    )
)

(define-public (mint-mirror-tokens (user principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        (let ((current-balance (default-to { mirror-tokens: u0, reflection-rewards: u0, staked-amount: u0 } 
                                          (get-user-balance user))))
            (map-set user-balances
                { user: user }
                {
                    mirror-tokens: (+ (get mirror-tokens current-balance) amount),
                    reflection-rewards: (get reflection-rewards current-balance),
                    staked-amount: (get staked-amount current-balance)
                }
            )
        )
        (ok true)
    )
)

(define-public (stake-tokens (amount uint))
    (let ((current-balance (default-to { mirror-tokens: u0, reflection-rewards: u0, staked-amount: u0 } 
                                      (get-user-balance tx-sender))))
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= (get mirror-tokens current-balance) amount) ERR_INSUFFICIENT_BALANCE)
        
        (map-set user-balances
            { user: tx-sender }
            {
                mirror-tokens: (- (get mirror-tokens current-balance) amount),
                reflection-rewards: (get reflection-rewards current-balance),
                staked-amount: (+ (get staked-amount current-balance) amount)
            }
        )
        (ok true)
    )
)

(define-public (unstake-tokens (amount uint))
    (let ((current-balance (default-to { mirror-tokens: u0, reflection-rewards: u0, staked-amount: u0 } 
                                      (get-user-balance tx-sender))))
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (>= (get staked-amount current-balance) amount) ERR_INSUFFICIENT_BALANCE)
        
        (map-set user-balances
            { user: tx-sender }
            {
                mirror-tokens: (+ (get mirror-tokens current-balance) amount),
                reflection-rewards: (get reflection-rewards current-balance),
                staked-amount: (- (get staked-amount current-balance) amount)
            }
        )
        (ok true)
    )
)

(define-public (deactivate-mirror (mirror-id uint))
    (let ((mirror (unwrap! (get-mirror mirror-id) ERR_NOT_FOUND)))
        (asserts! (is-eq (get creator mirror) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (get is-active mirror) ERR_MIRROR_INACTIVE)
        
        (map-set mirrors
            { mirror-id: mirror-id }
            (merge mirror { is-active: false })
        )
        (ok true)
    )
)

(define-public (update-global-reflection-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (asserts! (and (>= new-rate u1) (<= new-rate u1000)) ERR_INVALID_AMOUNT)
        (var-set global-reflection-rate new-rate)
        (ok true)
    )
)

(define-public (update-mirror-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (asserts! (>= new-fee u0) ERR_INVALID_AMOUNT)
        (var-set mirror-fee new-fee)
        (ok true)
    )
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)
