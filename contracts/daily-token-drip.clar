(define-fungible-token drip-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-time (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-transfer-failed (err u103))
(define-constant err-mint-failed (err u104))
(define-constant err-insufficient-stake (err u105))
(define-constant err-no-stake-found (err u106))

(define-constant blocks-per-day u144)
(define-constant daily-drip-amount u1000000)
(define-constant staking-reward-rate u50)
(define-constant min-stake-amount u100000)

(define-map last-claim-block principal uint)
(define-map user-total-claimed principal uint)
(define-map staking-info principal { amount: uint, stake-block: uint })
(define-map staking-rewards principal uint)

(define-data-var total-supply uint u0)
(define-data-var contract-balance uint u0)

(define-read-only (get-name)
  "Drip Token"
)

(define-read-only (get-symbol)
  "DRIP"
)

(define-read-only (get-decimals)
  u6
)

(define-read-only (get-balance (who principal))
  (ft-get-balance drip-token who)
)

(define-read-only (get-total-supply)
  (ft-get-supply drip-token)
)

(define-read-only (get-last-claim-block (who principal))
  (default-to u0 (map-get? last-claim-block who))
)

(define-read-only (get-user-total-claimed (who principal))
  (default-to u0 (map-get? user-total-claimed who))
)

(define-read-only (get-blocks-until-next-claim (who principal))
  (let (
    (last-claim (get-last-claim-block who))
    (current-block stacks-block-height)
    (blocks-since-claim (- current-block last-claim))
  )
    (if (>= blocks-since-claim blocks-per-day)
      u0
      (- blocks-per-day blocks-since-claim)
    )
  )
)

(define-read-only (can-claim-now (who principal))
  (let (
    (last-claim (get-last-claim-block who))
    (current-block stacks-block-height)
    (blocks-since-claim (- current-block last-claim))
  )
    (>= blocks-since-claim blocks-per-day)
  )
)

(define-read-only (get-contract-stats)
  {
    total-supply: (ft-get-supply drip-token),
    blocks-per-day: blocks-per-day,
    daily-drip-amount: daily-drip-amount,
    current-block: stacks-block-height
  }
)

(define-public (claim-daily-drip)
  (let (
    (claimer tx-sender)
    (last-claim (get-last-claim-block claimer))
    (current-block stacks-block-height)
    (blocks-since-claim (- current-block last-claim))
    (current-claimed (get-user-total-claimed claimer))
  )
    (asserts! (>= blocks-since-claim blocks-per-day) err-not-enough-time)
    (try! (ft-mint? drip-token daily-drip-amount claimer))
    (map-set last-claim-block claimer current-block)
    (map-set user-total-claimed claimer (+ current-claimed daily-drip-amount))
    (var-set total-supply (+ (var-get total-supply) daily-drip-amount))
    (ok daily-drip-amount)
  )
)

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-transfer-failed)
    (ft-transfer? drip-token amount from to)
  )
)

(define-public (mint-initial-supply (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? drip-token amount contract-owner))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok amount)
  )
)

(define-public (emergency-mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (ft-mint? drip-token amount recipient))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok amount)
  )
)

(define-public (set-last-claim-block-admin (user principal) (new-block-height uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set last-claim-block user new-block-height)
    (ok true)
  )
)

(define-read-only (get-user-claim-info (who principal))
  {
    last-claim-block: (get-last-claim-block who),
    total-claimed: (get-user-total-claimed who),
    current-balance: (ft-get-balance drip-token who),
    blocks-until-next-claim: (get-blocks-until-next-claim who),
    can-claim-now: (can-claim-now who)
  }
)

(define-public (bulk-claim-check (users (list 10 principal)))
  (ok (map get-user-claim-info users))
)

(define-read-only (estimate-daily-earnings (days uint))
  (* daily-drip-amount days)
)

(define-read-only (get-claim-history-summary (who principal))
  (let (
    (total-claimed (get-user-total-claimed who))
    (estimated-days (/ total-claimed daily-drip-amount))
  )
    {
      total-claimed: total-claimed,
      estimated-claim-days: estimated-days,
      average-per-claim: (if (> estimated-days u0) (/ total-claimed estimated-days) u0)
    }
  )
)

