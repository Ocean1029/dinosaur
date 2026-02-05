-- 更新所有color為null的徽章，循環分配4種顏色
-- 使用ROW_NUMBER()來確保顏色分配的一致性

WITH numbered_badges AS (
  SELECT 
    "id",
    (ROW_NUMBER() OVER (ORDER BY "id") - 1) % 4 AS color_index
  FROM "badges"
  WHERE "color" IS NULL
)
UPDATE "badges" b
SET "color" = CASE 
  WHEN nb.color_index = 0 THEN '#76a732'
  WHEN nb.color_index = 1 THEN '#F5BA4B'
  WHEN nb.color_index = 2 THEN '#FD853A'
  WHEN nb.color_index = 3 THEN '#5ab4c5'
END
FROM numbered_badges nb
WHERE b."id" = nb."id";

