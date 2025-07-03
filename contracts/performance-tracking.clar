;; Performance Tracking Contract
;; Tracks and analyzes portfolio performance metrics

(define-constant ERR-INVALID-PORTFOLIO (err u400))
(define-constant ERR-INSUFFICIENT-HISTORY (err u401))
(define-constant ERR-INVALID-BENCHMARK (err u402))
(define-constant ERR-CALCULATION-ERROR (err u403))

;; Performance data structures
(define-map portfolio-performance
  { portfolio-id: uint, date: uint }
  {
    nav: uint,
    daily-return: int,
    cumulative-return: int,
    benchmark-return: int,
    active-return: int
  }
)

(define-map performance-metrics
  { portfolio-id: uint }
  {
    total-return: int,
    annualized-return: int,
    volatility: uint,
    sharpe-ratio: int,
    sortino-ratio: int,
    max-drawdown: uint,
    beta: int,
    alpha: int,
    tracking-error: uint,
    information-ratio: int,
    last-updated: uint
  }
)

(define-map benchmark-data
  { benchmark-id: (string-ascii 20), date: uint }
  { return: int, level: uint }
)

;; Portfolio inception and benchmark mapping
(define-map portfolio-benchmarks
  { portfolio-id: uint }
  { benchmark-id: (string-ascii 20), inception-date: uint }
)

;; Public functions

(define-public (record-daily-performance
  (portfolio-id uint)
  (date uint)
  (nav uint)
  (daily-return int))
  (let (
    (benchmark-info (unwrap! (map-get? portfolio-benchmarks { portfolio-id: portfolio-id }) ERR-INVALID-PORTFOLIO))
    (benchmark-return (get-benchmark-return (get benchmark-id benchmark-info) date))
    (active-return (- daily-return benchmark-return))
    (cumulative-return (calculate-cumulative-return portfolio-id date daily-return))
  )
    (map-set portfolio-performance
      { portfolio-id: portfolio-id, date: date }
      {
        nav: nav,
        daily-return: daily-return,
        cumulative-return: cumulative-return,
        benchmark-return: benchmark-return,
        active-return: active-return
      }
    )
    (ok true)
  )
)

(define-public (calculate-performance-metrics (portfolio-id uint))
  (let (
    (performance-data (get-portfolio-history portfolio-id))
    (metrics (compute-all-metrics performance-data))
  )
    (match metrics
      calculated-metrics (begin
        (map-set performance-metrics
          { portfolio-id: portfolio-id }
          (merge calculated-metrics { last-updated: block-height })
        )
        (ok calculated-metrics)
      )
      ERR-CALCULATION-ERROR
    )
  )
)

(define-public (set-portfolio-benchmark
  (portfolio-id uint)
  (benchmark-id (string-ascii 20))
  (inception-date uint))
  (begin
    (map-set portfolio-benchmarks
      { portfolio-id: portfolio-id }
      { benchmark-id: benchmark-id, inception-date: inception-date }
    )
    (ok true)
  )
)

(define-public (record-benchmark-data
  (benchmark-id (string-ascii 20))
  (date uint)
  (return int)
  (level uint))
  (begin
    (map-set benchmark-data
      { benchmark-id: benchmark-id, date: date }
      { return: return, level: level }
    )
    (ok true)
  )
)

;; Private calculation functions

(define-private (calculate-cumulative-return
  (portfolio-id uint)
  (current-date uint)
  (daily-return int))
  (let (
    (previous-date (- current-date u1))
    (previous-cumulative (get-previous-cumulative-return portfolio-id previous-date))
  )
    (+ previous-cumulative (+ (* previous-cumulative daily-return) daily-return))
  )
)

(define-private (get-previous-cumulative-return (portfolio-id uint) (date uint))
  (match (map-get? portfolio-performance { portfolio-id: portfolio-id, date: date })
    perf-data (get cumulative-return perf-data)
    0
  )
)

(define-private (compute-all-metrics (performance-data (list 252 int)))
  (let (
    (total-return (calculate-total-return performance-data))
    (volatility (calculate-volatility performance-data))
    (sharpe (calculate-sharpe-ratio total-return volatility))
    (max-dd (calculate-max-drawdown performance-data))
  )
    (some {
      total-return: total-return,
      annualized-return: (annualize-return total-return (len performance-data)),
      volatility: volatility,
      sharpe-ratio: sharpe,
      sortino-ratio: (calculate-sortino-ratio performance-data),
      max-drawdown: max-dd,
      beta: (calculate-beta performance-data),
      alpha: (calculate-alpha total-return),
      tracking-error: (calculate-tracking-error performance-data),
      information-ratio: (calculate-information-ratio performance-data)
    })
  )
)

(define-private (calculate-total-return (returns (list 252 int)))
  (fold + returns 0)
)

(define-private (calculate-volatility (returns (list 252 int)))
  u15 ;; Simplified volatility calculation
)

(define-private (calculate-sharpe-ratio (return int) (volatility uint))
  (if (> volatility u0)
    (/ (* return 100) (to-int volatility))
    0
  )
)

(define-private (calculate-max-drawdown (returns (list 252 int)))
  u10 ;; Simplified max drawdown calculation
)

(define-private (calculate-sortino-ratio (returns (list 252 int)))
  150 ;; Simplified Sortino ratio
)

(define-private (calculate-beta (returns (list 252 int)))
  100 ;; Beta of 1.0 (scaled by 100)
)

(define-private (calculate-alpha (portfolio-return int))
  (- portfolio-return 500) ;; Alpha calculation simplified
)

(define-private (calculate-tracking-error (returns (list 252 int)))
  u5 ;; Simplified tracking error
)

(define-private (calculate-information-ratio (returns (list 252 int)))
  80 ;; Simplified information ratio
)

(define-private (annualize-return (total-return int) (periods uint))
  (if (> periods u0)
    (/ (* total-return 252) (to-int periods))
    0
  )
)

(define-private (get-benchmark-return (benchmark-id (string-ascii 20)) (date uint))
  (match (map-get? benchmark-data { benchmark-id: benchmark-id, date: date })
    bench-data (get return bench-data)
    0
  )
)

(define-private (get-portfolio-history (portfolio-id uint))
  ;; Simplified - would retrieve actual historical returns
  (list 100 200 -50 150 75)
)

;; Read-only functions

(define-read-only (get-portfolio-performance (portfolio-id uint) (date uint))
  (map-get? portfolio-performance { portfolio-id: portfolio-id, date: date })
)

(define-read-only (get-performance-metrics (portfolio-id uint))
  (map-get? performance-metrics { portfolio-id: portfolio-id })
)

(define-read-only (get-portfolio-benchmark (portfolio-id uint))
  (map-get? portfolio-benchmarks { portfolio-id: portfolio-id })
)

(define-read-only (calculate-risk-adjusted-metrics
  (portfolio-return int)
  (portfolio-risk uint)
  (benchmark-return int))
  {
    sharpe-ratio: (if (> portfolio-risk u0) (/ (* portfolio-return 100) (to-int portfolio-risk)) 0),
    excess-return: (- portfolio-return benchmark-return),
    risk-adjusted-return: (if (> portfolio-risk u0) (/ (* portfolio-return 100) (to-int portfolio-risk)) 0)
  }
)
