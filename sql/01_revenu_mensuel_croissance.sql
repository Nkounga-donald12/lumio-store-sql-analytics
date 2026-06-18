-- =============================================================================
-- 01 — REVENU MENSUEL & CROISSANCE MoM (Month-over-Month)
-- -----------------------------------------------------------------------------
-- Question business : Comment évolue notre chiffre d'affaires mois après mois ?
-- Quels mois ont connu une accélération ou une chute de croissance ?
--
-- Techniques : CTE, fonction fenêtre LAG(), agrégation, gestion des dates SQLite
-- =============================================================================

WITH revenu_mensuel AS (
    SELECT
        strftime('%Y-%m', o.order_date) AS mois,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenu
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Livrée'
    GROUP BY mois
)
SELECT
    mois,
    revenu,
    LAG(revenu) OVER (ORDER BY mois) AS revenu_mois_precedent,
    ROUND(
        100.0 * (revenu - LAG(revenu) OVER (ORDER BY mois))
        / LAG(revenu) OVER (ORDER BY mois),
        1
    ) AS croissance_mom_pct
FROM revenu_mensuel
ORDER BY mois;
