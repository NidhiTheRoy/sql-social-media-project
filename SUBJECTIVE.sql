-- Q1. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
WITH likes_count AS (
  SELECT
    user_id,
    COUNT(*) AS num_of_likes
  FROM likes
  GROUP BY
    user_id
),
comments_count AS (
  SELECT
    user_id,
    COUNT(*) AS num_of_comments
  FROM comments
  GROUP BY
    user_id
),
photo_counts AS (
  SELECT
    user_id,
    COUNT(*) AS num_of_photos
  FROM photos
  GROUP BY
    user_id
),
phototags_count AS (
  SELECT
    p.user_id,
    COUNT(pt.tag_id) AS num_of_phototags
  FROM photos AS p
  JOIN photo_tags AS pt
    ON p.id = pt.photo_id
  GROUP BY
    p.user_id
),
followers_count AS (
  SELECT
    followee_id AS user_id,
    COUNT(*) AS follower_count
  FROM follows
  GROUP BY
    followee_id
),
followees_count AS (
  SELECT
    follower_id AS user_id,
    COUNT(*) AS followee_count
  FROM follows
  GROUP BY
    follower_id
)
SELECT
  u.id AS UserID,
  u.username AS UserName,
  COALESCE(l.num_of_likes, 0) AS num_of_likes,
  COALESCE(c.num_of_comments, 0) AS num_of_comments,
  COALESCE(p.num_of_photos, 0) AS num_of_photos,
  COALESCE(pt.num_of_phototags, 0) AS num_of_phototags,
  COALESCE(f.follower_count, 0) AS follower_count,
  COALESCE(fe.followee_count, 0) AS followee_count,
  (COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(p.num_of_photos, 0)) AS engagement_rate,
  DENSE_RANK() OVER (
    ORDER BY
      (COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(p.num_of_photos, 0)) DESC
  ) AS engagement_rate_rank
FROM users AS u
LEFT JOIN likes_count AS l
  ON u.id = l.user_id
LEFT JOIN comments_count AS c
  ON u.id = c.user_id
LEFT JOIN photo_counts AS p
  ON u.id = p.user_id
LEFT JOIN phototags_count AS pt
  ON u.id = pt.user_id
LEFT JOIN followers_count AS f
  ON u.id = f.user_id
LEFT JOIN followees_count AS fe
  ON u.id = fe.user_id
ORDER BY
  engagement_rate_rank ASC;
  
  
-- Q2. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?

WITH likes_count AS (
  SELECT
    DISTINCT user_id,
    COUNT(*) AS num_of_likes
  FROM likes
  GROUP BY
    user_id
),
comments_count AS (
  SELECT
    user_id,
    COUNT(id) AS num_of_comments
  FROM comments
  GROUP BY
    user_id
),
photo_counts AS (
  SELECT
    user_id,
    COUNT(*) AS num_of_photos
  FROM photos
  GROUP BY
    user_id
),
phototags_count AS (
  SELECT
    p.user_id,
    COUNT(pt.tag_id) AS num_of_phototags
  FROM photos AS p
  JOIN photo_tags AS pt
    ON p.user_id = pt.photo_id
  GROUP BY
    p.user_id
),
Count_of_followers AS (
  SELECT
    follower_id,
    COUNT(follower_id) AS follower_count,
    COUNT(followee_id) AS followee_count
  FROM follows
  GROUP BY
    follower_id
)
SELECT
  u.id AS UserID,
  u.username AS UserName,
  COALESCE(l.num_of_likes, 0) AS num_of_likes,
  COALESCE(c.num_of_comments, 0) AS num_of_comments,
  COALESCE(pp.num_of_photos, 0) AS num_of_photos,
  COALESCE(p.num_of_phototags, 0) AS num_of_phototags,
  COALESCE(f.follower_count, 0) AS follower_count,
  COALESCE(f.followee_count, 0) AS followee_count,
  COALESCE((COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(pp.num_of_photos, 0)), 0) AS engagement_rate,
  DENSE_RANK() OVER (
    ORDER BY
      (COALESCE(l.num_of_likes, 0) + COALESCE(c.num_of_comments, 0) + COALESCE(pp.num_of_photos, 0)) ASC
  ) AS engagement_rate_rank
FROM users u
LEFT JOIN likes_count AS l
  ON u.id = l.user_id
LEFT JOIN comments_count AS c
  ON u.id = c.user_id
