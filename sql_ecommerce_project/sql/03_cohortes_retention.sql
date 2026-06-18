-- =============================================================================
-- 03 — ANALYSE DE COHORTES (rétention par mois d'inscription)
-- -----------------------------------------------------------------------------
-- Question business : Les clients inscrits en janvier 2023 commandent-ils
-- encore 6, 12, 18 mois après ? Nos cohortes récentes se retiennent-elles
-- mieux que les anciennes ?
--
-- Techniques : CTE, calcul d'écart de mois entre deux dates, GROUP BY croisé
-- =============================================================================

WITH cohorte_client AS (
    SELECT
        customer_id,
        strftime('%Y-%m', signup_date) AS mois_cohorte
    FROM customers
),
commandes_avec_cohorte AS (
    SELECT
        cc.mois_cohorte,
        o.customer_id,
        -- Nombre de mois écoulés entre l'inscription et la commande
        (CAST(strftime('%Y', o.order_date) AS INTEGER) * 12
            + CAST(strftime('%m', o.order_date) AS INTEGER))
        -
        (CAST(strftime('%Y', cc.mois_cohorte || '-01') AS INTEGER) * 12
            + CAST(strftime('%m', cc.mois_cohorte || '-01') AS INTEGER))
        AS mois_ecoule
    FROM orders o
    JOIN cohorte_client cc ON cc.customer_id = o.customer_id
    WHERE o.status = 'Livrée'
),
taille_cohorte AS (
    SELECT mois_cohorte, COUNT(*) AS nb_clients
    FROM cohorte_client
    GROUP BY mois_cohorte
)
SELECT
    cac.mois_cohorte,
    tc.nb_clients AS taille_cohorte,
    cac.mois_ecoule,
    COUNT(DISTINCT cac.customer_id) AS clients_actifs,
    ROUND(100.0 * COUNT(DISTINCT cac.customer_id) / tc.nb_clients, 1) AS taux_retention_pct
FROM commandes_avec_cohorte cac
JOIN taille_cohorte tc ON tc.mois_cohorte = cac.mois_cohorte
WHERE cac.mois_ecoule BETWEEN 0 AND 12
GROUP BY cac.mois_cohorte, cac.mois_ecoule
ORDER BY cac.mois_cohorte, cac.mois_ecoule;