(define-public (force-claim-for-user (user principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let (
      (current-claimed (get-user-total-claimed user))
    )
      (try! (ft-mint? drip-token daily-drip-amount user))
      (map-set last-claim-block user stacks-block-height)
      (map-set user-total-claimed user (+ current-claimed daily-drip-amount))
      (var-set total-supply (+ (var-get total-supply) daily-drip-amount))
      (ok daily-drip-amount)
    )
  )
)

(define-read-only (get-global-stats)
  {
    total-token-supply: (ft-get-supply drip-token),
    daily-drip-amount: daily-drip-amount,
    blocks-per-day: blocks-per-day,
    current-stacks-block-height: stacks-block-height,
    contract-owner: contract-owner
  }
)

(define-read-only (get-staking-info (who principal))
  (map-get? staking-info who)
)

(define-read-only (get-staking-rewards (who principal))
  (default-to u0 (map-get? staking-rewards who))
)

(define-read-only (calculate-staking-rewards (who principal))
  (match (map-get? staking-info who)
    stake-data (let (
      (staked-amount (get amount stake-data))
      (stake-block (get stake-block stake-data))
      (blocks-staked (- stacks-block-height stake-block))
      (reward-periods (/ blocks-staked blocks-per-day))
      (base-reward (/ (* staked-amount staking-reward-rate) u10000))
      (total-rewards (* base-reward reward-periods))
    )
      total-rewards
    )
    u0
  )
)

(define-public (stake-tokens (amount uint))
  (let (
    (staker tx-sender)
    (current-balance (ft-get-balance drip-token staker))
    (existing-stake (map-get? staking-info staker))
  )
    (asserts! (>= amount min-stake-amount) err-insufficient-stake)
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (try! (ft-transfer? drip-token amount staker (as-contract tx-sender)))
    (match existing-stake
      current-stake (let (
        (current-amount (get amount current-stake))
        (current-stake-block (get stake-block current-stake))
        (pending-rewards (calculate-staking-rewards staker))
        (new-total-amount (+ current-amount amount))
      )
        (map-set staking-rewards staker (+ (get-staking-rewards staker) pending-rewards))
        (map-set staking-info staker { amount: new-total-amount, stake-block: stacks-block-height })
        (ok new-total-amount)
      )
      (begin
        (map-set staking-info staker { amount: amount, stake-block: stacks-block-height })
        (ok amount)
      )
    )
  )
)

(define-public (unstake-tokens (amount uint))
  (let (
    (staker tx-sender)
    (stake-data (unwrap! (map-get? staking-info staker) err-no-stake-found))
    (staked-amount (get amount stake-data))
    (pending-rewards (calculate-staking-rewards staker))
    (total-rewards (+ (get-staking-rewards staker) pending-rewards))
  )
    (asserts! (>= staked-amount amount) err-insufficient-stake)
    (try! (as-contract (ft-transfer? drip-token amount tx-sender staker)))
    (if (is-eq amount staked-amount)
      (begin
        (map-delete staking-info staker)
        (map-delete staking-rewards staker)
        (if (> total-rewards u0)
          (try! (ft-mint? drip-token total-rewards staker))
          true
        )
      )
      (map-set staking-info staker { 
        amount: (- staked-amount amount), 
        stake-block: stacks-block-height 
      })
    )
    (ok { unstaked: amount, rewards: total-rewards })
  )
)

(define-public (claim-staking-rewards)
  (let (
    (staker tx-sender)
    (stake-data (unwrap! (map-get? staking-info staker) err-no-stake-found))
    (pending-rewards (calculate-staking-rewards staker))
    (accumulated-rewards (get-staking-rewards staker))
    (total-rewards (+ pending-rewards accumulated-rewards))
  )
    (asserts! (> total-rewards u0) err-insufficient-balance)
    (try! (ft-mint? drip-token total-rewards staker))
    (map-set staking-info staker { 
      amount: (get amount stake-data), 
      stake-block: stacks-block-height 
    })
    (map-set staking-rewards staker u0)
    (ok total-rewards)
  )
)