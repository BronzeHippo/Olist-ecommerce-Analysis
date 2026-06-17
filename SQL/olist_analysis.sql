-- Note: Revenue from order_paymenyts reflects actual amount paid by customers including --
-- vouchers and discounts. Revenue from order_item reflects listed_prices. Difference reflects  --
-- discounts applied at checkouts --

-- Category: Sales & Revenue --
-- Question: What is the total revenue --
Select round(sum(payment_value),2) as total_Revenue
from order_payments;


-- Question: What is the most popular payment method --
select round(sum(payment_value),0) as total_Revenue, payment_type, count(distinct(order_id)) as total_orders
from order_payments
group by payment_type
order by total_revenue desc;

-- Question: What is the Total Revenue from delivered orders --
select round(sum(payment_value),0) as total_Revenue, count(ors.order_id) as total_orders
from order_payments op
join orders ors
on op.order_id = ors.order_id
where order_status = 'delivered';

-- Question: Which product category generates the most revenue ? --
select round(sum(price + freight_value),2) as total_revenue, product_category_name, count(oi.order_id) as total_Orders
from order_items oi
join products p
on oi.product_id = p.product_id
join order_payments op
on op.order_id = oi.order_id
join orders o
on o.order_id = oi.order_id
where order_status = 'Delivered'
group by product_category_name
order by total_revenue desc
limit 10;

-- Question: What is the average order value?
select count(op.order_id) as total_orders, round(SUM(op.total_payment), 0) as total_revenue,
round(avg(op.total_payment), 0) as avg_order_value
from orders o
join (
    select order_id, SUM(payment_value) AS total_payment
    from order_payments
    group by order_id
) op on o.order_id = op.order_id
where o.order_status = 'delivered';

-- Category: Customer Behaviour --

-- Question: Which States have the most customers ?--
select count(customer_id) as total_customers, count(customer_unique_id) as unique_customers, 
g.geolocation_state
from customers c
join (
select distinct(geolocation_zip_code_prefix), geolocation_state
from geolocation 
) g
on c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
group by g.geolocation_state
order by total_customers desc;

-- Question: How many customers made more than one order ? --
select customer_unique_id, customer_state, count(order_id) as total_orders
from customers c
join orders o
on c.customer_id = o.customer_id
group by customer_unique_id, customer_state
having count(order_id) > 1
order by total_orders desc;

-- Question: What is the most popular payment method ? --
select payment_type, count(distinct(order_id)) as orders
from order_payments
group by payment_type
order by orders desc;

-- Question: What percentage of customers pay in installments ? --
select count(order_id) as total_orders,
sum(case when max_installments > 1 then 1 else 0 end) as multiple_payments,
sum(case when max_installments = 1 then 1 else 0 end) as single_payments,
round(sum(case when max_installments > 1 then 1 else 0 end) / count(order_id) * 100,1)
as multi_installment_pct,
round(sum(case when max_installments = 1 then 1 else 0 end) / count(order_id) * 100,1)
as single_installment_pct
from(
select order_id, max(payment_installments) as max_installments
from order_payments
group by order_id
) order_summary;

-- Category: Seller Performance --

-- Question: Who are the top 10 sellers by revenue --
select s.seller_id as seller, seller_city, count(distinct o.order_id) as total_sales,
round(sum(price + freight_value),0)  as revenue, seller_state
from sellers s
join order_items ors
on s.seller_id = ors.seller_id
join orders o
on ors.order_id = o.order_id
where order_status = 'Delivered'
group by s.seller_id, seller_city, seller_state
order by revenue desc
limit 10;

-- Question: Which sellers have the most orders ? --
select s.seller_id as seller, seller_city, count(distinct o.order_id) as total_sales,
round(sum(price + freight_value),0)  as revenue, seller_state
from sellers s
join order_items ors
on s.seller_id = ors.seller_id
join orders o
on ors.order_id = o.order_id
where order_status = 'Delivered'
group by s.seller_id, seller_city, seller_state
order by total_sales desc
limit 10;

