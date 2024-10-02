SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMONITORING] AS

/******************************************************** © Copyright & Licensing ****************************************************************
© 2019 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	30/07/2020
Original Work Created By:	Perspicacity Ltd (Matthew Bishop) & BSUH (Lawrence Simpson)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk / lawrencesimpson@nhs.net
Description:				Create a local config view to point at the place where the SCR
							replicated data is located so that the core procedures don't
							need to be changed when they are copied to different environments 
							(e.g. live vs test or from one trust to another)
**************************************************************************************************************************************************/

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(1 AS tinyint) AS SrcSysID
			,MONITOR_ID
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,N16_9_DECISION_ACTIVE
			,N16_10_START_ACTIVE
			,N1_3_ORG_CODE_TREATMENT = N1_3_ORG_CODE_TREATMENT COLLATE DATABASE_DEFAULT
			,L_MONITORING_INTENT = L_MONITORING_INTENT COLLATE DATABASE_DEFAULT
			,N_SITE_CODE_DTT = N_SITE_CODE_DTT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_EVENT = N_TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_SETTING = N_TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,L_TRIAL
			,DEFINITIVE_TREATMENT
			,CWT_PROFORMA
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,N7_2_CONSULTANT = N7_2_CONSULTANT COLLATE DATABASE_DEFAULT
			,PRE_TREAT_PSA
			,ROOT_CAUSE_COMMENTS = ROOT_CAUSE_COMMENTS COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,TertiaryReferralKey
			,ROOT_PRIM_ADJUSTMENT_COMMENTS = ROOT_PRIM_ADJUSTMENT_COMMENTS  COLLATE DATABASE_DEFAULT
			,ROOT_SUBPRIM_ADJUSTMENT_COMMENTS = ROOT_SUBPRIM_ADJUSTMENT_COMMENTS COLLATE DATABASE_DEFAULT
	FROM	[CancerRegister_WSHT]..tblMONITORING

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID
			,MONITOR_ID
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,N16_9_DECISION_ACTIVE
			,N16_10_START_ACTIVE
			,N1_3_ORG_CODE_TREATMENT = N1_3_ORG_CODE_TREATMENT COLLATE DATABASE_DEFAULT
			,L_MONITORING_INTENT = L_MONITORING_INTENT COLLATE DATABASE_DEFAULT
			,N_SITE_CODE_DTT = N_SITE_CODE_DTT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_EVENT = N_TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_SETTING = N_TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,L_TRIAL
			,DEFINITIVE_TREATMENT
			,CWT_PROFORMA
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,N7_2_CONSULTANT = N7_2_CONSULTANT COLLATE DATABASE_DEFAULT
			,PRE_TREAT_PSA
			,ROOT_CAUSE_COMMENTS = ROOT_CAUSE_COMMENTS COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,TertiaryReferralKey
			,ROOT_PRIM_ADJUSTMENT_COMMENTS = ROOT_PRIM_ADJUSTMENT_COMMENTS  COLLATE DATABASE_DEFAULT
			,ROOT_SUBPRIM_ADJUSTMENT_COMMENTS = ROOT_SUBPRIM_ADJUSTMENT_COMMENTS COLLATE DATABASE_DEFAULT
	FROM	[CancerRegister_BSUH]..tblMONITORING
GO
