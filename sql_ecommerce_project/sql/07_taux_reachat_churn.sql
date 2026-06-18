-- =============================================================================
-- 07 — TAUX DE RÉACHAT & DÉTECTION DU CHURN
-- -----------------------------------------------------------------------------
-- Question business : Quelle proportion de nos clients ne commande qu'une
-- seule fois (one-shot) ? Parmi les clients ayant déjà commandé, combien
-- n'ont rien acheté depuis plus de 6 mois (churn) ?
--
-- Techniques : sous-requête corrélée, CASE WHEN, agrégation sur agrégation
-- =============================================================================

WITH stats_client AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id) AS nb_commandes,
        MAX(o.order_date) AS derniere_commande,
        (SELECT MAX(order_date) FROM orders WHERE status = 'Livrée') AS date_reference
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Livrée'
    GROUP BY c.customer_id
)
SELECT
    CASE
        WHEN nb_commandes = 0 THEN 'Jamais commandé'
        WHEN nb_commandes = 1 THEN 'One-shot (1 commande)'
        WHEN nb_commandes >= 2
             AND CAST(julianday(date_reference) - julianday(derniere_commande) AS INTEGER) > 180
             THEN 'Client récurrent mais churné (>6 mois inactif)'
        ELSE 'Client récurrent actif'
    END AS statut_client,
    COUNT(*) AS nb_clients,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM customers), 1) AS pct_base_clients
FROM stats_client
GROUP BY statut_client
ORDER BY nb_clients DESC;
