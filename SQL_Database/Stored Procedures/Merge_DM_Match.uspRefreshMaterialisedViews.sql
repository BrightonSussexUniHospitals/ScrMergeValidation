SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_Match].[uspRefreshMaterialisedViews] AS 

/*************************************************************************************************************************************************************************************************/
-- tblDEMOGRAPHICS
/*************************************************************************************************************************************************************************************************/

TRUNCATE TABLE Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH
INSERT INTO Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH SELECT * FROM Merge_DM_MatchViews.tblDEMOGRAPHICS_vw_UH

-- ALTER TABLE Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH ADD CONSTRAINT PK_tblDEMOGRAPHICS_mvw_UH PRIMARY KEY CLUSTERED (SrcSys, Src_UID)
-- CREATE NONCLUSTERED INDEX tblDEMOGRAPHICS_mvw_UH_IsSCR ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (IsSCR)
-- CREATE NONCLUSTERED INDEX tblDEMOGRAPHICS_mvw_UH_HashBytesValue ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (HashBytesValue)
-- CREATE NONCLUSTERED INDEX tblDEMOGRAPHICS_mvw_UH_LastUpdated ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (LastUpdated)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_IsSCR] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (IsSCR ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_IsMostRecent] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (IsMostRecent ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_NhsNumber] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (NhsNumber ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_OrignalNhsNo] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (OriginalNhsNo ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_OriginalPasId] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (OriginalPasId ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_PasId] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (PasId ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_CasenoteId] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (CasenoteId ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DoB] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (DoB ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DoD] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (DoD ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Surname] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Surname ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Forename] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Forename ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Postcode] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Postcode ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Sex] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Sex ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address1] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Address1 ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address2] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Address2 ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address3] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Address3 ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address4] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Address4 ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Address5] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Address5 ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_DeathStatus] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (DeathStatus ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Title] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Title ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_Ethnicity] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (Ethnicity ASC)
-- CREATE NONCLUSTERED INDEX [Ix_Dem_UH_ReligionCode] ON Merge_DM_Match.tblDEMOGRAPHICS_mvw_UH (ReligionCode ASC)

/*************************************************************************************************************************************************************************************************/
-- tblMAIN_REFERRALS
/*************************************************************************************************************************************************************************************************/

TRUNCATE TABLE Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH
INSERT INTO Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH SELECT * FROM Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_UH_Filtered

