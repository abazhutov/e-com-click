--fill table products by random data by seed=1
insert into products
select * from generateRandom('
    product_id unsigned(Int32),
    product_name String,
    brand_id unsigned(Int32),
    seller_id unsigned(Int32),
    updated Date', 
  1) g LIMIT 100000000;

--fill table remainders by random data by seed=1 (60b rec same product_id)	
insert into remainders
select * 
from generateRandom('
    date Date,
    product_id unsigned(Int32),
    remainder unsigned(Int32),
    price unsigned(Int32),
    discount Int32,
    pics unsigned(Int32),
    rating Int32,
    reviews unsigned(Int32),
    new Bool',
  1) g LIMIT 100000000;  

--update for get merged data for query
alter table products
  update updated = today() 
  where product_id IN (
    select r.product_id
    from remainders r
    where r.date = (today() - 1)
  );