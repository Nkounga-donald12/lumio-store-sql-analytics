-- =============================================================================
-- 08 — PRODUITS ACHETÉS ENSEMBLE (Market Basket Analysis)
-- -----------------------------------------------------------------------------
-- Question business : Quelles paires de produits apparaissent souvent dans
-- la même commande ? Base pour des recommandations "fréquemment achetés
-- ensemble" ou des bundles promotionnels.
--
-- Techniques : self-join sur order_items, déduplication des paires (a < b)
-- =============================================================================

SELECT
    p1.product_name AS produit_a,
    p2.product_name AS produit_b,
    COUNT(*) AS nb_commandes_communes
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id          -- évite les doublons et les paires (a,a)
JOIN products p1 ON p1.product_id = oi1.product_id
JOIN products p2 ON p2.product_id = oi2.product_id
GROUP BY produit_a, produit_b
HAVING nb_commandes_communes >= 3
ORDER BY nb_commandes_communes DESC
LIMIT 15;
