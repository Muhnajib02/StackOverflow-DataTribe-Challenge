-- to get statistic activities by user reputation from 2017
SELECT
    rep_range AS Reputation,
    COUNT(*) AS Users,
    SUM(asked) AS Asked_question,
    SUM(unanswered) AS Unanswered_question,
    SUM(answered) AS Contributed_answer
FROM(
    SELECT 
        CASE
            WHEN reputation BETWEEN 1 AND 100 THEN 'Level 1 (1- 100)'
            WHEN reputation BETWEEN 101 AND 1000 THEN 'Level 2 (101- 1000)'
            WHEN reputation BETWEEN 1001 AND 10000 THEN 'Level 3 (1001- 10000)'
            WHEN reputation BETWEEN 10001 AND 100000 THEN 'Level 4 (10001- 100000)'
            WHEN reputation > 100000 THEN 'Level 5 (> 100000)'
        END AS rep_range,
        asked,
        answered,
        unanswered
    FROM(    
        SELECT  id AS user_id, reputation, asked, answered, unanswered
        FROM `bigquery-public-data.stackoverflow.users` u
        LEFT JOIN(
            SELECT extract(year from creation_date) as year, owner_user_id AS user_id, COUNT(*) AS asked
            FROM `bigquery-public-data.stackoverflow.posts_questions` 
            GROUP BY  year, user_id
            having year > 2016
        ) q ON u.id = q.user_id
        LEFT JOIN(
            SELECT extract(year from creation_date) as year, owner_user_id AS user_id, COUNT(*) AS answered
            FROM `bigquery-public-data.stackoverflow.posts_answers` 
            GROUP BY  year, user_id
            having year > 2016
        ) a ON u.id = a.user_id
        LEFT JOIN(
            SELECT extract(year from creation_date) as year, owner_user_id AS user_id, COUNT(*) AS unanswered 
            FROM (
                SELECT owner_user_id, creation_date
                FROM `bigquery-public-data.stackoverflow.posts_questions`
                WHERE answer_count=0
            )
            GROUP BY year, user_id
            having year > 2016
        ) ua ON u.id = ua.user_id
    )
)
GROUP BY rep_range
ORDER BY rep_range

-- find the percentage ration question that have answer from 2017
SELECT
        EXTRACT(YEAR FROM creation_date) AS Year,
        COUNT(*) AS Number_of_Questions,
        ROUND(100 * COUNTIF(answer_count > 0) / COUNT(*), 2) AS Percent_of_Questions_with_Answers
FROM `bigquery-public-data.stackoverflow.posts_questions`
GROUP BY Year
ORDER BY Year DESC
LIMIT 6

-- find the percentage of question answered within 1 hour by day of week
SELECT
      Day_of_Week,
      COUNT(*) AS Number_of_Questions,
      SUM(within_1h) AS Number_of_Answered_within_1h,
      ROUND(100 * SUM(within_1h) / COUNT(*), 2) AS Percent_of_Answered_within_1h
FROM
    (
      SELECT
      EXTRACT(YEAR from q.creation_date) as year,
      CASE
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 1 THEN 'Sunday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 2 THEN 'Monday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 3 THEN 'Tuesday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 4 THEN 'Wednesday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 5 THEN 'Thursday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 6 THEN 'Friday'
            WHEN EXTRACT(DAYOFWEEK FROM q.creation_date) = 7 THEN 'Saturday'
      END AS day_of_week,
      a.id AS answer_id,
      COUNTIF((UNIX_SECONDS(a.creation_date)-UNIX_SECONDS(q.creation_date))/3600 <= 1) AS within_1h
      FROM `bigquery-public-data.stackoverflow.posts_questions` AS q 
      LEFT JOIN `bigquery-public-data.stackoverflow.posts_answers` AS a
      ON q.id = a.parent_id
      GROUP BY answer_id, day_of_week, year
      HAVING year > 2019
      )
GROUP BY Day_of_Week
ORDER BY Day_of_Week