LEFT JOIN photo_counts AS pp
  ON u.id = pp.user_id
LEFT JOIN phototags_count AS p
  ON u.id = p.user_id
LEFT JOIN Count_of_followers AS f
  ON u.id = f.follower_id
ORDER BY
  engagement_rate_rank ASC;
  
  
-- Q3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

with Likes as (
SELECT photo_id, COUNT(*) AS total_likes 
FROM likes GROUP BY photo_id),

Comments as (  
  SELECT photo_id, COUNT(*) AS total_comments 
  FROM comments GROUP BY photo_id)
  
SELECT t.tag_name,
    COUNT(pt.photo_id) AS total_posts,
    COALESCE(SUM(l.total_likes), 0) AS total_likes,
    COALESCE(SUM(c.total_comments), 0) AS total_comments,
    ROUND((COALESCE(SUM(l.total_likes), 0) + COALESCE(SUM(c.total_comments), 0)) / COUNT(pt.photo_id),0) AS average_engagement
FROM tags t
JOIN photo_tags pt 
ON t.id = pt.tag_id
LEFT JOIN Likes as l 
on pt.photo_id = l.photo_id
LEFT JOIN Comments as c
on pt.photo_id = c.photo_id
group by t.tag_name
order by average_engagement desc
limit 10;


-- Q4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?


With Likes as 
(SELECT photo_id, COUNT(*) AS Total_likes 
FROM likes GROUP BY photo_id) , 

Comments as 
(SELECT photo_id, COUNT(*) AS Total_comments 
FROM comments GROUP BY photo_id) 

 SELECT
    DATE_FORMAT(p.created_dat, '%H') AS Hour_of_day,
    DAYNAME(p.created_dat) AS Day_of_week,
    COUNT(p.id) AS Total_posts,
    COALESCE(SUM(L.Total_likes), 0) AS Total_likes,
    COALESCE(SUM(c.Total_comments), 0) AS Total_comments,
    ROUND((COALESCE(SUM(l.Total_likes), 0) + COALESCE(SUM(c.Total_comments), 0)) / COUNT(p.id),0) 
    AS Average_engagement
FROM photos AS p
LEFT JOIN Likes as l
ON p.id = l.photo_id
LEFT JOIN Comments as c 
ON p.id = c.photo_id
GROUP BY Hour_of_day,Day_of_week ;


-- Q5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?

WITH Followers AS (
    SELECT f.follower_id AS user_id,
          COUNT(f.follower_id) AS follower_count
    FROM follows f
    GROUP BY f.follower_id),
total_likes_n_comments AS (
    SELECT p.user_id,
        COUNT(DISTINCT l.user_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id),
Final AS (
    SELECT u.id, u.username as Username,
	coalesce(sum(f.follower_count),0) as Follower_count,
	coalesce(sum(t.total_likes),0) AS Total_likes,
	coalesce(sum(t.total_comments),0) AS Total_comments,
	Round(coalesce(sum(t.total_likes), 0) + coalesce(sum(t.total_comments),0) / coalesce(count(f.follower_count),1),0) 
	AS Engagement_rate
    FROM users u
    LEFT JOIN Followers f ON u.id = f.user_id
    LEFT JOIN total_likes_n_comments t ON u.id = t.user_id
    group by u.id ,u.username )
    
SELECT
    id AS User_id, Username, Follower_count, 
    Total_likes, Total_comments, Engagement_rate
FROM Final 
where Follower_count != 0
ORDER BY engagement_rate DESC, follower_count DESC
limit 10;


-- Q6. Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?

With Likes as 
 (SELECT user_id, COUNT(*) AS likes_count 
 FROM likes 
 GROUP BY user_id),
 
Comments as 
 (SELECT user_id, COUNT(*) AS comments_count 
 FROM comments 
 GROUP BY user_id) 
 
 SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(SUM(likes_count), 0) AS Total_likes,
    COALESCE(SUM(comments_count), 0) AS Total_comments,
    COALESCE(COUNT(DISTINCT p.id), 0) AS Total_photos,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 0 
        ELSE (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) 
    END AS Engagement_rate,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 'Inactive Users'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) > 150 THEN 'Ative Users'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) BETWEEN 100 AND 150 
        THEN 'Moderately Active Users'
        ELSE 'Inactive Users'
    END AS Engagement_level
FROM users as u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN Likes as l 
ON u.id = l.user_id
LEFT JOIN Comments as c
ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY engagement_rate DESC;
