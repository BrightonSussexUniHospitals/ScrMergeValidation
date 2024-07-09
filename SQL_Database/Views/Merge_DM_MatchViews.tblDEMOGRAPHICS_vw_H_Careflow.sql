SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE VIEW	[Merge_DM_MatchViews].[tblDEMOGRAPHICS_vw_H_Careflow] AS

		SELECT		IsSCR			= CAST(0 AS BIT)
					,IsMostRecent	= CAST(CASE WHEN dimpat.MERGE_RECORD_ID IS NULL THEN 1 ELSE 0 END AS BIT)
					,SrcSys			= CAST(Merge_DM_Match.fnSrcSys('Careflow',DEFAULT, 1) AS TINYINT)
					,Src_UID		= dimpat.PATIENT_EXTERNAL_ID
					,OriginalNhsNo	= LTRIM(RTRIM(REPLACE(dimpat.NHS_NUMBER, ' ', '')))
					,NhsNumber		= LTRIM(RTRIM(REPLACE(ISNULL(dimpat_master.NHS_NUMBER, dimpat.NHS_NUMBER), ' ', '')))
					,OriginalPasId	= LTRIM(RTRIM(dimpat.PAS_ID))
					,PasId			= LTRIM(RTRIM(ISNULL(dimpat.MERGE_RECORD_ID, dimpat.PAS_ID)))
					,CasenoteId		= LTRIM(RTRIM(dimpat.CASENOTE_IDENTIFIER))
					,DoB			= dimpat_master.BIRTH_DTTM
					,DoD			= CAST(dimpat_master.DEATH_DTTM AS DATE)
					,Surname		= dimpat_master.SURNAME
					,Forename		= dimpat_master.FORENAME
					,Postcode		= REPLACE(dimpat_master.POSTCODE, ' ', '')
					,Sex			= dimpat_master.SEX_NHSCODE
					,Address1		= dbo.fnOrderedNonEmptyStrings(1, dimpat_master.ADDRESS1,dimpat_master.ADDRESS2,dimpat_master.ADDRESS3,dimpat_master.ADDRESS4,dimpat_master.ADDRESS5)
					,Address2		= dbo.fnOrderedNonEmptyStrings(2, dimpat_master.ADDRESS1,dimpat_master.ADDRESS2,dimpat_master.ADDRESS3,dimpat_master.ADDRESS4,dimpat_master.ADDRESS5)
					,Address3		= dbo.fnOrderedNonEmptyStrings(3, dimpat_master.ADDRESS1,dimpat_master.ADDRESS2,dimpat_master.ADDRESS3,dimpat_master.ADDRESS4,dimpat_master.ADDRESS5)
					,Address4		= dbo.fnOrderedNonEmptyStrings(4, dimpat_master.ADDRESS1,dimpat_master.ADDRESS2,dimpat_master.ADDRESS3,dimpat_master.ADDRESS4,dimpat_master.ADDRESS5)
					,Address5		= dimpat_master.ADDRESS5
					,DeathStatus	= CASE WHEN dimpat_master.DEATH_MAINCODE != 'ns' THEN 1 ELSE 0 END
					,Title			= dimpat_master.TITLE_DESC
					,Ethnicity		= dimpat_master.ETHNC_NHSCODE
					,ReligionCode	= CASE WHEN dimpat_master.RELGN_NHSCODE = 'C63' THEN 'K' ELSE ISNULL(dbo.fnEmptyStringAsNull(LEFT(dimpat_master.RELGN_NHSCODE,1)), 'N') END
					,LastUpdated	= dimpat.MODIF_DTTM
					,UpdateByPas	= 1
					,HashBytesValue	= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																		,dimpat.PATIENT_EXTERNAL_ID
																		,ISNULL(dimpat_master.NHS_NUMBER, dimpat.NHS_NUMBER)
																		,ISNULL(dimpat.MERGE_RECORD_ID, dimpat.PAS_ID)
																		,dimpat.CASENOTE_IDENTIFIER
																		,CONVERT(VARCHAR(255), dimpat_master.BIRTH_DTTM, 126)
																		,CONVERT(VARCHAR(255), dimpat_master.DEATH_DTTM, 126)
																		,dimpat_master.SURNAME
																		,dimpat_master.FORENAME
																		,dimpat_master.POSTCODE
																		,dimpat_master.SEX_NHSCODE
																		,dimpat_master.ADDRESS1
																		,dimpat_master.ADDRESS2
																		,dimpat_master.ADDRESS3
																		,dimpat_master.ADDRESS4
																		,dimpat_master.ADDRESS5
																		,dimpat_master.DEATH_MAINCODE
																		,dimpat_master.TITLE_DESC
																		,dimpat_master.ETHNC_NHSCODE
																		,dimpat_master.RELGN_NHSCODE
																		))

					,PATIENT_ID								= CAST(NULL AS INT)
					,N1_1_NHS_NUMBER						= LTRIM(RTRIM(REPLACE(dimpat.NHS_NUMBER, ' ', '')))
					,NHS_NUMBER_STATUS						= CASE dimpat.NNNST_NHSCODE WHEN '' THEN NULL WHEN 'Unknown' THEN NULL ELSE dimpat.NNNST_NHSCODE END
					,L_RA3_RID								= CAST(NULL AS VARCHAR(50))
					,L_RA7_RID								= CAST(NULL AS VARCHAR(50))
					,L_RVJ01_RID							= CAST(NULL AS VARCHAR(50))
					,TEMP_ID								= CAST(NULL AS VARCHAR(255))
					,L_NSTS_STATUS							= CAST(NULL AS INT)
					,N1_2_HOSPITAL_NUMBER					= LTRIM(RTRIM(ISNULL(dimpat.MERGE_RECORD_ID, dimpat.PAS_ID)))
					,L_TITLE								= ttl.TITLE_CODE
					,N1_5_SURNAME							= dimpat_master.SURNAME
					,N1_6_FORENAME							= dimpat_master.FORENAME
					,N1_7_ADDRESS_1							= CAST(dimpat_master.ADDRESS1 AS VARCHAR(150))
					,N1_7_ADDRESS_2							= CAST(dimpat_master.ADDRESS2 AS VARCHAR(150))
					,N1_7_ADDRESS_3							= CAST(dimpat_master.ADDRESS3 AS VARCHAR(150))
					,N1_7_ADDRESS_4							= CAST(dimpat_master.ADDRESS4 AS VARCHAR(150))
					,N1_7_ADDRESS_5							= CAST(dimpat_master.ADDRESS5 AS VARCHAR(150))
					,N1_8_POSTCODE							= dimpat_master.POSTCODE
					,N1_9_SEX								= dimpat_master.SEX_NHSCODE
					,N1_10_DATE_BIRTH						= dimpat_master.BIRTH_DTTM
					,N1_11_GP_CODE							= CAST(NULL AS VARCHAR(8))
					,N1_12_GP_PRACTICE_CODE					= CAST(NULL AS VARCHAR(15))
					,N1_13_PCT								= CAST(NULL AS VARCHAR(5))
					,N1_14_SURNAME_BIRTH					= CAST(NULL AS VARCHAR(60))
					,N1_15_ETHNICITY						= dimpat_master.ETHNC_NHSCODE
					,PAT_PREF_NAME							= CAST(NULL AS VARCHAR(50))
					,PAT_OCCUPATION							= CAST(NULL AS VARCHAR(50))
					,PAT_SOCIAL_CLASS						= CAST(NULL AS VARCHAR(5))
					,PAT_LIVES_ALONE						= CAST(NULL AS BIT)
					,MARITAL_STATUS							= CAST(NULL AS CHAR(1))
					,PAT_PREF_LANGUAGE						= CAST(NULL AS VARCHAR(50))
					,PAT_PREF_CONTACT						= CAST(NULL AS INT)
					,L_DEATH_STATUS							= CASE WHEN dimpat_master.DEATH_MAINCODE != 'ns' THEN 1 ELSE 0 END
					,N15_1_DATE_DEATH						= CAST(dimpat_master.DEATH_DTTM AS DATE)
					,N15_2_DEATH_LOCATION					= CAST(NULL AS INT)
					,N15_3_DEATH_CAUSE						= CAST(NULL AS INT)
					,N15_4_DEATH_CANCER						= CAST(NULL AS INT)
					,N15_5_DEATH_CODE_1						= CAST(NULL AS VARCHAR(5))
					,N15_6_DEATH_CODE_2						= CAST(NULL AS VARCHAR(5))
					,N15_7_DEATH_CODE_3						= CAST(NULL AS VARCHAR(5))
					,N15_8_DEATH_CODE_4						= CAST(NULL AS VARCHAR(5))
					,N15_9_DEATH_DISCREPANCY				= CAST(NULL AS INT)
					,N_CC4_TOWN								= CAST(NULL AS VARCHAR(50))
					,N_CC5_COUNTRY							= CAST(NULL AS VARCHAR(3))
					,N_CC6_M_SURNAME						= CAST(NULL AS VARCHAR(35))
					,N_CC7_M_CLASS							= CAST(NULL AS VARCHAR(1))
					,N_CC8_M_FORENAME						= CAST(NULL AS VARCHAR(35))
					,N_CC9_M_DOB							= CAST(NULL AS DATE)
					,N_CC10_M_TOWN							= CAST(NULL AS VARCHAR(50))
					,N_CC11_M_COUNTRY						= CAST(NULL AS VARCHAR(3))
					,N_CC12_M_OCC							= CAST(NULL AS VARCHAR(50))
					,N_CC13_M_OCC_DIAG						= CAST(NULL AS VARCHAR(50))
					,N_CC6_F_SURNAME						= CAST(NULL AS VARCHAR(35))
					,N_CC7_F_CLASS							= CAST(NULL AS VARCHAR(1))
					,N_CC8_F_FORENAME						= CAST(NULL AS VARCHAR(35))
					,N_CC9_F_DOB							= CAST(NULL AS DATE)
					,N_CC10_F_TOWN							= CAST(NULL AS VARCHAR(50))
					,N_CC11_F_COUNTRY						= CAST(NULL AS VARCHAR(3))
					,N_CC12_F_OCC							= CAST(NULL AS VARCHAR(50))
					,N_CC13_F_OCC_DIAG						= CAST(NULL AS VARCHAR(50))
					,N_CC14_MULTI_BIRTH						= CAST(NULL AS INT)
					,R_POST_MORTEM							= CAST(NULL AS BIT)
					,R_DAY_PHONE							= CAST(NULL AS VARCHAR(50))
					,DAY_PHONE_EXT							= CAST(NULL AS VARCHAR(10))
					,R_EVE_PHONE							= CAST(NULL AS VARCHAR(50))
					,EVE_PHONE_EXT							= CAST(NULL AS VARCHAR(10))
					,R_DEATH_TREATMENT						= CAST(NULL AS VARCHAR(1))
					,R_PM_DETAILS							= CAST(NULL AS VARCHAR(255))
					,L_IATROGENIC_DEATH						= CAST(NULL AS BIT)
					,L_INFECTION_DEATH						= CAST(NULL AS BIT)
					,L_DEATH_COMMENTS						= CAST(NULL AS VARCHAR(255))
					,RELIGION								= relgn.RELIGION_ID
					,CONTACT_DETAILS						= CAST(NULL AS VARCHAR(255))
					,NOK_NAME								= CAST(NULL AS VARCHAR(100))
					,NOK_ADDRESS_1							= CAST(NULL AS VARCHAR(150))
					,NOK_ADDRESS_2							= CAST(NULL AS VARCHAR(150))
					,NOK_ADDRESS_3							= CAST(NULL AS VARCHAR(150))
					,NOK_ADDRESS_4							= CAST(NULL AS VARCHAR(150))
					,NOK_ADDRESS_5							= CAST(NULL AS VARCHAR(150))
					,NOK_POSTCODE							= CAST(NULL AS VARCHAR(10))
					,NOK_CONTACT							= CAST(NULL AS VARCHAR(255))
					,NOK_RELATIONSHIP						= CAST(NULL AS VARCHAR(4))
					,PAT_DEPENDANTS							= CAST(NULL AS VARCHAR(MAX))
					,CARER_NAME								= CAST(NULL AS VARCHAR(100))
					,CARER_ADDRESS_1						= CAST(NULL AS VARCHAR(150))
					,CARER_ADDRESS_2						= CAST(NULL AS VARCHAR(150))
					,CARER_ADDRESS_3						= CAST(NULL AS VARCHAR(150))
					,CARER_ADDRESS_4						= CAST(NULL AS VARCHAR(150))
					,CARER_ADDRESS_5						= CAST(NULL AS VARCHAR(150))
					,CARER_POSTCODE							= CAST(NULL AS VARCHAR(10))
					,CARER_CONTACT							= CAST(NULL AS VARCHAR(255))
					,CARER_RELATIONSHIP						= CAST(NULL AS VARCHAR(1))
					,CARER1_TYPE							= CAST(NULL AS VARCHAR(4))
					,CARER2_NAME							= CAST(NULL AS VARCHAR(100))
					,CARER2_ADDRESS_1						= CAST(NULL AS VARCHAR(150))
					,CARER2_ADDRESS_2						= CAST(NULL AS VARCHAR(150))
					,CARER2_ADDRESS_3						= CAST(NULL AS VARCHAR(150))
					,CARER2_ADDRESS_4						= CAST(NULL AS VARCHAR(150))
					,CARER2_ADDRESS_5						= CAST(NULL AS VARCHAR(150))
					,CARER2_POSTCODE						= CAST(NULL AS VARCHAR(10))
					,CARER2_CONTACT							= CAST(NULL AS VARCHAR(255))
					,CARER2_RELATIONSHIP					= CAST(NULL AS VARCHAR(4))
					,CARER2_TYPE							= CAST(NULL AS VARCHAR(4))
					,PT_AT_RISK								= CAST(NULL AS BIT)
					,REASON_RISK							= CAST(NULL AS VARCHAR(MAX))
					,GESTATION								= CAST(NULL AS VARCHAR(100))
					,CAUSE_OF_DEATH_UROLOGY					= CAST(NULL AS INT)
					,AVOIDABLE_DEATH						= CAST(NULL AS BIT)
					,AVOIDABLE_DETAILS						= CAST(NULL AS VARCHAR(255))
					,OTHER_DEATH_CAUSE_UROLOGY				= CAST(NULL AS VARCHAR(255))
					,ACTION_ID								= CAST(NULL AS INT)
					,STATED_GENDER_CODE						= CAST(NULL AS VARCHAR(2))
					,CAUSE_OF_DEATH_UROLOGY_FUP				= CAST(NULL AS INT)
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= CAST(NULL AS INT)
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= CAST(NULL AS INT)
					,DEATH_CAUSE_LATER_DATE					= CAST(NULL AS INT)
					,RegisteredPractice						= CAST(NULL AS INT)
					,RegisteredGP							= CAST(NULL AS INT)
					,PersonSexualOrientation				= CAST(NULL AS INT)
		FROM		PASDataRepository.dbo.DIM_PATIENT dimpat WITH(NOLOCK)
		LEFT JOIN	PASDataRepository.dbo.DIM_PATIENT dimpat_master WITH(NOLOCK)
																ON	ISNULL(dimpat.MERGE_RECORD_ID, dimpat.PAS_ID) = dimpat_master.PAS_ID
																AND	dimpat_master.MERGE_RECORD_ID IS NULL
		LEFT JOIN	Merge_DM_MatchViews.ltblTITLE ttl
													ON	dimpat_master.TITLE_DESC = ttl.TITLE_DESC
													AND	ttl.SrcSysID = 4
		LEFT JOIN	Merge_DM_MatchViews.ltblRELIGION relgn
														ON	dimpat_master.RELGN_NHSCODE = relgn.RELIGION_CODE




GO
