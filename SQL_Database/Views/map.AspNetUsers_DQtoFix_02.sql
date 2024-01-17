SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

		CREATE VIEW [map].[AspNetUsers_DQtoFix_02] AS
		SELECT		'null merge primary' AS Issue
					,users.*
					,v_01.SrcSysID_Master
					,v_01.ID_Master
		FROM		map.AspNetUsers users
		LEFT JOIN	map.AspNetUsers_ValidateMatch_01 v_01
														ON	users.SrcSysID = v_01.SrcSysID
														AND	users.ID = v_01.ID
		WHERE		users.MergePrimary IS NULL
		AND			v_01.MatchCount IS NULL

GO
