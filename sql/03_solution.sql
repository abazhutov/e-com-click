SELECT distinct p.product_id
FROM products p 
WHERE p.updated = today()
  AND p.product_id IN (
    SELECT r.product_id
    FROM remainders r
    WHERE r.date = today() - 1
  );


