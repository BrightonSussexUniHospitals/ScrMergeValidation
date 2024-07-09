SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Merge_DM_Match].[uspSSRS_Merge_MDT_Data]

		(@SrcSys_Major TINYINT = NULL
		,@Src_UID_Major VARCHAR(255) = NULL
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

Original Work Created Date:	11/03/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to return the DM matching data for validation
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.uspSSRS_Merge_MDT_Data @SrcSys_Major = 1, @Src_UID_Major = '108421'

/*****************************************************************************************************************************************/
-- Refresh the matching data 
/*****************************************************************************************************************************************/

		EXEC Merge_DM_Match.MDT_uspMatchControlUpdateAndMatch @SrcSys = @SrcSys_Major, @Src_UID = @Src_UID_Major

/*****************************************************************************************************************************************/
-- Return the SSRS output 
/*****************************************************************************************************************************************/

		-- Return the output
		SELECT		mdt_vw.Ref_SrcSys_Major
					,mdt_vw.Ref_Src_UID_Major
					,mdt_vw.Ref_SrcSys_Minor
					,mdt_vw.Ref_Src_UID_Minor
					,mdt_vw.tableName
					,mdt_vw.table_UID
					,mdt_vw.Migrate
					,UH.LastUpdated
					-- Status'
					,UH.FrontEndStatus
					,UH.MeetingList_MDT_ID_DONE
					-- Dates
					,COALESCE(UH.CarePlan_MDT_DATE,UH.MDT_DATE,UH.MeetingList_MDT_DATE) AS CombinedDate
					,mdt_vw.MDT_DATE
					,UH.MeetingList_MDT_DATE
					,UH.CarePlan_MDT_DATE
					-- Sites
					,mdt_vw.CancerSite
					,UH.MDT_MDT_SITE
					,UH.MeetingList_SITE
					,UH.CarePlan_SITE
					,UH.OTHER_SITE
					,UH.SubSite
					,UH.MdtMeetingsNetworkFlag
					,UH.CarePlanNetworkFlag
					-- Locations
					,UH.MDTLocation
					,UH.CarePlanLocation
					,UH.TemplateLocation
					-- Comments
					,UH.MDT_Comments
					,UH.MeetingList_Comments
					,UH.CarePlan_Comments
					,CASE WHEN ref_mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END AS Confirmed
					,CASE	WHEN mdt_vw.Ref_SrcSys_Minor = 1 
							THEN 'https://ryrsomerset.wsht.nhs.uk/CancerRegister/careplan/careplan.aspx?PlanID='
							WHEN mdt_vw.Ref_SrcSys_Minor = 2 
							THEN 'https://svvscr01.bsuh.nhs.uk/CancerRegister/careplan/careplan.aspx?PlanID='
							END +
							CAST(uh.PLAN_ID AS VARCHAR(255)) AS ScrHyperlink
		FROM		Merge_DM_MatchViews.MDT_vw_SCOPE(@SrcSys_Major, @Src_UID_Major) mdt_vw
		INNER JOIN	Merge_DM_Match.MDT_mvw_UH UH
														ON	mdt_vw.Ref_SrcSys_Minor = UH.Ref_SrcSys_Minor
														AND	mdt_vw.tableName = UH.tableName
														AND	mdt_vw.table_UID = UH.table_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation ref_mmv
																				ON	mdt_vw.Ref_SrcSys_Major = ref_mmv.SrcSys_Major
																				AND	mdt_vw.Ref_Src_UID_Major = ref_mmv.Src_UID_Major
																				AND	ref_mmv.ValidationStatus IN ('Confirmed','Dont Merge')
		WHERE		mdt_vw.InScope = 1
		AND			mdt_vw.Ref_SrcSys_Major = @SrcSys_Major
		AND			mdt_vw.Ref_Src_UID_Major = @Src_UID_Major


GO
