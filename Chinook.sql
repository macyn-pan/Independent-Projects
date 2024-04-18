SELECT * 
FROM albums

-- 1. Which tracks appeared in the most playlists? how many playlist did they appear in?

SELECT tracks.Name, COUNT(playlist_track.PlaylistId)
FROM tracks 
JOIN playlist_track
ON tracks.TrackId = playlist_track.TrackId
GROUP BY name
ORDER BY COUNT(playlist_track.PlaylistID) DESC;

-- 2. Showcase which tracks generated the most revenue 

SELECT tracks.Name AS 'Song', albums.Title AS 'Album', genres.Name AS 'Genre', invoice_items.UnitPrice * COUNT(invoice_items.TrackId) AS Revenue
FROM tracks
JOIN albums ON tracks.AlbumId = albums.AlbumId
JOIN genres ON tracks.GenreId = genres.GenreId
JOIN invoice_items ON tracks.TrackId = invoice_items.TrackId
GROUP BY invoice_items.TrackId
ORDER BY Revenue DESC

-- 3. Which countries have the highest sales revenue? What percent of total revenue does each country make up?

SELECT BillingCountry, SUM(Total) AS SalesRevenue, SUM(Total) * 100 / SUM(SUM(Total)) OVER () AS Percentage
FROM invoices
GROUP BY BillingCountry
ORDER BY SUM(Total) DESC

-- 4. How many customers did each employee support, what is the average revenue for each sale, and what is their total sale?

SELECT * 
FROM invoices

SELECT *
FROM employees

SELECT * 
FROM customers

SELECT customers.SupportRepId, COUNT(DISTINCT customers.CustomerId) AS 'Customers', ROUND(AVG(Total), 2) AS 'Average_Sale', ROUND(SUM(Total), 2) AS 'Total_Sale'
FROM customers
JOIN employees ON customers.SupportRepId = employees.EmployeeId
JOIN invoices ON customers.CustomerId = invoices.CustomerId
GROUP BY employees.EmployeeId
ORDER BY COUNT(*) DESC

-- 5. Do longer or shorter length albums tend to generate more revenue?

SELECT * 
FROM albums

SELECT * 
FROM tracks

SELECT * 
FROM invoice_items

SELECT *
FROM invoices

-- To determine the number of tracks in each album
SELECT albums.AlbumId, albums.Title AS 'Title', COUNT(tracks.TrackId) AS 'alb_len'
FROM tracks 
JOIN albums ON tracks.AlbumId = albums.AlbumId
GROUP BY albums.AlbumId
ORDER BY COUNT(tracks.TrackId) DESC;

-- To determine how much each track makes
SELECT tracks.AlbumId, ROUND(SUM(invoice_items.UnitPrice * invoice_items.Quantity), 2) AS 'Revenue'
FROM invoice_items
JOIN tracks ON invoice_items.TrackId = tracks.TrackId
GROUP BY tracks.AlbumId

-- To determine how much revenue is generated with the length of the album
WITH stat1 AS (
SELECT albums.AlbumId, albums.Title AS 'Title', COUNT(tracks.TrackId) AS 'alb_len'
FROM tracks 
JOIN albums ON tracks.AlbumId = albums.AlbumId
GROUP BY albums.AlbumId
ORDER BY COUNT(tracks.TrackId) DESC),
	stat2 AS (
SELECT tracks.AlbumId, ROUND(SUM(invoice_items.UnitPrice * invoice_items.Quantity), 2) AS 'Revenue'
FROM invoice_items
JOIN tracks ON invoice_items.TrackId = tracks.TrackId
GROUP BY tracks.AlbumId)
SELECT alb_len AS 'Tracks Count', ROUND(AVG(Revenue),2) AS 'Album Average Revenue', ROUND(AVG(Revenue)/alb_len, 2) AS 'Track Average Revenue'
FROM stat1
JOIN stat2 ON stat1.AlbumId = stat2.AlbumId
GROUP BY 1
ORDER BY 2 DESC; 

-- 6. Is the number of times a track appear in any playlist a good indicator of sales

SELECT * 
FROM invoices

-- Determine the number of times a track appears in a playlist
SELECT tracks.TrackId, playlist_track.PlaylistId, COUNT(*) AS 'num_in_play'
FROM tracks
JOIN playlist_track ON tracks.TrackId = playlist_track.TrackId
GROUP BY 1
ORDER BY 3 DESC

-- Determine if sales is better with increase number of tracks in the playlists
WITH prev1 AS (
SELECT tracks.TrackId, playlist_track.PlaylistId, COUNT(*) AS 'num_in_play'
FROM tracks
JOIN playlist_track ON tracks.TrackId = playlist_track.TrackId
GROUP BY 1
ORDER BY 3 DESC)
SELECT num_in_play AS 'Appearance in Playlist', ROUND(SUM(invoice_items.UnitPrice * invoice_items.Quantity), 0) AS Revenue
FROM prev1 JOIN invoice_items using(TrackId)
GROUP BY 1 
ORDER BY 2 DESC;

-- 7. How much revenue is generated each year, and what is its percent change 84 from the previous year?

SELECT InvoiceDate, strftime('%Y', InvoiceDate) AS 'Year'
FROM invoices

-- Determine how much revenue is generated each year
SELECT strftime('%Y', InvoiceDate) AS 'Year', ROUND(SUM(invoice_items.UnitPrice * invoice_items.Quantity),2) AS Revenue
FROM invoices JOIN invoice_items USING(InvoiceId)
GROUP BY Year

-- Change the way the data was stored
SELECT CAST(strftime('%Y', InvoiceDate) AS INTEGER) AS 'Year', ROUND(SUM(invoice_items.UnitPrice * invoice_items.Quantity),2) AS Revenue
FROM invoices JOIN invoice_items USING(InvoiceId)
GROUP BY Year

with this_year_tbl as
(
select cast(strftime('%Y', InvoiceDate) as integer) as 'this_year',  sum(total) as 'total_this_year'
from invoices
group by 1)
,
prev_year_tbl as
(
select cast(strftime('%Y', InvoiceDate) as integer) as 'prev_year',  sum(total) as 'total_prev_year'
from invoices
group by 1 
)
select *, round((total_this_year-total_prev_year)/total_prev_year*100,2) as 'percent change'   from this_year_tbl, prev_year_tbl
where prev_year = this_year-1; 

