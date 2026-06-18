-- =============================================================================
-- 02 — SEGMENTATION RFM (Récence / Fréquence / Montant)
-- -----------------------------------------------------------------------------
-- Question business : Qui sont nos meilleurs clients ? Qui est en train de
-- nous quitter ? Sur qui concentrer les actions de fidélisation ?
--
-- Techniques : CTE multiples, NTILE() (quartiles), CASE WHEN, julianday()
-- =============================================================================

WITH derniere_commande AS (
    SELECT MAX(order_date) AS date_max FROM orders WHERE status = 'Livrée'
),
agregats_client AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS client,
        CAST(julianday((SELECT date_max FROM derniere_commande))
             - julianday(MAX(o.order_date)) AS INTEGER) AS recence_jours,
        COUNT(DISTINCT o.order_id) AS frequence,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS montant_total
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Livrée'
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id
),
scores AS (
    SELECT
        *,
        -- Recence : 4 = vient de commander, 1 = ne commande plus depuis longtemps
        (5 - NTILE(4) OVER (ORDER BY recence_jours)) AS score_r,
        NTILE(4) OVER (ORDER BY frequence)           AS score_f,
        NTILE(4) OVER (ORDER BY montant_total)        AS score_m
    FROM agregats_client
)
SELECT
    client,
    recence_jours,
    frequence,
    montant_total,
    score_r, score_f, score_m,
    (score_r + score_f + score_m) AS score_rfm_total,
    CASE
        WHEN score_r >= 3 AND score_f >= 3 AND score_m >= 3 THEN 'Champion'
        WHEN score_r >= 3 AND score_f >= 2                  THEN 'Client fidèle'
        WHEN score_r <= 2 AND score_f >= 3                  THEN 'À risque (était bon client)'
        WHEN score_r >= 3 AND score_f <= 2                   THEN 'Nouveau / occasionnel'
        ELSE 'Inactif / perdu'
    END AS segment_rfm
FROM scores
ORDER BY score_rfm_total DESC;
