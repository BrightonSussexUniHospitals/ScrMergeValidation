SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE VIEW	[Merge_DM_MatchViews].[tblDEMOGRAPHICS_vw_H_SCR] AS

		SELECT		IsSCR									= CAST(1 AS BIT)
					,IsMostRecent							= CAST(1 AS BIT)
					,SrcSys									= dem.SrcSysID
					,Src_UID								= CAST(dem.PATIENT_ID AS VARCHAR(255))
					,OriginalNhsNo							= LTRIM(RTRIM(REPLACE(CASE WHEN LEFT(dem.N1_1_NHS_NUMBER, 3) != '100' THEN dem.N1_1_NHS_NUMBER END, ' ', '')))
					,NhsNumber								= LTRIM(RTRIM(REPLACE(CASE WHEN LEFT(dem.N1_1_NHS_NUMBER, 3) != '100' THEN dem.N1_1_NHS_NUMBER END, ' ', '')))
					,OriginalPasId							= LTRIM(RTRIM(dem.N1_2_HOSPITAL_NUMBER))
					,PasId									= LTRIM(RTRIM(dem.N1_2_HOSPITAL_NUMBER))
					,CasenoteId								= LTRIM(RTRIM(dem.N1_2_HOSPITAL_NUMBER))
					,DoB									= dem.N1_10_DATE_BIRTH
					,DoD									= dem.N15_1_DATE_DEATH
					,Surname								= dem.N1_5_SURNAME
					,Forename								= dem.N1_6_FORENAME
					,Postcode								= REPLACE(dem.N1_8_POSTCODE, ' ', '')
					,Sex									= dem.N1_9_SEX
					,Address1								= dbo.fnOrderedNonEmptyStrings(1, dem.N1_7_ADDRESS_1, dem.N1_7_ADDRESS_2, dem.N1_7_ADDRESS_3, dem.N1_7_ADDRESS_4, dem.N1_7_ADDRESS_5)
					,Address2								= dbo.fnOrderedNonEmptyStrings(2, dem.N1_7_ADDRESS_1, dem.N1_7_ADDRESS_2, dem.N1_7_ADDRESS_3, dem.N1_7_ADDRESS_4, dem.N1_7_ADDRESS_5)
					,Address3								= dbo.fnOrderedNonEmptyStrings(3, dem.N1_7_ADDRESS_1, dem.N1_7_ADDRESS_2, dem.N1_7_ADDRESS_3, dem.N1_7_ADDRESS_4, dem.N1_7_ADDRESS_5)
					,Address4								= dbo.fnOrderedNonEmptyStrings(4, dem.N1_7_ADDRESS_1, dem.N1_7_ADDRESS_2, dem.N1_7_ADDRESS_3, dem.N1_7_ADDRESS_4, dem.N1_7_ADDRESS_5)
					,Address5								= dem.N1_7_ADDRESS_5
					,DeathStatus							= dem.L_DEATH_STATUS
					,Title									= ttl.TITLE_DESC
					,Ethnicity								= dbo.fnEmptyStringAsNull(LEFT(dem.N1_15_ETHNICITY,1))
					,ReligionCode							= ISNULL(map_relig.TargetCode, relig.RELIGION_CODE)
					,LastUpdated							= aud.ACTION_DATE
					,UpdateByPas							= CASE WHEN aud.USER_ID IN ('eReferralUser','Mirth_Batch','TIEUSER') THEN 1 ELSE 0 END
					,HashBytesValue							= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																								,CAST(dem.PATIENT_ID AS VARCHAR(255))
																								,dem.N1_1_NHS_NUMBER
																								,dem.N1_2_HOSPITAL_NUMBER
																								,CONVERT(VARCHAR(255), dem.N1_10_DATE_BIRTH, 126)
																								,CONVERT(VARCHAR(255), dem.N15_1_DATE_DEATH, 126)
																								,dem.N1_5_SURNAME
																								,dem.N1_6_FORENAME
																								,dem.N1_8_POSTCODE
																								,dem.N1_9_SEX
																								,dem.N1_7_ADDRESS_1
																								,dem.N1_7_ADDRESS_2
																								,dem.N1_7_ADDRESS_3
																								,dem.N1_7_ADDRESS_4
																								,dem.N1_7_ADDRESS_5
																								,dem.L_DEATH_STATUS
																								,ttl.TITLE_DESC
																								,dem.N1_15_ETHNICITY
																								,ISNULL(map_relig.TargetCode, relig.RELIGION_CODE)
																								))
					,PATIENT_ID								= dem.PATIENT_ID
					,N1_1_NHS_NUMBER						= dem.N1_1_NHS_NUMBER
					,NHS_NUMBER_STATUS						= dem.NHS_NUMBER_STATUS
					,L_RA3_RID								= dem.L_RA3_RID
					,L_RA7_RID								= dem.L_RA7_RID
					,L_RVJ01_RID							= dem.L_RVJ01_RID
					,TEMP_ID								= dem.TEMP_ID
					,L_NSTS_STATUS							= dem.L_NSTS_STATUS
					,N1_2_HOSPITAL_NUMBER					= dem.N1_2_HOSPITAL_NUMBER
					,L_TITLE								= dem.L_TITLE
					,N1_5_SURNAME							= dem.N1_5_SURNAME
					,N1_6_FORENAME							= dem.N1_6_FORENAME
					,N1_7_ADDRESS_1							= dem.N1_7_ADDRESS_1
					,N1_7_ADDRESS_2							= dem.N1_7_ADDRESS_2
					,N1_7_ADDRESS_3							= dem.N1_7_ADDRESS_3
					,N1_7_ADDRESS_4							= dem.N1_7_ADDRESS_4
					,N1_7_ADDRESS_5							= dem.N1_7_ADDRESS_5
					,N1_8_POSTCODE							= dem.N1_8_POSTCODE
					,N1_9_SEX								= dem.N1_9_SEX
					,N1_10_DATE_BIRTH						= dem.N1_10_DATE_BIRTH
					,N1_11_GP_CODE							= dem.N1_11_GP_CODE
					,N1_12_GP_PRACTICE_CODE					= dem.N1_12_GP_PRACTICE_CODE
					,N1_13_PCT								= dem.N1_13_PCT
					,N1_14_SURNAME_BIRTH					= dem.N1_14_SURNAME_BIRTH
					,N1_15_ETHNICITY						= dem.N1_15_ETHNICITY
					,PAT_PREF_NAME							= dem.PAT_PREF_NAME
					,PAT_OCCUPATION							= dem.PAT_OCCUPATION
					,PAT_SOCIAL_CLASS						= dem.PAT_SOCIAL_CLASS
					,PAT_LIVES_ALONE						= dem.PAT_LIVES_ALONE
					,MARITAL_STATUS							= dem.MARITAL_STATUS
					,PAT_PREF_LANGUAGE						= dem.PAT_PREF_LANGUAGE
					,PAT_PREF_CONTACT						= dem.PAT_PREF_CONTACT
					,L_DEATH_STATUS							= dem.L_DEATH_STATUS
					,N15_1_DATE_DEATH						= dem.N15_1_DATE_DEATH
					,N15_2_DEATH_LOCATION					= dem.N15_2_DEATH_LOCATION
					,N15_3_DEATH_CAUSE						= dem.N15_3_DEATH_CAUSE
					,N15_4_DEATH_CANCER						= dem.N15_4_DEATH_CANCER
					,N15_5_DEATH_CODE_1						= dem.N15_5_DEATH_CODE_1
					,N15_6_DEATH_CODE_2						= dem.N15_6_DEATH_CODE_2
					,N15_7_DEATH_CODE_3						= dem.N15_7_DEATH_CODE_3
					,N15_8_DEATH_CODE_4						= dem.N15_8_DEATH_CODE_4
					,N15_9_DEATH_DISCREPANCY				= dem.N15_9_DEATH_DISCREPANCY
					,N_CC4_TOWN								= dem.N_CC4_TOWN
					,N_CC5_COUNTRY							= dem.N_CC5_COUNTRY
					,N_CC6_M_SURNAME						= dem.N_CC6_M_SURNAME
					,N_CC7_M_CLASS							= dem.N_CC7_M_CLASS
					,N_CC8_M_FORENAME						= dem.N_CC8_M_FORENAME
					,N_CC9_M_DOB							= dem.N_CC9_M_DOB
					,N_CC10_M_TOWN							= dem.N_CC10_M_TOWN
					,N_CC11_M_COUNTRY						= dem.N_CC11_M_COUNTRY
					,N_CC12_M_OCC							= dem.N_CC12_M_OCC
					,N_CC13_M_OCC_DIAG						= dem.N_CC13_M_OCC_DIAG
					,N_CC6_F_SURNAME						= dem.N_CC6_F_SURNAME
					,N_CC7_F_CLASS							= dem.N_CC7_F_CLASS
					,N_CC8_F_FORENAME						= dem.N_CC8_F_FORENAME
					,N_CC9_F_DOB							= dem.N_CC9_F_DOB
					,N_CC10_F_TOWN							= dem.N_CC10_F_TOWN
					,N_CC11_F_COUNTRY						= dem.N_CC11_F_COUNTRY
					,N_CC12_F_OCC							= dem.N_CC12_F_OCC
					,N_CC13_F_OCC_DIAG						= dem.N_CC13_F_OCC_DIAG
					,N_CC14_MULTI_BIRTH						= dem.N_CC14_MULTI_BIRTH
					,R_POST_MORTEM							= dem.R_POST_MORTEM
					,R_DAY_PHONE							= dem.R_DAY_PHONE
					,DAY_PHONE_EXT							= dem.DAY_PHONE_EXT
					,R_EVE_PHONE							= dem.R_EVE_PHONE
					,EVE_PHONE_EXT							= dem.EVE_PHONE_EXT
					,R_DEATH_TREATMENT						= dem.R_DEATH_TREATMENT
					,R_PM_DETAILS							= dem.R_PM_DETAILS
					,L_IATROGENIC_DEATH						= dem.L_IATROGENIC_DEATH
					,L_INFECTION_DEATH						= dem.L_INFECTION_DEATH
					,L_DEATH_COMMENTS						= dem.L_DEATH_COMMENTS
					,RELIGION								= dem.RELIGION
					,CONTACT_DETAILS						= dem.CONTACT_DETAILS
					,NOK_NAME								= dem.NOK_NAME
					,NOK_ADDRESS_1							= dem.NOK_ADDRESS_1
					,NOK_ADDRESS_2							= dem.NOK_ADDRESS_2
					,NOK_ADDRESS_3							= dem.NOK_ADDRESS_3
					,NOK_ADDRESS_4							= dem.NOK_ADDRESS_4
					,NOK_ADDRESS_5							= dem.NOK_ADDRESS_5
					,NOK_POSTCODE							= dem.NOK_POSTCODE
					,NOK_CONTACT							= dem.NOK_CONTACT
					,NOK_RELATIONSHIP						= dem.NOK_RELATIONSHIP
					,PAT_DEPENDANTS							= dem.PAT_DEPENDANTS
					,CARER_NAME								= dem.CARER_NAME
					,CARER_ADDRESS_1						= dem.CARER_ADDRESS_1
					,CARER_ADDRESS_2						= dem.CARER_ADDRESS_2
					,CARER_ADDRESS_3						= dem.CARER_ADDRESS_3
					,CARER_ADDRESS_4						= dem.CARER_ADDRESS_4
					,CARER_ADDRESS_5						= dem.CARER_ADDRESS_5
					,CARER_POSTCODE							= dem.CARER_POSTCODE
					,CARER_CONTACT							= dem.CARER_CONTACT
					,CARER_RELATIONSHIP						= dem.CARER_RELATIONSHIP
					,CARER1_TYPE							= dem.CARER1_TYPE
					,CARER2_NAME							= dem.CARER2_NAME
					,CARER2_ADDRESS_1						= dem.CARER2_ADDRESS_1
					,CARER2_ADDRESS_2						= dem.CARER2_ADDRESS_2
					,CARER2_ADDRESS_3						= dem.CARER2_ADDRESS_3
					,CARER2_ADDRESS_4						= dem.CARER2_ADDRESS_4
					,CARER2_ADDRESS_5						= dem.CARER2_ADDRESS_5
					,CARER2_POSTCODE						= dem.CARER2_POSTCODE
					,CARER2_CONTACT							= dem.CARER2_CONTACT
					,CARER2_RELATIONSHIP					= dem.CARER2_RELATIONSHIP
					,CARER2_TYPE							= dem.CARER2_TYPE
					,PT_AT_RISK								= dem.PT_AT_RISK
					,REASON_RISK							= dem.REASON_RISK
					,GESTATION								= dem.GESTATION
					,CAUSE_OF_DEATH_UROLOGY					= dem.CAUSE_OF_DEATH_UROLOGY
					,AVOIDABLE_DEATH						= dem.AVOIDABLE_DEATH
					,AVOIDABLE_DETAILS						= dem.AVOIDABLE_DETAILS
					,OTHER_DEATH_CAUSE_UROLOGY				= dem.OTHER_DEATH_CAUSE_UROLOGY
					,ACTION_ID								= dem.ACTION_ID
					,STATED_GENDER_CODE						= dem.STATED_GENDER_CODE
					,CAUSE_OF_DEATH_UROLOGY_FUP				= dem.CAUSE_OF_DEATH_UROLOGY_FUP
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= dem.DEATH_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= dem.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_LATER_DATE					= dem.DEATH_CAUSE_LATER_DATE
					,RegisteredPractice						= dem.RegisteredPractice
					,RegisteredGP							= dem.RegisteredGP
					,PersonSexualOrientation				= dem.PersonSexualOrientation
		FROM		Merge_DM_MatchViews.tblDEMOGRAPHICS dem
		LEFT JOIN	(SELECT * FROM Merge_DM_MatchViews.tblAUDIT WHERE TABLE_NAME = 'tblDEMOGRAPHICS') aud
											ON	dem.SrcSysID = aud.SrcSysID
											AND	dem.ACTION_ID = aud.ACTION_ID
		LEFT JOIN	Merge_DM_MatchViews.ltblTITLE ttl
												ON	dem.SrcSysID = ttl.SrcSysID
												AND	dem.L_TITLE = ttl.TITLE_CODE
		LEFT JOIN	Merge_DM_MatchViews.ltblRELIGION relig
													ON	dem.SrcSysID = relig.SrcSysID
													AND	dem.RELIGION = relig.RELIGION_ID
		LEFT JOIN	map.tblDEMOGRAPHICS_ValueMap_RELIGION_CODE map_relig
																ON	relig.RELIGION_CODE = map_relig.SourceCode



GO
