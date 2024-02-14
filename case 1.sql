--What is the total amount each customer spent at the restaurant?

SELECT customer_id, sum(price) total_amt
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
GROUP BY customer_id 
ORDER BY 2 DESC;

--How many days has each customer visited the restaurant?

SELECT customer_id, COUNT(DISTINCT order_date) days
FROM sales
GROUP BY customer_id;

--What was the first item from the menu purchased by each customer?

WITH CTE AS (
	SELECT customer_id, order_date, product_name,
	RANK() OVER(PARTITION BY customer_id ORDER BY order_date) AS rnk,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS rn
	FROM sales S
	JOIN menu M 
	ON s.product_id = m.product_id)
SELECT customer_id, product_name
FROM CTE
WHERE rn = 1;

--What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT product_name, COUNT(order_date) AS orders
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


--Which item was the most popular for each customer?

WITH CTE AS (
	SELECT product_name, customer_id, COUNT(order_date) orders,
	RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) as rnk,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) as rn
	FROM sales S
	JOIN menu M 
	ON s.product_id = m.product_id
	GROUP BY product_name, customer_id)
SELECT customer_id, product_name
FROM CTE
WHERE rn = 1;

--Which item was purchased first by the customer after they became a member?

WITH CTE AS (
	SELECT s.customer_id, order_date, join_date, product_name,
	RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rnk
	FROM sales s
	JOIN members m ON m.customer_id = s.customer_id
	JOIN menu me ON s.product_id = me.product_id
	WHERE order_date >= join_date)
SELECT customer_id, product_name
FROM CTE
WHERE rnk = 1;
	
--Which item was purchased just before the customer became a member?
WITH CTE AS (
	SELECT s.customer_id, order_date, join_date, product_name,
	RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) as rnk
	FROM sales s
	JOIN members m ON m.customer_id = s.customer_id
	JOIN menu me ON s.product_id = me.product_id
	WHERE order_date < join_date)
SELECT customer_id, product_name
FROM CTE
WHERE rnk = 1;

--What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, count(product_name) as total_items, sum(price) amt_spent
FROM sales s
JOIN members m ON m.customer_id = s.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE order_date < join_date
GROUP BY 1;

--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
SUM (CASE WHEN product_name ='sushi' THEN price * 10 * 2
ELSE price * 10 
END) AS points
FROM menu m 
JOIN sales s ON s.product_id = m.product_id
GROUP BY 1;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id,
	SUM(CASE 
		WHEN order_date BETWEEN m.join_date AND (m.join_date + INTERVAL '6 days') THEN price * 10 * 2
		WHEN product_name ='sushi' THEN price * 10 * 2 
		ELSE price * 10 
	END) AS points
	FROM menu me
	JOIN sales s ON s.product_id = me.product_id
	JOIN members m ON s.customer_id = m.customer_id
	WHERE DATE_TRUNC('month', order_date) = '2021-01-01'
	GROUP BY s.customer_id;

--BONUS QUESTIONS 
SELECT 	s.customer_id, 
		s.order_date, 
		product_name, 
		price, 
CASE 
	WHEN join_date IS NULL THEN 'N'
	WHEN order_date < join_date THEN 'N'
	ELSE 'Y'
	END as member
	FROM sales s 
	JOIN menu m ON m.product_id = s.product_id 
	LEFT JOIN members me ON me.customer_id = s.customer_id 
	ORDER BY s.customer_id,
	order_date, price DESC;

--rank all things 

WITH CTE AS (SELECT
		s.customer_id, 
		s.order_date, 
		product_name, 
		price, 
CASE 
	WHEN join_date IS NULL THEN 'N'
	WHEN order_date < join_date THEN 'N'
	ELSE 'Y'
	END as member
	FROM sales s 
	JOIN menu m ON m.product_id = s.product_id 
	LEFT JOIN members me ON me.customer_id = s.customer_id 
	ORDER BY s.customer_id,
	order_date, price DESC
)
SELECT *,
CASE 
	WHEN member = 'N' THEN NULL 
	ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
	END as rnk	
FROM CTE;