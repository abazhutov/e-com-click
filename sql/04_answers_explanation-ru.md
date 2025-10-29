## Оптимизация с пояснениями
### Original query

*14sec*

Выполняется объединение всех строк, удолетворяющих условию в `USING` строк, а затем во `WHERE` фильтрация по объеденнёным записямс с дедубликацией на лету `FINAL`
```SQL
select product_id from products final 
join remainders final 
using(product_id) 
where updated=today() and date=today()-1
```
### First modifocation `USING`->`ON` 

*14sec->9sec*

При переносе условия в `ON`, фильтрация выполняется перед объединением и нужно объеденить минимум строк
```SQL
SELECT p.product_id 
from products p FINAL 
JOIN remainders r FINAL 
ON r.date=today()-1
  AND p.product_id = r.product_id
  AND p.updated=today();
```
### Second modifocation `JOIN`->`IN`

*9sec->2sec*

При использовании `JOIN` выполняется объединение всех строх подходящих под условие, а при использовании `EXISTS`,`IN` выполняется поиск первой строки удовлетворяющей условиям отбора.

```SQL
SELECT p.product_id
FROM products p FINAL
WHERE p.updated = today()
  AND p.product_id IN (
    SELECT r.product_id
    FROM remainders r FINAL
    WHERE r.date = today() - 1
  );
```
### Third modifocation `FINAL`->`DISTINCT` 

*2sec->0.2sec*

В условии указано, что данные обновляются всего 2 раза в день и учитывая, что движок таблицы `ReplacingMergeTree`, дубликаты удаляются из таблицы при обновлении. Для того, чтобы удалить дубликаты из запроса, достаточно `DISTINCT`, использование `FINAL` - исзбыточное.
```SQL
SELECT distinct p.product_id
FROM products p 
WHERE p.updated = today()
  AND p.product_id IN (
    SELECT r.product_id
    FROM remainders r
    WHERE r.date = today() - 1
  );
```