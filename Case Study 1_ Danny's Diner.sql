-- DATABASE SCHEMA 
-- SALES TABLE CREATION

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
 
 
-- MENU TABLE CREATION

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
  
 -- MEMBERS TABLE CREATION 

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from sales;
select * from menu;
select * from members;

-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(menu.price) AS Total_Amount
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
-- Customers A and B are potential customers for the restaurant as the total amount spent by them at the restaurants is high while the amount spent by the customer C is quite low.

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Number_of_customer_visit_days 
FROM sales
GROUP BY customer_id;
-- Customer A and B visit the restaurant the quite often than Customer C. This might be the reason why cusomers A and B generate good sales for the restaurant.

-- 3. What was the first item from the menu purchased by each customer?
WITH items_purchased AS
(SELECT sales.customer_id, menu.product_name, dense_rank() OVER (partition by sales.customer_id order by sales.order_date ASC) AS rnk
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id)

SELECT customer_id, product_name 
FROM items_purchased
WHERE rnk = 1
GROUP BY customer_id, product_name;
-- The customer A tries Sushi and Curry as the first items while Curry is tried by customer B and Customer C tries Ramen for the first time at the restaurant.

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name, COUNT(menu.product_name) AS number_of_purchases
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id
GROUP BY menu.product_name
ORDER BY number_of_purchases DESC
LIMIT 1;
-- Ramen is the top dish preferred by the customers and it has sold 8 times. The restaurant should focus on the quality and taste of the other two dishes in order to increase its sales.

-- 5. Which item was the most popular for each customer?
WITH purchases AS
(SELECT sales.customer_id, menu.product_name, COUNT(sales.product_id) AS number_of_purchases, DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(sales.product_id) DESC) AS rnk
FROM menu
INNER JOIN sales
ON menu.product_id = sales.product_id
GROUP BY sales.customer_id, menu.product_name)

SELECT customer_id, product_name, MAX(number_of_purchases) AS maximum_purchases
FROM purchases
WHERE rnk = 1
GROUP BY customer_id, product_name;
-- Ramen is the most famous dish among all the customers. The customer B likes all the dishes equally. The dishes other than Ramen need to be focussed.

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE_purchased AS
(SELECT sales.customer_id, menu.product_name, sales.product_id, members.join_date, sales.order_date, DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date ASC) AS rnk
FROM sales INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE sales.order_date >= members.join_date
GROUP BY sales.customer_id, menu.product_name)

SELECT customer_id, product_name, join_date, order_date
FROM CTE_purchased
WHERE rnk = 1;
-- Only customers A and B join as members at the restaurant and they took Curry and Sushi respectively after joining. The choice of dishes did no change after joining the program.

-- 7. Which item was purchased just before the customer became a member?
WITH CTE_purchased AS
(SELECT sales.customer_id, menu.product_name, sales.product_id, members.join_date, sales.order_date, DENSE_RANK() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) AS rnk
FROM sales INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id, menu.product_name)

SELECT customer_id, product_name, join_date, order_date
FROM CTE_purchased
WHERE rnk = 1
GROUP BY customer_id, product_name;
-- Just before joining the restaurant, the customer A ordered Sushi and Curry while the customer B ordered Sushi.

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, GROUP_CONCAT(distinct menu.product_name) AS items, COUNT(DISTINCT sales.product_id) AS items_count,  SUM(menu.price) AS total_amount
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
GROUP BY sales.customer_id;
-- Before the joining of customers, the customers A and B ordered Curry and Sushi and the total amount spent by them is 25 and 40 respectively.alter

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT sales.customer_id, SUM(CASE WHEN menu.product_name = 'sushi' THEN menu.price*20 ELSE menu.price*10 END) AS points
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
-- The customer B has earned maximum points, followed by customer A. The customer C has earned the least points.

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT sales.customer_id, SUM(CASE WHEN menu.product_name = 'sushi' THEN menu.price*20 WHEN order_date <= DATE_ADD(join_date, INTERVAL 6 DAY) AND join_date <= order_date THEN price*20 ELSE price*10 END) AS total_points
FROM sales 
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE MONTH(order_date) = 01
GROUP BY sales.customer_id;
-- Based on the required condition, the total points earned by customer A is the highest, followed by the customer B.
-- Sushi and Curry are the least selling dishes. The sales of Sushi can be increased by giving 2x points, but the sales of Curry can also be increased in a similar way by giving some points based on its frequency of orders as a part of the loyalty program. Ramen is alrady preferred highly by the customers, so there is no need to give points for ordering that dish.

-- BONUS QUESTIONS
-- JOIN ALL THE THINGS
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price, (CASE WHEN sales.order_date < members.join_date OR members.join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id;

-- RANK ALL THE THINGS
WITH CTE_Rank AS
(SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price, (CASE WHEN sales.order_date < members.join_date OR members.join_date IS NULL THEN 'N' ELSE 'Y' END) AS member
FROM sales
LEFT JOIN menu ON sales.product_id = menu.product_id
LEFT JOIN members ON sales.customer_id = members.customer_id)

SELECT *, CASE WHEN member = 'Y' THEN RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date ASC) ELSE NULL END AS ranking
FROM CTE_Rank;

          
