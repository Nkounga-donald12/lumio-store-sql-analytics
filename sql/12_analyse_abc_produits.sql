-- =============================================================================
-- 12 — ANALYSE ABC DES PRODUITS (Pareto 80/20)
-- -----------------------------------------------------------------------------
-- Question business : Quels produits génèrent 80% du chiffre d'affaires
-- (catégorie A, à ne jamais rupture-stocker) et lesquels sont marginaux
-- (catégorie C, candidats à un déréférencement) ?
--
-- Techniques : window SUM cumulatif, calcul de pourcentage cumulé, CASE WHEN
-- =============================================================================

WITH ca_produit AS (
    SELECT
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS chiffre_affaires
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id AND o.status = 'Livrée'
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY p.product_name
),
classement AS (
    SELECT
        product_name,
        chiffre_affaires,
        SUM(chiffre_affaires) OVER (ORDER BY chiffre_affaires DESC) AS ca_cumule,
        SUM(chiffre_affaires) OVER ()                                AS ca_total
    FROM ca_produit
)
SELECT
    product_name,
    chiffre_affaires,
    ROUND(100.0 * ca_cumule / ca_total, 1) AS pct_cumule,
    CASE
        WHEN 100.0 * ca_cumule / ca_total <= 80 THEN 'A (essentiel)'
        WHEN 100.0 * ca_cumule / ca_total <= 95 THEN 'B (intermédiaire)'
        ELSE 'C (marginal)'
    END AS classe_abc
FROM classement
ORDER BY chiffre_affaires DESC;
