SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [map].[AspNetUsers_ValidateToMerge_01] AS
SELECT		v_01.SrcSysID_Master
			,v_01.ID_Master
			,v_01.BestMatchScore
			,AspNetUsers.SrcSysID
			,AspNetUsers.ID
			,AspNetUsers.UserName
			,AspNetUsers.MergePrimary
			,AspNetUsers.MergeUsername
			,AspNetUsers.LogicalDelete
			,ISNULL(users_wsht.Email, users_bsuh.Email) AS Email_Comp
			,ISNULL(users_wsht.FullName, users_bsuh.FullName) AS FullName_Comp
			,ISNULL(users_wsht.OrganisationCode, users_bsuh.OrganisationCode) AS OrganisationCode_Comp
			,ISNULL(users_wsht.IsApproved, users_bsuh.IsApproved) AS IsApproved_Comp
			,ISNULL(users_wsht.CreatedDate, users_bsuh.CreatedDate) AS CreatedDate_Comp
			,ISNULL(users_wsht.LastLoginDate, users_bsuh.LastLoginDate) AS LastLoginDate_Comp
			,ISNULL(users_wsht.LastPasswordChangeDate, users_bsuh.LastPasswordChangeDate) AS LastPasswordChangeDate_Comp
			,ISNULL(users_wsht.PasswordReset, users_bsuh.PasswordReset) AS PasswordReset_Comp
			,ISNULL(users_wsht.AssociatedCNSId, users_bsuh.AssociatedCNSId) AS ASsociatedCNSId_Comp
			,ISNULL(users_wsht.LastLockoutDate, users_bsuh.LastLockoutDate) AS LastLockoutDate_Comp
			,AspNetUsers.DateLogged
FROM		map.AspNetUsers AspNetUsers
INNER JOIN	map.AspNetUsers_ValidateMatch_01 v_01
											ON	AspNetUsers.SrcSysID = v_01.SrcSysID
											AND	AspNetUsers.ID = v_01.ID
INNER JOIN	(SELECT		v_01_inner.SrcSysID_Master
						,v_01_inner.ID_Master
			FROM		map.AspNetUsers AspNetUsers_inner
			INNER JOIN	map.AspNetUsers_ValidateMatch_01 v_01_inner
																	ON	AspNetUsers_inner.SrcSysID = v_01_inner.SrcSysID
																	AND	AspNetUsers_inner.ID = v_01_inner.ID
			WHERE		AspNetUsers_inner.MergePrimary IS NULL
			OR			AspNetUsers_inner.MergeUsername IS NULL
			OR			AspNetUsers_inner.LogicalDelete IS NULL
			GROUP BY	v_01_inner.SrcSysID_Master
						,v_01_inner.ID_Master) checkMergeIncomplete
																ON	v_01.SrcSysID_Master = checkMergeIncomplete.SrcSysID_Master
																AND	v_01.ID_Master = checkMergeIncomplete.ID_Master
LEFT JOIN	CancerRegister_WSHT.dbo.AspNetUsers users_wsht
															ON	AspNetUsers.ID = users_wsht.Id
															AND	AspNetUsers.SrcSysID = 1
LEFT JOIN	CancerRegister_BSUH.dbo.AspNetUsers users_bsuh
															ON	AspNetUsers.ID = users_bsuh.Id
															AND	AspNetUsers.SrcSysID = 2
GO
