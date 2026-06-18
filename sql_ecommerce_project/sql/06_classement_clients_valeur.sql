-- =============================================================================
-- 06 — CLASSEMENT DES CLIENTS PAR VALEUR (Customer Lifetime Value)
-- -----------------------------------------------------------------------------
-- Question business : Quel pourcentage de notre CA repose sur le top 10% des
-- clients ? (test de la loi de Pareto appliquée à la clientèle)
--
-- Techniques : PERCENT_RANK(), DENSE_RANK(), agrégation conditionnelle
-- =============================================================================

WITH valeur_client AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS client,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS valeur_totale,
        COUNT(DISTINCT o.order_id) AS nb_commandes
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Livrée'
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id
)
SELECT
    client,
    valeur_totale,
    nb_commandes,
    DENSE_RANK() OVER (ORDER BY valeur_totale DESC) AS rang_valeur,
    ROUND(100.0 * PERCENT_RANK() OVER (ORDER BY valeur_totale), 1) AS percentile,
    CASE
        WHEN PERCENT_RANK() OVER (ORDER BY valeur_totale) >= 0.9 THEN 'Top 10%'
        WHEN PERCENT_RANK() OVER (ORDER BY valeur_totale) >= 0.75 THEN 'Top 25%'
        ELSE 'Reste de la clientèle'
    END AS tranche_valeur
FROM valeur_client
ORDER BY valeur_totale DESC
LIMIT 30;
