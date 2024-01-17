SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

		CREATE VIEW [map].[AspNetUsers_DQtoFix_07] AS
		SELECT		'Match recorded where no algorithmic match has been found' AS Issue
					,AspNetUsers.*
		FROM		map.AspNetUsers AspNetUsers
		INNER JOIN	map.AspNetUsers AspNetUsers_match
													ON	AspNetUsers.MergeUsername = AspNetUsers_match.MergeUsername
													AND	(AspNetUsers.SrcSysID != AspNetUsers_match.SrcSysID
													OR	AspNetUsers.ID != AspNetUsers_match.ID)
		LEFT JOIN	map.AspNetUsers_ValidateMatch_01 v_01
														ON	AspNetUsers.SrcSysID = v_01.SrcSysID
														AND	AspNetUsers.ID = v_01.ID
		
GO
