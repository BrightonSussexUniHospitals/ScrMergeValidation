SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMAIN_IMAGING] AS

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
			,IMAGE_ID = IMAGE_ID
			,CARE_ID = CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,L_REQUEST_DATE = L_REQUEST_DATE
			,N3_1_SITE_CODE = N3_1_SITE_CODE COLLATE DATABASE_DEFAULT
			,N3_2_IMAGING_DATE = N3_2_IMAGING_DATE
			,L_REPORT_DATE = L_REPORT_DATE
			,N3_3_MODALITY = N3_3_MODALITY COLLATE DATABASE_DEFAULT
			,L_OTHER_IMAGING = L_OTHER_IMAGING COLLATE DATABASE_DEFAULT
			,L_MOD_TYPE = L_MOD_TYPE
			,N3_4_ANATOMICAL_SITE = N3_4_ANATOMICAL_SITE COLLATE DATABASE_DEFAULT
			,L_SITE_2 = L_SITE_2 COLLATE DATABASE_DEFAULT
			,L_SITE_3 = L_SITE_3 COLLATE DATABASE_DEFAULT
			,L_ANATOMICAL_SIDE_CODE = L_ANATOMICAL_SIDE_CODE COLLATE DATABASE_DEFAULT
			,L_LATERALITY = L_LATERALITY COLLATE DATABASE_DEFAULT
			,N3_5_LESION_SIZE = N3_5_LESION_SIZE
			,L_IM_RESULT = L_IM_RESULT COLLATE DATABASE_DEFAULT
			,L_T_STAGE = L_T_STAGE COLLATE DATABASE_DEFAULT
			,L_T_LETTER = L_T_LETTER COLLATE DATABASE_DEFAULT
			,L_N_STAGE = L_N_STAGE COLLATE DATABASE_DEFAULT
			,L_N_LETTER = L_N_LETTER COLLATE DATABASE_DEFAULT
			,L_M_STAGE = L_M_STAGE COLLATE DATABASE_DEFAULT
			,L_M_LETTER = L_M_LETTER COLLATE DATABASE_DEFAULT
			,N_C6_INCOMPLETE = N_C6_INCOMPLETE COLLATE DATABASE_DEFAULT
			,L_OTHER_INCOMPLETE = L_OTHER_INCOMPLETE COLLATE DATABASE_DEFAULT
			,R_COLONOSCOPY_COMP = R_COLONOSCOPY_COMP COLLATE DATABASE_DEFAULT
			,R_OTHER_COMPLICATIONS = R_OTHER_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,R_MRI_MARGINS = R_MRI_MARGINS COLLATE DATABASE_DEFAULT
			,L_CONTRAST = L_CONTRAST COLLATE DATABASE_DEFAULT
			,L_REQ_BY = L_REQ_BY
			,L_BOOKED = L_BOOKED
			,L_FBC = L_FBC
			,L_FBC_RESULT = L_FBC_RESULT COLLATE DATABASE_DEFAULT
			,L_UE = L_UE
			,L_UE_RESULT = L_UE_RESULT COLLATE DATABASE_DEFAULT
			,L_LFT = L_LFT
			,L_LFT_RESULT = L_LFT_RESULT COLLATE DATABASE_DEFAULT
			,L_CREAT = L_CREAT
			,L_CREAT_RESULT = L_CREAT_RESULT COLLATE DATABASE_DEFAULT
			,L_RENAL = L_RENAL
			,L_RENAL_RESULT = L_RENAL_RESULT COLLATE DATABASE_DEFAULT
			,L_VIR = L_VIR
			,L_VIR_RESULT = L_VIR_RESULT COLLATE DATABASE_DEFAULT
			,L_ECG = L_ECG
			,L_GROUP = L_GROUP
			,L_XMATCH = L_XMATCH
			,L_CLOTTING = L_CLOTTING
			,L_CA153 = L_CA153
			,L_CALCIUM = L_CALCIUM
			,L_CALCIUM_RESULT = L_CALCIUM_RESULT COLLATE DATABASE_DEFAULT
			,L_SODIUM = L_SODIUM
			,L_ALBUMIN = L_ALBUMIN
			,L_GLUCOSE = L_GLUCOSE
			,L_UNITS = L_UNITS
			,L_PFT = L_PFT
			,L_CRP = L_CRP
			,L_PHENYTOIN = L_PHENYTOIN
			,L_OTHER = L_OTHER
			,L_OTHER_LAB = L_OTHER_LAB COLLATE DATABASE_DEFAULT
			,L_FT4 = L_FT4
			,L_FT4_RESULTS = L_FT4_RESULTS COLLATE DATABASE_DEFAULT
			,L_TSH = L_TSH
			,L_TSH_RESULTS = L_TSH_RESULTS COLLATE DATABASE_DEFAULT
			,L_9AMCORTISOL = L_9AMCORTISOL
			,L_9AMCORTISOL_RESULTS = L_9AMCORTISOL_RESULTS COLLATE DATABASE_DEFAULT
			,L_UFC = L_UFC
			,L_UFC_RESULTS = L_UFC_RESULTS COLLATE DATABASE_DEFAULT
			,L_LH = L_LH
			,L_LH_RESULTS = L_LH_RESULTS COLLATE DATABASE_DEFAULT
			,L_FSH = L_FSH
			,L_FSH_RESULTS = L_FSH_RESULTS COLLATE DATABASE_DEFAULT
			,L_PROLACTIN = L_PROLACTIN
			,L_PROLACTIN_RESULTS = L_PROLACTIN_RESULTS COLLATE DATABASE_DEFAULT
			,L_GROWTH_HORMONE = L_GROWTH_HORMONE
			,L_GROWTH_HORMONE_RESULTS = L_GROWTH_HORMONE_RESULTS COLLATE DATABASE_DEFAULT
			,L_IGF_I = L_IGF_I
			,L_IGF_I_RESULTS = L_IGF_I_RESULTS COLLATE DATABASE_DEFAULT
			,L_TESTOSTERONE_LAB = L_TESTOSTERONE_LAB
			,L_TESTOSTERONE_LAB_RESULTS = L_TESTOSTERONE_LAB_RESULTS COLLATE DATABASE_DEFAULT
			,L_CALCITONIN = L_CALCITONIN
			,L_CALCITONIN_RESULT = L_CALCITONIN_RESULT COLLATE DATABASE_DEFAULT
			,L_THYROGLOBULIN = L_THYROGLOBULIN
			,L_THYROGLOBULIN_RESULT = L_THYROGLOBULIN_RESULT COLLATE DATABASE_DEFAULT
			,L_LAB_COMMENTS = L_LAB_COMMENTS COLLATE DATABASE_DEFAULT
			,L_DILATION = L_DILATION
			,R_CA125 = R_CA125
			,R_CA125_RESULT = R_CA125_RESULT COLLATE DATABASE_DEFAULT
			,R_AFP = R_AFP
			,R_AFP_RESULT = R_AFP_RESULT COLLATE DATABASE_DEFAULT
			,L_CEA = L_CEA
			,L_CEA_RESULT = L_CEA_RESULT COLLATE DATABASE_DEFAULT
			,L_CA199 = L_CA199
			,L_CA199_RESULT = L_CA199_RESULT COLLATE DATABASE_DEFAULT
			,L_5H1AA = L_5H1AA
			,L_5H1AA_RESULT = L_5H1AA_RESULT COLLATE DATABASE_DEFAULT
			,L_PSA = L_PSA
			,L_PSA_RESULT = L_PSA_RESULT COLLATE DATABASE_DEFAULT
			,L_HCG = L_HCG
			,L_HCG_RESULT = L_HCG_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH = L_LDH
			,L_LDH_RESULT = L_LDH_RESULT COLLATE DATABASE_DEFAULT
			,L_CRATECH = L_CRATECH
			,L_CRATECH_RESULT = L_CRATECH_RESULT COLLATE DATABASE_DEFAULT
			,L_OTHER_MARKER = L_OTHER_MARKER
			,L_OTHER_RESULT = L_OTHER_RESULT COLLATE DATABASE_DEFAULT
			,L_HB = L_HB
			,L_HB_RESULT = L_HB_RESULT COLLATE DATABASE_DEFAULT
			,L_TESTOSTERONE = L_TESTOSTERONE
			,L_TESTOSTERONE_RESULT = L_TESTOSTERONE_RESULT COLLATE DATABASE_DEFAULT
			,L_PSAD = L_PSAD
			,L_PSAD_RESULT = L_PSAD_RESULT COLLATE DATABASE_DEFAULT
			,R_BHCG = R_BHCG
			,R_LIVER_RESULTS = R_LIVER_RESULTS
			,R_SECOND_MRI = R_SECOND_MRI
			,R_ENVELOPE = R_ENVELOPE
			,R_SPICULES_ENVELOPE = R_SPICULES_ENVELOPE
			,R_MESO_ENVELOPE = R_MESO_ENVELOPE
			,L_BIOPSY = L_BIOPSY COLLATE DATABASE_DEFAULT
			,R_FIGO = R_FIGO COLLATE DATABASE_DEFAULT
			,R_FIGO2 = R_FIGO2 COLLATE DATABASE_DEFAULT
			,R_ASCITES = R_ASCITES COLLATE DATABASE_DEFAULT
			,R_REASON_CT = R_REASON_CT COLLATE DATABASE_DEFAULT
			,R_PROBLEM_SIZE = R_PROBLEM_SIZE COLLATE DATABASE_DEFAULT
			,L_APPROACH = L_APPROACH
			,L_SOURCE = L_SOURCE
			,N_L5_FEV1_AMOUNT = N_L5_FEV1_AMOUNT
			,N_L6_FEV1_PER = N_L6_FEV1_PER
			,L_FVC = L_FVC
			,L_FVC_PER = L_FVC_PER
			,L_DLCO = L_DLCO
			,L_DLCO_PER = L_DLCO_PER
			,L_KCO = L_KCO
			,L_KCO_PER = L_KCO_PER
			,L_PAO2 = L_PAO2
			,L_PAO2_PER = L_PAO2_PER
			,R_LVEF = R_LVEF
			,R_LVEF_PER = R_LVEF_PER
			,R_WBC = R_WBC
			,L_B2M = L_B2M
			,L_B2M_RESULT = L_B2M_RESULT COLLATE DATABASE_DEFAULT
			,L_IG = L_IG
			,L_IG_RESULT = L_IG_RESULT COLLATE DATABASE_DEFAULT
			,N_H2_MASS = N_H2_MASS
			,N_H4_BULK = N_H4_BULK
			,N_H5_SURVEY = N_H5_SURVEY
			,N_H6_EVIDENCE = N_H6_EVIDENCE
			,R_ALBUMIN = R_ALBUMIN
			,N_CC22_ANAE = N_CC22_ANAE COLLATE DATABASE_DEFAULT
			,L_MORPHOLOGY = L_MORPHOLOGY COLLATE DATABASE_DEFAULT
			,L_IMMUNOPHENOTYPE = L_IMMUNOPHENOTYPE COLLATE DATABASE_DEFAULT
			,L_CYTOGENETICS = L_CYTOGENETICS COLLATE DATABASE_DEFAULT
			,L_EXTRAMEDULLARY_DISEASE = L_EXTRAMEDULLARY_DISEASE COLLATE DATABASE_DEFAULT
			,L_CELL_COUNT = L_CELL_COUNT
			,L_GLUCOSE_RES = L_GLUCOSE_RES
			,L_PROTEIN_RES = L_PROTEIN_RES
			,L_BIOPSY_SCORE_1 = L_BIOPSY_SCORE_1
			,L_BIOPSY_SCORE_2 = L_BIOPSY_SCORE_2
			,L_PROSTATE_VOL = L_PROSTATE_VOL COLLATE DATABASE_DEFAULT
			,L_CORES = L_CORES
			,L_CORES_POS = L_CORES_POS
			,L_RESULTS = L_RESULTS COLLATE DATABASE_DEFAULT
			,L_IMAGING_REPORT_TEXT = L_IMAGING_REPORT_TEXT COLLATE DATABASE_DEFAULT
			,R_FIGO3 = R_FIGO3 COLLATE DATABASE_DEFAULT
			,HGD_APPEARANCE = HGD_APPEARANCE
			,HGD_LESION = HGD_LESION
			,HGD_COL_LIN_CIRC_LENGTH = HGD_COL_LIN_CIRC_LENGTH
			,HGD_COL_LIN_MAX_LENGTH = HGD_COL_LIN_MAX_LENGTH
			,HGD_BARRETTS_SEGMENT = HGD_BARRETTS_SEGMENT
			,UGI_STAGING_PROCEDURE = UGI_STAGING_PROCEDURE COLLATE DATABASE_DEFAULT
			,L_IMAGING_CODE = L_IMAGING_CODE COLLATE DATABASE_DEFAULT
			,FBC_PLATELET_COUNT = FBC_PLATELET_COUNT
			,FBC_WBC_COUNT = FBC_WBC_COUNT
			,FBC_HB_CONCENTRATION = FBC_HB_CONCENTRATION
			,BM_BLASTS = BM_BLASTS
			,FBC_NEUTROPHIL_COUNT = FBC_NEUTROPHIL_COUNT
			,ALBUMIN_LEVEL = ALBUMIN_LEVEL
			,ALBUMIN_COMMENTS = ALBUMIN_COMMENTS COLLATE DATABASE_DEFAULT
			,BETA2_MICROGLOBULIN_LEVEL = BETA2_MICROGLOBULIN_LEVEL
			,FBC_LYMPHOCYTE_COUNT = FBC_LYMPHOCYTE_COUNT
			,FBC_BLOOD_MYELOBLASTS = FBC_BLOOD_MYELOBLASTS
			,FBC_BLOOD_BASOPHILS = FBC_BLOOD_BASOPHILS
			,FBC_BLOOD_EOSINOPHILS = FBC_BLOOD_EOSINOPHILS
			,ALBUMIN_CB = ALBUMIN_CB
			,L_PROTEIN = L_PROTEIN
			,L_PROTEIN_RESULTS = L_PROTEIN_RESULTS COLLATE DATABASE_DEFAULT
			,L_BENCE = L_BENCE
			,L_BENCE_RESULTS = L_BENCE_RESULTS COLLATE DATABASE_DEFAULT
			,L_SERUM = L_SERUM
			,L_SERUM_RESULTS = L_SERUM_RESULTS COLLATE DATABASE_DEFAULT
			,ROOT_REQUEST_COMMENTS = ROOT_REQUEST_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_PERFORMED_COMMENTS = ROOT_PERFORMED_COMMENTS COLLATE DATABASE_DEFAULT
			,R_FIGO4 = R_FIGO4 COLLATE DATABASE_DEFAULT
			,R_FIGO_STAGINGTYPE = R_FIGO_STAGINGTYPE COLLATE DATABASE_DEFAULT
			,SNOMED_CT = SNOMED_CT COLLATE DATABASE_DEFAULT
			,ACTION_ID = ACTION_ID
			,PORTAL_INVASION_SELECTED = PORTAL_INVASION_SELECTED
			,QUADRANTIC_BIOPSIES = QUADRANTIC_BIOPSIES
			,ADDITIONAL_BIOPSIES = ADDITIONAL_BIOPSIES
			,L_MYELOMA = L_MYELOMA
			,L_CEA_TM = L_CEA_TM
			,L_LFT_TM = L_LFT_TM
			,L_LFT_MLT = L_LFT_MLT
			,ROOT_REPORTED_COMMENTS = ROOT_REPORTED_COMMENTS COLLATE DATABASE_DEFAULT
			,RadiologistID = RadiologistID
			,MOD_ID = MOD_ID
			,OtherDescription = OtherDescription COLLATE DATABASE_DEFAULT
			,REASON_NOT_PERFORMED_ID = REASON_NOT_PERFORMED_ID
			,REASON_NOT_PERFORMED_OTHER = REASON_NOT_PERFORMED_OTHER COLLATE DATABASE_DEFAULT
			,LDH_MLT = LDH_MLT
			,LDH_MLT_RESULT = LDH_MLT_RESULT COLLATE DATABASE_DEFAULT
			,R_BHCG_RESULT = R_BHCG_RESULT COLLATE DATABASE_DEFAULT
			,L_CA153_RESULT = L_CA153_RESULT COLLATE DATABASE_DEFAULT
			,L_CLOTTING_RESULT = L_CLOTTING_RESULT COLLATE DATABASE_DEFAULT
			,L_CRP_RESULT = L_CRP_RESULT COLLATE DATABASE_DEFAULT
			,L_ECG_RESULT = L_ECG_RESULT COLLATE DATABASE_DEFAULT
			,L_GROUP_RESULT = L_GROUP_RESULT COLLATE DATABASE_DEFAULT
			,L_MYELOMA_RESULT = L_MYELOMA_RESULT COLLATE DATABASE_DEFAULT
			,L_PFT_RESULT = L_PFT_RESULT COLLATE DATABASE_DEFAULT
			,L_PHENYTOIN_RESULT = L_PHENYTOIN_RESULT COLLATE DATABASE_DEFAULT
			,L_SODIUM_RESULT = L_SODIUM_RESULT COLLATE DATABASE_DEFAULT
			,L_XMATCH_RESULT = L_XMATCH_RESULT COLLATE DATABASE_DEFAULT
			,L_CEA_TM_RESULT = L_CEA_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LFT_TM_RESULT = L_LFT_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH_TM_RESULT = L_LDH_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH_TM = L_LDH_TM
			,L_RANDOM_GLUCOSE = L_RANDOM_GLUCOSE COLLATE DATABASE_DEFAULT
			,LEFT_VENT_EFR = LEFT_VENT_EFR
			,CPET_TYPE = CPET_TYPE
			,CPET_RESULT = CPET_RESULT
			,PortalVeinInvasionID = PortalVeinInvasionID
			,TertiaryReferralKey = TertiaryReferralKey
			,PSALessThan01 = PSALessThan01
			,TransrectalBiopsyTechnique = TransrectalBiopsyTechnique
			,TransperinealBiopsyTechnique = TransperinealBiopsyTechnique
			,BiopsyAnaesthetic = BiopsyAnaesthetic
			,L_ALPTEST = L_ALPTEST
			,L_ALP_TEST_RESULT = L_ALP_TEST_RESULT COLLATE DATABASE_DEFAULT
			,PiradsCategoryId
			,LikertScoreId
	FROM	[CancerRegister_WSHT]..tblMAIN_IMAGING

		UNION ALL 

	-- Select a replica dataset from a V22.2 table
	SELECT  CAST(2 AS tinyint) AS SrcSysID
			,IMAGE_ID = IMAGE_ID
			,CARE_ID = CARE_ID
			,TEMP_ID = TEMP_ID COLLATE DATABASE_DEFAULT
			,L_REQUEST_DATE = L_REQUEST_DATE
			,N3_1_SITE_CODE = N3_1_SITE_CODE COLLATE DATABASE_DEFAULT
			,N3_2_IMAGING_DATE = N3_2_IMAGING_DATE
			,L_REPORT_DATE = L_REPORT_DATE
			,N3_3_MODALITY = N3_3_MODALITY COLLATE DATABASE_DEFAULT
			,L_OTHER_IMAGING = L_OTHER_IMAGING COLLATE DATABASE_DEFAULT
			,L_MOD_TYPE = L_MOD_TYPE
			,N3_4_ANATOMICAL_SITE = N3_4_ANATOMICAL_SITE COLLATE DATABASE_DEFAULT
			,L_SITE_2 = L_SITE_2 COLLATE DATABASE_DEFAULT
			,L_SITE_3 = L_SITE_3 COLLATE DATABASE_DEFAULT
			,L_ANATOMICAL_SIDE_CODE = L_ANATOMICAL_SIDE_CODE COLLATE DATABASE_DEFAULT
			,L_LATERALITY = L_LATERALITY COLLATE DATABASE_DEFAULT
			,N3_5_LESION_SIZE = N3_5_LESION_SIZE
			,L_IM_RESULT = L_IM_RESULT COLLATE DATABASE_DEFAULT
			,L_T_STAGE = L_T_STAGE COLLATE DATABASE_DEFAULT
			,L_T_LETTER = L_T_LETTER COLLATE DATABASE_DEFAULT
			,L_N_STAGE = L_N_STAGE COLLATE DATABASE_DEFAULT
			,L_N_LETTER = L_N_LETTER COLLATE DATABASE_DEFAULT
			,L_M_STAGE = L_M_STAGE COLLATE DATABASE_DEFAULT
			,L_M_LETTER = L_M_LETTER COLLATE DATABASE_DEFAULT
			,N_C6_INCOMPLETE = N_C6_INCOMPLETE COLLATE DATABASE_DEFAULT
			,L_OTHER_INCOMPLETE = L_OTHER_INCOMPLETE COLLATE DATABASE_DEFAULT
			,R_COLONOSCOPY_COMP = R_COLONOSCOPY_COMP COLLATE DATABASE_DEFAULT
			,R_OTHER_COMPLICATIONS = R_OTHER_COMPLICATIONS COLLATE DATABASE_DEFAULT
			,R_MRI_MARGINS = R_MRI_MARGINS COLLATE DATABASE_DEFAULT
			,L_CONTRAST = L_CONTRAST COLLATE DATABASE_DEFAULT
			,L_REQ_BY = L_REQ_BY
			,L_BOOKED = L_BOOKED
			,L_FBC = L_FBC
			,L_FBC_RESULT = L_FBC_RESULT COLLATE DATABASE_DEFAULT
			,L_UE = L_UE
			,L_UE_RESULT = L_UE_RESULT COLLATE DATABASE_DEFAULT
			,L_LFT = L_LFT
			,L_LFT_RESULT = L_LFT_RESULT COLLATE DATABASE_DEFAULT
			,L_CREAT = L_CREAT
			,L_CREAT_RESULT = L_CREAT_RESULT COLLATE DATABASE_DEFAULT
			,L_RENAL = L_RENAL
			,L_RENAL_RESULT = L_RENAL_RESULT COLLATE DATABASE_DEFAULT
			,L_VIR = L_VIR
			,L_VIR_RESULT = L_VIR_RESULT COLLATE DATABASE_DEFAULT
			,L_ECG = L_ECG
			,L_GROUP = L_GROUP
			,L_XMATCH = L_XMATCH
			,L_CLOTTING = L_CLOTTING
			,L_CA153 = L_CA153
			,L_CALCIUM = L_CALCIUM
			,L_CALCIUM_RESULT = L_CALCIUM_RESULT COLLATE DATABASE_DEFAULT
			,L_SODIUM = L_SODIUM
			,L_ALBUMIN = L_ALBUMIN
			,L_GLUCOSE = L_GLUCOSE
			,L_UNITS = L_UNITS
			,L_PFT = L_PFT
			,L_CRP = L_CRP
			,L_PHENYTOIN = L_PHENYTOIN
			,L_OTHER = L_OTHER
			,L_OTHER_LAB = L_OTHER_LAB COLLATE DATABASE_DEFAULT
			,L_FT4 = L_FT4
			,L_FT4_RESULTS = L_FT4_RESULTS COLLATE DATABASE_DEFAULT
			,L_TSH = L_TSH
			,L_TSH_RESULTS = L_TSH_RESULTS COLLATE DATABASE_DEFAULT
			,L_9AMCORTISOL = L_9AMCORTISOL
			,L_9AMCORTISOL_RESULTS = L_9AMCORTISOL_RESULTS COLLATE DATABASE_DEFAULT
			,L_UFC = L_UFC
			,L_UFC_RESULTS = L_UFC_RESULTS COLLATE DATABASE_DEFAULT
			,L_LH = L_LH
			,L_LH_RESULTS = L_LH_RESULTS COLLATE DATABASE_DEFAULT
			,L_FSH = L_FSH
			,L_FSH_RESULTS = L_FSH_RESULTS COLLATE DATABASE_DEFAULT
			,L_PROLACTIN = L_PROLACTIN
			,L_PROLACTIN_RESULTS = L_PROLACTIN_RESULTS COLLATE DATABASE_DEFAULT
			,L_GROWTH_HORMONE = L_GROWTH_HORMONE
			,L_GROWTH_HORMONE_RESULTS = L_GROWTH_HORMONE_RESULTS COLLATE DATABASE_DEFAULT
			,L_IGF_I = L_IGF_I
			,L_IGF_I_RESULTS = L_IGF_I_RESULTS COLLATE DATABASE_DEFAULT
			,L_TESTOSTERONE_LAB = L_TESTOSTERONE_LAB
			,L_TESTOSTERONE_LAB_RESULTS = L_TESTOSTERONE_LAB_RESULTS COLLATE DATABASE_DEFAULT
			,L_CALCITONIN = L_CALCITONIN
			,L_CALCITONIN_RESULT = L_CALCITONIN_RESULT COLLATE DATABASE_DEFAULT
			,L_THYROGLOBULIN = L_THYROGLOBULIN
			,L_THYROGLOBULIN_RESULT = L_THYROGLOBULIN_RESULT COLLATE DATABASE_DEFAULT
			,L_LAB_COMMENTS = L_LAB_COMMENTS COLLATE DATABASE_DEFAULT
			,L_DILATION = L_DILATION
			,R_CA125 = R_CA125
			,R_CA125_RESULT = R_CA125_RESULT COLLATE DATABASE_DEFAULT
			,R_AFP = R_AFP
			,R_AFP_RESULT = R_AFP_RESULT COLLATE DATABASE_DEFAULT
			,L_CEA = L_CEA
			,L_CEA_RESULT = L_CEA_RESULT COLLATE DATABASE_DEFAULT
			,L_CA199 = L_CA199
			,L_CA199_RESULT = L_CA199_RESULT COLLATE DATABASE_DEFAULT
			,L_5H1AA = L_5H1AA
			,L_5H1AA_RESULT = L_5H1AA_RESULT COLLATE DATABASE_DEFAULT
			,L_PSA = L_PSA
			,L_PSA_RESULT = L_PSA_RESULT COLLATE DATABASE_DEFAULT
			,L_HCG = L_HCG
			,L_HCG_RESULT = L_HCG_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH = L_LDH
			,L_LDH_RESULT = L_LDH_RESULT COLLATE DATABASE_DEFAULT
			,L_CRATECH = L_CRATECH
			,L_CRATECH_RESULT = L_CRATECH_RESULT COLLATE DATABASE_DEFAULT
			,L_OTHER_MARKER = L_OTHER_MARKER
			,L_OTHER_RESULT = L_OTHER_RESULT COLLATE DATABASE_DEFAULT
			,L_HB = L_HB
			,L_HB_RESULT = L_HB_RESULT COLLATE DATABASE_DEFAULT
			,L_TESTOSTERONE = L_TESTOSTERONE
			,L_TESTOSTERONE_RESULT = L_TESTOSTERONE_RESULT COLLATE DATABASE_DEFAULT
			,L_PSAD = L_PSAD
			,L_PSAD_RESULT = L_PSAD_RESULT COLLATE DATABASE_DEFAULT
			,R_BHCG = R_BHCG
			,R_LIVER_RESULTS = R_LIVER_RESULTS
			,R_SECOND_MRI = R_SECOND_MRI
			,R_ENVELOPE = R_ENVELOPE
			,R_SPICULES_ENVELOPE = R_SPICULES_ENVELOPE
			,R_MESO_ENVELOPE = R_MESO_ENVELOPE
			,L_BIOPSY = L_BIOPSY COLLATE DATABASE_DEFAULT
			,R_FIGO = R_FIGO COLLATE DATABASE_DEFAULT
			,R_FIGO2 = R_FIGO2 COLLATE DATABASE_DEFAULT
			,R_ASCITES = R_ASCITES COLLATE DATABASE_DEFAULT
			,R_REASON_CT = R_REASON_CT COLLATE DATABASE_DEFAULT
			,R_PROBLEM_SIZE = R_PROBLEM_SIZE COLLATE DATABASE_DEFAULT
			,L_APPROACH = L_APPROACH
			,L_SOURCE = L_SOURCE
			,N_L5_FEV1_AMOUNT = N_L5_FEV1_AMOUNT
			,N_L6_FEV1_PER = N_L6_FEV1_PER
			,L_FVC = L_FVC
			,L_FVC_PER = L_FVC_PER
			,L_DLCO = L_DLCO
			,L_DLCO_PER = L_DLCO_PER
			,L_KCO = L_KCO
			,L_KCO_PER = L_KCO_PER
			,L_PAO2 = L_PAO2
			,L_PAO2_PER = L_PAO2_PER
			,R_LVEF = R_LVEF
			,R_LVEF_PER = R_LVEF_PER
			,R_WBC = R_WBC
			,L_B2M = L_B2M
			,L_B2M_RESULT = L_B2M_RESULT COLLATE DATABASE_DEFAULT
			,L_IG = L_IG
			,L_IG_RESULT = L_IG_RESULT COLLATE DATABASE_DEFAULT
			,N_H2_MASS = N_H2_MASS
			,N_H4_BULK = N_H4_BULK
			,N_H5_SURVEY = N_H5_SURVEY
			,N_H6_EVIDENCE = N_H6_EVIDENCE
			,R_ALBUMIN = R_ALBUMIN
			,N_CC22_ANAE = N_CC22_ANAE COLLATE DATABASE_DEFAULT
			,L_MORPHOLOGY = L_MORPHOLOGY COLLATE DATABASE_DEFAULT
			,L_IMMUNOPHENOTYPE = L_IMMUNOPHENOTYPE COLLATE DATABASE_DEFAULT
			,L_CYTOGENETICS = L_CYTOGENETICS COLLATE DATABASE_DEFAULT
			,L_EXTRAMEDULLARY_DISEASE = L_EXTRAMEDULLARY_DISEASE COLLATE DATABASE_DEFAULT
			,L_CELL_COUNT = L_CELL_COUNT
			,L_GLUCOSE_RES = L_GLUCOSE_RES
			,L_PROTEIN_RES = L_PROTEIN_RES
			,L_BIOPSY_SCORE_1 = L_BIOPSY_SCORE_1
			,L_BIOPSY_SCORE_2 = L_BIOPSY_SCORE_2
			,L_PROSTATE_VOL = L_PROSTATE_VOL COLLATE DATABASE_DEFAULT
			,L_CORES = L_CORES
			,L_CORES_POS = L_CORES_POS
			,L_RESULTS = L_RESULTS COLLATE DATABASE_DEFAULT
			,L_IMAGING_REPORT_TEXT = L_IMAGING_REPORT_TEXT COLLATE DATABASE_DEFAULT
			,R_FIGO3 = R_FIGO3 COLLATE DATABASE_DEFAULT
			,HGD_APPEARANCE = HGD_APPEARANCE
			,HGD_LESION = HGD_LESION
			,HGD_COL_LIN_CIRC_LENGTH = HGD_COL_LIN_CIRC_LENGTH
			,HGD_COL_LIN_MAX_LENGTH = HGD_COL_LIN_MAX_LENGTH
			,HGD_BARRETTS_SEGMENT = HGD_BARRETTS_SEGMENT
			,UGI_STAGING_PROCEDURE = UGI_STAGING_PROCEDURE COLLATE DATABASE_DEFAULT
			,L_IMAGING_CODE = L_IMAGING_CODE COLLATE DATABASE_DEFAULT
			,FBC_PLATELET_COUNT = FBC_PLATELET_COUNT
			,FBC_WBC_COUNT = FBC_WBC_COUNT
			,FBC_HB_CONCENTRATION = FBC_HB_CONCENTRATION
			,BM_BLASTS = BM_BLASTS
			,FBC_NEUTROPHIL_COUNT = FBC_NEUTROPHIL_COUNT
			,ALBUMIN_LEVEL = ALBUMIN_LEVEL
			,ALBUMIN_COMMENTS = ALBUMIN_COMMENTS COLLATE DATABASE_DEFAULT
			,BETA2_MICROGLOBULIN_LEVEL = BETA2_MICROGLOBULIN_LEVEL
			,FBC_LYMPHOCYTE_COUNT = FBC_LYMPHOCYTE_COUNT
			,FBC_BLOOD_MYELOBLASTS = FBC_BLOOD_MYELOBLASTS
			,FBC_BLOOD_BASOPHILS = FBC_BLOOD_BASOPHILS
			,FBC_BLOOD_EOSINOPHILS = FBC_BLOOD_EOSINOPHILS
			,ALBUMIN_CB = ALBUMIN_CB
			,L_PROTEIN = L_PROTEIN
			,L_PROTEIN_RESULTS = L_PROTEIN_RESULTS COLLATE DATABASE_DEFAULT
			,L_BENCE = L_BENCE
			,L_BENCE_RESULTS = L_BENCE_RESULTS COLLATE DATABASE_DEFAULT
			,L_SERUM = L_SERUM
			,L_SERUM_RESULTS = L_SERUM_RESULTS COLLATE DATABASE_DEFAULT
			,ROOT_REQUEST_COMMENTS = ROOT_REQUEST_COMMENTS COLLATE DATABASE_DEFAULT
			,ROOT_PERFORMED_COMMENTS = ROOT_PERFORMED_COMMENTS COLLATE DATABASE_DEFAULT
			,R_FIGO4 = R_FIGO4 COLLATE DATABASE_DEFAULT
			,R_FIGO_STAGINGTYPE = R_FIGO_STAGINGTYPE COLLATE DATABASE_DEFAULT
			,SNOMED_CT = SNOMED_CT COLLATE DATABASE_DEFAULT
			,ACTION_ID = ACTION_ID
			,PORTAL_INVASION_SELECTED = PORTAL_INVASION_SELECTED
			,QUADRANTIC_BIOPSIES = QUADRANTIC_BIOPSIES
			,ADDITIONAL_BIOPSIES = ADDITIONAL_BIOPSIES
			,L_MYELOMA = L_MYELOMA
			,L_CEA_TM = L_CEA_TM
			,L_LFT_TM = L_LFT_TM
			,L_LFT_MLT = L_LFT_MLT
			,ROOT_REPORTED_COMMENTS = ROOT_REPORTED_COMMENTS COLLATE DATABASE_DEFAULT
			,RadiologistID = RadiologistID
			,MOD_ID = MOD_ID
			,OtherDescription = OtherDescription COLLATE DATABASE_DEFAULT
			,REASON_NOT_PERFORMED_ID = REASON_NOT_PERFORMED_ID
			,REASON_NOT_PERFORMED_OTHER = REASON_NOT_PERFORMED_OTHER COLLATE DATABASE_DEFAULT
			,LDH_MLT = LDH_MLT
			,LDH_MLT_RESULT = LDH_MLT_RESULT COLLATE DATABASE_DEFAULT
			,R_BHCG_RESULT = R_BHCG_RESULT COLLATE DATABASE_DEFAULT
			,L_CA153_RESULT = L_CA153_RESULT COLLATE DATABASE_DEFAULT
			,L_CLOTTING_RESULT = L_CLOTTING_RESULT COLLATE DATABASE_DEFAULT
			,L_CRP_RESULT = L_CRP_RESULT COLLATE DATABASE_DEFAULT
			,L_ECG_RESULT = L_ECG_RESULT COLLATE DATABASE_DEFAULT
			,L_GROUP_RESULT = L_GROUP_RESULT COLLATE DATABASE_DEFAULT
			,L_MYELOMA_RESULT = L_MYELOMA_RESULT COLLATE DATABASE_DEFAULT
			,L_PFT_RESULT = L_PFT_RESULT COLLATE DATABASE_DEFAULT
			,L_PHENYTOIN_RESULT = L_PHENYTOIN_RESULT COLLATE DATABASE_DEFAULT
			,L_SODIUM_RESULT = L_SODIUM_RESULT COLLATE DATABASE_DEFAULT
			,L_XMATCH_RESULT = L_XMATCH_RESULT COLLATE DATABASE_DEFAULT
			,L_CEA_TM_RESULT = L_CEA_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LFT_TM_RESULT = L_LFT_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH_TM_RESULT = L_LDH_TM_RESULT COLLATE DATABASE_DEFAULT
			,L_LDH_TM = L_LDH_TM
			,L_RANDOM_GLUCOSE = L_RANDOM_GLUCOSE COLLATE DATABASE_DEFAULT
			,LEFT_VENT_EFR = LEFT_VENT_EFR
			,CPET_TYPE = CPET_TYPE
			,CPET_RESULT = CPET_RESULT
			,PortalVeinInvasionID = PortalVeinInvasionID
			,TertiaryReferralKey = TertiaryReferralKey
			,PSALessThan01 = PSALessThan01
			,TransrectalBiopsyTechnique = TransrectalBiopsyTechnique
			,TransperinealBiopsyTechnique = TransperinealBiopsyTechnique
			,BiopsyAnaesthetic = BiopsyAnaesthetic
			,L_ALPTEST = L_ALPTEST
			,L_ALP_TEST_RESULT = L_ALP_TEST_RESULT COLLATE DATABASE_DEFAULT
			,PiradsCategoryId
			,LikertScoreId
	FROM	[CancerRegister_BSUH]..tblMAIN_IMAGING
GO
