SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [Merge_DM_Match].[tblDEMOGRAPHICS_uspValidatedData]

		(@PivotForSSRS BIT = 0
		,@OutputToTable BIT = 0
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
Description:				A stored procedure to return the validated DM matching data for incororporating into the merge process
							or for the purposes of validation
**************************************************************************************************************************************************/

-- Test me
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspValidatedData
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspValidatedData @PivotForSSRS = 1
-- EXEC Merge_DM_Match.tblDEMOGRAPHICS_uspValidatedData @OutputToTable = 1

/*****************************************************************************************************************************************/
-- Create the temporary tables needed to create the output
/*****************************************************************************************************************************************/
		
		-- Create the #RelatedEntities table if it doesn't already exist - this allows a set of SrcSys/Src_UIDs to be passed to the procedure if we wish to retrieve the data for a specific cohort
		IF OBJECT_ID('tempdb..#RelatedEntities') IS NULL
		CREATE TABLE #RelatedEntities (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL)

		-- Test whether we have any records in the #RelatedEntities table
		DECLARE @HasRelatedEntities BIT
		SELECT @HasRelatedEntities = COUNT(*) FROM #RelatedEntities

		-- Create the #mcIx table to represent the match control table with a priority order to it
		IF OBJECT_ID('tempdb..#mcIx') IS NOT NULL DROP TABLE #mcIx
		SELECT		IsMajor = CASE WHEN mc.SrcSys_Major = mc.SrcSys AND mc.Src_UID_Major = mc.Src_UID THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
					,IsMajorSCR = CASE WHEN mc.SrcSys_Major IN (1,2) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
					,IsConfirmed = CASE WHEN mmv_Confirmed.SrcSys_Major IS NOT NULL THEN 1 ELSE 0 END
					,mc.*
					,mcIx = ROW_NUMBER() OVER (PARTITION BY mc.SrcSys_Major, mc.Src_UID_Major ORDER BY mc.IsSCR DESC, h.LastUpdated DESC, mc.SrcSys, mc.Src_UID)
					,h.LastUpdated
		INTO		#mcIx
		FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
															ON	mc.SrcSys = h.SrcSys
															AND	mc.Src_UID = h.Src_UID
															AND	h.SrcSys IN (1,2)
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv_Confirmed
																			ON	mc.SrcSys_Major = mmv_Confirmed.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv_Confirmed.Src_UID_Major
																			AND	mmv_Confirmed.ValidationStatus IN ('Confirmed')
		LEFT JOIN	#RelatedEntities re
										ON	mc.SrcSys = re.SrcSys
										AND	mc.Src_UID = re.Src_UID
		WHERE		re.SrcSys IS NOT NULL
		OR			@HasRelatedEntities = 0

		-- Create an index on the temporary match control table
		DECLARE @NewID VARCHAR(255)
		DECLARE @SQL_mc VARCHAR(MAX)
		SELECT @NewID = CAST(NEWID() AS VARCHAR(255))
		SET @SQL_mc = 'CREATE UNIQUE CLUSTERED INDEX [PK_mcIx_' + @NewID + '] ON #mcIx (SrcSys ASC, Src_UID ASC)'; PRINT @SQL_mc; EXEC (@SQL_mc)
		SET @SQL_mc = 'CREATE NONCLUSTERED INDEX [Ix_mcIx_Minors_' + @NewID + '] ON #mcIx (mcIx, IsMajorSCR, SrcSys_Major ASC, Src_UID_Major)'; PRINT @SQL_mc; EXEC (@SQL_mc)
		SET @SQL_mc = 'CREATE NONCLUSTERED INDEX [Ix_mcIx_Major_' + @NewID + '] ON #mcIx (SrcSys_Major ASC, Src_UID_Major)'; PRINT @SQL_mc; EXEC (@SQL_mc)
		SET @SQL_mc = 'CREATE NONCLUSTERED INDEX [Ix_mcIx_IsMajorSCR_' + @NewID + '] ON #mcIx (IsMajorSCR)'; PRINT @SQL_mc; EXEC (@SQL_mc)
		SET @SQL_mc = 'CREATE NONCLUSTERED INDEX [Ix_mcIx_mcIx_' + @NewID + '] ON #mcIx (mcIx)'; PRINT @SQL_mc; EXEC (@SQL_mc)

		-- SELECT * FROM #mcIx WHERE #mcIx.IsMajorSCR = 0

/*****************************************************************************************************************************************/
-- Create the validated dataset and populate the output
/*****************************************************************************************************************************************/

		-- Create the #ValidatedData table to temporarily hold the output dataset
		IF OBJECT_ID('tempdb..#ValidatedData') IS NOT NULL DROP TABLE #ValidatedData
		SELECT		SrcSys_MajorExt		= CAST(NULL AS TINYINT)
					,Src_UID_MajorExt	= CAST(NULL AS VARCHAR(255))
					,SrcSys_Major		= CAST(NULL AS TINYINT)
					,Src_UID_Major		= CAST(NULL AS VARCHAR(255))
					,IsValidatedMajor	= CAST(NULL AS BIT)
					,IsConfirmed		= CAST(NULL AS BIT)
					,LastUpdated		= CAST(NULL AS DATETIME)
					,uh.SrcSys
					,uh.Src_UID
					,uh.PATIENT_ID
					,uh.N1_1_NHS_NUMBER
					,uh.NHS_NUMBER_STATUS
					,uh.L_RA3_RID
					,uh.L_RA7_RID
					,uh.L_RVJ01_RID
					,uh.TEMP_ID
					,uh.L_NSTS_STATUS
					,uh.N1_2_HOSPITAL_NUMBER
					,uh.L_TITLE
					,uh.N1_5_SURNAME
					,uh.N1_6_FORENAME
					,uh.N1_7_ADDRESS_1
					,uh.N1_7_ADDRESS_2
					,uh.N1_7_ADDRESS_3
					,uh.N1_7_ADDRESS_4
					,uh.N1_7_ADDRESS_5
					,uh.N1_8_POSTCODE
					,uh.N1_9_SEX
					,uh.N1_10_DATE_BIRTH
					,uh.N1_11_GP_CODE
					,uh.N1_12_GP_PRACTICE_CODE
					,uh.N1_13_PCT
					,uh.N1_14_SURNAME_BIRTH
					,uh.N1_15_ETHNICITY
					,uh.PAT_PREF_NAME
					,uh.PAT_OCCUPATION
					,uh.PAT_SOCIAL_CLASS
					,uh.PAT_LIVES_ALONE
					,uh.MARITAL_STATUS
					,uh.PAT_PREF_LANGUAGE
					,uh.PAT_PREF_CONTACT
					,uh.L_DEATH_STATUS
					,uh.N15_1_DATE_DEATH
					,uh.N15_2_DEATH_LOCATION
					,uh.N15_3_DEATH_CAUSE
					,uh.N15_4_DEATH_CANCER
					,uh.N15_5_DEATH_CODE_1
					,uh.N15_6_DEATH_CODE_2
					,uh.N15_7_DEATH_CODE_3
					,uh.N15_8_DEATH_CODE_4
					,uh.N15_9_DEATH_DISCREPANCY
					,uh.N_CC4_TOWN
					,uh.N_CC5_COUNTRY
					,uh.N_CC6_M_SURNAME
					,uh.N_CC7_M_CLASS
					,uh.N_CC8_M_FORENAME
					,uh.N_CC9_M_DOB
					,uh.N_CC10_M_TOWN
					,uh.N_CC11_M_COUNTRY
					,uh.N_CC12_M_OCC
					,uh.N_CC13_M_OCC_DIAG
					,uh.N_CC6_F_SURNAME
					,uh.N_CC7_F_CLASS
					,uh.N_CC8_F_FORENAME
					,uh.N_CC9_F_DOB
					,uh.N_CC10_F_TOWN
					,uh.N_CC11_F_COUNTRY
					,uh.N_CC12_F_OCC
					,uh.N_CC13_F_OCC_DIAG
					,uh.N_CC14_MULTI_BIRTH
					,uh.R_POST_MORTEM
					,uh.R_DAY_PHONE
					,uh.DAY_PHONE_EXT
					,uh.R_EVE_PHONE
					,uh.EVE_PHONE_EXT
					,uh.R_DEATH_TREATMENT
					,uh.R_PM_DETAILS
					,uh.L_IATROGENIC_DEATH
					,uh.L_INFECTION_DEATH
					,uh.L_DEATH_COMMENTS
					,uh.RELIGION
					,uh.CONTACT_DETAILS
					,uh.NOK_NAME
					,uh.NOK_ADDRESS_1
					,uh.NOK_ADDRESS_2
					,uh.NOK_ADDRESS_3
					,uh.NOK_ADDRESS_4
					,uh.NOK_ADDRESS_5
					,uh.NOK_POSTCODE
					,uh.NOK_CONTACT
					,uh.NOK_RELATIONSHIP
					,uh.PAT_DEPENDANTS
					,uh.CARER_NAME
					,uh.CARER_ADDRESS_1
					,uh.CARER_ADDRESS_2
					,uh.CARER_ADDRESS_3
					,uh.CARER_ADDRESS_4
					,uh.CARER_ADDRESS_5
					,uh.CARER_POSTCODE
					,uh.CARER_CONTACT
					,uh.CARER_RELATIONSHIP
					,uh.CARER1_TYPE
					,uh.CARER2_NAME
					,uh.CARER2_ADDRESS_1
					,uh.CARER2_ADDRESS_2
					,uh.CARER2_ADDRESS_3
					,uh.CARER2_ADDRESS_4
					,uh.CARER2_ADDRESS_5
					,uh.CARER2_POSTCODE
					,uh.CARER2_CONTACT
					,uh.CARER2_RELATIONSHIP
					,uh.CARER2_TYPE
					,uh.PT_AT_RISK
					,uh.REASON_RISK
					,uh.GESTATION
					,uh.CAUSE_OF_DEATH_UROLOGY
					,uh.AVOIDABLE_DEATH
					,uh.AVOIDABLE_DETAILS
					,uh.OTHER_DEATH_CAUSE_UROLOGY
					,uh.ACTION_ID
					,uh.STATED_GENDER_CODE
					,uh.CAUSE_OF_DEATH_UROLOGY_FUP
					,uh.DEATH_WITHIN_30_DAYS_OF_TREAT
					,uh.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,uh.DEATH_CAUSE_LATER_DATE
					,uh.RegisteredPractice
					,uh.RegisteredGP
					,uh.PersonSexualOrientation
		INTO		#ValidatedData
		FROM		Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH uh
		WHERE		0 = 1 -- only return an empty dataset with the desired table structure

		-- internal majors
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
					,Src_UID_MajorExt						= mc.Src_UID_Major
					,SrcSys_Major							= mc.SrcSys_Major
					,Src_UID_Major							= mc.Src_UID_Major
					,IsValidatedMajor						= 1
					,IsConfirmed							= mc.IsConfirmed
					,LastUpdated							= h.LastUpdated
					,SrcSys									= mc.SrcSys
					,Src_UID								= mc.Src_UID
					,PATIENT_ID								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PATIENT_ID = 1 THEN mmv.PATIENT_ID ELSE h.PATIENT_ID END
					,N1_1_NHS_NUMBER						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_1_NHS_NUMBER = 1 THEN mmv.N1_1_NHS_NUMBER ELSE h.N1_1_NHS_NUMBER END
					,NHS_NUMBER_STATUS						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NHS_NUMBER_STATUS = 1 THEN mmv.NHS_NUMBER_STATUS ELSE h.NHS_NUMBER_STATUS END
					,L_RA3_RID								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RA3_RID = 1 THEN mmv.L_RA3_RID ELSE h.L_RA3_RID END
					,L_RA7_RID								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RA7_RID = 1 THEN mmv.L_RA7_RID ELSE h.L_RA7_RID END
					,L_RVJ01_RID							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RVJ01_RID = 1 THEN mmv.L_RVJ01_RID ELSE h.L_RVJ01_RID END
					,TEMP_ID								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.TEMP_ID = 1 THEN mmv.TEMP_ID ELSE h.TEMP_ID END
					,L_NSTS_STATUS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_NSTS_STATUS = 1 THEN mmv.L_NSTS_STATUS ELSE h.L_NSTS_STATUS END
					,N1_2_HOSPITAL_NUMBER					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_2_HOSPITAL_NUMBER = 1 THEN mmv.N1_2_HOSPITAL_NUMBER ELSE h.N1_2_HOSPITAL_NUMBER END
					,L_TITLE								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_TITLE = 1 THEN mmv.L_TITLE ELSE h.L_TITLE END
					,N1_5_SURNAME							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_5_SURNAME = 1 THEN mmv.N1_5_SURNAME ELSE h.N1_5_SURNAME END
					,N1_6_FORENAME							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_6_FORENAME = 1 THEN mmv.N1_6_FORENAME ELSE h.N1_6_FORENAME END
					,N1_7_ADDRESS_1							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_1 = 1 THEN mmv.N1_7_ADDRESS_1 ELSE h.N1_7_ADDRESS_1 END
					,N1_7_ADDRESS_2							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_2 = 1 THEN mmv.N1_7_ADDRESS_2 ELSE h.N1_7_ADDRESS_2 END
					,N1_7_ADDRESS_3							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_3 = 1 THEN mmv.N1_7_ADDRESS_3 ELSE h.N1_7_ADDRESS_3 END
					,N1_7_ADDRESS_4							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_4 = 1 THEN mmv.N1_7_ADDRESS_4 ELSE h.N1_7_ADDRESS_4 END
					,N1_7_ADDRESS_5							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_5 = 1 THEN mmv.N1_7_ADDRESS_5 ELSE h.N1_7_ADDRESS_5 END
					,N1_8_POSTCODE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_8_POSTCODE = 1 THEN mmv.N1_8_POSTCODE ELSE h.N1_8_POSTCODE END
					,N1_9_SEX								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_9_SEX = 1 THEN mmv.N1_9_SEX ELSE h.N1_9_SEX END
					,N1_10_DATE_BIRTH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_10_DATE_BIRTH = 1 THEN mmv.N1_10_DATE_BIRTH ELSE h.N1_10_DATE_BIRTH END
					,N1_11_GP_CODE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_11_GP_CODE = 1 THEN mmv.N1_11_GP_CODE ELSE h.N1_11_GP_CODE END
					,N1_12_GP_PRACTICE_CODE					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_12_GP_PRACTICE_CODE = 1 THEN mmv.N1_12_GP_PRACTICE_CODE ELSE h.N1_12_GP_PRACTICE_CODE END
					,N1_13_PCT								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_13_PCT = 1 THEN mmv.N1_13_PCT ELSE h.N1_13_PCT END
					,N1_14_SURNAME_BIRTH					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_14_SURNAME_BIRTH = 1 THEN mmv.N1_14_SURNAME_BIRTH ELSE h.N1_14_SURNAME_BIRTH END
					,N1_15_ETHNICITY						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_15_ETHNICITY = 1 THEN mmv.N1_15_ETHNICITY ELSE h.N1_15_ETHNICITY END
					,PAT_PREF_NAME							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_NAME = 1 THEN mmv.PAT_PREF_NAME ELSE h.PAT_PREF_NAME END
					,PAT_OCCUPATION							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_OCCUPATION = 1 THEN mmv.PAT_OCCUPATION ELSE h.PAT_OCCUPATION END
					,PAT_SOCIAL_CLASS						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_SOCIAL_CLASS = 1 THEN mmv.PAT_SOCIAL_CLASS ELSE h.PAT_SOCIAL_CLASS END
					,PAT_LIVES_ALONE						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_LIVES_ALONE = 1 THEN mmv.PAT_LIVES_ALONE ELSE h.PAT_LIVES_ALONE END
					,MARITAL_STATUS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.MARITAL_STATUS = 1 THEN mmv.MARITAL_STATUS ELSE h.MARITAL_STATUS END
					,PAT_PREF_LANGUAGE						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_LANGUAGE = 1 THEN mmv.PAT_PREF_LANGUAGE ELSE h.PAT_PREF_LANGUAGE END
					,PAT_PREF_CONTACT						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_CONTACT = 1 THEN mmv.PAT_PREF_CONTACT ELSE h.PAT_PREF_CONTACT END
					,L_DEATH_STATUS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_DEATH_STATUS = 1 THEN mmv.L_DEATH_STATUS ELSE h.L_DEATH_STATUS END
					,N15_1_DATE_DEATH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_1_DATE_DEATH = 1 THEN mmv.N15_1_DATE_DEATH ELSE h.N15_1_DATE_DEATH END
					,N15_2_DEATH_LOCATION					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_2_DEATH_LOCATION = 1 THEN mmv.N15_2_DEATH_LOCATION ELSE h.N15_2_DEATH_LOCATION END
					,N15_3_DEATH_CAUSE						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_3_DEATH_CAUSE = 1 THEN mmv.N15_3_DEATH_CAUSE ELSE h.N15_3_DEATH_CAUSE END
					,N15_4_DEATH_CANCER						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_4_DEATH_CANCER = 1 THEN mmv.N15_4_DEATH_CANCER ELSE h.N15_4_DEATH_CANCER END
					,N15_5_DEATH_CODE_1						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_5_DEATH_CODE_1 = 1 THEN mmv.N15_5_DEATH_CODE_1 ELSE h.N15_5_DEATH_CODE_1 END
					,N15_6_DEATH_CODE_2						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_6_DEATH_CODE_2 = 1 THEN mmv.N15_6_DEATH_CODE_2 ELSE h.N15_6_DEATH_CODE_2 END
					,N15_7_DEATH_CODE_3						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_7_DEATH_CODE_3 = 1 THEN mmv.N15_7_DEATH_CODE_3 ELSE h.N15_7_DEATH_CODE_3 END
					,N15_8_DEATH_CODE_4						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_8_DEATH_CODE_4 = 1 THEN mmv.N15_8_DEATH_CODE_4 ELSE h.N15_8_DEATH_CODE_4 END
					,N15_9_DEATH_DISCREPANCY				= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_9_DEATH_DISCREPANCY = 1 THEN mmv.N15_9_DEATH_DISCREPANCY ELSE h.N15_9_DEATH_DISCREPANCY END
					,N_CC4_TOWN								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC4_TOWN = 1 THEN mmv.N_CC4_TOWN ELSE h.N_CC4_TOWN END
					,N_CC5_COUNTRY							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC5_COUNTRY = 1 THEN mmv.N_CC5_COUNTRY ELSE h.N_CC5_COUNTRY END
					,N_CC6_M_SURNAME						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC6_M_SURNAME = 1 THEN mmv.N_CC6_M_SURNAME ELSE h.N_CC6_M_SURNAME END
					,N_CC7_M_CLASS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC7_M_CLASS = 1 THEN mmv.N_CC7_M_CLASS ELSE h.N_CC7_M_CLASS END
					,N_CC8_M_FORENAME						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC8_M_FORENAME = 1 THEN mmv.N_CC8_M_FORENAME ELSE h.N_CC8_M_FORENAME END
					,N_CC9_M_DOB							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC9_M_DOB = 1 THEN mmv.N_CC9_M_DOB ELSE h.N_CC9_M_DOB END
					,N_CC10_M_TOWN							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC10_M_TOWN = 1 THEN mmv.N_CC10_M_TOWN ELSE h.N_CC10_M_TOWN END
					,N_CC11_M_COUNTRY						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC11_M_COUNTRY = 1 THEN mmv.N_CC11_M_COUNTRY ELSE h.N_CC11_M_COUNTRY END
					,N_CC12_M_OCC							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC12_M_OCC = 1 THEN mmv.N_CC12_M_OCC ELSE h.N_CC12_M_OCC END
					,N_CC13_M_OCC_DIAG						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC13_M_OCC_DIAG = 1 THEN mmv.N_CC13_M_OCC_DIAG ELSE h.N_CC13_M_OCC_DIAG END
					,N_CC6_F_SURNAME						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC6_F_SURNAME = 1 THEN mmv.N_CC6_F_SURNAME ELSE h.N_CC6_F_SURNAME END
					,N_CC7_F_CLASS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC7_F_CLASS = 1 THEN mmv.N_CC7_F_CLASS ELSE h.N_CC7_F_CLASS END
					,N_CC8_F_FORENAME						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC8_F_FORENAME = 1 THEN mmv.N_CC8_F_FORENAME ELSE h.N_CC8_F_FORENAME END
					,N_CC9_F_DOB							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC9_F_DOB = 1 THEN mmv.N_CC9_F_DOB ELSE h.N_CC9_F_DOB END
					,N_CC10_F_TOWN							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC10_F_TOWN = 1 THEN mmv.N_CC10_F_TOWN ELSE h.N_CC10_F_TOWN END
					,N_CC11_F_COUNTRY						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC11_F_COUNTRY = 1 THEN mmv.N_CC11_F_COUNTRY ELSE h.N_CC11_F_COUNTRY END
					,N_CC12_F_OCC							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC12_F_OCC = 1 THEN mmv.N_CC12_F_OCC ELSE h.N_CC12_F_OCC END
					,N_CC13_F_OCC_DIAG						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC13_F_OCC_DIAG = 1 THEN mmv.N_CC13_F_OCC_DIAG ELSE h.N_CC13_F_OCC_DIAG END
					,N_CC14_MULTI_BIRTH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC14_MULTI_BIRTH = 1 THEN mmv.N_CC14_MULTI_BIRTH ELSE h.N_CC14_MULTI_BIRTH END
					,R_POST_MORTEM							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_POST_MORTEM = 1 THEN mmv.R_POST_MORTEM ELSE h.R_POST_MORTEM END
					,R_DAY_PHONE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_DAY_PHONE = 1 THEN mmv.R_DAY_PHONE ELSE h.R_DAY_PHONE END
					,DAY_PHONE_EXT							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DAY_PHONE_EXT = 1 THEN mmv.DAY_PHONE_EXT ELSE h.DAY_PHONE_EXT END
					,R_EVE_PHONE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_EVE_PHONE = 1 THEN mmv.R_EVE_PHONE ELSE h.R_EVE_PHONE END
					,EVE_PHONE_EXT							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.EVE_PHONE_EXT = 1 THEN mmv.EVE_PHONE_EXT ELSE h.EVE_PHONE_EXT END
					,R_DEATH_TREATMENT						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_DEATH_TREATMENT = 1 THEN mmv.R_DEATH_TREATMENT ELSE h.R_DEATH_TREATMENT END
					,R_PM_DETAILS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_PM_DETAILS = 1 THEN mmv.R_PM_DETAILS ELSE h.R_PM_DETAILS END
					,L_IATROGENIC_DEATH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_IATROGENIC_DEATH = 1 THEN mmv.L_IATROGENIC_DEATH ELSE h.L_IATROGENIC_DEATH END
					,L_INFECTION_DEATH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_INFECTION_DEATH = 1 THEN mmv.L_INFECTION_DEATH ELSE h.L_INFECTION_DEATH END
					,L_DEATH_COMMENTS						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_DEATH_COMMENTS = 1 THEN mmv.L_DEATH_COMMENTS ELSE h.L_DEATH_COMMENTS END
					,RELIGION								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RELIGION = 1 THEN mmv.RELIGION ELSE h.RELIGION END
					,CONTACT_DETAILS						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CONTACT_DETAILS = 1 THEN mmv.CONTACT_DETAILS ELSE h.CONTACT_DETAILS END
					,NOK_NAME								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_NAME = 1 THEN mmv.NOK_NAME ELSE h.NOK_NAME END
					,NOK_ADDRESS_1							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_1 = 1 THEN mmv.NOK_ADDRESS_1 ELSE h.NOK_ADDRESS_1 END
					,NOK_ADDRESS_2							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_2 = 1 THEN mmv.NOK_ADDRESS_2 ELSE h.NOK_ADDRESS_2 END
					,NOK_ADDRESS_3							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_3 = 1 THEN mmv.NOK_ADDRESS_3 ELSE h.NOK_ADDRESS_3 END
					,NOK_ADDRESS_4							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_4 = 1 THEN mmv.NOK_ADDRESS_4 ELSE h.NOK_ADDRESS_4 END
					,NOK_ADDRESS_5							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_5 = 1 THEN mmv.NOK_ADDRESS_5 ELSE h.NOK_ADDRESS_5 END
					,NOK_POSTCODE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_POSTCODE = 1 THEN mmv.NOK_POSTCODE ELSE h.NOK_POSTCODE END
					,NOK_CONTACT							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_CONTACT = 1 THEN mmv.NOK_CONTACT ELSE h.NOK_CONTACT END
					,NOK_RELATIONSHIP						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_RELATIONSHIP = 1 THEN mmv.NOK_RELATIONSHIP ELSE h.NOK_RELATIONSHIP END
					,PAT_DEPENDANTS							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_DEPENDANTS = 1 THEN mmv.PAT_DEPENDANTS ELSE h.PAT_DEPENDANTS END
					,CARER_NAME								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_NAME = 1 THEN mmv.CARER_NAME ELSE h.CARER_NAME END
					,CARER_ADDRESS_1						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_1 = 1 THEN mmv.CARER_ADDRESS_1 ELSE h.CARER_ADDRESS_1 END
					,CARER_ADDRESS_2						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_2 = 1 THEN mmv.CARER_ADDRESS_2 ELSE h.CARER_ADDRESS_2 END
					,CARER_ADDRESS_3						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_3 = 1 THEN mmv.CARER_ADDRESS_3 ELSE h.CARER_ADDRESS_3 END
					,CARER_ADDRESS_4						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_4 = 1 THEN mmv.CARER_ADDRESS_4 ELSE h.CARER_ADDRESS_4 END
					,CARER_ADDRESS_5						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_5 = 1 THEN mmv.CARER_ADDRESS_5 ELSE h.CARER_ADDRESS_5 END
					,CARER_POSTCODE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_POSTCODE = 1 THEN mmv.CARER_POSTCODE ELSE h.CARER_POSTCODE END
					,CARER_CONTACT							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_CONTACT = 1 THEN mmv.CARER_CONTACT ELSE h.CARER_CONTACT END
					,CARER_RELATIONSHIP						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_RELATIONSHIP = 1 THEN mmv.CARER_RELATIONSHIP ELSE h.CARER_RELATIONSHIP END
					,CARER1_TYPE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER1_TYPE = 1 THEN mmv.CARER1_TYPE ELSE h.CARER1_TYPE END
					,CARER2_NAME							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_NAME = 1 THEN mmv.CARER2_NAME ELSE h.CARER2_NAME END
					,CARER2_ADDRESS_1						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_1 = 1 THEN mmv.CARER2_ADDRESS_1 ELSE h.CARER2_ADDRESS_1 END
					,CARER2_ADDRESS_2						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_2 = 1 THEN mmv.CARER2_ADDRESS_2 ELSE h.CARER2_ADDRESS_2 END
					,CARER2_ADDRESS_3						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_3 = 1 THEN mmv.CARER2_ADDRESS_3 ELSE h.CARER2_ADDRESS_3 END
					,CARER2_ADDRESS_4						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_4 = 1 THEN mmv.CARER2_ADDRESS_4 ELSE h.CARER2_ADDRESS_4 END
					,CARER2_ADDRESS_5						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_5 = 1 THEN mmv.CARER2_ADDRESS_5 ELSE h.CARER2_ADDRESS_5 END
					,CARER2_POSTCODE						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_POSTCODE = 1 THEN mmv.CARER2_POSTCODE ELSE h.CARER2_POSTCODE END
					,CARER2_CONTACT							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_CONTACT = 1 THEN mmv.CARER2_CONTACT ELSE h.CARER2_CONTACT END
					,CARER2_RELATIONSHIP					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_RELATIONSHIP = 1 THEN mmv.CARER2_RELATIONSHIP ELSE h.CARER2_RELATIONSHIP END
					,CARER2_TYPE							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_TYPE = 1 THEN mmv.CARER2_TYPE ELSE h.CARER2_TYPE END
					,PT_AT_RISK								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PT_AT_RISK = 1 THEN mmv.PT_AT_RISK ELSE h.PT_AT_RISK END
					,REASON_RISK							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.REASON_RISK = 1 THEN mmv.REASON_RISK ELSE h.REASON_RISK END
					,GESTATION								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.GESTATION = 1 THEN mmv.GESTATION ELSE h.GESTATION END
					,CAUSE_OF_DEATH_UROLOGY					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CAUSE_OF_DEATH_UROLOGY = 1 THEN mmv.CAUSE_OF_DEATH_UROLOGY ELSE h.CAUSE_OF_DEATH_UROLOGY END
					,AVOIDABLE_DEATH						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.AVOIDABLE_DEATH = 1 THEN mmv.AVOIDABLE_DEATH ELSE h.AVOIDABLE_DEATH END
					,AVOIDABLE_DETAILS						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.AVOIDABLE_DETAILS = 1 THEN mmv.AVOIDABLE_DETAILS ELSE h.AVOIDABLE_DETAILS END
					,OTHER_DEATH_CAUSE_UROLOGY				= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.OTHER_DEATH_CAUSE_UROLOGY = 1 THEN mmv.OTHER_DEATH_CAUSE_UROLOGY ELSE h.OTHER_DEATH_CAUSE_UROLOGY END
					,ACTION_ID								= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.ACTION_ID = 1 THEN mmv.ACTION_ID ELSE h.ACTION_ID END
					,STATED_GENDER_CODE						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.STATED_GENDER_CODE = 1 THEN mmv.STATED_GENDER_CODE ELSE h.STATED_GENDER_CODE END
					,CAUSE_OF_DEATH_UROLOGY_FUP				= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CAUSE_OF_DEATH_UROLOGY_FUP = 1 THEN mmv.CAUSE_OF_DEATH_UROLOGY_FUP ELSE h.CAUSE_OF_DEATH_UROLOGY_FUP END
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_WITHIN_30_DAYS_OF_TREAT = 1 THEN mmv.DEATH_WITHIN_30_DAYS_OF_TREAT ELSE h.DEATH_WITHIN_30_DAYS_OF_TREAT END
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT = 1 THEN mmv.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT ELSE h.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT END
					,DEATH_CAUSE_LATER_DATE					= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_CAUSE_LATER_DATE = 1 THEN mmv.DEATH_CAUSE_LATER_DATE ELSE h.DEATH_CAUSE_LATER_DATE END
					,RegisteredPractice						= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RegisteredPractice = 1 THEN mmv.RegisteredPractice ELSE h.RegisteredPractice END
					,RegisteredGP							= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RegisteredGP = 1 THEN mmv.RegisteredGP ELSE h.RegisteredGP END
					,PersonSexualOrientation				= CASE WHEN (h.LastUpdated <= mmv.LastValidatedDttm OR h.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PersonSexualOrientation = 1 THEN mmv.PersonSexualOrientation ELSE h.PersonSexualOrientation END
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
															ON	mc.SrcSys_Major = h.SrcSys
															AND	mc.Src_UID_Major = h.Src_UID
															AND	h.SrcSys IN (1,2)
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																			ON	mc.SrcSys_Major = mmv.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv.Src_UID_Major
																			AND	mmv.ValidationStatus NOT IN ('All Matches Algorithmic') -- use this to stop column overrides for validation records with these statuses
		LEFT JOIN	Merge_DM_MatchViews.tblDEMOGRAPHICS_vw_Match_MajorValidationColumns mmvc
																							ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvc.Src_UID_Major
		WHERE		mc.IsMajor = 1
		AND			mc.IsMajorSCR = 1

		-- external majors
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
					,Src_UID_MajorExt						= mc.Src_UID_Major
					,SrcSys_Major							= mc.SrcSys
					,Src_UID_Major							= mc.Src_UID
					,IsValidatedMajor						= 1
					,IsConfirmed							= mc.IsConfirmed
					,LastUpdated							= h_CF.LastUpdated
					,SrcSys									= mc.SrcSys
					,Src_UID								= mc.Src_UID
					,PATIENT_ID								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PATIENT_ID = 1 THEN mmv.PATIENT_ID ELSE ISNULL(h_CF.PATIENT_ID, h_SCR.PATIENT_ID) END
					,N1_1_NHS_NUMBER						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_1_NHS_NUMBER = 1 THEN mmv.N1_1_NHS_NUMBER ELSE ISNULL(h_CF.N1_1_NHS_NUMBER,h_SCR.N1_1_NHS_NUMBER) END
					,NHS_NUMBER_STATUS						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NHS_NUMBER_STATUS = 1 THEN mmv.NHS_NUMBER_STATUS ELSE ISNULL(h_CF.NHS_NUMBER_STATUS, h_SCR.NHS_NUMBER_STATUS) END
					,L_RA3_RID								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RA3_RID = 1 THEN mmv.L_RA3_RID ELSE ISNULL(h_CF.L_RA3_RID, h_SCR.L_RA3_RID) END
					,L_RA7_RID								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RA7_RID = 1 THEN mmv.L_RA7_RID ELSE ISNULL(h_CF.L_RA7_RID, h_SCR.L_RA7_RID) END
					,L_RVJ01_RID							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_RVJ01_RID = 1 THEN mmv.L_RVJ01_RID ELSE ISNULL(h_CF.L_RVJ01_RID, h_SCR.L_RVJ01_RID) END
					,TEMP_ID								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.TEMP_ID = 1 THEN mmv.TEMP_ID ELSE ISNULL(h_CF.TEMP_ID, h_SCR.TEMP_ID) END
					,L_NSTS_STATUS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_NSTS_STATUS = 1 THEN mmv.L_NSTS_STATUS ELSE ISNULL(h_CF.L_NSTS_STATUS, h_SCR.L_NSTS_STATUS) END
					,N1_2_HOSPITAL_NUMBER					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_2_HOSPITAL_NUMBER = 1 THEN mmv.N1_2_HOSPITAL_NUMBER ELSE ISNULL(h_CF.N1_2_HOSPITAL_NUMBER, h_SCR.N1_2_HOSPITAL_NUMBER) END
					,L_TITLE								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_TITLE = 1 THEN mmv.L_TITLE ELSE ISNULL(h_CF.L_TITLE, h_SCR.L_TITLE) END
					,N1_5_SURNAME							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_5_SURNAME = 1 THEN mmv.N1_5_SURNAME ELSE ISNULL(h_CF.N1_5_SURNAME, h_SCR.N1_5_SURNAME) END
					,N1_6_FORENAME							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_6_FORENAME = 1 THEN mmv.N1_6_FORENAME ELSE ISNULL(h_CF.N1_6_FORENAME, h_SCR.N1_6_FORENAME) END
					,N1_7_ADDRESS_1							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_1 = 1 THEN mmv.N1_7_ADDRESS_1 WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_7_ADDRESS_1 ELSE h_SCR.N1_7_ADDRESS_1 END
					,N1_7_ADDRESS_2							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_2 = 1 THEN mmv.N1_7_ADDRESS_2 WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_7_ADDRESS_2 ELSE h_SCR.N1_7_ADDRESS_2 END
					,N1_7_ADDRESS_3							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_3 = 1 THEN mmv.N1_7_ADDRESS_3 WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_7_ADDRESS_3 ELSE h_SCR.N1_7_ADDRESS_3 END
					,N1_7_ADDRESS_4							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_4 = 1 THEN mmv.N1_7_ADDRESS_4 WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_7_ADDRESS_4 ELSE h_SCR.N1_7_ADDRESS_4 END
					,N1_7_ADDRESS_5							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_7_ADDRESS_5 = 1 THEN mmv.N1_7_ADDRESS_5 WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_7_ADDRESS_5 ELSE h_SCR.N1_7_ADDRESS_5 END
					,N1_8_POSTCODE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_8_POSTCODE = 1 THEN mmv.N1_8_POSTCODE WHEN COALESCE(h_CF.N1_7_ADDRESS_1,h_CF.N1_7_ADDRESS_2,h_CF.N1_7_ADDRESS_3,h_CF.N1_7_ADDRESS_4,h_CF.N1_7_ADDRESS_5,h_CF.N1_8_POSTCODE) IS NOT NULL THEN h_CF.N1_8_POSTCODE ELSE h_SCR.N1_8_POSTCODE END
					,N1_9_SEX								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_9_SEX = 1 THEN mmv.N1_9_SEX ELSE ISNULL(h_CF.N1_9_SEX, h_SCR.N1_9_SEX) END
					,N1_10_DATE_BIRTH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_10_DATE_BIRTH = 1 THEN mmv.N1_10_DATE_BIRTH ELSE ISNULL(h_CF.N1_10_DATE_BIRTH, h_SCR.N1_10_DATE_BIRTH) END
					,N1_11_GP_CODE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_11_GP_CODE = 1 THEN mmv.N1_11_GP_CODE ELSE ISNULL(h_CF.N1_11_GP_CODE, h_SCR.N1_11_GP_CODE) END
					,N1_12_GP_PRACTICE_CODE					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_12_GP_PRACTICE_CODE = 1 THEN mmv.N1_12_GP_PRACTICE_CODE ELSE ISNULL(h_CF.N1_12_GP_PRACTICE_CODE, h_SCR.N1_12_GP_PRACTICE_CODE) END
					,N1_13_PCT								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_13_PCT = 1 THEN mmv.N1_13_PCT ELSE ISNULL(h_CF.N1_13_PCT, h_SCR.N1_13_PCT) END
					,N1_14_SURNAME_BIRTH					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_14_SURNAME_BIRTH = 1 THEN mmv.N1_14_SURNAME_BIRTH ELSE ISNULL(h_CF.N1_14_SURNAME_BIRTH, h_SCR.N1_14_SURNAME_BIRTH) END
					,N1_15_ETHNICITY						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N1_15_ETHNICITY = 1 THEN mmv.N1_15_ETHNICITY ELSE ISNULL(h_CF.N1_15_ETHNICITY, h_SCR.N1_15_ETHNICITY) END
					,PAT_PREF_NAME							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_NAME = 1 THEN mmv.PAT_PREF_NAME ELSE ISNULL(h_CF.PAT_PREF_NAME, h_SCR.PAT_PREF_NAME) END
					,PAT_OCCUPATION							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_OCCUPATION = 1 THEN mmv.PAT_OCCUPATION ELSE ISNULL(h_CF.PAT_OCCUPATION, h_SCR.PAT_OCCUPATION) END
					,PAT_SOCIAL_CLASS						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_SOCIAL_CLASS = 1 THEN mmv.PAT_SOCIAL_CLASS ELSE ISNULL(h_CF.PAT_SOCIAL_CLASS, h_SCR.PAT_SOCIAL_CLASS) END
					,PAT_LIVES_ALONE						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_LIVES_ALONE = 1 THEN mmv.PAT_LIVES_ALONE ELSE ISNULL(h_CF.PAT_LIVES_ALONE, h_SCR.PAT_LIVES_ALONE) END
					,MARITAL_STATUS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.MARITAL_STATUS = 1 THEN mmv.MARITAL_STATUS ELSE ISNULL(h_CF.MARITAL_STATUS, h_SCR.MARITAL_STATUS) END
					,PAT_PREF_LANGUAGE						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_LANGUAGE = 1 THEN mmv.PAT_PREF_LANGUAGE ELSE ISNULL(h_CF.PAT_PREF_LANGUAGE, h_SCR.PAT_PREF_LANGUAGE) END
					,PAT_PREF_CONTACT						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_PREF_CONTACT = 1 THEN mmv.PAT_PREF_CONTACT ELSE ISNULL(h_CF.PAT_PREF_CONTACT, h_SCR.PAT_PREF_CONTACT) END
					,L_DEATH_STATUS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_DEATH_STATUS = 1 THEN mmv.L_DEATH_STATUS ELSE ISNULL(h_CF.L_DEATH_STATUS, h_SCR.L_DEATH_STATUS) END
					,N15_1_DATE_DEATH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_1_DATE_DEATH = 1 THEN mmv.N15_1_DATE_DEATH ELSE ISNULL(h_CF.N15_1_DATE_DEATH, h_SCR.N15_1_DATE_DEATH) END
					,N15_2_DEATH_LOCATION					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_2_DEATH_LOCATION = 1 THEN mmv.N15_2_DEATH_LOCATION ELSE ISNULL(h_CF.N15_2_DEATH_LOCATION, h_SCR.N15_2_DEATH_LOCATION) END
					,N15_3_DEATH_CAUSE						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_3_DEATH_CAUSE = 1 THEN mmv.N15_3_DEATH_CAUSE ELSE ISNULL(h_CF.N15_3_DEATH_CAUSE, h_SCR.N15_3_DEATH_CAUSE) END
					,N15_4_DEATH_CANCER						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_4_DEATH_CANCER = 1 THEN mmv.N15_4_DEATH_CANCER ELSE ISNULL(h_CF.N15_4_DEATH_CANCER, h_SCR.N15_4_DEATH_CANCER) END
					,N15_5_DEATH_CODE_1						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_5_DEATH_CODE_1 = 1 THEN mmv.N15_5_DEATH_CODE_1 ELSE ISNULL(h_CF.N15_5_DEATH_CODE_1, h_SCR.N15_5_DEATH_CODE_1) END
					,N15_6_DEATH_CODE_2						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_6_DEATH_CODE_2 = 1 THEN mmv.N15_6_DEATH_CODE_2 ELSE ISNULL(h_CF.N15_6_DEATH_CODE_2, h_SCR.N15_6_DEATH_CODE_2) END
					,N15_7_DEATH_CODE_3						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_7_DEATH_CODE_3 = 1 THEN mmv.N15_7_DEATH_CODE_3 ELSE ISNULL(h_CF.N15_7_DEATH_CODE_3, h_SCR.N15_7_DEATH_CODE_3) END
					,N15_8_DEATH_CODE_4						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_8_DEATH_CODE_4 = 1 THEN mmv.N15_8_DEATH_CODE_4 ELSE ISNULL(h_CF.N15_8_DEATH_CODE_4, h_SCR.N15_8_DEATH_CODE_4) END
					,N15_9_DEATH_DISCREPANCY				= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N15_9_DEATH_DISCREPANCY = 1 THEN mmv.N15_9_DEATH_DISCREPANCY ELSE ISNULL(h_CF.N15_9_DEATH_DISCREPANCY, h_SCR.N15_9_DEATH_DISCREPANCY) END
					,N_CC4_TOWN								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC4_TOWN = 1 THEN mmv.N_CC4_TOWN ELSE ISNULL(h_CF.N_CC4_TOWN, h_SCR.N_CC4_TOWN) END
					,N_CC5_COUNTRY							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC5_COUNTRY = 1 THEN mmv.N_CC5_COUNTRY ELSE ISNULL(h_CF.N_CC5_COUNTRY, h_SCR.N_CC5_COUNTRY) END
					,N_CC6_M_SURNAME						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC6_M_SURNAME = 1 THEN mmv.N_CC6_M_SURNAME ELSE ISNULL(h_CF.N_CC6_M_SURNAME, h_SCR.N_CC6_M_SURNAME) END
					,N_CC7_M_CLASS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC7_M_CLASS = 1 THEN mmv.N_CC7_M_CLASS ELSE ISNULL(h_CF.N_CC7_M_CLASS, h_SCR.N_CC7_M_CLASS) END
					,N_CC8_M_FORENAME						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC8_M_FORENAME = 1 THEN mmv.N_CC8_M_FORENAME ELSE ISNULL(h_CF.N_CC8_M_FORENAME, h_SCR.N_CC8_M_FORENAME) END
					,N_CC9_M_DOB							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC9_M_DOB = 1 THEN mmv.N_CC9_M_DOB ELSE ISNULL(h_CF.N_CC9_M_DOB, h_SCR.N_CC9_M_DOB) END
					,N_CC10_M_TOWN							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC10_M_TOWN = 1 THEN mmv.N_CC10_M_TOWN ELSE ISNULL(h_CF.N_CC10_M_TOWN, h_SCR.N_CC10_M_TOWN) END
					,N_CC11_M_COUNTRY						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC11_M_COUNTRY = 1 THEN mmv.N_CC11_M_COUNTRY ELSE ISNULL(h_CF.N_CC11_M_COUNTRY, h_SCR.N_CC11_M_COUNTRY) END
					,N_CC12_M_OCC							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC12_M_OCC = 1 THEN mmv.N_CC12_M_OCC ELSE ISNULL(h_CF.N_CC12_M_OCC, h_SCR.N_CC12_M_OCC) END
					,N_CC13_M_OCC_DIAG						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC13_M_OCC_DIAG = 1 THEN mmv.N_CC13_M_OCC_DIAG ELSE ISNULL(h_CF.N_CC13_M_OCC_DIAG, h_SCR.N_CC13_M_OCC_DIAG) END
					,N_CC6_F_SURNAME						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC6_F_SURNAME = 1 THEN mmv.N_CC6_F_SURNAME ELSE ISNULL(h_CF.N_CC6_F_SURNAME, h_SCR.N_CC6_F_SURNAME) END
					,N_CC7_F_CLASS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC7_F_CLASS = 1 THEN mmv.N_CC7_F_CLASS ELSE ISNULL(h_CF.N_CC7_F_CLASS, h_SCR.N_CC7_F_CLASS) END
					,N_CC8_F_FORENAME						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC8_F_FORENAME = 1 THEN mmv.N_CC8_F_FORENAME ELSE ISNULL(h_CF.N_CC8_F_FORENAME, h_SCR.N_CC8_F_FORENAME) END
					,N_CC9_F_DOB							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC9_F_DOB = 1 THEN mmv.N_CC9_F_DOB ELSE ISNULL(h_CF.N_CC9_F_DOB, h_SCR.N_CC9_F_DOB) END
					,N_CC10_F_TOWN							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC10_F_TOWN = 1 THEN mmv.N_CC10_F_TOWN ELSE ISNULL(h_CF.N_CC10_F_TOWN, h_SCR.N_CC10_F_TOWN) END
					,N_CC11_F_COUNTRY						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC11_F_COUNTRY = 1 THEN mmv.N_CC11_F_COUNTRY ELSE ISNULL(h_CF.N_CC11_F_COUNTRY, h_SCR.N_CC11_F_COUNTRY) END
					,N_CC12_F_OCC							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC12_F_OCC = 1 THEN mmv.N_CC12_F_OCC ELSE ISNULL(h_CF.N_CC12_F_OCC, h_SCR.N_CC12_F_OCC) END
					,N_CC13_F_OCC_DIAG						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC13_F_OCC_DIAG = 1 THEN mmv.N_CC13_F_OCC_DIAG ELSE ISNULL(h_CF.N_CC13_F_OCC_DIAG, h_SCR.N_CC13_F_OCC_DIAG) END
					,N_CC14_MULTI_BIRTH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.N_CC14_MULTI_BIRTH = 1 THEN mmv.N_CC14_MULTI_BIRTH ELSE ISNULL(h_CF.N_CC14_MULTI_BIRTH, h_SCR.N_CC14_MULTI_BIRTH) END
					,R_POST_MORTEM							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_POST_MORTEM = 1 THEN mmv.R_POST_MORTEM ELSE ISNULL(h_CF.R_POST_MORTEM, h_SCR.R_POST_MORTEM) END
					,R_DAY_PHONE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_DAY_PHONE = 1 THEN mmv.R_DAY_PHONE ELSE ISNULL(h_CF.R_DAY_PHONE, h_SCR.R_DAY_PHONE) END
					,DAY_PHONE_EXT							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DAY_PHONE_EXT = 1 THEN mmv.DAY_PHONE_EXT ELSE ISNULL(h_CF.DAY_PHONE_EXT, h_SCR.DAY_PHONE_EXT) END
					,R_EVE_PHONE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_EVE_PHONE = 1 THEN mmv.R_EVE_PHONE ELSE ISNULL(h_CF.R_EVE_PHONE, h_SCR.R_EVE_PHONE) END
					,EVE_PHONE_EXT							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.EVE_PHONE_EXT = 1 THEN mmv.EVE_PHONE_EXT ELSE ISNULL(h_CF.EVE_PHONE_EXT, h_SCR.EVE_PHONE_EXT) END
					,R_DEATH_TREATMENT						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_DEATH_TREATMENT = 1 THEN mmv.R_DEATH_TREATMENT ELSE ISNULL(h_CF.R_DEATH_TREATMENT, h_SCR.R_DEATH_TREATMENT) END
					,R_PM_DETAILS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.R_PM_DETAILS = 1 THEN mmv.R_PM_DETAILS ELSE ISNULL(h_CF.R_PM_DETAILS, h_SCR.R_PM_DETAILS) END
					,L_IATROGENIC_DEATH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_IATROGENIC_DEATH = 1 THEN mmv.L_IATROGENIC_DEATH ELSE ISNULL(h_CF.L_IATROGENIC_DEATH, h_SCR.L_IATROGENIC_DEATH) END
					,L_INFECTION_DEATH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_INFECTION_DEATH = 1 THEN mmv.L_INFECTION_DEATH ELSE ISNULL(h_CF.L_INFECTION_DEATH, h_SCR.L_INFECTION_DEATH) END
					,L_DEATH_COMMENTS						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.L_DEATH_COMMENTS = 1 THEN mmv.L_DEATH_COMMENTS ELSE ISNULL(h_CF.L_DEATH_COMMENTS, h_SCR.L_DEATH_COMMENTS) END
					,RELIGION								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RELIGION = 1 THEN mmv.RELIGION ELSE ISNULL(h_CF.RELIGION, h_SCR.RELIGION) END
					,CONTACT_DETAILS						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CONTACT_DETAILS = 1 THEN mmv.CONTACT_DETAILS ELSE ISNULL(h_CF.CONTACT_DETAILS, h_SCR.CONTACT_DETAILS) END
					,NOK_NAME								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_NAME = 1 THEN mmv.NOK_NAME ELSE ISNULL(h_CF.NOK_NAME, h_SCR.NOK_NAME) END
					,NOK_ADDRESS_1							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_1 = 1 THEN mmv.NOK_ADDRESS_1 ELSE ISNULL(h_CF.NOK_ADDRESS_1, h_SCR.NOK_ADDRESS_1) END
					,NOK_ADDRESS_2							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_2 = 1 THEN mmv.NOK_ADDRESS_2 ELSE ISNULL(h_CF.NOK_ADDRESS_2, h_SCR.NOK_ADDRESS_2) END
					,NOK_ADDRESS_3							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_3 = 1 THEN mmv.NOK_ADDRESS_3 ELSE ISNULL(h_CF.NOK_ADDRESS_3, h_SCR.NOK_ADDRESS_3) END
					,NOK_ADDRESS_4							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_4 = 1 THEN mmv.NOK_ADDRESS_4 ELSE ISNULL(h_CF.NOK_ADDRESS_4, h_SCR.NOK_ADDRESS_4) END
					,NOK_ADDRESS_5							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_ADDRESS_5 = 1 THEN mmv.NOK_ADDRESS_5 ELSE ISNULL(h_CF.NOK_ADDRESS_5, h_SCR.NOK_ADDRESS_5) END
					,NOK_POSTCODE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_POSTCODE = 1 THEN mmv.NOK_POSTCODE ELSE ISNULL(h_CF.NOK_POSTCODE, h_SCR.NOK_POSTCODE) END
					,NOK_CONTACT							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_CONTACT = 1 THEN mmv.NOK_CONTACT ELSE ISNULL(h_CF.NOK_CONTACT, h_SCR.NOK_CONTACT) END
					,NOK_RELATIONSHIP						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.NOK_RELATIONSHIP = 1 THEN mmv.NOK_RELATIONSHIP ELSE ISNULL(h_CF.NOK_RELATIONSHIP, h_SCR.NOK_RELATIONSHIP) END
					,PAT_DEPENDANTS							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PAT_DEPENDANTS = 1 THEN mmv.PAT_DEPENDANTS ELSE ISNULL(h_CF.PAT_DEPENDANTS, h_SCR.PAT_DEPENDANTS) END
					,CARER_NAME								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_NAME = 1 THEN mmv.CARER_NAME ELSE ISNULL(h_CF.CARER_NAME, h_SCR.CARER_NAME) END
					,CARER_ADDRESS_1						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_1 = 1 THEN mmv.CARER_ADDRESS_1 ELSE ISNULL(h_CF.CARER_ADDRESS_1, h_SCR.CARER_ADDRESS_1) END
					,CARER_ADDRESS_2						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_2 = 1 THEN mmv.CARER_ADDRESS_2 ELSE ISNULL(h_CF.CARER_ADDRESS_2, h_SCR.CARER_ADDRESS_2) END
					,CARER_ADDRESS_3						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_3 = 1 THEN mmv.CARER_ADDRESS_3 ELSE ISNULL(h_CF.CARER_ADDRESS_3, h_SCR.CARER_ADDRESS_3) END
					,CARER_ADDRESS_4						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_4 = 1 THEN mmv.CARER_ADDRESS_4 ELSE ISNULL(h_CF.CARER_ADDRESS_4, h_SCR.CARER_ADDRESS_4) END
					,CARER_ADDRESS_5						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_ADDRESS_5 = 1 THEN mmv.CARER_ADDRESS_5 ELSE ISNULL(h_CF.CARER_ADDRESS_5, h_SCR.CARER_ADDRESS_5) END
					,CARER_POSTCODE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_POSTCODE = 1 THEN mmv.CARER_POSTCODE ELSE ISNULL(h_CF.CARER_POSTCODE, h_SCR.CARER_POSTCODE) END
					,CARER_CONTACT							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_CONTACT = 1 THEN mmv.CARER_CONTACT ELSE ISNULL(h_CF.CARER_CONTACT, h_SCR.CARER_CONTACT) END
					,CARER_RELATIONSHIP						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER_RELATIONSHIP = 1 THEN mmv.CARER_RELATIONSHIP ELSE ISNULL(h_CF.CARER_RELATIONSHIP, h_SCR.CARER_RELATIONSHIP) END
					,CARER1_TYPE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER1_TYPE = 1 THEN mmv.CARER1_TYPE ELSE ISNULL(h_CF.CARER1_TYPE, h_SCR.CARER1_TYPE) END
					,CARER2_NAME							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_NAME = 1 THEN mmv.CARER2_NAME ELSE ISNULL(h_CF.CARER2_NAME, h_SCR.CARER2_NAME) END
					,CARER2_ADDRESS_1						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_1 = 1 THEN mmv.CARER2_ADDRESS_1 ELSE ISNULL(h_CF.CARER2_ADDRESS_1, h_SCR.CARER2_ADDRESS_1) END
					,CARER2_ADDRESS_2						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_2 = 1 THEN mmv.CARER2_ADDRESS_2 ELSE ISNULL(h_CF.CARER2_ADDRESS_2, h_SCR.CARER2_ADDRESS_2) END
					,CARER2_ADDRESS_3						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_3 = 1 THEN mmv.CARER2_ADDRESS_3 ELSE ISNULL(h_CF.CARER2_ADDRESS_3, h_SCR.CARER2_ADDRESS_3) END
					,CARER2_ADDRESS_4						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_4 = 1 THEN mmv.CARER2_ADDRESS_4 ELSE ISNULL(h_CF.CARER2_ADDRESS_4, h_SCR.CARER2_ADDRESS_4) END
					,CARER2_ADDRESS_5						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_ADDRESS_5 = 1 THEN mmv.CARER2_ADDRESS_5 ELSE ISNULL(h_CF.CARER2_ADDRESS_5, h_SCR.CARER2_ADDRESS_5) END
					,CARER2_POSTCODE						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_POSTCODE = 1 THEN mmv.CARER2_POSTCODE ELSE ISNULL(h_CF.CARER2_POSTCODE, h_SCR.CARER2_POSTCODE) END
					,CARER2_CONTACT							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_CONTACT = 1 THEN mmv.CARER2_CONTACT ELSE ISNULL(h_CF.CARER2_CONTACT, h_SCR.CARER2_CONTACT) END
					,CARER2_RELATIONSHIP					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_RELATIONSHIP = 1 THEN mmv.CARER2_RELATIONSHIP ELSE ISNULL(h_CF.CARER2_RELATIONSHIP, h_SCR.CARER2_RELATIONSHIP) END
					,CARER2_TYPE							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CARER2_TYPE = 1 THEN mmv.CARER2_TYPE ELSE ISNULL(h_CF.CARER2_TYPE, h_SCR.CARER2_TYPE) END
					,PT_AT_RISK								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PT_AT_RISK = 1 THEN mmv.PT_AT_RISK ELSE ISNULL(h_CF.PT_AT_RISK, h_SCR.PT_AT_RISK) END
					,REASON_RISK							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.REASON_RISK = 1 THEN mmv.REASON_RISK ELSE ISNULL(h_CF.REASON_RISK, h_SCR.REASON_RISK) END
					,GESTATION								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.GESTATION = 1 THEN mmv.GESTATION ELSE ISNULL(h_CF.GESTATION, h_SCR.GESTATION) END
					,CAUSE_OF_DEATH_UROLOGY					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CAUSE_OF_DEATH_UROLOGY = 1 THEN mmv.CAUSE_OF_DEATH_UROLOGY ELSE ISNULL(h_CF.CAUSE_OF_DEATH_UROLOGY, h_SCR.CAUSE_OF_DEATH_UROLOGY) END
					,AVOIDABLE_DEATH						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.AVOIDABLE_DEATH = 1 THEN mmv.AVOIDABLE_DEATH ELSE ISNULL(h_CF.AVOIDABLE_DEATH, h_SCR.AVOIDABLE_DEATH) END
					,AVOIDABLE_DETAILS						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.AVOIDABLE_DETAILS = 1 THEN mmv.AVOIDABLE_DETAILS ELSE ISNULL(h_CF.AVOIDABLE_DETAILS, h_SCR.AVOIDABLE_DETAILS) END
					,OTHER_DEATH_CAUSE_UROLOGY				= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.OTHER_DEATH_CAUSE_UROLOGY = 1 THEN mmv.OTHER_DEATH_CAUSE_UROLOGY ELSE ISNULL(h_CF.OTHER_DEATH_CAUSE_UROLOGY, h_SCR.OTHER_DEATH_CAUSE_UROLOGY) END
					,ACTION_ID								= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.ACTION_ID = 1 THEN mmv.ACTION_ID ELSE ISNULL(h_CF.ACTION_ID, h_SCR.ACTION_ID) END
					,STATED_GENDER_CODE						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.STATED_GENDER_CODE = 1 THEN mmv.STATED_GENDER_CODE ELSE ISNULL(h_CF.STATED_GENDER_CODE, h_SCR.STATED_GENDER_CODE) END
					,CAUSE_OF_DEATH_UROLOGY_FUP				= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.CAUSE_OF_DEATH_UROLOGY_FUP = 1 THEN mmv.CAUSE_OF_DEATH_UROLOGY_FUP ELSE ISNULL(h_CF.CAUSE_OF_DEATH_UROLOGY_FUP, h_SCR.CAUSE_OF_DEATH_UROLOGY_FUP) END
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_WITHIN_30_DAYS_OF_TREAT = 1 THEN mmv.DEATH_WITHIN_30_DAYS_OF_TREAT ELSE ISNULL(h_CF.DEATH_WITHIN_30_DAYS_OF_TREAT, h_SCR.DEATH_WITHIN_30_DAYS_OF_TREAT) END
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT = 1 THEN mmv.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT ELSE ISNULL(h_CF.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT, h_SCR.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT) END
					,DEATH_CAUSE_LATER_DATE					= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.DEATH_CAUSE_LATER_DATE = 1 THEN mmv.DEATH_CAUSE_LATER_DATE ELSE ISNULL(h_CF.DEATH_CAUSE_LATER_DATE, h_SCR.DEATH_CAUSE_LATER_DATE) END
					,RegisteredPractice						= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RegisteredPractice = 1 THEN mmv.RegisteredPractice ELSE ISNULL(h_CF.RegisteredPractice, h_SCR.RegisteredPractice) END
					,RegisteredGP							= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.RegisteredGP = 1 THEN mmv.RegisteredGP ELSE ISNULL(h_CF.RegisteredGP, h_SCR.RegisteredGP) END
					,PersonSexualOrientation				= CASE WHEN (h_CF.LastUpdated <= mmv.LastValidatedDttm OR h_CF.LastUpdated IS NULL OR mmv.LastValidatedDttm IS NULL) AND mmvc.PersonSexualOrientation = 1 THEN mmv.PersonSexualOrientation ELSE ISNULL(h_CF.PersonSexualOrientation, h_SCR.PersonSexualOrientation) END
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_CF
																ON	mc.SrcSys_Major = h_CF.SrcSys
																AND	mc.Src_UID_Major = h_CF.Src_UID
																AND	h_CF.SrcSys = 3
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h_SCR
																ON	mc.SrcSys = h_SCR.SrcSys
																AND	mc.Src_UID = h_SCR.Src_UID
																AND	h_SCR.SrcSys IN (1,2)
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidation mmv
																			ON	mc.SrcSys_Major = mmv.SrcSys_Major
																			AND	mc.Src_UID_Major = mmv.Src_UID_Major
																			AND	mmv.ValidationStatus NOT IN ('All Matches Algorithmic') -- use this to stop column overrides for validation records with these statuses
		LEFT JOIN	Merge_DM_MatchViews.tblDEMOGRAPHICS_vw_Match_MajorValidationColumns mmvc
																							ON	mmv.SrcSys_Major = mmvc.SrcSys_Major
																							AND	mmv.Src_UID_Major = mmvc.Src_UID_Major
		WHERE		mc.IsMajorSCR = 0
		AND			mc.mcIx = 1

		-- unconfirmed minors 
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
					,Src_UID_MajorExt						= mc.Src_UID_Major
					,SrcSys_Major							= mc.SrcSys
					,Src_UID_Major							= mc.Src_UID
					,IsValidatedMajor						= 0
					,IsConfirmed							= mc.IsConfirmed
					,LastUpdated							= h.LastUpdated
					,SrcSys									= mc.SrcSys
					,Src_UID								= mc.Src_UID
					,PATIENT_ID								= h.PATIENT_ID							
					,N1_1_NHS_NUMBER						= h.N1_1_NHS_NUMBER					
					,NHS_NUMBER_STATUS						= h.NHS_NUMBER_STATUS					
					,L_RA3_RID								= h.L_RA3_RID							
					,L_RA7_RID								= h.L_RA7_RID							
					,L_RVJ01_RID							= h.L_RVJ01_RID						
					,TEMP_ID								= h.TEMP_ID							
					,L_NSTS_STATUS							= h.L_NSTS_STATUS						
					,N1_2_HOSPITAL_NUMBER					= h.N1_2_HOSPITAL_NUMBER				
					,L_TITLE								= h.L_TITLE							
					,N1_5_SURNAME							= h.N1_5_SURNAME						
					,N1_6_FORENAME							= h.N1_6_FORENAME						
					,N1_7_ADDRESS_1							= h.N1_7_ADDRESS_1						
					,N1_7_ADDRESS_2							= h.N1_7_ADDRESS_2						
					,N1_7_ADDRESS_3							= h.N1_7_ADDRESS_3						
					,N1_7_ADDRESS_4							= h.N1_7_ADDRESS_4						
					,N1_7_ADDRESS_5							= h.N1_7_ADDRESS_5						
					,N1_8_POSTCODE							= h.N1_8_POSTCODE						
					,N1_9_SEX								= h.N1_9_SEX							
					,N1_10_DATE_BIRTH						= h.N1_10_DATE_BIRTH					
					,N1_11_GP_CODE							= h.N1_11_GP_CODE						
					,N1_12_GP_PRACTICE_CODE					= h.N1_12_GP_PRACTICE_CODE				
					,N1_13_PCT								= h.N1_13_PCT							
					,N1_14_SURNAME_BIRTH					= h.N1_14_SURNAME_BIRTH				
					,N1_15_ETHNICITY						= h.N1_15_ETHNICITY					
					,PAT_PREF_NAME							= h.PAT_PREF_NAME						
					,PAT_OCCUPATION							= h.PAT_OCCUPATION						
					,PAT_SOCIAL_CLASS						= h.PAT_SOCIAL_CLASS					
					,PAT_LIVES_ALONE						= h.PAT_LIVES_ALONE					
					,MARITAL_STATUS							= h.MARITAL_STATUS						
					,PAT_PREF_LANGUAGE						= h.PAT_PREF_LANGUAGE					
					,PAT_PREF_CONTACT						= h.PAT_PREF_CONTACT					
					,L_DEATH_STATUS							= h.L_DEATH_STATUS						
					,N15_1_DATE_DEATH						= h.N15_1_DATE_DEATH					
					,N15_2_DEATH_LOCATION					= h.N15_2_DEATH_LOCATION				
					,N15_3_DEATH_CAUSE						= h.N15_3_DEATH_CAUSE					
					,N15_4_DEATH_CANCER						= h.N15_4_DEATH_CANCER					
					,N15_5_DEATH_CODE_1						= h.N15_5_DEATH_CODE_1					
					,N15_6_DEATH_CODE_2						= h.N15_6_DEATH_CODE_2					
					,N15_7_DEATH_CODE_3						= h.N15_7_DEATH_CODE_3					
					,N15_8_DEATH_CODE_4						= h.N15_8_DEATH_CODE_4					
					,N15_9_DEATH_DISCREPANCY				= h.N15_9_DEATH_DISCREPANCY			
					,N_CC4_TOWN								= h.N_CC4_TOWN							
					,N_CC5_COUNTRY							= h.N_CC5_COUNTRY						
					,N_CC6_M_SURNAME						= h.N_CC6_M_SURNAME					
					,N_CC7_M_CLASS							= h.N_CC7_M_CLASS						
					,N_CC8_M_FORENAME						= h.N_CC8_M_FORENAME					
					,N_CC9_M_DOB							= h.N_CC9_M_DOB						
					,N_CC10_M_TOWN							= h.N_CC10_M_TOWN						
					,N_CC11_M_COUNTRY						= h.N_CC11_M_COUNTRY					
					,N_CC12_M_OCC							= h.N_CC12_M_OCC						
					,N_CC13_M_OCC_DIAG						= h.N_CC13_M_OCC_DIAG					
					,N_CC6_F_SURNAME						= h.N_CC6_F_SURNAME					
					,N_CC7_F_CLASS							= h.N_CC7_F_CLASS						
					,N_CC8_F_FORENAME						= h.N_CC8_F_FORENAME					
					,N_CC9_F_DOB							= h.N_CC9_F_DOB						
					,N_CC10_F_TOWN							= h.N_CC10_F_TOWN						
					,N_CC11_F_COUNTRY						= h.N_CC11_F_COUNTRY					
					,N_CC12_F_OCC							= h.N_CC12_F_OCC						
					,N_CC13_F_OCC_DIAG						= h.N_CC13_F_OCC_DIAG					
					,N_CC14_MULTI_BIRTH						= h.N_CC14_MULTI_BIRTH					
					,R_POST_MORTEM							= h.R_POST_MORTEM						
					,R_DAY_PHONE							= h.R_DAY_PHONE						
					,DAY_PHONE_EXT							= h.DAY_PHONE_EXT						
					,R_EVE_PHONE							= h.R_EVE_PHONE						
					,EVE_PHONE_EXT							= h.EVE_PHONE_EXT						
					,R_DEATH_TREATMENT						= h.R_DEATH_TREATMENT					
					,R_PM_DETAILS							= h.R_PM_DETAILS						
					,L_IATROGENIC_DEATH						= h.L_IATROGENIC_DEATH					
					,L_INFECTION_DEATH						= h.L_INFECTION_DEATH					
					,L_DEATH_COMMENTS						= h.L_DEATH_COMMENTS					
					,RELIGION								= h.RELIGION							
					,CONTACT_DETAILS						= h.CONTACT_DETAILS					
					,NOK_NAME								= h.NOK_NAME							
					,NOK_ADDRESS_1							= h.NOK_ADDRESS_1						
					,NOK_ADDRESS_2							= h.NOK_ADDRESS_2						
					,NOK_ADDRESS_3							= h.NOK_ADDRESS_3						
					,NOK_ADDRESS_4							= h.NOK_ADDRESS_4						
					,NOK_ADDRESS_5							= h.NOK_ADDRESS_5						
					,NOK_POSTCODE							= h.NOK_POSTCODE						
					,NOK_CONTACT							= h.NOK_CONTACT						
					,NOK_RELATIONSHIP						= h.NOK_RELATIONSHIP					
					,PAT_DEPENDANTS							= h.PAT_DEPENDANTS						
					,CARER_NAME								= h.CARER_NAME							
					,CARER_ADDRESS_1						= h.CARER_ADDRESS_1					
					,CARER_ADDRESS_2						= h.CARER_ADDRESS_2					
					,CARER_ADDRESS_3						= h.CARER_ADDRESS_3					
					,CARER_ADDRESS_4						= h.CARER_ADDRESS_4					
					,CARER_ADDRESS_5						= h.CARER_ADDRESS_5					
					,CARER_POSTCODE							= h.CARER_POSTCODE						
					,CARER_CONTACT							= h.CARER_CONTACT						
					,CARER_RELATIONSHIP						= h.CARER_RELATIONSHIP					
					,CARER1_TYPE							= h.CARER1_TYPE						
					,CARER2_NAME							= h.CARER2_NAME						
					,CARER2_ADDRESS_1						= h.CARER2_ADDRESS_1					
					,CARER2_ADDRESS_2						= h.CARER2_ADDRESS_2					
					,CARER2_ADDRESS_3						= h.CARER2_ADDRESS_3					
					,CARER2_ADDRESS_4						= h.CARER2_ADDRESS_4					
					,CARER2_ADDRESS_5						= h.CARER2_ADDRESS_5					
					,CARER2_POSTCODE						= h.CARER2_POSTCODE					
					,CARER2_CONTACT							= h.CARER2_CONTACT						
					,CARER2_RELATIONSHIP					= h.CARER2_RELATIONSHIP				
					,CARER2_TYPE							= h.CARER2_TYPE						
					,PT_AT_RISK								= h.PT_AT_RISK							
					,REASON_RISK							= h.REASON_RISK						
					,GESTATION								= h.GESTATION							
					,CAUSE_OF_DEATH_UROLOGY					= h.CAUSE_OF_DEATH_UROLOGY				
					,AVOIDABLE_DEATH						= h.AVOIDABLE_DEATH					
					,AVOIDABLE_DETAILS						= h.AVOIDABLE_DETAILS					
					,OTHER_DEATH_CAUSE_UROLOGY				= h.OTHER_DEATH_CAUSE_UROLOGY			
					,ACTION_ID								= h.ACTION_ID							
					,STATED_GENDER_CODE						= h.STATED_GENDER_CODE					
					,CAUSE_OF_DEATH_UROLOGY_FUP				= h.CAUSE_OF_DEATH_UROLOGY_FUP			
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= h.DEATH_WITHIN_30_DAYS_OF_TREAT		
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= h.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_LATER_DATE					= h.DEATH_CAUSE_LATER_DATE				
					,RegisteredPractice						= h.RegisteredPractice					
					,RegisteredGP							= h.RegisteredGP						
					,PersonSexualOrientation				= h.PersonSexualOrientation			
		FROM		#mcIx mc
		INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
															ON	mc.SrcSys = h.SrcSys
															AND	mc.Src_UID = h.Src_UID
															AND	h.SrcSys IN (1,2)
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		mc.IsConfirmed = 0
		AND			vd.SrcSys IS NULL
		
		-- Create an index on the temporary match control table		--	DECLARE @NewID VARCHAR(255) SELECT @NewID = CAST(NEWID() AS VARCHAR(255))
		DECLARE @SQL_vd VARCHAR(MAX)
		SET @SQL_vd = 'CREATE UNIQUE CLUSTERED INDEX [PK_vdIx_' + @NewID + '] ON #ValidatedData (SrcSys ASC, Src_UID ASC)'; PRINT @SQL_vd; EXEC (@SQL_vd)
		SET @SQL_vd = 'CREATE NONCLUSTERED INDEX [Ix_vdIx_Major_' + @NewID + '] ON #ValidatedData (SrcSys_Major ASC, Src_UID_Major)'; PRINT @SQL_vd; EXEC (@SQL_vd)
		SET @SQL_vd = 'CREATE NONCLUSTERED INDEX [Ix_vdIx_MajorExt_' + @NewID + '] ON #ValidatedData (SrcSys_MajorExt ASC, Src_UID_MajorExt)'; PRINT @SQL_vd; EXEC (@SQL_vd)


		-- minors that are left
		INSERT INTO	#ValidatedData
					(SrcSys_MajorExt
					,Src_UID_MajorExt
					,SrcSys_Major
					,Src_UID_Major
					,IsValidatedMajor
					,IsConfirmed
					,LastUpdated
					,SrcSys
					,Src_UID
					)
		SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
					,Src_UID_MajorExt						= mc.Src_UID_Major
					,SrcSys_Major							= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
					,Src_UID_Major							= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
					,IsValidatedMajor						= 0
					,IsConfirmed							= mc.IsConfirmed
					,LastUpdated							= mc.LastUpdated
					,SrcSys									= mc.SrcSys
					,Src_UID								= mc.Src_UID
		FROM		#mcIx mc
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		LEFT JOIN	#mcIx mc_1st
								ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
								AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
								AND	mc_1st.IsMajorSCR = 0
								AND	mc_1st.mcIx = 1
		WHERE		vd.SrcSys IS NULL

		-- SCR records that aren't in the match control table (if we are creating a bulk dataset)
		IF @HasRelatedEntities = 0
		INSERT INTO	#ValidatedData
		SELECT		SrcSys_MajorExt							= h.SrcSys
					,Src_UID_MajorExt						= h.Src_UID
					,SrcSys_Major							= h.SrcSys
					,Src_UID_Major							= h.Src_UID
					,IsValidatedMajor						= 0
					,IsConfirmed							= 0
					,LastUpdated							= h.LastUpdated
					,SrcSys									= h.SrcSys
					,Src_UID								= h.Src_UID

					,PATIENT_ID								= h.PATIENT_ID
					,N1_1_NHS_NUMBER						= h.N1_1_NHS_NUMBER
					,NHS_NUMBER_STATUS						= h.NHS_NUMBER_STATUS
					,L_RA3_RID								= h.L_RA3_RID
					,L_RA7_RID								= h.L_RA7_RID
					,L_RVJ01_RID							= h.L_RVJ01_RID
					,TEMP_ID								= h.TEMP_ID
					,L_NSTS_STATUS							= h.L_NSTS_STATUS
					,N1_2_HOSPITAL_NUMBER					= h.N1_2_HOSPITAL_NUMBER
					,L_TITLE								= h.L_TITLE
					,N1_5_SURNAME							= h.N1_5_SURNAME
					,N1_6_FORENAME							= h.N1_6_FORENAME
					,N1_7_ADDRESS_1							= h.N1_7_ADDRESS_1
					,N1_7_ADDRESS_2							= h.N1_7_ADDRESS_2
					,N1_7_ADDRESS_3							= h.N1_7_ADDRESS_3
					,N1_7_ADDRESS_4							= h.N1_7_ADDRESS_4
					,N1_7_ADDRESS_5							= h.N1_7_ADDRESS_5
					,N1_8_POSTCODE							= h.N1_8_POSTCODE
					,N1_9_SEX								= h.N1_9_SEX
					,N1_10_DATE_BIRTH						= h.N1_10_DATE_BIRTH
					,N1_11_GP_CODE							= h.N1_11_GP_CODE
					,N1_12_GP_PRACTICE_CODE					= h.N1_12_GP_PRACTICE_CODE
					,N1_13_PCT								= h.N1_13_PCT
					,N1_14_SURNAME_BIRTH					= h.N1_14_SURNAME_BIRTH
					,N1_15_ETHNICITY						= h.N1_15_ETHNICITY
					,PAT_PREF_NAME							= h.PAT_PREF_NAME
					,PAT_OCCUPATION							= h.PAT_OCCUPATION
					,PAT_SOCIAL_CLASS						= h.PAT_SOCIAL_CLASS
					,PAT_LIVES_ALONE						= h.PAT_LIVES_ALONE
					,MARITAL_STATUS							= h.MARITAL_STATUS
					,PAT_PREF_LANGUAGE						= h.PAT_PREF_LANGUAGE
					,PAT_PREF_CONTACT						= h.PAT_PREF_CONTACT
					,L_DEATH_STATUS							= h.L_DEATH_STATUS
					,N15_1_DATE_DEATH						= h.N15_1_DATE_DEATH
					,N15_2_DEATH_LOCATION					= h.N15_2_DEATH_LOCATION
					,N15_3_DEATH_CAUSE						= h.N15_3_DEATH_CAUSE
					,N15_4_DEATH_CANCER						= h.N15_4_DEATH_CANCER
					,N15_5_DEATH_CODE_1						= h.N15_5_DEATH_CODE_1
					,N15_6_DEATH_CODE_2						= h.N15_6_DEATH_CODE_2
					,N15_7_DEATH_CODE_3						= h.N15_7_DEATH_CODE_3
					,N15_8_DEATH_CODE_4						= h.N15_8_DEATH_CODE_4
					,N15_9_DEATH_DISCREPANCY				= h.N15_9_DEATH_DISCREPANCY
					,N_CC4_TOWN								= h.N_CC4_TOWN
					,N_CC5_COUNTRY							= h.N_CC5_COUNTRY
					,N_CC6_M_SURNAME						= h.N_CC6_M_SURNAME
					,N_CC7_M_CLASS							= h.N_CC7_M_CLASS
					,N_CC8_M_FORENAME						= h.N_CC8_M_FORENAME
					,N_CC9_M_DOB							= h.N_CC9_M_DOB
					,N_CC10_M_TOWN							= h.N_CC10_M_TOWN
					,N_CC11_M_COUNTRY						= h.N_CC11_M_COUNTRY
					,N_CC12_M_OCC							= h.N_CC12_M_OCC
					,N_CC13_M_OCC_DIAG						= h.N_CC13_M_OCC_DIAG
					,N_CC6_F_SURNAME						= h.N_CC6_F_SURNAME
					,N_CC7_F_CLASS							= h.N_CC7_F_CLASS
					,N_CC8_F_FORENAME						= h.N_CC8_F_FORENAME
					,N_CC9_F_DOB							= h.N_CC9_F_DOB
					,N_CC10_F_TOWN							= h.N_CC10_F_TOWN
					,N_CC11_F_COUNTRY						= h.N_CC11_F_COUNTRY
					,N_CC12_F_OCC							= h.N_CC12_F_OCC
					,N_CC13_F_OCC_DIAG						= h.N_CC13_F_OCC_DIAG
					,N_CC14_MULTI_BIRTH						= h.N_CC14_MULTI_BIRTH
					,R_POST_MORTEM							= h.R_POST_MORTEM
					,R_DAY_PHONE							= h.R_DAY_PHONE
					,DAY_PHONE_EXT							= h.DAY_PHONE_EXT
					,R_EVE_PHONE							= h.R_EVE_PHONE
					,EVE_PHONE_EXT							= h.EVE_PHONE_EXT
					,R_DEATH_TREATMENT						= h.R_DEATH_TREATMENT
					,R_PM_DETAILS							= h.R_PM_DETAILS
					,L_IATROGENIC_DEATH						= h.L_IATROGENIC_DEATH
					,L_INFECTION_DEATH						= h.L_INFECTION_DEATH
					,L_DEATH_COMMENTS						= h.L_DEATH_COMMENTS
					,RELIGION								= h.RELIGION
					,CONTACT_DETAILS						= h.CONTACT_DETAILS
					,NOK_NAME								= h.NOK_NAME
					,NOK_ADDRESS_1							= h.NOK_ADDRESS_1
					,NOK_ADDRESS_2							= h.NOK_ADDRESS_2
					,NOK_ADDRESS_3							= h.NOK_ADDRESS_3
					,NOK_ADDRESS_4							= h.NOK_ADDRESS_4
					,NOK_ADDRESS_5							= h.NOK_ADDRESS_5
					,NOK_POSTCODE							= h.NOK_POSTCODE
					,NOK_CONTACT							= h.NOK_CONTACT
					,NOK_RELATIONSHIP						= h.NOK_RELATIONSHIP
					,PAT_DEPENDANTS							= h.PAT_DEPENDANTS
					,CARER_NAME								= h.CARER_NAME
					,CARER_ADDRESS_1						= h.CARER_ADDRESS_1
					,CARER_ADDRESS_2						= h.CARER_ADDRESS_2
					,CARER_ADDRESS_3						= h.CARER_ADDRESS_3
					,CARER_ADDRESS_4						= h.CARER_ADDRESS_4
					,CARER_ADDRESS_5						= h.CARER_ADDRESS_5
					,CARER_POSTCODE							= h.CARER_POSTCODE
					,CARER_CONTACT							= h.CARER_CONTACT
					,CARER_RELATIONSHIP						= h.CARER_RELATIONSHIP
					,CARER1_TYPE							= h.CARER1_TYPE
					,CARER2_NAME							= h.CARER2_NAME
					,CARER2_ADDRESS_1						= h.CARER2_ADDRESS_1
					,CARER2_ADDRESS_2						= h.CARER2_ADDRESS_2
					,CARER2_ADDRESS_3						= h.CARER2_ADDRESS_3
					,CARER2_ADDRESS_4						= h.CARER2_ADDRESS_4
					,CARER2_ADDRESS_5						= h.CARER2_ADDRESS_5
					,CARER2_POSTCODE						= h.CARER2_POSTCODE
					,CARER2_CONTACT							= h.CARER2_CONTACT
					,CARER2_RELATIONSHIP					= h.CARER2_RELATIONSHIP
					,CARER2_TYPE							= h.CARER2_TYPE
					,PT_AT_RISK								= h.PT_AT_RISK
					,REASON_RISK							= h.REASON_RISK
					,GESTATION								= h.GESTATION
					,CAUSE_OF_DEATH_UROLOGY					= h.CAUSE_OF_DEATH_UROLOGY
					,AVOIDABLE_DEATH						= h.AVOIDABLE_DEATH
					,AVOIDABLE_DETAILS						= h.AVOIDABLE_DETAILS
					,OTHER_DEATH_CAUSE_UROLOGY				= h.OTHER_DEATH_CAUSE_UROLOGY
					,ACTION_ID								= h.ACTION_ID
					,STATED_GENDER_CODE						= h.STATED_GENDER_CODE
					,CAUSE_OF_DEATH_UROLOGY_FUP				= h.CAUSE_OF_DEATH_UROLOGY_FUP
					,DEATH_WITHIN_30_DAYS_OF_TREAT			= h.DEATH_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= h.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
					,DEATH_CAUSE_LATER_DATE					= h.DEATH_CAUSE_LATER_DATE
					,RegisteredPractice						= h.RegisteredPractice
					,RegisteredGP							= h.RegisteredGP
					,PersonSexualOrientation				= h.PersonSexualOrientation
		FROM		Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
		LEFT JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																ON	h.SrcSys = mc.SrcSys
																AND	h.Src_UID = mc.Src_UID
		LEFT JOIN	#ValidatedData vd
									ON	mc.SrcSys = vd.SrcSys
									AND	mc.Src_UID = vd.Src_UID
		WHERE		(mc.SrcSys IS NULL
		OR			vd.SrcSys IS NULL)
		AND			h.SrcSys IN (1,2)



/*********************************************************************************************************************************************************************************************************************************************************************************/
-- Make post-merge corrections
/*********************************************************************************************************************************************************************************************************************************************************************************/

		-- Only run the NHS number status correction if there are records to correct
		IF	(SELECT		COUNT(*)
			FROM		#ValidatedData vd  -- Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData vd
			LEFT JOIN	#RelatedEntities re
											ON	vd.SrcSys = re.SrcSys
											AND	vd.Src_UID = re.Src_UID
			WHERE		vd.N1_1_NHS_NUMBER IS NOT NULL
			AND			vd.NHS_NUMBER_STATUS IS NULL
			AND			(re.SrcSys IS NOT NULL
			OR			@HasRelatedEntities = 0)
			) > 0

		BEGIN
		
				-- Create the table of NHS number status values to update back into #ValidatedData where the NHS number status is missing
				IF OBJECT_ID('tempdb..#ReplacementNhsNoStatus') IS NOT NULL DROP TABLE #ReplacementNhsNoStatus
				SELECT		vd.SrcSys
							,vd.Src_UID
							,UH.NHS_NUMBER_STATUS
							,ROW_NUMBER() OVER	(PARTITION BY	vd.SrcSys
																,vd.Src_UID
												ORDER BY		CASE UH.NHS_NUMBER_STATUS
																WHEN '01' THEN 1
																WHEN '07' THEN 2
																WHEN '06' THEN 3
																WHEN '08' THEN 4
																WHEN '04' THEN 5
																WHEN '05' THEN 6
																WHEN '02' THEN 7
																WHEN '03' THEN 8
																END
																) AS NhsNoStatusIx
				INTO		#ReplacementNhsNoStatus
				FROM		#ValidatedData vd -- Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData vd
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																			ON	vd.SrcSys_MajorExt = mc.SrcSys_Major
																			AND	vd.Src_UID_MajorExt = mc.Src_UID_Major
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH UH
																	ON	mc.SrcSys = UH.SrcSys
																	AND	mc.Src_UID = UH.Src_UID
																	AND	UH.NHS_NUMBER_STATUS IS NOT NULL
				LEFT JOIN	#RelatedEntities re
												ON	vd.SrcSys = re.SrcSys
												AND	vd.Src_UID = re.Src_UID
				WHERE		vd.N1_1_NHS_NUMBER IS NOT NULL
				AND			vd.NHS_NUMBER_STATUS IS NULL
				AND			(re.SrcSys IS NOT NULL
				OR			@HasRelatedEntities = 0)
				GROUP BY	vd.SrcSys
							,vd.Src_UID
							,UH.NHS_NUMBER_STATUS
				ORDER BY	vd.SrcSys
							,vd.Src_UID

				-- Update #ValidatedData where the NHS number status is missing with the "best" NHS number status value from other minor records
				UPDATE		vd
				SET			vd.NHS_NUMBER_STATUS = NhsNoStatus.NHS_NUMBER_STATUS
				FROM		#ValidatedData vd
				INNER JOIN	#ReplacementNhsNoStatus	NhsNoStatus
																ON	vd.SrcSys = NhsNoStatus.SrcSys
																AND	vd.Src_UID = NhsNoStatus.Src_UID
		
				-- Create the table of L_DEATH_STATUS values to update back into #ValidatedData where the record has been given a date death
				IF OBJECT_ID('tempdb..#ReplacementDeathStatus') IS NOT NULL DROP TABLE #ReplacementDeathStatus
				SELECT		vd.SrcSys
							,vd.Src_UID
				INTO		#ReplacementDeathStatus
				FROM		#ValidatedData vd -- Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData vd
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																			ON	vd.SrcSys_MajorExt = mc.SrcSys_Major
																			AND	vd.Src_UID_MajorExt = mc.Src_UID_Major
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH UH
																	ON	mc.SrcSys = UH.SrcSys
																	AND	mc.Src_UID = UH.Src_UID
																	AND	UH.NHS_NUMBER_STATUS IS NOT NULL
				WHERE		uh.N15_1_DATE_DEATH IS NULL
				AND			vd.N15_1_DATE_DEATH IS NOT NULL
				GROUP BY	vd.SrcSys
							,vd.Src_UID
				ORDER BY	vd.SrcSys
							,vd.Src_UID

				-- Update #ValidatedData where the record has been given a date death
				UPDATE		vd
				SET			vd.L_DEATH_STATUS = 1
				FROM		#ValidatedData vd
				INNER JOIN	#ReplacementDeathStatus	DeathStatus
																ON	vd.SrcSys = DeathStatus.SrcSys
																AND	vd.Src_UID = DeathStatus.Src_UID

				-- Strip out NHS numbers for records with duplicate temporary NHS numbers
						-- Identify the records that need to be marked for rematching
						IF OBJECT_ID('tempdb..#DupeNHS') IS NOT NULL DROP TABLE #DupeNHS
						SELECT		N1_1_NHS_NUMBER
						INTO		#DupeNHS
						FROM		#ValidatedData
						WHERE		IsValidatedMajor = 1
						AND			IsConfirmed = 1
						AND			LEFT(N1_1_NHS_NUMBER, 6) = '100000'
						GROUP BY	N1_1_NHS_NUMBER
						HAVING		COUNT(*) > 1

						-- Find the associated major records
						IF OBJECT_ID('tempdb..#DupeNhsMajors') IS NOT NULL DROP TABLE #DupeNhsMajors
						SELECT		dem_vd.SrcSys_MajorExt
									,dem_vd.Src_UID_MajorExt
						INTO		#DupeNhsMajors
						FROM		#ValidatedData dem_vd
						INNER JOIN	#DupeNHS dupe
													ON	dem_vd.N1_1_NHS_NUMBER = dupe.N1_1_NHS_NUMBER
						WHERE		dem_vd.IsValidatedMajor = 1
						AND			dem_vd.IsConfirmed = 1
						GROUP BY	dem_vd.SrcSys_MajorExt
									,dem_vd.Src_UID_MajorExt

						-- Find the associated minor records
						UPDATE		dem_vd
						SET			NHS_NUMBER_STATUS = NULL
						FROM		#ValidatedData dem_vd
						INNER JOIN	#DupeNhsMajors dupe
													ON	dem_vd.SrcSys_MajorExt = dupe.SrcSys_MajorExt
													AND	dem_vd.Src_UID_MajorExt = dupe.Src_UID_MajorExt


				-- Assume that any remaining duplicate NHS numbers want to major the most recently updated record (to avoid interface duplicate issues)
						-- Identify the records that need to be marked for rematching
						IF OBJECT_ID('tempdb..#DupeNHS2') IS NOT NULL DROP TABLE #DupeNHS2
						SELECT		N1_1_NHS_NUMBER
						INTO		#DupeNHS2
						FROM		#ValidatedData
						WHERE		IsValidatedMajor = 1
						--AND			IsConfirmed = 1
						AND			LEFT(N1_1_NHS_NUMBER, 6) != '100000'
						GROUP BY	N1_1_NHS_NUMBER
						HAVING		COUNT(*) > 1
						
						-- Find and prioritise the associated major records to establish a successor and victim majors (victims will become minors of the successor major)
						IF OBJECT_ID('tempdb..#DupeNhsMajors2') IS NOT NULL DROP TABLE #DupeNhsMajors2
						SELECT		dem_vd.SrcSys_MajorExt
									,dem_vd.Src_UID_MajorExt
									,dem_vd.SrcSys_Major
									,dem_vd.Src_UID_Major
									,dupe.N1_1_NHS_NUMBER
									,dem_vd.LastUpdated
									,ROW_NUMBER() OVER (PARTITION BY dupe.N1_1_NHS_NUMBER ORDER BY dem_vd.LastUpdated, CASE WHEN dem_vd.SrcSys_MajorExt = 3 THEN 1 ELSE 2 END, dem_vd.Src_UID_MajorExt DESC) AS LastUpdIx
						INTO		#DupeNhsMajors2
						FROM		#ValidatedData dem_vd
						INNER JOIN	#DupeNHS2 dupe
													ON	dem_vd.N1_1_NHS_NUMBER = dupe.N1_1_NHS_NUMBER
						WHERE		dem_vd.IsValidatedMajor = 1
						AND			dem_vd.IsConfirmed = 1

						-- Repoint the associated minor records for the victims to have the successor as the major
						UPDATE		dem_vd
						SET			SrcSys_MajorExt		= successor.SrcSys_MajorExt
									,Src_UID_MajorExt	= successor.Src_UID_MajorExt
									,SrcSys_Major		= successor.SrcSys_Major
									,Src_UID_Major		= successor.Src_UID_Major
									,IsValidatedMajor	= CASE WHEN dupe.LastUpdIx = 1 THEN 1 ELSE 0 END

						FROM		#ValidatedData dem_vd
						INNER JOIN	#DupeNhsMajors2 dupe
														ON	dem_vd.SrcSys_MajorExt = dupe.SrcSys_MajorExt
														AND	dem_vd.Src_UID_MajorExt = dupe.Src_UID_MajorExt
						INNER JOIN	#DupeNhsMajors2 successor
															ON	dem_vd.N1_1_NHS_NUMBER = successor.N1_1_NHS_NUMBER
															AND	successor.LastUpdIx = 1
		
		END


/*********************************************************************************************************************************************************************************************************************************************************************************/
-- Output the data
/*********************************************************************************************************************************************************************************************************************************************************************************/

		-- Persist the data to a table
		IF	@OutputToTable = 1
		AND	@HasRelatedEntities = 0
		BEGIN
				-- Drop the persisted table if it exists
				IF OBJECT_ID('Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData') IS NOT NULL DROP TABLE Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData

				-- Persist the data
				SELECT		*
							,GETDATE() AS ValidatedRecordCreatedDttm
				INTO		Merge_DM_Match.tblDEMOGRAPHICS_tblValidatedData
				FROM		#ValidatedData

		END

		-- Output the table dataset
		IF	@OutputToTable = 0
		AND	@PivotForSSRS = 0
		SELECT		*
		FROM		#ValidatedData

		-- Output the pivoted data for SSRS
		IF	@PivotForSSRS = 1
		BEGIN

		--	SELECT * FROM #ValidatedData

				-- Create the table of data we wish to present to SSRS
				IF OBJECT_ID ('tempdb..#DataForValidation') IS NOT NULL DROP TABLE #DataForValidation
				SELECT		*
				INTO		#DataForValidation
				FROM		#ValidatedData
				WHERE		#ValidatedData.IsValidatedMajor = 1

				-- Add in all other internal related rows to the data for validation
				INSERT INTO	#DataForValidation
				SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
							,Src_UID_MajorExt						= mc.Src_UID_Major
							,SrcSys_Major							= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
							,Src_UID_Major							= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
							,IsValidatedMajor						= 0
							,IsConfirmed							= 0
							,LastUpdated							= h.LastUpdated
							,SrcSys									= mc.SrcSys
							,Src_UID								= mc.Src_UID

							,PATIENT_ID								= h.PATIENT_ID
							,N1_1_NHS_NUMBER						= h.N1_1_NHS_NUMBER
							,NHS_NUMBER_STATUS						= h.NHS_NUMBER_STATUS
							,L_RA3_RID								= h.L_RA3_RID
							,L_RA7_RID								= h.L_RA7_RID
							,L_RVJ01_RID							= h.L_RVJ01_RID
							,TEMP_ID								= h.TEMP_ID
							,L_NSTS_STATUS							= h.L_NSTS_STATUS
							,N1_2_HOSPITAL_NUMBER					= h.N1_2_HOSPITAL_NUMBER
							,L_TITLE								= h.L_TITLE
							,N1_5_SURNAME							= h.N1_5_SURNAME
							,N1_6_FORENAME							= h.N1_6_FORENAME
							,N1_7_ADDRESS_1							= h.N1_7_ADDRESS_1
							,N1_7_ADDRESS_2							= h.N1_7_ADDRESS_2
							,N1_7_ADDRESS_3							= h.N1_7_ADDRESS_3
							,N1_7_ADDRESS_4							= h.N1_7_ADDRESS_4
							,N1_7_ADDRESS_5							= h.N1_7_ADDRESS_5
							,N1_8_POSTCODE							= h.N1_8_POSTCODE
							,N1_9_SEX								= h.N1_9_SEX
							,N1_10_DATE_BIRTH						= h.N1_10_DATE_BIRTH
							,N1_11_GP_CODE							= h.N1_11_GP_CODE
							,N1_12_GP_PRACTICE_CODE					= h.N1_12_GP_PRACTICE_CODE
							,N1_13_PCT								= h.N1_13_PCT
							,N1_14_SURNAME_BIRTH					= h.N1_14_SURNAME_BIRTH
							,N1_15_ETHNICITY						= h.N1_15_ETHNICITY
							,PAT_PREF_NAME							= h.PAT_PREF_NAME
							,PAT_OCCUPATION							= h.PAT_OCCUPATION
							,PAT_SOCIAL_CLASS						= h.PAT_SOCIAL_CLASS
							,PAT_LIVES_ALONE						= h.PAT_LIVES_ALONE
							,MARITAL_STATUS							= h.MARITAL_STATUS
							,PAT_PREF_LANGUAGE						= h.PAT_PREF_LANGUAGE
							,PAT_PREF_CONTACT						= h.PAT_PREF_CONTACT
							,L_DEATH_STATUS							= h.L_DEATH_STATUS
							,N15_1_DATE_DEATH						= h.N15_1_DATE_DEATH
							,N15_2_DEATH_LOCATION					= h.N15_2_DEATH_LOCATION
							,N15_3_DEATH_CAUSE						= h.N15_3_DEATH_CAUSE
							,N15_4_DEATH_CANCER						= h.N15_4_DEATH_CANCER
							,N15_5_DEATH_CODE_1						= h.N15_5_DEATH_CODE_1
							,N15_6_DEATH_CODE_2						= h.N15_6_DEATH_CODE_2
							,N15_7_DEATH_CODE_3						= h.N15_7_DEATH_CODE_3
							,N15_8_DEATH_CODE_4						= h.N15_8_DEATH_CODE_4
							,N15_9_DEATH_DISCREPANCY				= h.N15_9_DEATH_DISCREPANCY
							,N_CC4_TOWN								= h.N_CC4_TOWN
							,N_CC5_COUNTRY							= h.N_CC5_COUNTRY
							,N_CC6_M_SURNAME						= h.N_CC6_M_SURNAME
							,N_CC7_M_CLASS							= h.N_CC7_M_CLASS
							,N_CC8_M_FORENAME						= h.N_CC8_M_FORENAME
							,N_CC9_M_DOB							= h.N_CC9_M_DOB
							,N_CC10_M_TOWN							= h.N_CC10_M_TOWN
							,N_CC11_M_COUNTRY						= h.N_CC11_M_COUNTRY
							,N_CC12_M_OCC							= h.N_CC12_M_OCC
							,N_CC13_M_OCC_DIAG						= h.N_CC13_M_OCC_DIAG
							,N_CC6_F_SURNAME						= h.N_CC6_F_SURNAME
							,N_CC7_F_CLASS							= h.N_CC7_F_CLASS
							,N_CC8_F_FORENAME						= h.N_CC8_F_FORENAME
							,N_CC9_F_DOB							= h.N_CC9_F_DOB
							,N_CC10_F_TOWN							= h.N_CC10_F_TOWN
							,N_CC11_F_COUNTRY						= h.N_CC11_F_COUNTRY
							,N_CC12_F_OCC							= h.N_CC12_F_OCC
							,N_CC13_F_OCC_DIAG						= h.N_CC13_F_OCC_DIAG
							,N_CC14_MULTI_BIRTH						= h.N_CC14_MULTI_BIRTH
							,R_POST_MORTEM							= h.R_POST_MORTEM
							,R_DAY_PHONE							= h.R_DAY_PHONE
							,DAY_PHONE_EXT							= h.DAY_PHONE_EXT
							,R_EVE_PHONE							= h.R_EVE_PHONE
							,EVE_PHONE_EXT							= h.EVE_PHONE_EXT
							,R_DEATH_TREATMENT						= h.R_DEATH_TREATMENT
							,R_PM_DETAILS							= h.R_PM_DETAILS
							,L_IATROGENIC_DEATH						= h.L_IATROGENIC_DEATH
							,L_INFECTION_DEATH						= h.L_INFECTION_DEATH
							,L_DEATH_COMMENTS						= h.L_DEATH_COMMENTS
							,RELIGION								= h.RELIGION
							,CONTACT_DETAILS						= h.CONTACT_DETAILS
							,NOK_NAME								= h.NOK_NAME
							,NOK_ADDRESS_1							= h.NOK_ADDRESS_1
							,NOK_ADDRESS_2							= h.NOK_ADDRESS_2
							,NOK_ADDRESS_3							= h.NOK_ADDRESS_3
							,NOK_ADDRESS_4							= h.NOK_ADDRESS_4
							,NOK_ADDRESS_5							= h.NOK_ADDRESS_5
							,NOK_POSTCODE							= h.NOK_POSTCODE
							,NOK_CONTACT							= h.NOK_CONTACT
							,NOK_RELATIONSHIP						= h.NOK_RELATIONSHIP
							,PAT_DEPENDANTS							= h.PAT_DEPENDANTS
							,CARER_NAME								= h.CARER_NAME
							,CARER_ADDRESS_1						= h.CARER_ADDRESS_1
							,CARER_ADDRESS_2						= h.CARER_ADDRESS_2
							,CARER_ADDRESS_3						= h.CARER_ADDRESS_3
							,CARER_ADDRESS_4						= h.CARER_ADDRESS_4
							,CARER_ADDRESS_5						= h.CARER_ADDRESS_5
							,CARER_POSTCODE							= h.CARER_POSTCODE
							,CARER_CONTACT							= h.CARER_CONTACT
							,CARER_RELATIONSHIP						= h.CARER_RELATIONSHIP
							,CARER1_TYPE							= h.CARER1_TYPE
							,CARER2_NAME							= h.CARER2_NAME
							,CARER2_ADDRESS_1						= h.CARER2_ADDRESS_1
							,CARER2_ADDRESS_2						= h.CARER2_ADDRESS_2
							,CARER2_ADDRESS_3						= h.CARER2_ADDRESS_3
							,CARER2_ADDRESS_4						= h.CARER2_ADDRESS_4
							,CARER2_ADDRESS_5						= h.CARER2_ADDRESS_5
							,CARER2_POSTCODE						= h.CARER2_POSTCODE
							,CARER2_CONTACT							= h.CARER2_CONTACT
							,CARER2_RELATIONSHIP					= h.CARER2_RELATIONSHIP
							,CARER2_TYPE							= h.CARER2_TYPE
							,PT_AT_RISK								= h.PT_AT_RISK
							,REASON_RISK							= h.REASON_RISK
							,GESTATION								= h.GESTATION
							,CAUSE_OF_DEATH_UROLOGY					= h.CAUSE_OF_DEATH_UROLOGY
							,AVOIDABLE_DEATH						= h.AVOIDABLE_DEATH
							,AVOIDABLE_DETAILS						= h.AVOIDABLE_DETAILS
							,OTHER_DEATH_CAUSE_UROLOGY				= h.OTHER_DEATH_CAUSE_UROLOGY
							,ACTION_ID								= h.ACTION_ID
							,STATED_GENDER_CODE						= h.STATED_GENDER_CODE
							,CAUSE_OF_DEATH_UROLOGY_FUP				= h.CAUSE_OF_DEATH_UROLOGY_FUP
							,DEATH_WITHIN_30_DAYS_OF_TREAT			= h.DEATH_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= h.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_LATER_DATE					= h.DEATH_CAUSE_LATER_DATE
							,RegisteredPractice						= h.RegisteredPractice
							,RegisteredGP							= h.RegisteredGP
							,PersonSexualOrientation				= h.PersonSexualOrientation
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																			ON	h.SrcSys = mc.SrcSys
																			AND	h.Src_UID = mc.Src_UID
				INNER JOIN	#RelatedEntities re
												ON	h.SrcSys = re.SrcSys
												AND	h.Src_UID = re.Src_UID
				LEFT JOIN	#mcIx mc_1st
										ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
										AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
										AND	mc_1st.IsMajorSCR = 0
										AND	mc_1st.mcIx = 1
				WHERE		h.SrcSys IN (1,2)

				-- Add in all other external related rows to the data for validation
				INSERT INTO	#DataForValidation
				SELECT		SrcSys_MajorExt							= mc.SrcSys_Major
							,Src_UID_MajorExt						= mc.Src_UID_Major
							,SrcSys_Major							= ISNULL(mc_1st.SrcSys, mc.SrcSys_Major)
							,Src_UID_Major							= ISNULL(mc_1st.Src_UID, mc.Src_UID_Major)
							,IsValidatedMajor						= 0
							,IsConfirmed							= 0
							,LastUpdated							= h.LastUpdated
							,SrcSys									= mc.SrcSys
							,Src_UID								= mc.Src_UID

							,PATIENT_ID								= h.PATIENT_ID
							,N1_1_NHS_NUMBER						= h.N1_1_NHS_NUMBER
							,NHS_NUMBER_STATUS						= h.NHS_NUMBER_STATUS
							,L_RA3_RID								= h.L_RA3_RID
							,L_RA7_RID								= h.L_RA7_RID
							,L_RVJ01_RID							= h.L_RVJ01_RID
							,TEMP_ID								= h.TEMP_ID
							,L_NSTS_STATUS							= h.L_NSTS_STATUS
							,N1_2_HOSPITAL_NUMBER					= h.N1_2_HOSPITAL_NUMBER
							,L_TITLE								= h.L_TITLE
							,N1_5_SURNAME							= h.N1_5_SURNAME
							,N1_6_FORENAME							= h.N1_6_FORENAME
							,N1_7_ADDRESS_1							= h.N1_7_ADDRESS_1
							,N1_7_ADDRESS_2							= h.N1_7_ADDRESS_2
							,N1_7_ADDRESS_3							= h.N1_7_ADDRESS_3
							,N1_7_ADDRESS_4							= h.N1_7_ADDRESS_4
							,N1_7_ADDRESS_5							= h.N1_7_ADDRESS_5
							,N1_8_POSTCODE							= h.N1_8_POSTCODE
							,N1_9_SEX								= h.N1_9_SEX
							,N1_10_DATE_BIRTH						= h.N1_10_DATE_BIRTH
							,N1_11_GP_CODE							= h.N1_11_GP_CODE
							,N1_12_GP_PRACTICE_CODE					= h.N1_12_GP_PRACTICE_CODE
							,N1_13_PCT								= h.N1_13_PCT
							,N1_14_SURNAME_BIRTH					= h.N1_14_SURNAME_BIRTH
							,N1_15_ETHNICITY						= h.N1_15_ETHNICITY
							,PAT_PREF_NAME							= h.PAT_PREF_NAME
							,PAT_OCCUPATION							= h.PAT_OCCUPATION
							,PAT_SOCIAL_CLASS						= h.PAT_SOCIAL_CLASS
							,PAT_LIVES_ALONE						= h.PAT_LIVES_ALONE
							,MARITAL_STATUS							= h.MARITAL_STATUS
							,PAT_PREF_LANGUAGE						= h.PAT_PREF_LANGUAGE
							,PAT_PREF_CONTACT						= h.PAT_PREF_CONTACT
							,L_DEATH_STATUS							= h.L_DEATH_STATUS
							,N15_1_DATE_DEATH						= h.N15_1_DATE_DEATH
							,N15_2_DEATH_LOCATION					= h.N15_2_DEATH_LOCATION
							,N15_3_DEATH_CAUSE						= h.N15_3_DEATH_CAUSE
							,N15_4_DEATH_CANCER						= h.N15_4_DEATH_CANCER
							,N15_5_DEATH_CODE_1						= h.N15_5_DEATH_CODE_1
							,N15_6_DEATH_CODE_2						= h.N15_6_DEATH_CODE_2
							,N15_7_DEATH_CODE_3						= h.N15_7_DEATH_CODE_3
							,N15_8_DEATH_CODE_4						= h.N15_8_DEATH_CODE_4
							,N15_9_DEATH_DISCREPANCY				= h.N15_9_DEATH_DISCREPANCY
							,N_CC4_TOWN								= h.N_CC4_TOWN
							,N_CC5_COUNTRY							= h.N_CC5_COUNTRY
							,N_CC6_M_SURNAME						= h.N_CC6_M_SURNAME
							,N_CC7_M_CLASS							= h.N_CC7_M_CLASS
							,N_CC8_M_FORENAME						= h.N_CC8_M_FORENAME
							,N_CC9_M_DOB							= h.N_CC9_M_DOB
							,N_CC10_M_TOWN							= h.N_CC10_M_TOWN
							,N_CC11_M_COUNTRY						= h.N_CC11_M_COUNTRY
							,N_CC12_M_OCC							= h.N_CC12_M_OCC
							,N_CC13_M_OCC_DIAG						= h.N_CC13_M_OCC_DIAG
							,N_CC6_F_SURNAME						= h.N_CC6_F_SURNAME
							,N_CC7_F_CLASS							= h.N_CC7_F_CLASS
							,N_CC8_F_FORENAME						= h.N_CC8_F_FORENAME
							,N_CC9_F_DOB							= h.N_CC9_F_DOB
							,N_CC10_F_TOWN							= h.N_CC10_F_TOWN
							,N_CC11_F_COUNTRY						= h.N_CC11_F_COUNTRY
							,N_CC12_F_OCC							= h.N_CC12_F_OCC
							,N_CC13_F_OCC_DIAG						= h.N_CC13_F_OCC_DIAG
							,N_CC14_MULTI_BIRTH						= h.N_CC14_MULTI_BIRTH
							,R_POST_MORTEM							= h.R_POST_MORTEM
							,R_DAY_PHONE							= h.R_DAY_PHONE
							,DAY_PHONE_EXT							= h.DAY_PHONE_EXT
							,R_EVE_PHONE							= h.R_EVE_PHONE
							,EVE_PHONE_EXT							= h.EVE_PHONE_EXT
							,R_DEATH_TREATMENT						= h.R_DEATH_TREATMENT
							,R_PM_DETAILS							= h.R_PM_DETAILS
							,L_IATROGENIC_DEATH						= h.L_IATROGENIC_DEATH
							,L_INFECTION_DEATH						= h.L_INFECTION_DEATH
							,L_DEATH_COMMENTS						= h.L_DEATH_COMMENTS
							,RELIGION								= h.RELIGION
							,CONTACT_DETAILS						= h.CONTACT_DETAILS
							,NOK_NAME								= h.NOK_NAME
							,NOK_ADDRESS_1							= h.NOK_ADDRESS_1
							,NOK_ADDRESS_2							= h.NOK_ADDRESS_2
							,NOK_ADDRESS_3							= h.NOK_ADDRESS_3
							,NOK_ADDRESS_4							= h.NOK_ADDRESS_4
							,NOK_ADDRESS_5							= h.NOK_ADDRESS_5
							,NOK_POSTCODE							= h.NOK_POSTCODE
							,NOK_CONTACT							= h.NOK_CONTACT
							,NOK_RELATIONSHIP						= h.NOK_RELATIONSHIP
							,PAT_DEPENDANTS							= h.PAT_DEPENDANTS
							,CARER_NAME								= h.CARER_NAME
							,CARER_ADDRESS_1						= h.CARER_ADDRESS_1
							,CARER_ADDRESS_2						= h.CARER_ADDRESS_2
							,CARER_ADDRESS_3						= h.CARER_ADDRESS_3
							,CARER_ADDRESS_4						= h.CARER_ADDRESS_4
							,CARER_ADDRESS_5						= h.CARER_ADDRESS_5
							,CARER_POSTCODE							= h.CARER_POSTCODE
							,CARER_CONTACT							= h.CARER_CONTACT
							,CARER_RELATIONSHIP						= h.CARER_RELATIONSHIP
							,CARER1_TYPE							= h.CARER1_TYPE
							,CARER2_NAME							= h.CARER2_NAME
							,CARER2_ADDRESS_1						= h.CARER2_ADDRESS_1
							,CARER2_ADDRESS_2						= h.CARER2_ADDRESS_2
							,CARER2_ADDRESS_3						= h.CARER2_ADDRESS_3
							,CARER2_ADDRESS_4						= h.CARER2_ADDRESS_4
							,CARER2_ADDRESS_5						= h.CARER2_ADDRESS_5
							,CARER2_POSTCODE						= h.CARER2_POSTCODE
							,CARER2_CONTACT							= h.CARER2_CONTACT
							,CARER2_RELATIONSHIP					= h.CARER2_RELATIONSHIP
							,CARER2_TYPE							= h.CARER2_TYPE
							,PT_AT_RISK								= h.PT_AT_RISK
							,REASON_RISK							= h.REASON_RISK
							,GESTATION								= h.GESTATION
							,CAUSE_OF_DEATH_UROLOGY					= h.CAUSE_OF_DEATH_UROLOGY
							,AVOIDABLE_DEATH						= h.AVOIDABLE_DEATH
							,AVOIDABLE_DETAILS						= h.AVOIDABLE_DETAILS
							,OTHER_DEATH_CAUSE_UROLOGY				= h.OTHER_DEATH_CAUSE_UROLOGY
							,ACTION_ID								= h.ACTION_ID
							,STATED_GENDER_CODE						= h.STATED_GENDER_CODE
							,CAUSE_OF_DEATH_UROLOGY_FUP				= h.CAUSE_OF_DEATH_UROLOGY_FUP
							,DEATH_WITHIN_30_DAYS_OF_TREAT			= h.DEATH_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= h.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT
							,DEATH_CAUSE_LATER_DATE					= h.DEATH_CAUSE_LATER_DATE
							,RegisteredPractice						= h.RegisteredPractice
							,RegisteredGP							= h.RegisteredGP
							,PersonSexualOrientation				= h.PersonSexualOrientation
				FROM		Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH h
				INNER JOIN	Merge_DM_Match.tblDEMOGRAPHICS_Match_Control mc
																			ON	h.SrcSys = mc.SrcSys
																			AND	h.Src_UID = mc.Src_UID
				INNER JOIN	#RelatedEntities re
												ON	h.SrcSys = re.SrcSys
												AND	h.Src_UID = re.Src_UID
				LEFT JOIN	#mcIx mc_1st
										ON	mc.SrcSys_Major = mc_1st.SrcSys_Major
										AND	mc.Src_UID_Major = mc_1st.Src_UID_Major
										AND	mc_1st.IsMajorSCR = 0
										AND	mc_1st.mcIx = 1 
				WHERE		h.SrcSys = 3

				
				-- Create and populate the list of colums we wish to present to SSRS
				IF OBJECT_ID('tempdb..#ColumnDetails') IS NULL CREATE TABLE #ColumnDetails (ColumnName VARCHAR(255), ColumnDesc VARCHAR(255))
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) 
				SELECT		ColumnName
							,ColumnDesc
				FROM		Merge_DM_Match.Config_ColumnsAndGroups
				WHERE		TableName = 'tblDEMOGRAPHICS'
				AND			ShowInReport = 1
				
				/*
				TRUNCATE TABLE #ColumnDetails
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PATIENT_ID',				'Demographic Record ID')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_1_NHS_NUMBER',			'NHS Number')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NHS_NUMBER_STATUS',			'NHS Number Status')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_RA3_RID',					'Hospital Number for RA3 (Bristol specific)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_RA7_RID',					'Hospital Number for RA7 (Bristol specific)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_RVJ01_RID',				'Hospital Number for RVJ01 (Bristol specific)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_NSTS_STATUS',				'Whether NHS Number is valid (1 - Valid, 9 - Invalid)')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_2_HOSPITAL_NUMBER',		'Hospital Number')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_TITLE',					'Title')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_5_SURNAME',				'Family Name')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_6_FORENAME',				'Given Name')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_7_ADDRESS_1',			'Address at Diagnosis - Line 1')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_7_ADDRESS_2',			'Address at Diagnosis - Line 2')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_7_ADDRESS_3',			'Address at Diagnosis - Line 3')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_7_ADDRESS_4',			'Address at Diagnosis - Line 4')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_7_ADDRESS_5',			'Address at Diagnosis - Line 5')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_8_POSTCODE',				'Address at Diagnosis - Postcode')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_9_SEX',					'Gender')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_10_DATE_BIRTH',			'Date of Birth')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_11_GP_CODE',				'Registered GP - GMC Code')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_12_GP_PRACTICE_CODE',	'Registered GP - Practice Code')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_13_PCT',					'Registered GP - PCT Code')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_14_SURNAME_BIRTH',		'Family Name at Birth')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N1_15_ETHNICITY',			'Ethnicity')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_PREF_NAME',				'Preferred Name')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_OCCUPATION',			'Occupation')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_SOCIAL_CLASS',			'Social Class')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_LIVES_ALONE',			'Lives Alone')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('MARITAL_STATUS',			'Marital Status')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_PREF_LANGUAGE',			'Preferred Language')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_PREF_CONTACT',			'Preferred Contact Method')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_DEATH_STATUS',			'Patient Status (0 - Alive, 1 - Dead)')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_1_DATE_DEATH',			'Date of Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_2_DEATH_LOCATION',		'Place of Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_3_DEATH_CAUSE',			'Cause of Death Indentification Method')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_4_DEATH_CANCER',		'Cancer Related Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_5_DEATH_CODE_1',		'Cause of Death - Immediate')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_6_DEATH_CODE_2',		'Cause of Death - Condition Giving Rise to Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_7_DEATH_CODE_3',		'Cause of Death - Underlying Condition Leading to Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_8_DEATH_CODE_4',		'Cause of Death - Significant Condition Not Directly Related')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N15_9_DEATH_DISCREPANCY',	'Death Discrepancy')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC4_TOWN',				'Child Additional Details - Town (Birth)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC5_COUNTRY',				'Child Additional Details - Country (Birth)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC6_M_SURNAME',			'Biological Mother - Surname')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC7_M_CLASS',				'Biological Mother - Classification')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC8_M_FORENAME',			'Biological Mother - Forename')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC9_M_DOB',				'Biological Mother - Date of Birth')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC10_M_TOWN',				'Biological Mother - Birth Town')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC11_M_COUNTRY',			'Biological Mother - Birth Country')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC12_M_OCC',				'Biological Mother - Occupation (Birth)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC13_M_OCC_DIAG',			'Biological Mother - Occupation (Diagnosis)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC6_F_SURNAME',			'Biological Father - Surname')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC7_F_CLASS',				'Biological Father - Classification')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC8_F_FORENAME',			'Biological Father - Forename')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC9_F_DOB',				'Biological Father - Date of Birth')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC10_F_TOWN',				'Biological Father - Birth Town')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC11_F_COUNTRY',			'Biological Father - Birth Country')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC12_F_OCC',				'Biological Father - Occupation (Birth)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC13_F_OCC_DIAG',			'Biological Father - Occupation (Diagnosis)')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('N_CC14_MULTI_BIRTH',		'Part of Multiple Birth')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('R_POST_MORTEM',				'Post Mortem Undertaken')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('R_DAY_PHONE',				'Day Time Phone No.')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('R_EVE_PHONE',				'Evening Phone No.')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('R_DEATH_TREATMENT',			'Was Death Related to Treatment')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('R_PM_DETAILS',				'Post Mortem Details')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_IATROGENIC_DEATH',		'Iatrogenic Death')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_INFECTION_DEATH',			'Death due to Infection')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('L_DEATH_COMMENTS',			'Death Comments')
				INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('RELIGION',					'Religion')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CONTACT_DETAILS',			'Preferred Contact Method')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_NAME',					'Next of Kin - Name')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_ADDRESS_1',				'Next of Kin - Address Line 1')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_ADDRESS_2',				'Next of Kin - Address Line 2')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_ADDRESS_3',				'Next of Kin - Address Line 3')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_ADDRESS_4',				'Next of Kin - Address Line 4')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_ADDRESS_5',				'Next of Kin - Address Line 5')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_POSTCODE',				'Next of Kin - Postcode')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_CONTACT',				'Next of Kin - Contact Details')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('NOK_RELATIONSHIP',			'Next of Kin - Relationship to patient')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PAT_DEPENDANTS',			'Dependants')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_NAME',				'Carer 1 - Name')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_ADDRESS_1',			'Carer 1 - Address Line 1')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_ADDRESS_2',			'Carer 1 - Address Line 2')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_ADDRESS_3',			'Carer 1 - Address Line 3')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_ADDRESS_4',			'Carer 1 - Address Line 4')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_ADDRESS_5',			'Carer 1 - Address Line 5')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_POSTCODE',			'Carer 1 - Postcode')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_CONTACT',				'Carer 1 - Contact Details')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER_RELATIONSHIP',		'Carer 1 - Relationship to patient')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER1_TYPE',				'Carer 1 - Type')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_NAME',				'Carer 2 - Name')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_ADDRESS_1',			'Carer 2 - Address Line 1')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_ADDRESS_2',			'Carer 2 - Address Line 2')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_ADDRESS_3',			'Carer 2 - Address Line 3')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_ADDRESS_4',			'Carer 2 - Address Line 4')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_ADDRESS_5',			'Carer 2 - Address Line 5')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_POSTCODE',			'Carer 2 - Postcode')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_CONTACT',			'Carer 2 - Contact Details')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_RELATIONSHIP',		'Carer 2 - Relationship to patient')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CARER2_TYPE',				'Carer 2 - Type')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('PT_AT_RISK',				'Patient At Risk')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('REASON_RISK',				'At Risk Reason')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('GESTATION',					'Gestation/Birth Weight')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('CAUSE_OF_DEATH_UROLOGY',	'[Not in use]')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('AVOIDABLE_DEATH',			'[Not in use]')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('AVOIDABLE_DETAILS',			'[Not in use]')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('OTHER_DEATH_CAUSE_UROLOGY',	'[Not in use]')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('ACTION_ID',					'Latest Audit ID for Demographic Data')
				--INSERT INTO #ColumnDetails (ColumnName,ColumnDesc) VALUES ('STATED_GENDER_CODE',		'Person Stated Gender')
				*/

				SELECT		'ValidatedData' AS ReportingCohort
							,ISNULL(RowWise.SrcSys_MajorExt, mmvc.SrcSys_MajorExt) AS SrcSys_MajorExt
							,ISNULL(RowWise.Src_UID_MajorExt, mmvc.Src_UID_MajorExt) AS Src_UID_MajorExt
							,ISNULL(RowWise.SrcSys_Major, mmvc.SrcSys_Major) AS SrcSys_Major
							,ISNULL(RowWise.Src_UID_Major, mmvc.Src_UID_Major) AS Src_UID_Major
							,ISNULL(RowWise.IsValidatedMajor, mmvc.IsValidatedMajor) AS IsValidatedMajor
							,ISNULL(RowWise.LastUpdated, mmvc.LastUpdated) AS LastUpdated
							,CAST(CASE	WHEN RowWise.SrcSys = 1 
										THEN 'https://ryrsomerset.wsht.nhs.uk/CancerRegister/referrals_overview.aspx?PatientID=' + RowWise.Src_UID
										WHEN RowWise.SrcSys = 2 
										THEN 'https://svvscr01.bsuh.nhs.uk/CancerRegister/referrals_overview.aspx?PatientID=' + RowWise.Src_UID
										END AS VARCHAR(255)) AS ScrHyperlink
							,ISNULL(RowWise.SrcSys, mmvc.SrcSys) AS SrcSys
							,ISNULL(RowWise.Src_UID, mmvc.Src_UID) AS Src_UID
							,ISNULL(RowWise.FieldName, mmvc.FieldName) AS FieldName
							,RowWise.FieldValue
							,ISNULL(Cols.ColumnDesc, mmvc.ColumnDesc) AS ColumnDesc
							,CASE WHEN mmvc.SrcSys_Major IS NOT NULL THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS IsColumnOverride
				FROM		(SELECT		d4v.SrcSys_MajorExt
										,d4v.Src_UID_MajorExt
										,d4v.SrcSys_Major
										,d4v.Src_UID_Major
										,d4v.IsValidatedMajor
										,d4v.LastUpdated
										,d4v.SrcSys
										,d4v.Src_UID
										,PATIENT_ID								= CAST(d4v.PATIENT_ID AS VARCHAR(8000))
										,N1_1_NHS_NUMBER						= CAST(d4v.N1_1_NHS_NUMBER AS VARCHAR(8000))
										,NHS_NUMBER_STATUS						= CAST(d4v.NHS_NUMBER_STATUS AS VARCHAR(8000))
										,L_RA3_RID								= CAST(d4v.L_RA3_RID AS VARCHAR(8000))
										,L_RA7_RID								= CAST(d4v.L_RA7_RID AS VARCHAR(8000))
										,L_RVJ01_RID							= CAST(d4v.L_RVJ01_RID AS VARCHAR(8000))
										,TEMP_ID								= CAST(d4v.TEMP_ID AS VARCHAR(8000))
										,L_NSTS_STATUS							= CAST(d4v.L_NSTS_STATUS AS VARCHAR(8000))
										,N1_2_HOSPITAL_NUMBER					= CAST(d4v.N1_2_HOSPITAL_NUMBER AS VARCHAR(8000))
										,L_TITLE								= ISNULL(CAST(ttl.TITLE_DESC AS VARCHAR(8000)) ,CAST(d4v.L_TITLE AS VARCHAR(8000))) COLLATE DATABASE_DEFAULT
										,N1_5_SURNAME							= CAST(d4v.N1_5_SURNAME AS VARCHAR(8000))
										,N1_6_FORENAME							= CAST(d4v.N1_6_FORENAME AS VARCHAR(8000))
										,N1_7_ADDRESS_1							= CAST(d4v.N1_7_ADDRESS_1 AS VARCHAR(8000))
										,N1_7_ADDRESS_2							= CAST(d4v.N1_7_ADDRESS_2 AS VARCHAR(8000))
										,N1_7_ADDRESS_3							= CAST(d4v.N1_7_ADDRESS_3 AS VARCHAR(8000))
										,N1_7_ADDRESS_4							= CAST(d4v.N1_7_ADDRESS_4 AS VARCHAR(8000))
										,N1_7_ADDRESS_5							= CAST(d4v.N1_7_ADDRESS_5 AS VARCHAR(8000))
										,N1_8_POSTCODE							= CAST(d4v.N1_8_POSTCODE AS VARCHAR(8000))
										,N1_9_SEX								= ISNULL(CAST(sex.GENDER_DESC AS VARCHAR(8000)), CAST(d4v.N1_9_SEX AS VARCHAR(8000))) COLLATE DATABASE_DEFAULT
										,N1_10_DATE_BIRTH						= CONVERT(VARCHAR(8000), d4v.N1_10_DATE_BIRTH, 103)
										,N1_11_GP_CODE							= CAST(d4v.N1_11_GP_CODE AS VARCHAR(8000))
										,N1_12_GP_PRACTICE_CODE					= CAST(d4v.N1_12_GP_PRACTICE_CODE AS VARCHAR(8000))
										,N1_13_PCT								= CAST(d4v.N1_13_PCT AS VARCHAR(8000))
										,N1_14_SURNAME_BIRTH					= CAST(d4v.N1_14_SURNAME_BIRTH AS VARCHAR(8000))
										,N1_15_ETHNICITY						= ISNULL(CAST(ec.ETHNIC_DESC AS VARCHAR(8000)), CAST(d4v.N1_15_ETHNICITY AS VARCHAR(8000))) COLLATE DATABASE_DEFAULT
										,PAT_PREF_NAME							= CAST(d4v.PAT_PREF_NAME AS VARCHAR(8000))
										,PAT_OCCUPATION							= CAST(d4v.PAT_OCCUPATION AS VARCHAR(8000))
										,PAT_SOCIAL_CLASS						= CAST(d4v.PAT_SOCIAL_CLASS AS VARCHAR(8000))
										,PAT_LIVES_ALONE						= CAST(d4v.PAT_LIVES_ALONE AS VARCHAR(8000))
										,MARITAL_STATUS							= CAST(d4v.MARITAL_STATUS AS VARCHAR(8000))
										,PAT_PREF_LANGUAGE						= CAST(d4v.PAT_PREF_LANGUAGE AS VARCHAR(8000))
										,PAT_PREF_CONTACT						= CAST(d4v.PAT_PREF_CONTACT AS VARCHAR(8000))
										,L_DEATH_STATUS							= CAST(d4v.L_DEATH_STATUS AS VARCHAR(8000))
										,N15_1_DATE_DEATH						= CONVERT(VARCHAR(8000), d4v.N15_1_DATE_DEATH, 103)
										,N15_2_DEATH_LOCATION					= CAST(d4v.N15_2_DEATH_LOCATION AS VARCHAR(8000))
										,N15_3_DEATH_CAUSE						= CAST(d4v.N15_3_DEATH_CAUSE AS VARCHAR(8000))
										,N15_4_DEATH_CANCER						= CAST(d4v.N15_4_DEATH_CANCER AS VARCHAR(8000))
										,N15_5_DEATH_CODE_1						= CAST(d4v.N15_5_DEATH_CODE_1 AS VARCHAR(8000))
										,N15_6_DEATH_CODE_2						= CAST(d4v.N15_6_DEATH_CODE_2 AS VARCHAR(8000))
										,N15_7_DEATH_CODE_3						= CAST(d4v.N15_7_DEATH_CODE_3 AS VARCHAR(8000))
										,N15_8_DEATH_CODE_4						= CAST(d4v.N15_8_DEATH_CODE_4 AS VARCHAR(8000))
										,N15_9_DEATH_DISCREPANCY				= CAST(d4v.N15_9_DEATH_DISCREPANCY AS VARCHAR(8000))
										,N_CC4_TOWN								= CAST(d4v.N_CC4_TOWN AS VARCHAR(8000))
										,N_CC5_COUNTRY							= CAST(d4v.N_CC5_COUNTRY AS VARCHAR(8000))
										,N_CC6_M_SURNAME						= CAST(d4v.N_CC6_M_SURNAME AS VARCHAR(8000))
										,N_CC7_M_CLASS							= CAST(d4v.N_CC7_M_CLASS AS VARCHAR(8000))
										,N_CC8_M_FORENAME						= CAST(d4v.N_CC8_M_FORENAME AS VARCHAR(8000))
										,N_CC9_M_DOB							= CAST(d4v.N_CC9_M_DOB AS VARCHAR(8000))
										,N_CC10_M_TOWN							= CAST(d4v.N_CC10_M_TOWN AS VARCHAR(8000))
										,N_CC11_M_COUNTRY						= CAST(d4v.N_CC11_M_COUNTRY AS VARCHAR(8000))
										,N_CC12_M_OCC							= CAST(d4v.N_CC12_M_OCC AS VARCHAR(8000))
										,N_CC13_M_OCC_DIAG						= CAST(d4v.N_CC13_M_OCC_DIAG AS VARCHAR(8000))
										,N_CC6_F_SURNAME						= CAST(d4v.N_CC6_F_SURNAME AS VARCHAR(8000))
										,N_CC7_F_CLASS							= CAST(d4v.N_CC7_F_CLASS AS VARCHAR(8000))
										,N_CC8_F_FORENAME						= CAST(d4v.N_CC8_F_FORENAME AS VARCHAR(8000))
										,N_CC9_F_DOB							= CAST(d4v.N_CC9_F_DOB AS VARCHAR(8000))
										,N_CC10_F_TOWN							= CAST(d4v.N_CC10_F_TOWN AS VARCHAR(8000))
										,N_CC11_F_COUNTRY						= CAST(d4v.N_CC11_F_COUNTRY AS VARCHAR(8000))
										,N_CC12_F_OCC							= CAST(d4v.N_CC12_F_OCC AS VARCHAR(8000))
										,N_CC13_F_OCC_DIAG						= CAST(d4v.N_CC13_F_OCC_DIAG AS VARCHAR(8000))
										,N_CC14_MULTI_BIRTH						= CAST(d4v.N_CC14_MULTI_BIRTH AS VARCHAR(8000))
										,R_POST_MORTEM							= CAST(d4v.R_POST_MORTEM AS VARCHAR(8000))
										,R_DAY_PHONE							= CAST(d4v.R_DAY_PHONE AS VARCHAR(8000))
										,DAY_PHONE_EXT							= CAST(d4v.DAY_PHONE_EXT AS VARCHAR(8000))
										,R_EVE_PHONE							= CAST(d4v.R_EVE_PHONE AS VARCHAR(8000))
										,EVE_PHONE_EXT							= CAST(d4v.EVE_PHONE_EXT AS VARCHAR(8000))
										,R_DEATH_TREATMENT						= CAST(d4v.R_DEATH_TREATMENT AS VARCHAR(8000))
										,R_PM_DETAILS							= CAST(d4v.R_PM_DETAILS AS VARCHAR(8000))
										,L_IATROGENIC_DEATH						= CAST(d4v.L_IATROGENIC_DEATH AS VARCHAR(8000))
										,L_INFECTION_DEATH						= CAST(d4v.L_INFECTION_DEATH AS VARCHAR(8000))
										,L_DEATH_COMMENTS						= CAST(d4v.L_DEATH_COMMENTS AS VARCHAR(8000))
										,RELIGION								= ISNULL(CAST(relgn.RELIGION_DESC AS VARCHAR(8000)), CAST(d4v.RELIGION AS VARCHAR(8000))) COLLATE DATABASE_DEFAULT
										,CONTACT_DETAILS						= CAST(d4v.CONTACT_DETAILS AS VARCHAR(8000))
										,NOK_NAME								= CAST(d4v.NOK_NAME AS VARCHAR(8000))
										,NOK_ADDRESS_1							= CAST(d4v.NOK_ADDRESS_1 AS VARCHAR(8000))
										,NOK_ADDRESS_2							= CAST(d4v.NOK_ADDRESS_2 AS VARCHAR(8000))
										,NOK_ADDRESS_3							= CAST(d4v.NOK_ADDRESS_3 AS VARCHAR(8000))
										,NOK_ADDRESS_4							= CAST(d4v.NOK_ADDRESS_4 AS VARCHAR(8000))
										,NOK_ADDRESS_5							= CAST(d4v.NOK_ADDRESS_5 AS VARCHAR(8000))
										,NOK_POSTCODE							= CAST(d4v.NOK_POSTCODE AS VARCHAR(8000))
										,NOK_CONTACT							= CAST(d4v.NOK_CONTACT AS VARCHAR(8000))
										,NOK_RELATIONSHIP						= CAST(d4v.NOK_RELATIONSHIP AS VARCHAR(8000))
										,PAT_DEPENDANTS							= CAST(d4v.PAT_DEPENDANTS AS VARCHAR(8000))
										,CARER_NAME								= CAST(d4v.CARER_NAME AS VARCHAR(8000))
										,CARER_ADDRESS_1						= CAST(d4v.CARER_ADDRESS_1 AS VARCHAR(8000))
										,CARER_ADDRESS_2						= CAST(d4v.CARER_ADDRESS_2 AS VARCHAR(8000))
										,CARER_ADDRESS_3						= CAST(d4v.CARER_ADDRESS_3 AS VARCHAR(8000))
										,CARER_ADDRESS_4						= CAST(d4v.CARER_ADDRESS_4 AS VARCHAR(8000))
										,CARER_ADDRESS_5						= CAST(d4v.CARER_ADDRESS_5 AS VARCHAR(8000))
										,CARER_POSTCODE							= CAST(d4v.CARER_POSTCODE AS VARCHAR(8000))
										,CARER_CONTACT							= CAST(d4v.CARER_CONTACT AS VARCHAR(8000))
										,CARER_RELATIONSHIP						= CAST(d4v.CARER_RELATIONSHIP AS VARCHAR(8000))
										,CARER1_TYPE							= CAST(d4v.CARER1_TYPE AS VARCHAR(8000))
										,CARER2_NAME							= CAST(d4v.CARER2_NAME AS VARCHAR(8000))
										,CARER2_ADDRESS_1						= CAST(d4v.CARER2_ADDRESS_1 AS VARCHAR(8000))
										,CARER2_ADDRESS_2						= CAST(d4v.CARER2_ADDRESS_2 AS VARCHAR(8000))
										,CARER2_ADDRESS_3						= CAST(d4v.CARER2_ADDRESS_3 AS VARCHAR(8000))
										,CARER2_ADDRESS_4						= CAST(d4v.CARER2_ADDRESS_4 AS VARCHAR(8000))
										,CARER2_ADDRESS_5						= CAST(d4v.CARER2_ADDRESS_5 AS VARCHAR(8000))
										,CARER2_POSTCODE						= CAST(d4v.CARER2_POSTCODE AS VARCHAR(8000))
										,CARER2_CONTACT							= CAST(d4v.CARER2_CONTACT AS VARCHAR(8000))
										,CARER2_RELATIONSHIP					= CAST(d4v.CARER2_RELATIONSHIP AS VARCHAR(8000))
										,CARER2_TYPE							= CAST(d4v.CARER2_TYPE AS VARCHAR(8000))
										,PT_AT_RISK								= CAST(d4v.PT_AT_RISK AS VARCHAR(8000))
										,REASON_RISK							= CAST(d4v.REASON_RISK AS VARCHAR(8000))
										,GESTATION								= CAST(d4v.GESTATION AS VARCHAR(8000))
										,CAUSE_OF_DEATH_UROLOGY					= CAST(d4v.CAUSE_OF_DEATH_UROLOGY AS VARCHAR(8000))
										,AVOIDABLE_DEATH						= CAST(d4v.AVOIDABLE_DEATH AS VARCHAR(8000))
										,AVOIDABLE_DETAILS						= CAST(d4v.AVOIDABLE_DETAILS AS VARCHAR(8000))
										,OTHER_DEATH_CAUSE_UROLOGY				= CAST(d4v.OTHER_DEATH_CAUSE_UROLOGY AS VARCHAR(8000))
										,ACTION_ID								= CAST(d4v.ACTION_ID AS VARCHAR(8000))
										,STATED_GENDER_CODE						= CAST(d4v.STATED_GENDER_CODE AS VARCHAR(8000))
										,CAUSE_OF_DEATH_UROLOGY_FUP				= CAST(d4v.CAUSE_OF_DEATH_UROLOGY_FUP AS VARCHAR(8000))
										,DEATH_WITHIN_30_DAYS_OF_TREAT			= CAST(d4v.DEATH_WITHIN_30_DAYS_OF_TREAT AS VARCHAR(8000))
										,DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT	= CAST(d4v.DEATH_CAUSE_WITHIN_30_DAYS_OF_TREAT AS VARCHAR(8000))
										,DEATH_CAUSE_LATER_DATE					= CAST(d4v.DEATH_CAUSE_LATER_DATE AS VARCHAR(8000))
										,RegisteredPractice						= CAST(d4v.RegisteredPractice AS VARCHAR(8000))
										,RegisteredGP							= CAST(d4v.RegisteredGP AS VARCHAR(8000))
										,PersonSexualOrientation				= CAST(d4v.PersonSexualOrientation AS VARCHAR(8000))
							FROM		#DataForValidation d4v
							LEFT JOIN	Merge_DM_MatchViews.ltblETHNIC_CAT ec
																			ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = ec.SrcSysID
																			AND	d4v.N1_15_ETHNICITY COLLATE DATABASE_DEFAULT = ec.ETHNIC_CODE COLLATE DATABASE_DEFAULT
							LEFT JOIN	Merge_DM_MatchViews.ltblTITLE ttl
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = ttl.SrcSysID
																		AND	d4v.L_TITLE = ttl.TITLE_CODE
							LEFT JOIN	Merge_DM_MatchViews.ltblRELIGION relgn
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = relgn.SrcSysID
																		AND	d4v.RELIGION = relgn.RELIGION_ID
							LEFT JOIN	Merge_DM_MatchViews.ltblGENDER sex
																		ON	CASE WHEN d4v.SrcSys > 2 THEN 1 ELSE d4v.SrcSys END = sex.SrcSysID
																		AND	d4v.N1_9_SEX COLLATE DATABASE_DEFAULT = sex.GENDER_CODE COLLATE DATABASE_DEFAULT
										) UnpivotPrepare
							UNPIVOT		(FieldValue FOR FieldName IN
												(PATIENT_ID
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
										) AS RowWise

				INNER JOIN		#ColumnDetails cols
													ON	RowWise.FieldName COLLATE DATABASE_DEFAULT = cols.ColumnName COLLATE DATABASE_DEFAULT
				FULL JOIN		(SELECT		d4v_inner.SrcSys_MajorExt
											,d4v_inner.Src_UID_MajorExt
											,d4v_inner.SrcSys_Major
											,d4v_inner.Src_UID_Major
											,d4v_inner.IsValidatedMajor
											,d4v_inner.LastUpdated
											,d4v_inner.SrcSys
											,d4v_inner.Src_UID
											,mmvc_inner.FieldName
											,cols_inner.ColumnDesc
								FROM		Merge_DM_Match.tblDEMOGRAPHICS_Match_MajorValidationColumns mmvc_inner
								INNER JOIN	#DataForValidation d4v_inner
																	ON	mmvc_inner.SrcSys_Major = d4v_inner.SrcSys_MajorExt
																	AND	mmvc_inner.Src_UID_Major = d4v_inner.Src_UID_MajorExt
																	AND	mmvc_inner.SrcSys = d4v_inner.SrcSys
																	AND	mmvc_inner.Src_UID = d4v_inner.Src_UID
																	AND	d4v_inner.IsValidatedMajor = 0
								INNER JOIN	#ColumnDetails cols_inner
																	ON	mmvc_inner.FieldName COLLATE DATABASE_DEFAULT = cols_inner.ColumnName COLLATE DATABASE_DEFAULT
											) mmvc
													ON	RowWise.SrcSys_MajorExt = mmvc.SrcSys_MajorExt
													AND	RowWise.Src_UID_MajorExt COLLATE DATABASE_DEFAULT = mmvc.Src_UID_MajorExt COLLATE DATABASE_DEFAULT
													AND	RowWise.SrcSys = mmvc.SrcSys
													AND	RowWise.Src_UID COLLATE DATABASE_DEFAULT = mmvc.Src_UID COLLATE DATABASE_DEFAULT
													AND	RowWise.FieldName COLLATE DATABASE_DEFAULT = mmvc.FieldName COLLATE DATABASE_DEFAULT

		END





GO
