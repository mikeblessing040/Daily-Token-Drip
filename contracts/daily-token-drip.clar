(define-fungible-token drip-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-enough-time (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-transfer-failed (err u103))
(define-constant err-mint-failed (err u104))
(define-constant err-insufficient-stake (err u105))
(define-constant err-no-stake-found (err u106))
(define-constant err-referral-not-found (err u107))
(define-constant err-self-referral (err u108))
(define-constant err-already-referred (err u109))

(define-constant blocks-per-day u144)
(define-constant daily-drip-amount u1000000)
(define-constant staking-reward-rate u50)
(define-constant min-stake-amount u100000)
(define-constant referral-bonus-rate u10)
(define-constant referee-bonus-rate u5)

(define-map last-claim-block principal uint)
(define-map user-total-claimed principal uint)
(define-map staking-info principal { amount: uint, stake-block: uint })
(define-map staking-rewards principal uint)
(define-map referral-codes principal uint)
(define-map code-to-user uint principal)
(define-map user-referrals principal (list 50 principal))
(define-map referral-count principal uint)
(define-map user-referrer principal principal)
(define-map referral-bonuses principal uint)

(define-data-var total-supply uint u0)
(define-data-var contract-balance uint u0)
(define-data-var next-referral-code uint u1000)

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

(define-read-only (get-referral-code (who principal))
  (map-get? referral-codes who)
)

(define-read-only (get-user-by-code (code uint))
  (map-get? code-to-user code)
)

(define-read-only (get-referral-count (who principal))
  (default-to u0 (map-get? referral-count who))
)

(define-read-only (get-user-referrer (who principal))
  (map-get? user-referrer who)
)

(define-read-only (get-referral-bonuses (who principal))
  (default-to u0 (map-get? referral-bonuses who))
)

(define-read-only (get-referral-tier (who principal))
  (let (
    (ref-count (get-referral-count who))
  )
    (if (>= ref-count u50) u4
      (if (>= ref-count u25) u3
        (if (>= ref-count u10) u2
          (if (>= ref-count u5) u1 u0)
        )
      )
    )
  )
)

(define-read-only (calculate-tier-bonus (tier uint))
  (if (is-eq tier u4) u25
    (if (is-eq tier u3) u20
      (if (is-eq tier u2) u15
        (if (is-eq tier u1) u10 u0)
      )
    )
  )
)

(define-public (create-referral-code)
  (let (
    (user tx-sender)
    (current-code (var-get next-referral-code))
    (existing-code (map-get? referral-codes user))
  )
    (asserts! (is-none existing-code) err-already-referred)
    (map-set referral-codes user current-code)
    (map-set code-to-user current-code user)
    (var-set next-referral-code (+ current-code u1))
    (ok current-code)
  )
)

(define-public (join-with-referral (referral-code uint))
  (let (
    (new-user tx-sender)
    (referrer (unwrap! (map-get? code-to-user referral-code) err-referral-not-found))
    (existing-referrer (map-get? user-referrer new-user))
  )
    (asserts! (not (is-eq new-user referrer)) err-self-referral)
    (asserts! (is-none existing-referrer) err-already-referred)
    (let (
      (current-refs (default-to (list) (map-get? user-referrals referrer)))
      (current-count (get-referral-count referrer))
      (tier (get-referral-tier referrer))
      (tier-bonus (calculate-tier-bonus tier))
      (referrer-bonus (/ (* daily-drip-amount (+ referral-bonus-rate tier-bonus)) u100))
      (referee-bonus (/ (* daily-drip-amount referee-bonus-rate) u100))
    )
      (map-set user-referrer new-user referrer)
      (map-set user-referrals referrer (unwrap-panic (as-max-len? (append current-refs new-user) u50)))
      (map-set referral-count referrer (+ current-count u1))
      (if (> referrer-bonus u0)
        (begin
          (try! (ft-mint? drip-token referrer-bonus referrer))
          (map-set referral-bonuses referrer (+ (get-referral-bonuses referrer) referrer-bonus))
        )
        true
      )
      (if (> referee-bonus u0)
        (begin
          (try! (ft-mint? drip-token referee-bonus new-user))
          (map-set referral-bonuses new-user (+ (get-referral-bonuses new-user) referee-bonus))
        )
        true
      )
      (ok { referrer: referrer, referrer-bonus: referrer-bonus, referee-bonus: referee-bonus })
    )
  )
)

(define-public (claim-with-referral-bonus)
  (let (
    (claimer tx-sender)
    (last-claim (get-last-claim-block claimer))
    (current-block stacks-block-height)
    (blocks-since-claim (- current-block last-claim))
    (current-claimed (get-user-total-claimed claimer))
    (base-amount daily-drip-amount)
    (referrer-opt (map-get? user-referrer claimer))
  )
    (asserts! (>= blocks-since-claim blocks-per-day) err-not-enough-time)
    (let (
      (bonus-amount (match referrer-opt
        referrer (let (
          (tier (get-referral-tier referrer))
          (bonus-rate (/ (calculate-tier-bonus tier) u2))
        )
          (/ (* base-amount bonus-rate) u100)
        )
        u0
      ))
      (total-amount (+ base-amount bonus-amount))
    )
      (try! (ft-mint? drip-token total-amount claimer))
      (map-set last-claim-block claimer current-block)
      (map-set user-total-claimed claimer (+ current-claimed total-amount))
      (var-set total-supply (+ (var-get total-supply) total-amount))
      (ok { base-amount: base-amount, bonus-amount: bonus-amount, total-amount: total-amount })
    )
  )
)

(define-read-only (get-referral-network-info (who principal))
  {
    referral-code: (map-get? referral-codes who),
    referrer: (map-get? user-referrer who),
    referral-count: (get-referral-count who),
    referral-tier: (get-referral-tier who),
    total-bonuses: (get-referral-bonuses who),
    tier-bonus-rate: (calculate-tier-bonus (get-referral-tier who))
  }
)