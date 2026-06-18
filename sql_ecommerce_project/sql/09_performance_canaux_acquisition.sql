-- =============================================================================
-- 09 — PERFORMANCE DES CANAUX D'ACQUISITION
-- -----------------------------------------------------------------------------
-- Question business : Quel canal marketing nous amène le plus de clients,
-- et surtout les clients qui dépensent le plus / reviennent le plus ?
-- (tous les canaux n'ont pas la même valeur)
--
-- Techniques : LEFT JOIN, agrégation multi-niveaux, ROUND, ratios
-- =============================================================================

WITH valeur_par_client AS (
    SELECT
        c.customer_id,
        c.acquisition_channel,
        COUNT(DISTINCT o.order_id) AS nb_commandes,
        COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS valeur_totale
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Livrée'
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id
)
SELECT
    acquisition_channel,
    COUNT(*) AS nb_clients_acquis,
    ROUND(AVG(valeur_totale), 2) AS valeur_moyenne_par_client,
    ROUND(SUM(valeur_totale), 2) AS valeur_totale_canal,
    ROUND(100.0 * SUM(CASE WHEN nb_commandes >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS taux_reachat_pct
FROM valeur_par_client
GROUP BY acquisition_channel
ORDER BY valeur_totale_canal DESC;