-- Question: Which cities have the most sellers ? --
select seller_state, seller_city, count(distinct s.seller_id) as sellers, count(distinct o.order_id) as total_sales,
round(sum(price + freight_value),0)  as revenue
from sellers s
join order_items ors
on s.seller_id = ors.seller_id
join orders o
on ors.order_id = o.order_id
where order_status = 'Delivered'
group by seller_city, seller_state
order by sellers desc
limit 10;

-- Category : Delivery & Logistics --

-- Question: What percentage of orders were delivered late ?--
select count(distinct order_id),
sum(case when order_delivered_customer_date > order_estimated_delivery_date then 1 else 0 end)
as late_orders,
sum(case when order_delivered_customer_date <= order_estimated_delivery_date  then 1 else 0 end)
as early_orders,
round(sum(case when order_delivered_customer_date > order_estimated_delivery_date then 1 else 0 end)/
count(distinct order_id) *100,2) as late_pct,
round(sum(case when order_delivered_customer_date <= order_estimated_delivery_date then 1 else 0 end)/
count(distinct order_id) *100,2) as early_pct
from orders
where order_status = 'Delivered'
and order_delivered_customer_date is not null
and order_estimated_delivery_date is not null;

-- Question: Which states have the worst delivery time ? --
select customer_state, count(distinct order_id), round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp)),1) as avg_delivery_date,
max(datediff(order_delivered_customer_date,order_purchase_timestamp)) as longest_delivery_dste
from orders o
join customers c
on o.customer_id = c.customer_id
where order_status = 'Delivered'
and order_delivered_customer_date is not null
and order_purchase_timestamp is not null
group by customer_state
order by avg_delivery_date desc
limit 10;

-- Question : What is the average delivery time across all orders  --
select count(distinct order_id) as total_orders,
round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp)),0)as avg_delivery_date,
min(datediff(order_delivered_customer_date,order_purchase_timestamp)) as earliest_delivery_date,
max(datediff(order_delivered_customer_date,order_purchase_timestamp)) as late_delivery_date
from orders
where order_status = 'Delivered'
and order_delivered_customer_date is not null
and order_purchase_timestamp is not null;

-- Category: Customer Satisfaction--

-- Question: What is the average review scrore overall ? --
select count(distinct order_id) as total_orders, count(distinct review_id) as total_reviews,
round(avg(review_score),1) as avg_score
from order_reviews ;

-- Question: Which product categories have the lowest ratings?
select product_category_name, round(avg(review_score),1) as avg_review_score
from products p
join order_items ors
on p.product_id = ors.product_id
join orders o
on ors.order_id = o.order_id
join order_reviews orv
on orv.order_id = ors.order_id
where order_status = 'Delivered'
group by product_category_name
order by avg_review_score asc
limit 10;

-- Question: Which product categories have the highest ratings?
select product_category_name, round(avg(review_score),1) as avg_review_score
from products p
join order_items ors
on p.product_id = ors.product_id
join orders o
on ors.order_id = o.order_id
join order_reviews orv
on orv.order_id = ors.order_id
where order_status = 'Delivered'
group by product_category_name
order by avg_review_score desc
limit 10;

-- Question: Is there a relationship between late delivery and low review scores ?  --
select count(o.order_id),
case when order_delivered_customer_date > order_estimated_delivery_date then 'Late' else  'On Time'
end as delivery_status,
round(avg(review_score),1) as avg_review_score
from orders o
join order_reviews orv
on o.order_id = orv.order_id
where order_status = 'Delivered'
and order_delivered_customer_date is not null
and order_estimated_delivery_date is not null
group by delivery_status
order by avg_review_score desc;

select count(distinct(c.customer_id)) as total_customers, count(distinct order_id) as total_orders,
customer_state
from orders o
join customers c
on o.customer_id = c.customer_id 
where order_status = 'Delivered'
group by customer_state
order by total_orders desc;


-- What is the monthly revenue ? --
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.total_payment), 0) AS total_revenue
FROM orders o
JOIN (
    SELECT order_id, SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
) op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
AND order_purchase_timestamp IS NOT NULL
GROUP BY month
ORDER BY month;

