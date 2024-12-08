-- 移動記録の事前計算
ALTER TABLE chairs
ADD COLUMN total_distance INTEGER NOT NULL DEFAULT 0 COMMENT '移動距離';

UPDATE chairs c
JOIN (
  SELECT
    chair_id,
    SUM(IFNULL(distance, 0)) AS total_distance,
    MAX(created_at) AS total_distance_updated_at
  FROM (
    SELECT 
      chair_id, created_at,
      ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) +
      ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance
    FROM chair_locations
  ) tmp
  GROUP BY chair_id
) tmp_result ON c.id = tmp_result.chair_id
SET c.total_distance = tmp_result.total_distance;
