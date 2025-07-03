;; Portfolio Optimization Algorithm Contract
;; Implements Modern Portfolio Theory and optimization algorithms

(define-constant ERR-INVALID-CONSTRAINTS (err u300))
(define-constant ERR-OPTIMIZATION-FAILED (err u301))
(define-constant ERR-INSUFFICIENT-ASSETS (err u302))
(define-constant ERR-INVALID-RISK-TOLERANCE (err u303))

;; Optimization parameters
(define-map optimization-constraints
  { portfolio-id: uint }
  {
    max-single-asset-weight: uint,
    min-single-asset-weight: uint,
    max-sector-concentration: uint,
    target-return: uint,
    risk-tolerance: uint
  }
)

;; Optimized portfolio allocations
(define-map optimized-portfolios
  { portfolio-id: uint }
  {
    allocations: (list 20 { asset: (string-ascii 10), weight: uint }),
    expected-return: uint,
    expected-risk: uint,
    sharpe-ratio: uint,
    optimization-date: uint
  }
)

;; Asset universe for optimization
(define-map asset-universe
  { asset: (string-ascii 10) }
  {
    expected-return: uint,
    volatility: uint,
    sector: (string-ascii 20),
    market-cap: uint,
    liquidity-score: uint
  }
)

;; Public functions

(define-public (set-optimization-constraints
  (portfolio-id uint)
  (max-single-weight uint)
  (min-single-weight uint)
  (max-sector-weight uint)
  (target-return uint)
  (risk-tolerance uint))
  (begin
    (asserts! (<= max-single-weight u100) ERR-INVALID-CONSTRAINTS)
    (asserts! (<= min-single-weight max-single-weight) ERR-INVALID-CONSTRAINTS)
    (asserts! (<= max-sector-weight u100) ERR-INVALID-CONSTRAINTS)
    (asserts! (<= risk-tolerance u100) ERR-INVALID-RISK-TOLERANCE)

    (map-set optimization-constraints
      { portfolio-id: portfolio-id }
      {
        max-single-asset-weight: max-single-weight,
        min-single-asset-weight: min-single-weight,
        max-sector-concentration: max-sector-weight,
        target-return: target-return,
        risk-tolerance: risk-tolerance
      }
    )
    (ok true)
  )
)

(define-public (optimize-portfolio
  (portfolio-id uint)
  (available-assets (list 20 (string-ascii 10)))
  (optimization-objective (string-ascii 20)))
  (begin
    (asserts! (>= (len available-assets) u2) ERR-INSUFFICIENT-ASSETS)

    (let (
      (constraints (unwrap! (map-get? optimization-constraints { portfolio-id: portfolio-id }) ERR-INVALID-CONSTRAINTS))
      (optimal-weights (calculate-optimal-weights available-assets constraints optimization-objective))
    )
      (match optimal-weights
        weights (let (
          (expected-return (calculate-portfolio-expected-return weights))
          (expected-risk (calculate-portfolio-expected-risk weights))
          (sharpe (calculate-sharpe-ratio expected-return expected-risk))
        )
          (map-set optimized-portfolios
            { portfolio-id: portfolio-id }
            {
              allocations: weights,
              expected-return: expected-return,
              expected-risk: expected-risk,
              sharpe-ratio: sharpe,
              optimization-date: block-height
            }
          )
          (ok weights)
        )
        ERR-OPTIMIZATION-FAILED
      )
    )
  )
)

(define-public (add-asset-to-universe
  (asset (string-ascii 10))
  (expected-return uint)
  (volatility uint)
  (sector (string-ascii 20))
  (market-cap uint)
  (liquidity-score uint))
  (begin
    (map-set asset-universe
      { asset: asset }
      {
        expected-return: expected-return,
        volatility: volatility,
        sector: sector,
        market-cap: market-cap,
        liquidity-score: liquidity-score
      }
    )
    (ok true)
  )
)

;; Private optimization functions

(define-private (calculate-optimal-weights
  (assets (list 20 (string-ascii 10)))
  (constraints { max-single-asset-weight: uint, min-single-asset-weight: uint, max-sector-concentration: uint, target-return: uint, risk-tolerance: uint })
  (objective (string-ascii 20)))
  (let (
    (num-assets (len assets))
    (equal-weight (/ u100 num-assets))
  )
    ;; Simplified equal-weight allocation for demonstration
    ;; In practice, this would implement mean-variance optimization
    (some (map create-equal-weight-allocation assets))
  )
)

(define-private (create-equal-weight-allocation (asset (string-ascii 10)))
  { asset: asset, weight: u5 } ;; 5% each for up to 20 assets
)

(define-private (calculate-portfolio-expected-return
  (allocations (list 20 { asset: (string-ascii 10), weight: uint })))
  (fold sum-weighted-returns allocations u0)
)

(define-private (sum-weighted-returns
  (allocation { asset: (string-ascii 10), weight: uint })
  (acc uint))
  (let (
    (asset (get asset allocation))
    (weight (get weight allocation))
    (asset-return (get-asset-expected-return asset))
  )
    (match asset-return
      return (+ acc (/ (* weight return) u100))
      acc
    )
  )
)

(define-private (calculate-portfolio-expected-risk
  (allocations (list 20 { asset: (string-ascii 10), weight: uint })))
  u15 ;; Simplified risk calculation
)

(define-private (calculate-sharpe-ratio (expected-return uint) (risk uint))
  (if (> risk u0)
    (/ (* expected-return u100) risk)
    u0
  )
)

(define-private (get-asset-expected-return (asset (string-ascii 10)))
  (match (map-get? asset-universe { asset: asset })
    asset-data (some (get expected-return asset-data))
    none
  )
)

;; Read-only functions

(define-read-only (get-optimized-portfolio (portfolio-id uint))
  (map-get? optimized-portfolios { portfolio-id: portfolio-id })
)

(define-read-only (get-optimization-constraints (portfolio-id uint))
  (map-get? optimization-constraints { portfolio-id: portfolio-id })
)

(define-read-only (get-asset-data (asset (string-ascii 10)))
  (map-get? asset-universe { asset: asset })
)

(define-read-only (calculate-efficient-frontier-point
  (target-return uint)
  (assets (list 20 (string-ascii 10))))
  ;; Simplified efficient frontier calculation
  (some { return: target-return, risk: (+ target-return u5) })
)
