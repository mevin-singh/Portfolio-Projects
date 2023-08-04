with txn as (
select customer_id, to_char(txn_date, 'month') as month, txn_type 
from data_bank.customer_transactions
order by customer_id, txn_date),

txn_type as (
select 
	customer_id,
	month,
	sum(case when txn_type = 'deposit' then 1 else 0 end) as n_deposits,
	sum(case when txn_type = 'purchase' then 1 else 0 end) as n_purchase,
	sum(case when txn_type = 'withdrawal' then 1 else 0 end) as n_withdrawal
from txn
group by 1,2
order by 1,2
),

conditions as (
select * from txn_type
where n_deposits > 1 and (n_purchase = 1 or n_withdrawal = 1)
order by month, customer_id
)

select month, count(distinct customer_id) from conditions
group by 1

