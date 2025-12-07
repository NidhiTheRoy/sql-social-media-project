-- Q1. Are there any tables with duplicate or missing null values? If so, how would you handle them?

-- for duplicate values

SELECT * FROM comments
GROUP BY id HAVING COUNT(*) > 1;

SELECT follower_id, followee_id, COUNT(*) AS count
FROM follows GROUP BY followee_id, follower_id
HAVING COUNT(*) > 1;

SELECT photo_id, user_id, COUNT(*) as total_no_likes
FROM likes GROUP BY photo_id, user_id
HAVING COUNT(*) > 1;

SELECT photo_id, tag_id, COUNT(*) AS cnt
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1;

SELECT * FROM photos
GROUP BY id HAVING COUNT(*) > 1;

SELECT * FROM tags
GROUP BY id HAVING COUNT(*) > 1;

SELECT * FROM users
GROUP BY id HAVING COUNT(*) > 1;


-- for NULL values

SELECT * FROM comments
WHERE id IS NULL OR comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

SELECT * FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL OR created_at IS NULL;

SELECT * FROM likes
WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

SELECT * FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;

SELECT * FROM photos
WHERE id IS NULL OR image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;

SELECT * FROM tags
WHERE id IS NULL OR tag_name IS NULL OR created_at IS NULL;

SELECT * FROM users
WHERE id IS NULL OR username IS NULL OR created_at IS NULL;


-- Q2. What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

SELECT u.id AS user_id, u.username, 
COUNT(DISTINCT p.id) AS num_of_posts,
COUNT(DISTINCT l.photo_id) AS num_of_likes,
COUNT(DISTINCT c.id) AS num_of_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
LIMIT 50;


-- Q3. Calculate the average number of tags per post (photo_tags and photos tables)

WITH CTE AS (
	SELECT p.id, COUNT(*) AS total_tags FROM photos p 
	LEFT JOIN photo_tags t ON p.id = t.photo_id
	GROUP BY p.id
)
SELECT ROUND(AVG(total_tags),0) AS avg_total_tags
FROM CTE;


-- Q4. Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

WITH Total_likes AS (
    SELECT u.username, COUNT(l.user_id) AS total_likes
    FROM users AS u LEFT JOIN likes AS l ON u.id = l.user_id
    GROUP BY u.username
),
Total_comments AS (
    SELECT u.username, COUNT(c.user_id) AS total_comments
    FROM users AS u LEFT JOIN comments AS c ON u.id = c.user_id
    GROUP BY u.username
)
SELECT l.username, l.total_likes, c.total_comments,
    (l.total_likes + c.total_comments) AS engagement_rate,
    DENSE_RANK() OVER (ORDER BY (l.total_likes + c.total_comments) DESC) AS engagement_rate_rank
FROM Total_likes AS l JOIN Total_comments AS c ON l.username = c.username
ORDER BY engagement_rate DESC
LIMIT 20;


-- Q5. Which users have the highest number of followers and followings?

WITH Count_of_followers AS (
    SELECT followee_id AS user_id, COUNT(follower_id) AS follower_count
    FROM follows GROUP BY followee_id
),
Count_of_followee AS (
    SELECT follower_id AS user_id, COUNT(followee_id) AS followee_count
    FROM follows GROUP BY follower_id
)

SELECT u.id, u.username,
    COALESCE(followers.follower_count, 0) AS follower_count,
    COALESCE(followings.followee_count, 0) AS followee_count
FROM users AS u
LEFT JOIN Count_of_followers AS followers ON u.id = followers.user_id
LEFT JOIN Count_of_followee AS followings ON u.id = followings.user_id
ORDER BY u.id ASC;

-- Q6. Calculate the average engagement rate (likes, comments) per post for each user.
WITH engagement AS(
SELECT u.id, username ,p.id AS photo_id
	,COUNT(DISTINCT l.user_id) AS likes
	,COUNT(DISTINCT c.user_id) AS comments
FROM users u LEFT JOIN photos p ON u.id=p.user_id
JOIN likes l ON l.photo_id=p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY u.id, username, p.id
)
SELECT id, username
,ROUND((AVG(likes+comments)),2)AS avg_engagement
FROM engagement 
GROUP BY id, username, likes,comments
ORDER BY avg_engagement DESC, id ASC;


-- Q7. Get the list of users who have never liked any post (users and likes tables)

