-- =============================================================================
-- 10 — PANIER MOYEN PAR TRIMESTRE + MOYENNE MOBILE
-- -----------------------------------------------------------------------------
-- Question business : Le panier moyen augmente-t-il dans le temps (montée en
-- gamme, upsell) ou stagne-t-il ? On lisse la tendance avec une moyenne
-- mobile sur 2 trimestres pour gommer les effets ponctuels.
--
-- Techniques : CTE, AVG() OVER (fenêtre glissante ROWS BETWEEN ... PRECEDING)
-- =============================================================================

WITH panier_par_commande AS (
    SELECT
        o.order_id,
        strftime('%Y', o.order_date) || '-T' ||
            ((CAST(strftime('%m', o.order_date) AS INTEGER) - 1) / 3 + 1) AS trimestre,
        SUM(oi.quantity * oi.unit_price) AS montant_commande
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Livrée'
    GROUP BY o.order_id
),
panier_moyen_trimestre AS (
    SELECT
        trimestre,
        ROUND(AVG(montant_commande), 2) AS panier_moyen
    FROM panier_par_commande
    GROUP BY trimestre
)
SELECT
    trimestre,
    panier_moyen,
    ROUND(
        AVG(panier_moyen) OVER (
            ORDER BY trimestre
            ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
        ), 2
    ) AS moyenne_mobile_2_trimestres
FROM panier_moyen_trimestre
ORDER BY trimestre;
