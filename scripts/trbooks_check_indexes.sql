select indexname, indexdef
from pg_indexes
where tablename = 'trbooks'
order by indexname;
