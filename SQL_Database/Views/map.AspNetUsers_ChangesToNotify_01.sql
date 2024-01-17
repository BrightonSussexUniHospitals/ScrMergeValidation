SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

		CREATE VIEW [map].[AspNetUsers_ChangesToNotify_01] AS
		SELECT		'Single merge username record where the username has changed' AS Issue
					,AspNetUsers.*
					,Email		= ISNULL(wsht.Email, bsuh.Email)
					,FullName		= ISNULL(wsht.FullName, bsuh.FullName)
		FROM		map.AspNetUsers AspNetUsers
		LEFT JOIN	CancerRegister_WSHT.dbo.AspNetUsers wsht
															ON	AspNetUsers.ID = wsht.Id
															AND	AspNetUsers.SrcSysID = 1
		LEFT JOIN	CancerRegister_BSUH.dbo.AspNetUsers bsuh
															ON	AspNetUsers.ID = bsuh.Id
															AND	AspNetUsers.SrcSysID = 2
		INNER JOIN	(SELECT		AspNetUsers_inner.MergeUsername
					FROM		map.AspNetUsers AspNetUsers_inner
					GROUP BY	AspNetUsers_inner.MergeUsername
					HAVING		COUNT(*) = 1) singleMergeRec
															ON	AspNetUsers.MergeUsername = singleMergeRec.MergeUsername
		WHERE		AspNetUsers.UserName != AspNetUsers.MergeUsername

GO
