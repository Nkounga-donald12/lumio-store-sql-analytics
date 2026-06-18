-- =============================================================================
-- 04 — TOP 3 PRODUITS PAR CATÉGORIE (chiffre d'affaires)
-- -----------------------------------------------------------------------------
-- Question business : Quels sont les produits stars de chaque rayon ? Utile
-- pour la mise en avant homepage et la négociation avec les fournisseurs.
--
-- Techniques : RANK() OVER (PARTITION BY ... ORDER BY ...), sous-requête filtrée
-- =============================================================================

WITH ca_produit AS (
    SELECT
        cat.category_name,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS chiffre_affaires
    FROM order_items oi
    JOIN orders o      ON o.order_id = oi.order_id AND o.status = 'Livrée'
    JOIN products p    ON p.product_id = oi.product_id
    JOIN categories cat ON cat.category_id = p.category_id
    GROUP BY cat.category_name, p.product_name
),
classement AS (
    SELECT
        category_name,
        product_name,
        chiffre_affaires,
        RANK() OVER (
            PARTITION BY category_name
            ORDER BY chiffre_affaires DESC
        ) AS rang_categorie
    FROM ca_produit
)
SELECT *
FROM classement
WHERE rang_categorie <= 3
ORDER BY category_name, rang_categorie;
