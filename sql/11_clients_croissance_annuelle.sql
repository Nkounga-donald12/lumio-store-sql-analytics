-- =============================================================================
-- 11 — CLIENTS EN CROISSANCE D'UNE ANNÉE SUR L'AUTRE (YoY)
-- -----------------------------------------------------------------------------
-- Question business : Parmi nos clients actifs sur plusieurs années, qui
-- augmente ses dépenses (à chouchouter / upseller) et qui diminue (à
-- relancer avant qu'il ne parte) ?
--
-- Techniques : CTE, LAG() OVER (PARTITION BY client ORDER BY année)
-- =============================================================================

WITH depense_annuelle AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name AS client,
        CAST(strftime('%Y', o.order_date) AS INTEGER) AS annee,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS depense_annee
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'Livrée'
    JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, annee
),
comparaison_yoy AS (
    SELECT
        client,
        annee,
        depense_annee,
        LAG(depense_annee) OVER (PARTITION BY customer_id ORDER BY annee) AS depense_annee_precedente
    FROM depense_annuelle
)
SELECT
    client,
    annee,
    depense_annee_precedente,
    depense_annee,
    ROUND(
        100.0 * (depense_annee - depense_annee_precedente) / depense_annee_precedente, 1
    ) AS evolution_pct
FROM comparaison_yoy
WHERE depense_annee_precedente IS NOT NULL
ORDER BY evolution_pct DESC
LIMIT 20;
