SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[tblMAIN_REFERRALS_uspMatchControlUpdate] AS 

/******************************************************** © Copyright & Licensing ****************************************************************
© 2024 Perspicacity Ltd & University Hospitals Sussex

This code / file is part of Perspicacity & University Hospitals Sussex SCR merge validation suite.

This SCR merge validation suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This SCR migration merge suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/ScrMergeValidation

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	31/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A template stored procedure to update the data used in the matching
							and validation process with changes in the source data
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.tblMAIN_REFERRALS_uspMatchControlUpdate

		-- Set up the variables for process auditing
		DECLARE	@CurrentUser VARCHAR(255)
				,@ProcIdName VARCHAR(255)
				,@CurrentSection VARCHAR(255)
				,@CurrentDttm DATETIME2
				,@LoopCounter SMALLINT = 1

		SELECT	@CurrentUser = CURRENT_USER
				,@ProcIdName = ISNULL(OBJECT_NAME(@@PROCID), 'ad hoc')

		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'new records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL
		
		-- Insert all new SCR values to the match control table
		INSERT INTO	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control
					(IsSCR
					,SrcSys
					,Src_UID
					,HashBytesValue
					,ChangeLastDetected)
		SELECT		uh.IsSCR
					,uh.SrcSys
					,uh.Src_UID
					,uh.HashBytesValue
					,GETDATE()
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
													ON	uh.SrcSys = mc.SrcSys
													AND	uh.Src_UID = mc.Src_UID
		WHERE		mc.SrcSys IS NULL
		AND			uh.IsSCR = 1	-- only add new SCR records

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'update existing records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Update existing match control records where a change has been detected
		UPDATE		mc
		SET			mc.HashBytesValue = uh.HashBytesValue
					,mc.ChangeLastDetected = GETDATE()
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
		INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
											ON	mc.SrcSys = uh.SrcSys
											AND	mc.Src_UID = uh.Src_UID
		WHERE		mc.HashBytesValue != uh.HashBytesValue

		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL
		SELECT @CurrentDttm = GETDATE(), @CurrentSection = 'deleted records'; EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 0, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = @CurrentDttm, @EndDttm = NULL, @Success = NULL, @ErrorMessage = NULL

		-- Mark existing match control records deleted where the source has been deleted
		UPDATE		mc
		SET			mc.DeletedDttm = GETDATE()
					,mc.ChangeLastDetected = GETDATE()
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
											ON	mc.SrcSys = uh.SrcSys
											AND	mc.Src_UID = uh.Src_UID
		WHERE		uh.SrcSys IS NULL
		
		SELECT @CurrentDttm = GETDATE(); EXEC Merge_DM_MatchAudit.uspProcessAudit @IsUpdate = 1, @SessionID = @@SPID, @UserID = @CurrentUser, @ProcName = @ProcIdName, @Section = @CurrentSection, @StartDttm = NULL, @EndDttm = @CurrentDttm, @Success = NULL, @ErrorMessage = NULL

GO
