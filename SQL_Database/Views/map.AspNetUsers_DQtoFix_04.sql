SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

		CREATE VIEW [map].[AspNetUsers_DQtoFix_04] AS
		SELECT		'multiple merge primaries per merge username' AS Issue
					,users.MergeUsername
		FROM		map.AspNetUsers users
		GROUP BY	users.MergeUsername
		HAVING		SUM(CAST(ISNULL(users.MergePrimary, 0) AS TINYINT)) > 1

GO
