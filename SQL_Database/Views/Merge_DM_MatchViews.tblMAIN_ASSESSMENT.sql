SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMAIN_ASSESSMENT] AS

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
	SELECT   CAST(1 AS tinyint) AS SrcSysID
			,ASSESSMENT_ID 
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,N14_1_ASSESSMENT_DATE 
			,N14_2_TUMOUR_STATUS 
			,N14_3_NODE_STATUS 
			,N14_4_METS_STATUS 
			,N14_5_MARKER_RESPONSE 
			,N14_6_WHO_STATUS 
			,N14_7_MORBIDITY_TYPE 
			,N14_8_MORBIDITY_CODE = N14_8_MORBIDITY_CODE COLLATE DATABASE_DEFAULT
			,N14_9_FOLLOW_UP 
			,N14_10_CHEMO_MORBIDITY
			,N14_11_RADIO_MORBIDITY
			,N14_12_COMB_MORBIDITY 
			,N_SK24_TUMOUR_STATUS 
			,N_L21_RECEIVED_PCI = N_L21_RECEIVED_PCI COLLATE DATABASE_DEFAULT
			,N_L30_PLAN = N_L30_PLAN COLLATE DATABASE_DEFAULT
			,N_L31_FAILURE =N_L31_FAILURE COLLATE DATABASE_DEFAULT
			,R_ORG_CODE = R_ORG_CODE COLLATE DATABASE_DEFAULT
			,R_ALIVE_DATE 
			,R_ABROAD_DATE
			,R_MODE_FOLLOWUP 
			,L_OTHER_MODE = L_OTHER_MODE COLLATE DATABASE_DEFAULT
			,R_RECURRENCE_BY
			,R_DATE_RECURRENCE 
			,R_POTENCY = R_POTENCY COLLATE DATABASE_DEFAULT
			,R_CONTINENCE = R_CONTINENCE COLLATE DATABASE_DEFAULT
			,R_INTERVENTION 
			,R_OTHER_INTERVENTION = R_OTHER_INTERVENTION COLLATE DATABASE_DEFAULT
			,R_COMPLICATIONS 
			,R_OTHER_COMPLICATIONS = R_OTHER_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,R_CURRENT_STATUS 
			,R_DATE_STATUS 
			,R_STATUS 
			,R_OTHER_TRACT = R_OTHER_TRACT COLLATE DATABASE_DEFAULT
			,R_SERUM 
			,R_FBC
			,R_LFT
			,R_CT 
			,R_USS
			,R_CXR
			,R_OTHER_TESTS = R_OTHER_TESTS COLLATE DATABASE_DEFAULT
			,R_PSA 
			,R_DATE_METATASECTOMY 
			,L_HEIGHT 
			,L_WEIGHT 
			,L_FOLLOWUP = L_FOLLOWUP COLLATE DATABASE_DEFAULT
			,L_REF_ONCOLOGIST 
			,L_WHOLE_IMAGED
			,L_COLO_REQUEST
			,L_BA_REQUEST 
			,L_ASYMPTOMATIC
			,L_SYMPTOMATIC 
			,L_DETAILS = L_DETAILS COLLATE DATABASE_DEFAULT
			,L_RECURRENCE
			,L_REC_SITE = L_REC_SITE COLLATE DATABASE_DEFAULT
			,L_REC_SITE_2 = L_REC_SITE_2  COLLATE DATABASE_DEFAULT
			,L_ERECTILE = L_ERECTILE COLLATE DATABASE_DEFAULT
			,L_BLADDER = L_BLADDER COLLATE DATABASE_DEFAULT
			,L_RESOLUTION_ERECTILE = L_RESOLUTION_ERECTILE COLLATE DATABASE_DEFAULT
			,L_RESOLUTION_BLADDER = L_RESOLUTION_BLADDER COLLATE DATABASE_DEFAULT
			,L_CT_REQUEST 
			,L_MRI_REQUEST
			,L_INCISIONAL_HERNIA 
			,L_STRICTURE
			,L_SCREENING
			,L_LOCATION 
			,L_REASON = L_REASON COLLATE DATABASE_DEFAULT
			,L_MAMMOGRAM 
			,L_OUTSIDE_FOLLOWUP 
			,L_OUTSIDE_DETAILS = L_OUTSIDE_DETAILS COLLATE DATABASE_DEFAULT
			,L_METS = L_METS COLLATE DATABASE_DEFAULT
			,L_PLANNED
			,L_LYMPHOEDEMA 
			,L_DIARY 
			,L_SEIZURES = L_SEIZURES COLLATE DATABASE_DEFAULT
			,L_OUTCOME
			,L_OTHER_OUTCOME = L_OTHER_OUTCOME COLLATE DATABASE_DEFAULT
			,L_RE_BX = L_RE_BX COLLATE DATABASE_DEFAULT
			,L_DISCHARGE 
			,L_OTHER_DISCHARGE  = L_OTHER_DISCHARGE COLLATE DATABASE_DEFAULT
			,L_SALT_ASSESSMENT 
			,L_SALT_ASSESSMENT_DATE 
			,L_INVESTIGATIONS  = L_INVESTIGATIONS COLLATE DATABASE_DEFAULT
			,L_COMPLICATIONS = L_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,L_PLAN = L_PLAN COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,StratifiedFollowupType 

	 FROM [CancerRegister_WSHT]..tblMAIN_ASSESSMENT

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT   CAST(2 AS tinyint) AS SrcSysID
			,ASSESSMENT_ID 
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,N14_1_ASSESSMENT_DATE 
			,N14_2_TUMOUR_STATUS 
			,N14_3_NODE_STATUS 
			,N14_4_METS_STATUS 
			,N14_5_MARKER_RESPONSE 
			,N14_6_WHO_STATUS 
			,N14_7_MORBIDITY_TYPE 
			,N14_8_MORBIDITY_CODE = N14_8_MORBIDITY_CODE COLLATE DATABASE_DEFAULT
			,N14_9_FOLLOW_UP 
			,N14_10_CHEMO_MORBIDITY
			,N14_11_RADIO_MORBIDITY
			,N14_12_COMB_MORBIDITY 
			,N_SK24_TUMOUR_STATUS 
			,N_L21_RECEIVED_PCI = N_L21_RECEIVED_PCI COLLATE DATABASE_DEFAULT
			,N_L30_PLAN = N_L30_PLAN COLLATE DATABASE_DEFAULT
			,N_L31_FAILURE =N_L31_FAILURE COLLATE DATABASE_DEFAULT
			,R_ORG_CODE = R_ORG_CODE COLLATE DATABASE_DEFAULT
			,R_ALIVE_DATE 
			,R_ABROAD_DATE
			,R_MODE_FOLLOWUP 
			,L_OTHER_MODE = L_OTHER_MODE COLLATE DATABASE_DEFAULT
			,R_RECURRENCE_BY
			,R_DATE_RECURRENCE 
			,R_POTENCY = R_POTENCY COLLATE DATABASE_DEFAULT
			,R_CONTINENCE = R_CONTINENCE COLLATE DATABASE_DEFAULT
			,R_INTERVENTION 
			,R_OTHER_INTERVENTION = R_OTHER_INTERVENTION COLLATE DATABASE_DEFAULT
			,R_COMPLICATIONS 
			,R_OTHER_COMPLICATIONS = R_OTHER_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,R_CURRENT_STATUS 
			,R_DATE_STATUS 
			,R_STATUS 
			,R_OTHER_TRACT = R_OTHER_TRACT COLLATE DATABASE_DEFAULT
			,R_SERUM 
			,R_FBC
			,R_LFT
			,R_CT 
			,R_USS
			,R_CXR
			,R_OTHER_TESTS = R_OTHER_TESTS COLLATE DATABASE_DEFAULT
			,R_PSA 
			,R_DATE_METATASECTOMY 
			,L_HEIGHT 
			,L_WEIGHT 
			,L_FOLLOWUP = L_FOLLOWUP COLLATE DATABASE_DEFAULT
			,L_REF_ONCOLOGIST 
			,L_WHOLE_IMAGED
			,L_COLO_REQUEST
			,L_BA_REQUEST 
			,L_ASYMPTOMATIC
			,L_SYMPTOMATIC 
			,L_DETAILS = L_DETAILS COLLATE DATABASE_DEFAULT
			,L_RECURRENCE
			,L_REC_SITE = L_REC_SITE COLLATE DATABASE_DEFAULT
			,L_REC_SITE_2 = L_REC_SITE_2  COLLATE DATABASE_DEFAULT
			,L_ERECTILE = L_ERECTILE COLLATE DATABASE_DEFAULT
			,L_BLADDER = L_BLADDER COLLATE DATABASE_DEFAULT
			,L_RESOLUTION_ERECTILE = L_RESOLUTION_ERECTILE COLLATE DATABASE_DEFAULT
			,L_RESOLUTION_BLADDER = L_RESOLUTION_BLADDER COLLATE DATABASE_DEFAULT
			,L_CT_REQUEST 
			,L_MRI_REQUEST
			,L_INCISIONAL_HERNIA 
			,L_STRICTURE
			,L_SCREENING
			,L_LOCATION 
			,L_REASON = L_REASON COLLATE DATABASE_DEFAULT
			,L_MAMMOGRAM 
			,L_OUTSIDE_FOLLOWUP 
			,L_OUTSIDE_DETAILS = L_OUTSIDE_DETAILS COLLATE DATABASE_DEFAULT
			,L_METS = L_METS COLLATE DATABASE_DEFAULT
			,L_PLANNED
			,L_LYMPHOEDEMA 
			,L_DIARY 
			,L_SEIZURES = L_SEIZURES COLLATE DATABASE_DEFAULT
			,L_OUTCOME
			,L_OTHER_OUTCOME = L_OTHER_OUTCOME COLLATE DATABASE_DEFAULT
			,L_RE_BX = L_RE_BX COLLATE DATABASE_DEFAULT
			,L_DISCHARGE 
			,L_OTHER_DISCHARGE  = L_OTHER_DISCHARGE COLLATE DATABASE_DEFAULT
			,L_SALT_ASSESSMENT 
			,L_SALT_ASSESSMENT_DATE 
			,L_INVESTIGATIONS  = L_INVESTIGATIONS COLLATE DATABASE_DEFAULT
			,L_COMPLICATIONS = L_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,L_PLAN = L_PLAN COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,StratifiedFollowupType 

	 FROM [CancerRegister_BSUH]..tblMAIN_ASSESSMENT
GO