SELECT id, username
FROM users
WHERE id NOT IN (SELECT user_id FROM likes);


-- Q8. How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?

SELECT t.tag_name,
    COUNT(pt.photo_id) AS tag_usage_count
FROM tags t
JOIN photo_tags pt ON t.id = pt.tag_id
GROUP BY t.tag_name
ORDER BY tag_usage_count DESC;

-- Q9: Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?

WITH uploads AS (
SELECT u.id AS user_id, u.username, 
    COUNT(p.id) AS photo_uploads
FROM users u LEFT JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.username
),
likes AS (
SELECT u.id AS user_id, u.username, COUNT(l.photo_id) AS total_likes
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
GROUP BY u.id, u.username
),
comments AS(
SELECT u.id user_id, u.username, 
COUNT(c.id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
)
SELECT DISTINCT photo_uploads,
	ROUND(AVG(total_likes+total_comments) OVER(PARTITION BY photo_uploads),0) average_engagement
FROM uploads u JOIN likes l ON u.user_id=l.user_id
JOIN comments c ON u.user_id=c.user_id;

-- Q10. Calculate the total number of likes, comments, and photo tags for each user.

WITH likes_count AS (
    SELECT user_id, COUNT(*) AS num_of_likes
    FROM likes GROUP BY user_id
),
comments_count AS (
    SELECT user_id, COUNT(id) AS num_of_comments
    FROM comments GROUP BY user_id
),
phototags_count AS (
    SELECT u.id AS user_id, COUNT(pt.tag_id) AS num_of_phototags
    FROM photos p JOIN photo_tags pt ON p.id = pt.photo_id
    JOIN users u ON u.id = p.user_id
    GROUP BY u.id
)
SELECT 
    u.id AS UserID, u.username AS UserName,
    COALESCE(l.num_of_likes, 0) AS num_of_likes,
    COALESCE(c.num_of_comments, 0) AS num_of_comments,
    COALESCE(p.num_of_phototags, 0) AS num_of_phototags
FROM users u
LEFT JOIN likes_count l ON u.id = l.user_id
LEFT JOIN comments_count c ON u.id = c.user_id
LEFT JOIN phototags_count p ON u.id = p.user_id
ORDER BY u.id ASC;
    
    
-- Q11. Rank users based on their total engagement (likes, comments, shares) over a month.

WITH Post_likes AS (
  SELECT user_id, COUNT(*) AS like_count
  FROM likes WHERE EXTRACT(MONTH FROM created_at) = 11 AND EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY user_id
),
Post_comments AS (
  SELECT user_id, COUNT(*) AS comment_count
  FROM comments WHERE EXTRACT(MONTH FROM created_at) = 11 AND EXTRACT(YEAR FROM created_at) = 2024
  GROUP BY user_id
),
Total_likes_n_comments AS (
  SELECT u.id AS User_id, u.username,
    COALESCE(pl.like_count, 0) AS like_count,
    COALESCE(pc.comment_count, 0) AS comment_count,
    COALESCE(pl.like_count, 0) + COALESCE(pc.comment_count, 0) AS total_engagement
  FROM users AS u LEFT JOIN Post_likes AS pl ON u.id = pl.user_id
  LEFT JOIN Post_comments AS pc ON u.id = pc.user_id
)
SELECT User_id, Username AS Username, like_count,
  comment_count, total_engagement, DENSE_RANK() OVER (ORDER BY total_engagement DESC) AS User_rank
FROM Total_likes_n_comments;

-- Q12. Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

WITH Likes_Count AS (
  SELECT photo_id, COUNT(user_id) AS LikesCount
  FROM likes GROUP BY photo_id
)
SELECT
  t.tag_name, ROUND(AVG(c.LikesCount), 0) AS Avg_likes
FROM tags AS t
JOIN photo_tags AS pt ON t.id = pt.tag_id
JOIN Likes_Count AS c ON pt.photo_id = c.photo_id
GROUP BY t.tag_name
ORDER BY Avg_likes DESC;

-- Q13. Retrieve the users who have started following someone after being followed by that person
SELECT
  f1.follower_id AS Followed_User,
  f1.followee_id AS Follower_User
FROM follows AS f1
JOIN follows AS f2
  ON f1.follower_id = f2.followee_id
  AND f1.followee_id = f2.follower_id
  AND f1.created_at > f2.created_at;


