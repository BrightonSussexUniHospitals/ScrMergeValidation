SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMAIN_CHEMOTHERAPY] AS

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
			,CHEMO_ID
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,PROG_NUMBER
			,REG_NUMBER
			,N9_1_SITE_CODE = N9_1_SITE_CODE COLLATE DATABASE_DEFAULT
			,N_SITE_CODE_DTT = N_SITE_CODE_DTT COLLATE DATABASE_DEFAULT
			,N9_2_CONSULTANT = N9_2_CONSULTANT COLLATE DATABASE_DEFAULT
			,N9_3_SPECIALTY = N9_3_SPECIALTY COLLATE DATABASE_DEFAULT
			,N9_4_DECISION_DATE
			,N9_7_THERAPY_TYPE = N9_7_THERAPY_TYPE COLLATE DATABASE_DEFAULT
			,N9_8_TREATMENT_INTENT
			,N9_9_DRUG_REGIMEN = N9_9_DRUG_REGIMEN COLLATE DATABASE_DEFAULT
			,N9_10_START_DATE
			,N9_16_CYCLE_NO = N9_16_CYCLE_NO COLLATE DATABASE_DEFAULT
			,N9_20_DOSAGE
			,N9_21_DURATION
			,N9_22_RESPONSE
			,N9_24_CHEMO_HRG = N9_24_CHEMO_HRG COLLATE DATABASE_DEFAULT
			,N_B7_ENDOCRINE_TYPE = N_B7_ENDOCRINE_TYPE COLLATE DATABASE_DEFAULT
			,N_L27_CHEMO_GIVEN = N_L27_CHEMO_GIVEN COLLATE DATABASE_DEFAULT
			,N_TREATMENT_EVENT = N_TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_SETTING = N_TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,N_CHEMORADIO
			,L_END_DATE
			,L_TRIAL
			,L_CYCLE_GIVEN = L_CYCLE_GIVEN COLLATE DATABASE_DEFAULT
			,DEPRECATED_20_02_L_NAMED_COMP = DEPRECATED_20_02_L_NAMED_COMP COLLATE DATABASE_DEFAULT
			,L_AROMATASE
			,L_AROMATASE_DETAILS = L_AROMATASE_DETAILS COLLATE DATABASE_DEFAULT
			,L_ROUTE = L_ROUTE COLLATE DATABASE_DEFAULT
			,DEFINITIVE_TREATMENT
			,CWT_PROFORMA
			,L_HEIGHT
			,L_WEIGHT
			,L_WHO_STATUS
			,L_CO_MORBIDITY
			,L_DOSE_REDUCTION
			,L_TIME_DELAY
			,L_STOPPED_EARLY
			,L_DATE_DEATH
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,CONSULTANT_AGE_SPECIALTY = CONSULTANT_AGE_SPECIALTY COLLATE DATABASE_DEFAULT
			,TRANS_ARTERIAL_CHEMOEMBO = TRANS_ARTERIAL_CHEMOEMBO COLLATE DATABASE_DEFAULT
			,ROOT_START_DATE_COMMENTS = ROOT_START_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_END_DATE_COMMENTS = ROOT_END_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,CHEMO_TIMING
			,DEPRECATED_20_02_DISCHARGE_DATE
			,DEPRECATED_20_02_DISCHARGE_DELAY_REASON
			,DEPRECATED_20_02_DISCHARGE_DESTINATION = DEPRECATED_20_02_DISCHARGE_DESTINATION COLLATE DATABASE_DEFAULT
			,DISCHARGE_SUMMARY_SENT
			,HANADrugRegimen
			,AcuteToxicity
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,PrimaryInductionFailureID
			,AdjunctiveTherapyID
			,OtherTreatmentIntent = OtherTreatmentIntent COLLATE DATABASE_DEFAULT
			,HCCEmbolisation
			,HCCEmbolisationModality
			,TreatmentCompletedAsPlanned
			,NotCompleteReasonID
			,PalExtendLifeExpectancy
			,PalRelieveControlSymptoms
			,PalAchieveRemission
			,PalDelayTumourProgression
			,OtherReasonNotCompleted = OtherReasonNotCompleted COLLATE DATABASE_DEFAULT
			,RegOutcomeToxicity
			,RegOutcomeNonCurative
			,TertiaryReferralKey
			,ROOT_PRIM_ADJUSTMENT_COMMENTS = ROOT_PRIM_ADJUSTMENT_COMMENTS  COLLATE DATABASE_DEFAULT
			,ROOT_SUBPRIM_ADJUSTMENT_COMMENTS = ROOT_SUBPRIM_ADJUSTMENT_COMMENTS COLLATE DATABASE_DEFAULT
	FROM  [CancerRegister_WSHT]..tblMAIN_CHEMOTHERAPY

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID
			,CHEMO_ID
			,CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,PROG_NUMBER
			,REG_NUMBER
			,N9_1_SITE_CODE = N9_1_SITE_CODE COLLATE DATABASE_DEFAULT
			,N_SITE_CODE_DTT = N_SITE_CODE_DTT COLLATE DATABASE_DEFAULT
			,N9_2_CONSULTANT = N9_2_CONSULTANT COLLATE DATABASE_DEFAULT
			,N9_3_SPECIALTY = N9_3_SPECIALTY COLLATE DATABASE_DEFAULT
			,N9_4_DECISION_DATE
			,N9_7_THERAPY_TYPE = N9_7_THERAPY_TYPE COLLATE DATABASE_DEFAULT
			,N9_8_TREATMENT_INTENT
			,N9_9_DRUG_REGIMEN = N9_9_DRUG_REGIMEN COLLATE DATABASE_DEFAULT
			,N9_10_START_DATE
			,N9_16_CYCLE_NO = N9_16_CYCLE_NO COLLATE DATABASE_DEFAULT
			,N9_20_DOSAGE
			,N9_21_DURATION
			,N9_22_RESPONSE
			,N9_24_CHEMO_HRG = N9_24_CHEMO_HRG COLLATE DATABASE_DEFAULT
			,N_B7_ENDOCRINE_TYPE = N_B7_ENDOCRINE_TYPE COLLATE DATABASE_DEFAULT
			,N_L27_CHEMO_GIVEN = N_L27_CHEMO_GIVEN COLLATE DATABASE_DEFAULT
			,N_TREATMENT_EVENT = N_TREATMENT_EVENT COLLATE DATABASE_DEFAULT
			,N_TREATMENT_SETTING = N_TREATMENT_SETTING COLLATE DATABASE_DEFAULT
			,N_CHEMORADIO
			,L_END_DATE
			,L_TRIAL
			,L_CYCLE_GIVEN = L_CYCLE_GIVEN COLLATE DATABASE_DEFAULT
			,DEPRECATED_20_02_L_NAMED_COMP = DEPRECATED_20_02_L_NAMED_COMP COLLATE DATABASE_DEFAULT
			,L_AROMATASE
			,L_AROMATASE_DETAILS = L_AROMATASE_DETAILS COLLATE DATABASE_DEFAULT
			,L_ROUTE = L_ROUTE COLLATE DATABASE_DEFAULT
			,DEFINITIVE_TREATMENT
			,CWT_PROFORMA
			,L_HEIGHT
			,L_WEIGHT
			,L_WHO_STATUS
			,L_CO_MORBIDITY
			,L_DOSE_REDUCTION
			,L_TIME_DELAY
			,L_STOPPED_EARLY
			,L_DATE_DEATH
			,L_COMMENTS = L_COMMENTS COLLATE DATABASE_DEFAULT
			,CONSULTANT_AGE_SPECIALTY = CONSULTANT_AGE_SPECIALTY COLLATE DATABASE_DEFAULT
			,TRANS_ARTERIAL_CHEMOEMBO = TRANS_ARTERIAL_CHEMOEMBO COLLATE DATABASE_DEFAULT
			,ROOT_START_DATE_COMMENTS = ROOT_START_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_END_DATE_COMMENTS = ROOT_END_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,ACTION_ID
			,CHEMO_TIMING
			,DEPRECATED_20_02_DISCHARGE_DATE
			,DEPRECATED_20_02_DISCHARGE_DELAY_REASON
			,DEPRECATED_20_02_DISCHARGE_DESTINATION = DEPRECATED_20_02_DISCHARGE_DESTINATION COLLATE DATABASE_DEFAULT
			,DISCHARGE_SUMMARY_SENT
			,HANADrugRegimen
			,AcuteToxicity
			,ROOT_DECISION_DATE_COMMENTS = ROOT_DECISION_DATE_COMMENTS COLLATE DATABASE_DEFAULT
			,PrimaryInductionFailureID
			,AdjunctiveTherapyID
			,OtherTreatmentIntent = OtherTreatmentIntent COLLATE DATABASE_DEFAULT
			,HCCEmbolisation
			,HCCEmbolisationModality
			,TreatmentCompletedAsPlanned
			,NotCompleteReasonID
			,PalExtendLifeExpectancy
			,PalRelieveControlSymptoms
			,PalAchieveRemission
			,PalDelayTumourProgression
			,OtherReasonNotCompleted = OtherReasonNotCompleted COLLATE DATABASE_DEFAULT
			,RegOutcomeToxicity
			,RegOutcomeNonCurative
			,TertiaryReferralKey
			,ROOT_PRIM_ADJUSTMENT_COMMENTS = ROOT_PRIM_ADJUSTMENT_COMMENTS  COLLATE DATABASE_DEFAULT
			,ROOT_SUBPRIM_ADJUSTMENT_COMMENTS = ROOT_SUBPRIM_ADJUSTMENT_COMMENTS COLLATE DATABASE_DEFAULT
	FROM  [CancerRegister_BSUH]..tblMAIN_CHEMOTHERAPY
GO