-- ALTER TABLE Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH ADD CONSTRAINT PK_tblMAIN_REFERRALS_mvw_UH PRIMARY KEY CLUSTERED (SrcSys, Src_UID)
-- CREATE NONCLUSTERED INDEX tblMAIN_REFERRALS_mvw_UH_HashBytesValue ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (HashBytesValue)
-- CREATE NONCLUSTERED INDEX tblMAIN_REFERRALS_mvw_UH_LastUpdated ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (LastUpdated)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_IsSCR] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (IsSCR ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_linkedcareID] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (linkedcareID ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_PatientPathwayID] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (PatientPathwayID ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_HospitalNumber] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (HospitalNumber ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_NHSNumber] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (NHSNumber ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_CANCER_SITE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (L_CANCER_SITE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_4_PRIORITY_TYPE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_4_PRIORITY_TYPE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_6_RECEIPT_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_6_RECEIPT_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_5_DECISION_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_5_DECISION_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_ADT_REF_ID_SameSys] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (ADT_REF_ID_SameSys ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_ADT_PLACER_ID_SameSys] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (ADT_PLACER_ID_SameSys ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_1_REFERRAL_SOURCE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_1_REFERRAL_SOURCE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_12_CANCER_TYPE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_12_CANCER_TYPE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_13_CANCER_STATUS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_13_CANCER_STATUS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_9_FIRST_SEEN_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N2_9_FIRST_SEEN_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N1_3_ORG_CODE_SEEN] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N1_3_ORG_CODE_SEEN ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_OTHER_DIAG_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (L_OTHER_DIAG_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N_UPGRADE_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N_UPGRADE_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N_UPGRADE_ORG_CODE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N_UPGRADE_ORG_CODE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_1_DIAGNOSIS_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N4_1_DIAGNOSIS_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_DIAGNOSIS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (L_DIAGNOSIS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_ORG_CODE_DIAGNOSIS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (L_ORG_CODE_DIAGNOSIS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_2_DIAGNOSIS_CODE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N4_2_DIAGNOSIS_CODE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_3_LATERALITY] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (N4_3_LATERALITY ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_PT_INFORMED_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (L_PT_INFORMED_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_FasterDiagnosisOrganisationCode] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (FasterDiagnosisOrganisationCode ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_FasterDiagnosisExclusionReasonCode] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (FasterDiagnosisExclusionReasonCode ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_NotRecurrence] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH (NotRecurrence ASC)

TRUNCATE TABLE Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded
INSERT INTO Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded SELECT * FROM Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_UH_Excluded

-- ALTER TABLE Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded ADD CONSTRAINT PK_tblMAIN_REFERRALS_mvw_UH_Excluded PRIMARY KEY CLUSTERED (SrcSys, Src_UID)
-- CREATE NONCLUSTERED INDEX tblMAIN_REFERRALS_mvw_UH_HashBytesValue ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (HashBytesValue)
-- CREATE NONCLUSTERED INDEX tblMAIN_REFERRALS_mvw_UH_LastUpdated ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (LastUpdated)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_IsSCR] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (IsSCR ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_linkedcareID] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (linkedcareID ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_PatientPathwayID] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (PatientPathwayID ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_HospitalNumber] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (HospitalNumber ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_NHSNumber] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (NHSNumber ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_CANCER_SITE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (L_CANCER_SITE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_4_PRIORITY_TYPE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_4_PRIORITY_TYPE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_6_RECEIPT_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_6_RECEIPT_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_5_DECISION_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_5_DECISION_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_ADT_REF_ID_SameSys] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (ADT_REF_ID_SameSys ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_ADT_PLACER_ID_SameSys] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (ADT_PLACER_ID_SameSys ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_1_REFERRAL_SOURCE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_1_REFERRAL_SOURCE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_12_CANCER_TYPE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_12_CANCER_TYPE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_13_CANCER_STATUS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_13_CANCER_STATUS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N2_9_FIRST_SEEN_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N2_9_FIRST_SEEN_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N1_3_ORG_CODE_SEEN] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N1_3_ORG_CODE_SEEN ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_OTHER_DIAG_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (L_OTHER_DIAG_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N_UPGRADE_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N_UPGRADE_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N_UPGRADE_ORG_CODE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N_UPGRADE_ORG_CODE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_1_DIAGNOSIS_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N4_1_DIAGNOSIS_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_DIAGNOSIS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (L_DIAGNOSIS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_ORG_CODE_DIAGNOSIS] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (L_ORG_CODE_DIAGNOSIS ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_2_DIAGNOSIS_CODE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N4_2_DIAGNOSIS_CODE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_N4_3_LATERALITY] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (N4_3_LATERALITY ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_L_PT_INFORMED_DATE] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (L_PT_INFORMED_DATE ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_FasterDiagnosisOrganisationCode] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (FasterDiagnosisOrganisationCode ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_FasterDiagnosisExclusionReasonCode] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (FasterDiagnosisExclusionReasonCode ASC)
-- CREATE NONCLUSTERED INDEX [Ix_tblMAIN_REFERRALS_NotRecurrence] ON Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH_Excluded (NotRecurrence ASC)

/*************************************************************************************************************************************************************************************************/
-- Treatments
/*************************************************************************************************************************************************************************************************/

TRUNCATE TABLE Merge_DM_Match.Treatments_mvw_UH
INSERT INTO Merge_DM_Match.Treatments_mvw_UH
			(Ref_SrcSys_Minor
			,Ref_Src_UID_Minor
			,TreatmentDate
			,Treatment
			,TreatmentSite
			,TreatmentID
			,LastUpdated
			,HashBytesValue
			,NonNullColumnCount
			)
 SELECT		Tx.Ref_SrcSys_Minor
			,Tx.Ref_Src_UID_Minor
			,Tx.TreatmentDate
			,Tx.Treatment
			,Tx.TreatmentSite
			,Tx.TreatmentID
			,Tx.LastUpdated
			,Tx.HashBytesValue
			,Tx.NonNullColumnCount
 FROM		Merge_DM_MatchViews.Treatments_vw_UH (DEFAULT,DEFAULT) Tx
-- ALTER TABLE Merge_DM_Match.Treatments_mvw_UH ADD CONSTRAINT PK_Treatments_mvw_UH PRIMARY KEY CLUSTERED (Ref_SrcSys_Minor, Treatment, TreatmentID)
-- CREATE NONCLUSTERED INDEX Treatments_mvw_UH_HashBytesValue ON Merge_DM_Match.Treatments_mvw_UH (HashBytesValue)
-- CREATE NONCLUSTERED INDEX Treatments_mvw_UH_LastUpdated ON Merge_DM_Match.Treatments_mvw_UH (LastUpdated)
-- CREATE NONCLUSTERED INDEX Treatments_mvw_UH_Minor ON Merge_DM_Match.Treatments_mvw_UH (Ref_SrcSys_Minor, Ref_Src_UID_Minor)
-- CREATE NONCLUSTERED INDEX Treatments_mvw_UH_TreatmentDate ON Merge_DM_Match.Treatments_mvw_UH (TreatmentDate)
-- CREATE NONCLUSTERED INDEX Treatments_mvw_UH_TreatmentSite ON Merge_DM_Match.Treatments_mvw_UH (TreatmentSite)

/*************************************************************************************************************************************************************************************************/
-- MDTs
/*************************************************************************************************************************************************************************************************/

TRUNCATE TABLE Merge_DM_Match.MDT_mvw_UH
INSERT INTO Merge_DM_Match.MDT_mvw_UH
			(Ref_SrcSys_Minor
			,Ref_Src_UID_Minor
			,SrcSysID
			,tableName
			,table_UID
			,FrontEndStatus
			,PATIENT_ID
			,CARE_ID
			,MDT_MDT_ID
			,MeetingList_MDT_ID
			,MeetingList_MDT_ID_DONE
			,CarePlan_TEMP_ID
			,PLAN_ID
			,MEETING_ID
			,MDT_DATE
			,MeetingList_MDT_DATE
			,CarePlan_MDT_DATE
			,MDT_MDT_SITE
			,MeetingList_SITE
			,CarePlan_SITE
			,OTHER_SITE
			,CancerSite
			,MeetingTemplateID
			,MDTLocation
			,CarePlanLocation
			,TemplateLocation
			,MDT_Comments
			,MeetingList_Comments
			,CarePlan_Comments
			,SubSite
			,SubSiteSaysSpecialist
			,MdtMeetingsNetworkFlag
			,CarePlanNetworkFlag
			,LastUpdated
			,HashBytesValue
			)
SELECT		MDT.Ref_SrcSys_Minor
			,MDT.Ref_Src_UID_Minor
			,MDT.SrcSysID
			,MDT.tableName
			,MDT.table_UID
			,MDT.FrontEndStatus
			,MDT.PATIENT_ID
			,MDT.CARE_ID
			,MDT.MDT_MDT_ID
			,MDT.MeetingList_MDT_ID
			,MDT.MeetingList_MDT_ID_DONE
			,MDT.CarePlan_TEMP_ID
			,MDT.PLAN_ID
			,MDT.MEETING_ID
			,MDT.MDT_DATE
			,MDT.MeetingList_MDT_DATE
			,MDT.CarePlan_MDT_DATE
			,MDT.MDT_MDT_SITE
			,MDT.MeetingList_SITE
			,MDT.CarePlan_SITE
			,MDT.OTHER_SITE
			,MDT.CancerSite
			,MDT.MeetingTemplateID
			,MDT.MDTLocation
			,MDT.CarePlanLocation
			,MDT.TemplateLocation
			,MDT.MDT_Comments
			,MDT.MeetingList_Comments
			,MDT.CarePlan_Comments
			,MDT.SubSite
			,MDT.SubSiteSaysSpecialist
			,MDT.MdtMeetingsNetworkFlag
			,MDT.CarePlanNetworkFlag
			,MDT.LastUpdated
			,MDT.HashBytesValue
FROM		Merge_DM_MatchViews.MDT_vw_UH (DEFAULT,DEFAULT) MDT

-- ALTER TABLE Merge_DM_Match.MDT_mvw_UH ADD CONSTRAINT PK_MDT_mvw_UH PRIMARY KEY CLUSTERED (SrcSysID, tableName, table_UID)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_HashBytesValue ON Merge_DM_Match.MDT_mvw_UH (HashBytesValue)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_LastUpdated ON Merge_DM_Match.MDT_mvw_UH (LastUpdated)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_Minor ON Merge_DM_Match.MDT_mvw_UH (Ref_SrcSys_Minor, Ref_Src_UID_Minor)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_tableName ON Merge_DM_Match.MDT_mvw_UH (tableName)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_table_UID ON Merge_DM_Match.MDT_mvw_UH (table_UID)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_FrontEndStatus ON Merge_DM_Match.MDT_mvw_UH (FrontEndStatus)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_MDT_DATE ON Merge_DM_Match.MDT_mvw_UH (MDT_DATE)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_MeetingList_MDT_DATE ON Merge_DM_Match.MDT_mvw_UH (MeetingList_MDT_DATE)
-- CREATE NONCLUSTERED INDEX MDT_mvw_UH_CarePlan_MDT_DATE ON Merge_DM_Match.MDT_mvw_UH (CarePlan_MDT_DATE)


GO
