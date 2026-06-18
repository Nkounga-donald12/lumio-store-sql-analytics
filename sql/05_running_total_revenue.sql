-- =============================================================================
-- 05 — CUMUL DE REVENU PAR TRIMESTRE (running total)
-- -----------------------------------------------------------------------------
-- Question business : Où sommes-nous par rapport à notre objectif annuel
-- cumulé ? Visualiser la trajectoire de croissance sur 3 ans.
--
-- Techniques : fonction fenêtre SUM() ... OVER (ORDER BY ... ROWS UNBOUNDED
-- PRECEDING) pour un cumul progressif (running total)
-- =============================================================================

WITH revenu_trimestre AS (
    SELECT
        strftime('%Y', o.order_date) || '-T' ||
            ((CAST(strftime('%m', o.order_date) AS INTEGER) - 1) / 3 + 1) AS trimestre,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenu_trimestre
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Livrée'
    GROUP BY trimestre
)
SELECT
    trimestre,
    revenu_trimestre,
    SUM(revenu_trimestre) OVER (
        ORDER BY trimestre
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS revenu_cumule
FROM revenu_trimestre
ORDER BY trimestre;
