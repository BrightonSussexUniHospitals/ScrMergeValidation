SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspUnlinkReferralLaterality]

		(@SrcSys_Major TINYINT
		,@Src_UID_Major VARCHAR(255)
		,@UserID VARCHAR(255)
		)

AS 

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
Description:				A stored procedure to unlink incorrect matches between an entity and the major entity
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspUnlinkReferralLaterality @SrcSys_Major = 1, @Src_UID_Major = '393091', @UserId = 'BSUH\Matthew.Bishop'

		/*****************************************************************************************************************************************/
		-- Make the updates
		/*****************************************************************************************************************************************/

		BEGIN TRY

			BEGIN TRANSACTION
		
				-- Update unlinking columns in EntityPairs_Unique for links between left and right sided referrals (pair A)
				UPDATE		ep_u
				SET			ep_u.UnlinkDttm = GETDATE()
							,ep_u.LastUnlinkedBy = @UserID
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
				INNER JOIN	(SELECT		ep_u_inner.*
										,UH_A.N4_3_LATERALITY AS Side_A
										,UH_B.N4_3_LATERALITY AS Side_B
							FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u_inner
																									ON	mc.SrcSys = ep_u_inner.SrcSys_A
																									AND	mc.Src_UID = ep_u_inner.Src_UID_A
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH UH_A
																				ON	ep_u_inner.SrcSys_A = UH_A.SrcSys
																				AND	ep_u_inner.Src_UID_A = UH_A.Src_UID
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH UH_B
																				ON	ep_u_inner.SrcSys_B = UH_B.SrcSys
																				AND	ep_u_inner.Src_UID_B = UH_B.Src_UID
							WHERE		mc.SrcSys_Major = @SrcSys_Major
							AND			mc.Src_UID_Major = @Src_UID_Major
							AND			((UH_A.N4_3_LATERALITY = 'L' AND UH_B.N4_3_LATERALITY = 'R')
							OR			(UH_A.N4_3_LATERALITY = 'R' AND UH_B.N4_3_LATERALITY = 'L'))
										) LR
											ON	ep_u.SrcSys_A = LR.SrcSys_A
											AND	ep_u.Src_UID_A = LR.Src_UID_A
											AND	ep_u.SrcSys_B = LR.SrcSys_B
											AND	ep_u.Src_UID_B = LR.Src_UID_B
		
				-- Update unlinking columns in EntityPairs_Unique for links between left and right sided referrals (pair B)
				UPDATE		ep_u
				SET			ep_u.UnlinkDttm = GETDATE()
							,ep_u.LastUnlinkedBy = @UserID
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
				INNER JOIN	(SELECT		ep_u_inner.*
										,UH_A.N4_3_LATERALITY AS Side_A
										,UH_B.N4_3_LATERALITY AS Side_B
							FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u_inner
																									ON	mc.SrcSys = ep_u_inner.SrcSys_B
																									AND	mc.Src_UID = ep_u_inner.Src_UID_B
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH UH_A
																				ON	ep_u_inner.SrcSys_A = UH_A.SrcSys
																				AND	ep_u_inner.Src_UID_A = UH_A.Src_UID
							INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH UH_B
																				ON	ep_u_inner.SrcSys_B = UH_B.SrcSys
																				AND	ep_u_inner.Src_UID_B = UH_B.Src_UID
							WHERE		mc.SrcSys_Major = @SrcSys_Major
							AND			mc.Src_UID_Major = @Src_UID_Major
							AND			((UH_A.N4_3_LATERALITY = 'L' AND UH_B.N4_3_LATERALITY = 'R')
							OR			(UH_A.N4_3_LATERALITY = 'R' AND UH_B.N4_3_LATERALITY = 'L'))
										) LR
											ON	ep_u.SrcSys_A = LR.SrcSys_A
											AND	ep_u.Src_UID_A = LR.Src_UID_A
											AND	ep_u.SrcSys_B = LR.SrcSys_B
											AND	ep_u.Src_UID_B = LR.Src_UID_B
		
			COMMIT TRANSACTION

			EXEC Merge_DM_MatchAudit.uspUnlinkMatch 1, NULL, @UserID, 'tblMAIN_REFERRALS', @SrcSys_Major, @Src_UID_Major, 0, 'LeftRight'

		END TRY

		BEGIN CATCH
 
			DECLARE @ErrorMessage VARCHAR(MAX)
			SELECT @ErrorMessage = ERROR_MESSAGE()
			
			SELECT ERROR_NUMBER() AS ErrorNumber
			SELECT @ErrorMessage AS ErrorMessage
 
			PRINT ERROR_NUMBER()
			PRINT @ErrorMessage

			IF @@TRANCOUNT > 0 -- SELECT @@TRANCOUNT
					PRINT 'Rolling back because of error in Incremental Transaction'
				ROLLBACK TRANSACTION

			EXEC Merge_DM_MatchAudit.uspUnlinkMatch 0, @ErrorMessage, @UserID, 'tblMAIN_REFERRALS', @SrcSys_Major, @Src_UID_Major, 0, 'LeftRight'

			RAISERROR (@ErrorMessage, -- Message text.  
										15, -- Severity.  
										1 -- State.  
										);
 
		END CATCH


GO
