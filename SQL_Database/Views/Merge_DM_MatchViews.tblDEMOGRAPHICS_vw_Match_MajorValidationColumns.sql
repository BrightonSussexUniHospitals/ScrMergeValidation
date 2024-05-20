SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [Merge_DM_MatchViews].[tblDEMOGRAPHICS_vw_Match_MajorValidationColumns] AS

SELECT		*
FROM		(SELECT		SrcSys_Major
						,Src_UID_Major
						,FieldName
			FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns) mmvc
PIVOT		(COUNT(FieldName)
			FOR FieldName IN	(PATIENT_ID
								,N1_1_NHS_NUMBER
								,NHS_NUMBER_STATUS
								,L_RA3_RID
								,L_RA7_RID
								,L_RVJ01_RID
								,TEMP_ID
								,L_NSTS_STATUS
								,N1_2_HOSPITAL_NUMBER
								,L_TITLE
								,N1_5_SURNAME
								,N1_6_FORENAME
								,N1_7_ADDRESS_1
								,N1_7_ADDRESS_2
								,N1_7_ADDRESS_3
								,N1_7_ADDRESS_4
								,N1_7_ADDRESS_5
								,N1_8_POSTCODE
								,N1_9_SEX
								,N1_10_DATE_BIRTH
								,N1_11_GP_CODE
								,N1_12_GP_PRACTICE_CODE
								,N1_13_PCT
								,N1_14_SURNAME_BIRTH
								,N1_15_ETHNICITY
								,PAT_PREF_NAME
								,PAT_OCCUPATION
								,PAT_SOCIAL_CLASS
								,PAT_LIVES_ALONE
								,MARITAL_STATUS
								,PAT_PREF_LANGUAGE
								,PAT_PREF_CONTACT
								,L_DEATH_STATUS
								,N15_1_DATE_DEATH
								,N15_2_DEATH_LOCATION
								,N15_3_DEATH_CAUSE
								,N15_4_DEATH_CANCER
								,N15_5_DEATH_CODE_1
								,N15_6_DEATH_CODE_2
								,N15_7_DEATH_CODE_3
								,N15_8_DEATH_CODE_4
								,N15_9_DEATH_DISCREPANCY
								,N_CC4_TOWN
								,N_CC5_COUNTRY
								,N_CC6_M_SURNAME
								,N_CC7_M_CLASS
								,N_CC8_M_FORENAME
								,N_CC9_M_DOB
								,N_CC10_M_TOWN
								,N_CC11_M_COUNTRY
								,N_CC12_M_OCC
								,N_CC13_M_OCC_DIAG
								,N_CC6_F_SURNAME
								,N_CC7_F_CLASS
								,N_CC8_F_FORENAME
								,N_CC9_F_DOB
								,N_CC10_F_TOWN
								,N_CC11_F_COUNTRY
								,N_CC12_F_OCC
								,N_CC13_F_OCC_DIAG
								,N_CC14_MULTI_BIRTH
								,R_POST_MORTEM
								,R_DAY_PHONE
								,DAY_PHONE_EXT
								,R_EVE_PHONE
								,EVE_PHONE_EXT
								,R_DEATH_TREATMENT
								,R_PM_DETAILS
								,L_IATROGENIC_DEATH
								,L_INFECTION_DEATH
								,L_DEATH_COMMENTS
								,RELIGION
								,CONTACT_DETAILS
								,NOK_NAME
								,NOK_ADDRESS_1
								,NOK_ADDRESS_2
								,NOK_ADDRESS_3
								,NOK_ADDRESS_4
								,NOK_ADDRESS_5
								,NOK_POSTCODE
								,NOK_CONTACT
								,NOK_RELATIONSHIP
								,PAT_DEPENDANTS
								,CARER_NAME
								,CARER_ADDRESS_1
								,CARER_ADDRESS_2
								,CARER_ADDRESS_3
								,CARER_ADDRESS_4
								,CARER_ADDRESS_5
								,CARER_POSTCODE
								,CARER_CONTACT
								,CARER_RELATIONSHIP
								,CARER1_TYPE
								,CARER2_NAME
								,CARER2_ADDRESS_1
								,CARER2_ADDRESS_2
								,CARER2_ADDRESS_3
								,CARER2_ADDRESS_4
								,CARER2_ADDRESS_5
								,CARER2_POSTCODE
								,CARER2_CONTACT
								,CARER2_RELATIONSHIP
								,CARER2_TYPE
								,PT_AT_RISK
								,REASON_RISK
								,GESTATION
								,CAUSE_OF_DEATH_UROLOGY
								,AVOIDABLE_DEATH
								,AVOIDABLE_DETAILS
								,OTHER_DEATH_CAUSE_UROLOGY
								,ACTION_ID
								,STATED_GENDER_CODE
								,CAUSE_OF_DEATH_UROLOGY_FUP
								,DEATH_WITHIN_30_DAYS_OF_TREAT
								,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
								,DEATH_CAUSE_LATER_DATE
								,RegisteredPractice
								,RegisteredGP
								,PersonSexualOrientation
								)
			) AS PivotTable
GO
