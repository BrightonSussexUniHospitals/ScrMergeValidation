SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspSSRS_Merge_Treatments_Data]

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
-- EXEC Merge_DM_Match.uspSSRS_Merge_Treatments_Data @SrcSys_Major = 1, @Src_UID_Major = '388974'
-- EXEC Merge_DM_Match.uspSSRS_Merge_Treatments_Data @SrcSys_Major = 1, @Src_UID_Major = '393091'

/*****************************************************************************************************************************************/
-- Refresh the matching data 
/*****************************************************************************************************************************************/

		EXEC Merge_DM_Match.Treatments_uspMatchControlUpdateAndMatch @SrcSys = @SrcSys_Major, @Src_UID = @Src_UID_Major

/*****************************************************************************************************************************************/
-- Return the SSRS output 
/*****************************************************************************************************************************************/

		-- Return the output
		SELECT		tx_vw.Ref_SrcSys_Major
					,tx_vw.Ref_Src_UID_Major
					,tx_vw.Ref_SrcSys_Minor
					,tx_vw.Ref_Src_UID_Minor
					,tx_vw.TreatmentDate
					,tx_vw.Treatment
					,CASE	tx_vw.Treatment
							WHEN 'tblMAIN_CHEMOTHERAPY' THEN 'Chemo'
							WHEN 'tblMAIN_BRACHYTHERAPY' THEN 'Brachy'
							WHEN 'tblMAIN_PALLIATIVE' THEN 'Pall'
							WHEN 'tblMAIN_SURGERY' THEN 'Surg'
							WHEN 'tblMAIN_TELETHERAPY' THEN 'Tele'
							WHEN 'tblMONITORING' THEN 'Monitor'
							WHEN 'tblOTHER_TREATMENT' THEN 'Other'
							END AS TreatmentShortName
					,tx_vw.TreatmentSite
					,tx_vw.TreatmentID
					,tx_vw.Migrate
					,UH.LastUpdated
					,UH.NonNullColumnCount
					,CASE WHEN ref_mmv.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END AS Confirmed
					,CASE	WHEN tx_vw.Ref_SrcSys_Minor = 1 
							THEN 'https://ryrsomerset.wsht.nhs.uk/CancerRegister/treatments/'
							WHEN tx_vw.Ref_SrcSys_Minor = 2 
							THEN 'https://svvscr01.bsuh.nhs.uk/CancerRegister/treatments/'
							END +
					CASE	tx_vw.Treatment
							WHEN 'tblMAIN_CHEMOTHERAPY' THEN 'antiCancerDrugs/antiCancerDrugs.aspx?CHEMO_ID='
							WHEN 'tblMAIN_BRACHYTHERAPY' THEN 'brachytherapy/brachy.aspx?BRACHY_ID='
							WHEN 'tblMAIN_PALLIATIVE' THEN 'palliative/pcare.aspx?PalliativeID='
							WHEN 'tblMAIN_SURGERY' THEN 'surgery/surgery.aspx?SurgeryID='
							WHEN 'tblMAIN_TELETHERAPY' THEN 'teletherapy/tele.aspx?TELE_ID'
							WHEN 'tblMONITORING' THEN 'active_monitor/monitor.aspx?MONITOR_ID='
							WHEN 'tblOTHER_TREATMENT' THEN 'other/other.aspx?OTHER_ID='
							END  + CAST(tx_vw.TreatmentID AS VARCHAR(255)) AS ScrHyperlink
		FROM		Merge_DM_MatchViews.Treatments_vw_SCOPE(@SrcSys_Major, @Src_UID_Major) tx_vw
		INNER JOIN	Merge_DM_Match.Treatments_mvw_UH UH
														ON	tx_vw.Ref_SrcSys_Minor = UH.Ref_SrcSys_Minor
														AND	tx_vw.Treatment = UH.Treatment
														AND	tx_vw.TreatmentID = UH.TreatmentID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_MajorValidation ref_mmv
																				ON	tx_vw.Ref_SrcSys_Major = ref_mmv.SrcSys_Major
																				AND	tx_vw.Ref_Src_UID_Major = ref_mmv.Src_UID_Major
																				AND	ref_mmv.ValidationStatus IN ('Confirmed','Dont Merge')
		WHERE		tx_vw.InScope = 1
		AND			tx_vw.Ref_SrcSys_Major = @SrcSys_Major
		AND			tx_vw.Ref_Src_UID_Major = @Src_UID_Major


GO
