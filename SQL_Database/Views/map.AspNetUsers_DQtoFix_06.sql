SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

		CREATE VIEW [map].[AspNetUsers_DQtoFix_06] AS
		SELECT		'logical deletes on a non primary merge' AS Issue
					,users.*
		FROM		map.AspNetUsers users
		WHERE		ISNULL(users.MergePrimary, 0) = 0
		AND			users.LogicalDelete = 1

GO
