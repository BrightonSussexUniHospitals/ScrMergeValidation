SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [Merge_DM_MatchViews].[MDT_vw_UH]
				(@Ref_SrcSys_Major TINYINT = NULL
				,@Ref_Src_UID_Major VARCHAR(255) = NULL
				)
RETURNS @TumourSiteMdtData TABLE
			(Ref_SrcSys_Major TINYINT NOT NULL
			,Ref_Src_UID_Major VARCHAR(255) NOT NULL
			,Ref_SrcSys_Minor TINYINT NOT NULL
			,Ref_Src_UID_Minor VARCHAR(255) NOT NULL
			,SrcSysID TINYINT
			,tableName VARCHAR(255)
			,table_UID VARCHAR(255)
			,FrontEndStatus VARCHAR(50)
			,PATIENT_ID INT
			,CARE_ID INT
			,MDT_MDT_ID VARCHAR(255)
			,MeetingList_MDT_ID VARCHAR(255)
			,MeetingList_MDT_ID_DONE INT
			,CarePlan_TEMP_ID VARCHAR(255)
			,PLAN_ID INT
			,MEETING_ID INT
			,MDT_DATE SMALLDATETIME
			,MeetingList_MDT_DATE SMALLDATETIME
			,CarePlan_MDT_DATE SMALLDATETIME
			,MDT_MDT_SITE VARCHAR(50)
			,MeetingList_SITE VARCHAR(50)
			,CarePlan_SITE VARCHAR(50)
			,OTHER_SITE VARCHAR(50)
			,CancerSite VARCHAR(50)
			,MeetingTemplateID INT
			,MDTLocation VARCHAR(50)		-- LOCATION in tblXXX_MDT table
			,CarePlanLocation VARCHAR(50)	-- L_LOCATION in tblMAIN_CARE_PLAN
			,TemplateLocation VARCHAR(50)	-- LOCATION in tblMDT_MEETINGS
			,MDT_Comments VARCHAR(8000)
			,MeetingList_Comments VARCHAR(8000)
			,CarePlan_Comments VARCHAR(8000)
			,SubSite VARCHAR(50)
			,SubSiteSaysSpecialist BIT
			,MdtMeetingsNetworkFlag VARCHAR(50)
			,CarePlanNetworkFlag VARCHAR(5)
			,LastUpdated DATETIME2 NULL
			,HashBytesValue VARBINARY(8000) NULL
			)

AS

BEGIN

-- Run me
-- SELECT * FROM Merge_DM_MatchViews.MDT_vw_UH (DEFAULT, DEFAULT)

-- Create a table to hold the cohort of referrals we want to deduplicate the treatments for
DECLARE @MajorIDs_SCOPE TABLE (SrcSys_Major TINYINT, Src_UID_Major VARCHAR(255), SrcSys TINYINT, Src_UID INT, Src_UIDTxt VARCHAR(255), LastProcessed DATETIME2, PRIMARY KEY (SrcSys, Src_UID))

-- Find the cohort of referrals we want to deduplicate the treatments for
INSERT INTO	@MajorIDs_SCOPE
			(SrcSys_Major
			,Src_UID_Major
			,SrcSys
			,Src_UID
			,Src_UIDTxt
			,LastProcessed
			)
SELECT		mc.SrcSys_Major
			,mc.Src_UID_Major
			,mc.SrcSys
			,TRY_CAST(mc.Src_UID AS INT) AS Src_UID
			,mc.Src_UID AS Src_UIDTxt
			,mc.LastProcessed
FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
INNER JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(NULL, NULL)  Ref_Scope	
																										ON mc.Src_UID_Major = Ref_Scope.Src_UID_Major
																										AND mc.SrcSys_Major = Ref_Scope.SrcSys_Major
-- SELECT COUNT(*) FROM @MajorIDs_SCOPE
 

/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Create and populate a table of MDT data
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/


INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblBRAIN_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblBRAIN_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblBRAIN_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID


INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblBREAST_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblBREAST_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblBREAST_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblCOLORECTAL_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblCOLORECTAL_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblCOLORECTAL_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblCUP_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblCUP_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblCUP_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblGYNAECOLOGY_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblGYNAECOLOGY_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblGYNAECOLOGY_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblHAEMATOLOGY_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblHAEMATOLOGY_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblHAEMATOLOGY_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblHEAD_NECK_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblHEAD_NECK_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblHEAD_NECK_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblLUNG_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblLUNG_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblLUNG_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblOTHER_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblOTHER_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblOTHER_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblPAEDIATRIC_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblPAEDIATRIC_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblPAEDIATRIC_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblSARCOMA_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblSARCOMA_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblSARCOMA_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblSKIN_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblSKIN_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblSKIN_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblUGI_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblUGI_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblUGI_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID

INSERT INTO	@TumourSiteMdtData (Ref_SrcSys_Major,Ref_Src_UID_Major,Ref_SrcSys_Minor,Ref_Src_UID_Minor,SrcSysID,tableName,Table_UID,CARE_ID,MDT_MDT_ID,PLAN_ID,MEETING_ID,MDT_DATE,MDT_MDT_SITE,MDTLocation,MDT_Comments,HashBytesValue) 
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mdt.SrcSysID
			,'tblUROLOGY_MDT' AS tableName
			,mdt.MDT_ID
			,mdt.CARE_ID
			,mdt.MDT_ID
			,mdt.PLAN_ID
			,mdt.MEETING_ID
			,mdt.MDT_DATE
			,mdt.MDT_SITE
			,CASE WHEN mdt.LOCATION != '' THEN mdt.LOCATION END
			,CAST(mdt.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblUROLOGY_MDT'
																	,LEN(CAST(mdt.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mdt.COMMENTS AS VARCHAR(8000)),1)
																	,mdt.MDT_DATE
																	,mdt.MDT_SITE
																	,mdt.MDTDiscussionType
																	,mdt.LOCATION
																	,mdt.PRE_POST
																	,mdt.CARE_PLAN_AGREED_MDT
																	,mdt.REFERRED_TO
																	,mdt.PATH_REVIEW
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblUROLOGY_MDT mdt
												ON	mc.SrcSys = mdt.SrcSysID
												AND	mc.Src_UID = mdt.CARE_ID


/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Insert any additional records from tblMAIN_CARE_PLAN not in a tblXXX_MDT table
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/

-- Fill in null / zls PLAN_ID from the main care plan
UPDATE		ts_mdt
SET			ts_mdt.PLAN_ID = mcp.PLAN_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.MDT_MDT_ID = mcp.TEMP_ID
											AND	ts_mdt.CARE_ID = mcp.CARE_ID
WHERE		ts_mdt.PLAN_ID IS NULL

-- Fill in null / zls PLAN_ID from the main care plan (using date for circumstances when the temp ID referential integrity is broken)
UPDATE		ts_mdt
SET			ts_mdt.PLAN_ID = mcp.PLAN_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.MDT_DATE = mcp.N5_2_MDT_DATE
											AND	ts_mdt.CARE_ID = mcp.CARE_ID
LEFT JOIN	@TumourSiteMdtData PlanIdAlreadyUsed
												ON	mcp.SrcSysID = PlanIdAlreadyUsed.SrcSysID
												AND	mcp.PLAN_ID = PlanIdAlreadyUsed.PLAN_ID
WHERE		ts_mdt.PLAN_ID IS NULL
AND			PlanIdAlreadyUsed.SrcSysID IS NULL

-- Checking whether there are any remaining records in tblMAIN_CARE_PLAN that aren't in our data (and whether they show on the front end)
INSERT INTO	@TumourSiteMdtData
			(Ref_SrcSys_Major 
 			,Ref_Src_UID_Major
			,Ref_SrcSys_Minor 
			,Ref_Src_UID_Minor
			,SrcSysID
			,tableName
			,table_UID
			,CARE_ID
			,CarePlan_TEMP_ID
			,PLAN_ID
			,CarePlan_MDT_DATE
			,CarePlan_SITE
			,CarePlanLocation
			,CarePlan_Comments
			,CarePlanNetworkFlag
			,HashBytesValue
			)
SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,mcp.SrcSysID
			,'tblMAIN_CARE_PLAN' AS tableName
			,mcp.PLAN_ID
			,mcp.CARE_ID
			,mcp.TEMP_ID
			,mcp.PLAN_ID
			,mcp.N5_2_MDT_DATE
			,mcp.L_MDT_SITE
			,mcp.L_LOCATION
			,CAST(mcp.L_MDT_COMMENTS AS VARCHAR(8000))
			,mcp.L_NETWORK
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblMAIN_CARE_PLAN'
																	,LEN(CAST(mcp.L_MDT_COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(mcp.L_MDT_COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(mcp.L_MDT_COMMENTS AS VARCHAR(8000)),1)
																	,mcp.N5_2_MDT_DATE
																	,mcp.L_MDT_SITE
																	,mcp.L_LOCATION
																	,mcp.L_CARE_PLAN_AGREED
																	,mcp.N5_3_PLAN_AGREE_DATE
																	,mcp.N1_3_ORG_CODE_DECISION
																	,mcp.N5_5_CARE_INTENT
																	,mcp.N5_6_TREATMENT_TYPE_1
																	,mcp.N5_6_TREATMENT_TYPE_2
																	,mcp.N5_6_TREATMENT_TYPE_3
																	,mcp.N5_6_TREATMENT_TYPE_4
																	,mcp.N5_10_WHO_STATUS
																	,mcp.N5_9_CO_MORBIDITY
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
												ON	mc.SrcSys = mcp.SrcSysID
												AND	mc.Src_UID = mcp.CARE_ID
LEFT JOIN	@TumourSiteMdtData ts_mdt
									ON	mcp.SrcSysID = ts_mdt.SrcSysID
									AND	mcp.PLAN_ID = ts_mdt.PLAN_ID
WHERE		ts_mdt.SrcSysID IS NULL
AND			TRY_CAST(mcp.TEMP_ID AS INT) IS NULL
ORDER BY	mcp.N5_2_MDT_DATE DESC


/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Insert any additional records from tblMDT_List not in a tblXXX_MDT table
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/

-- Fill in the MeetingList_MDT_ID from the MDT list (using MDT_MDT_ID)
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_MDT_ID = ml.MDT_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MDT_MDT_ID = ml.MDT_ID
									AND	ts_mdt.CARE_ID = ml.CARE_ID
WHERE		TRY_CAST(ts_mdt.MDT_MDT_ID AS INT) IS NOT NULL

-- Fill in the MeetingList_MDT_ID from the MDT list (using care ID and the meeting ID as long as the MeetingList_MDT_ID hasn't already been used)
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_MDT_ID = ml.MDT_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MEETING_ID = ml.MEETING_ID
									AND	ts_mdt.CARE_ID = ml.CARE_ID
LEFT JOIN	@TumourSiteMdtData MeetingListMdtIdAlreadyUsed
												ON	ml.SrcSysID = MeetingListMdtIdAlreadyUsed.SrcSysID
												AND	ml.MDT_ID = MeetingListMdtIdAlreadyUsed.MeetingList_MDT_ID
WHERE		ts_mdt.MeetingList_MDT_ID IS NULL
AND			MeetingListMdtIdAlreadyUsed.SrcSysID IS NULL

-- Determine whether the MDT List attendance has been marked as "DONE" (these records won't show as a pending MDT when the value is 2 - NB: Records show as pending when there is a MeetingList_MDT_ID but no PLAN_ID)
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_MDT_ID_DONE = ml.DONE
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MeetingList_MDT_ID = ml.MDT_ID

-- Checking whether there are any remaining records in tblMDT_LIST that aren't in our data (and whether they show on the front end)
INSERT INTO	@TumourSiteMdtData
			(Ref_SrcSys_Major 
 			,Ref_Src_UID_Major
			,Ref_SrcSys_Minor 
			,Ref_Src_UID_Minor
			,SrcSysID
			,tableName
			,table_UID
			,PATIENT_ID
			,CARE_ID
			,MeetingList_MDT_ID
			,MeetingList_MDT_ID_DONE
			,MEETING_ID
			,MeetingList_MDT_DATE
			,MeetingList_Comments
			,HashBytesValue
			)

SELECT		mc.SrcSys_Major
 			,mc.Src_UID_Major
			,mc.SrcSys
			,mc.Src_UID
			,ml.SrcSysID
			,'tblMDT_LIST' AS tableName
			,ml.MDT_ID
			,ml.PATIENT_ID
			,ml.CARE_ID
			,ml.MDT_ID
			,ml.DONE
			,ml.MEETING_ID
			,ml.MDT_DATE
			,CAST(ml.COMMENTS AS VARCHAR(8000))
			,HashBytesValue		= HASHBYTES('SHA2_512', CONCAT_WS	('|'
																	--,mc.SrcSys_Major
 																	--,mc.Src_UID_Major
																	,mc.LastProcessed
																	,'tblMDT_LIST'
																	,LEN(CAST(ml.COMMENTS AS VARCHAR(8000)))
																	,LEFT(CAST(ml.COMMENTS AS VARCHAR(8000)),1)
																	,RIGHT(CAST(ml.COMMENTS AS VARCHAR(8000)),1)
																	,ml.MDT_DATE
																	,ml.MEETING_ID
																	,ml.DONE
																	,ml.OTHER_SITE
																	,ml.PRE_POST
																	,ml.PT_ORDER
																	,ml.MDTDiscussionType
																	,ml.LAST_SAVED
																	,CAST(ml.MDT_COMMENTS AS VARCHAR(8000))
																	,ml.RADIOLOGY_COMMENTS
																	,ml.HISTOLOGY_COMMENTS
																	,ml.ROOT_CAUSE_COMMENTS
																	))
FROM		@MajorIDs_SCOPE mc
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
												ON	mc.SrcSys = ml.SrcSysID
												AND	mc.Src_UID = ml.CARE_ID
LEFT JOIN	@TumourSiteMdtData ts_mdt
									ON	ml.SrcSysID = ts_mdt.SrcSysID
									AND	ml.MDT_ID = ts_mdt.MeetingList_MDT_ID
WHERE		ts_mdt.SrcSysID IS NULL
AND			ml.CARE_ID IS NOT NULL

/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Update any missing data with information from the main care plan / meeting template
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/

-- Update the CarePlan_TEMP_ID (using PLAN_ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_TEMP_ID = mcp.TEMP_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID

-- Update the CarePlan_TEMP_ID (using TEMP_ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_TEMP_ID = mcp.TEMP_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.MDT_MDT_ID = mcp.TEMP_ID
											AND	ts_mdt.CARE_ID = mcp.CARE_ID
WHERE		ts_mdt.CarePlan_TEMP_ID IS NULL

-- Fill in null meeting ID from the MDT list
UPDATE		ts_mdt
SET			ts_mdt.MEETING_ID = ml.MEETING_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MDT_MDT_ID = ml.MDT_ID
									AND	ts_mdt.CARE_ID = ml.CARE_ID
WHERE		ts_mdt.MEETING_ID IS NULL
AND			TRY_CAST(ts_mdt.MDT_MDT_ID AS INT) IS NOT NULL

-- Fill in null MeetingTemplateID from the MDT list
UPDATE		ts_mdt
SET			ts_mdt.MeetingTemplateID = ml.MEETING_ID
FROM		@TumourSiteMdtData ts_mdt
LEFT JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MEETING_ID = ml.MDT_ID
WHERE		ts_mdt.MeetingTemplateID IS NULL

-- Update the MDT_DATE from the MDT list (where it is still missing)
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_MDT_DATE = ml.MDT_DATE
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MeetingList_MDT_ID = ml.MDT_ID

-- Update the MDT_DATE from the main care plan (where it is still missing)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_MDT_DATE = mcp.N5_2_MDT_DATE
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID
WHERE		ts_mdt.MDT_DATE IS NULL


-- Update the location from the MDT List
UPDATE		ts_mdt
SET			ts_mdt.TemplateLocation = M.LOCATION
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_MEETINGS	M
												ON	ts_mdt.SrcSysID = M.SrcSysID
												AND	ts_mdt.MeetingTemplateID = M.MEETING_ID
												AND ISNULL(M.LOCATION, '') != ''

-- Update the location from the main care plan (using plan ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlanLocation = mcp.L_LOCATION
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID
											AND	ISNULL(mcp.L_LOCATION, '') != ''
WHERE		ISNULL(ts_mdt.CarePlanLocation, '') = ''


-- Update the Comments from the MDT List
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_Comments = CAST(ml.COMMENTS AS VARCHAR(8000))
FROM		@TumourSiteMdtData ts_mdt
LEFT JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MeetingList_MDT_ID = ml.MDT_ID
									AND	ISNULL(ml.COMMENTS, '') != ''
WHERE		ISNULL(ts_mdt.MeetingList_Comments, '') = ''

-- Update the Comments from the main care plan (using plan ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_Comments = CAST(mcp.L_MDT_COMMENTS AS VARCHAR(8000))
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID
											AND	ISNULL(mcp.L_MDT_COMMENTS, '') != ''
WHERE		ISNULL(ts_mdt.CarePlan_Comments, '') = ''

-- Update the MeetingList_SITE
UPDATE		ts_mdt
SET			ts_mdt.MeetingList_SITE = MT.MEETING_TYPE_DESC
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_MEETINGS	M
												ON	ts_mdt.SrcSysID = M.SrcSysID
												AND	ts_mdt.MeetingTemplateID = M.MEETING_ID
INNER JOIN	Merge_DM_MatchViews.ltblMDT_MEETING_TYPE MT
													ON	M.MEETING_TYPE_ID = MT.MEETING_TYPE_ID
													AND	M.SrcSysID = MT.SrcSysID
													AND ISNULL(MT.MEETING_TYPE_DESC, '') != ''

-- Update the CarePlan_SITE (using temp ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_SITE = MT.MEETING_TYPE_DESC
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.CarePlan_TEMP_ID = mcp.TEMP_ID
											AND	ts_mdt.CARE_ID = mcp.CARE_ID
INNER JOIN	Merge_DM_MatchViews.ltblMDT_MEETING_TYPE MT
													ON	mcp.L_MDT_SITE = MT.MEETING_TYPE_ID
													AND	mcp.SrcSysID = MT.SrcSysID
													AND ISNULL(MT.MEETING_TYPE_DESC, '') != ''

-- Update the CarePlan_SITE (using plan ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlan_SITE = MT.MEETING_TYPE_DESC
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID
											AND	ts_mdt.CARE_ID = mcp.CARE_ID
INNER JOIN	Merge_DM_MatchViews.ltblMDT_MEETING_TYPE MT
													ON	mcp.L_MDT_SITE = MT.MEETING_TYPE_ID
													AND	mcp.SrcSysID = MT.SrcSysID
													AND ISNULL(MT.MEETING_TYPE_DESC, '') != ''

-- Update the OTHER_SITE
UPDATE		ts_mdt
SET			ts_mdt.OTHER_SITE = ml.OTHER_SITE
FROM		@TumourSiteMdtData ts_mdt
LEFT JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MeetingList_MDT_ID = ml.MDT_ID
									AND ISNULL(ml.OTHER_SITE, '') != ''

-- Update the CancerSite and PATIENT_ID from the referral
UPDATE		ts_mdt
SET			ts_mdt.CancerSite = mainref.L_CANCER_SITE
			,ts_mdt.PATIENT_ID = mainref.PATIENT_ID
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_REFERRALS mainref
												ON	ts_mdt.SrcSysID = mainref.SrcSysID
												AND	ts_mdt.CARE_ID = mainref.CARE_ID

-- Update the sub site and SubSiteSaysSpecialist
UPDATE		ts_mdt
SET			ts_mdt.SubSite = SS.SUB_DESC
			,ts_mdt.SubSiteSaysSpecialist = CASE WHEN  SS.SUB_DESC LIKE '%Specialist%' THEN 1 ELSE 0 END
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_MEETINGS	M
												ON	ts_mdt.SrcSysID = M.SrcSysID
												AND	ts_mdt.MeetingTemplateID = M.MEETING_ID
INNER JOIN	Merge_DM_MatchViews.ltblCANCER_SUB_SITE SS
													ON	M.SUB_SITE = SS.SUB_ID
													AND	M.SrcSysID = SS.SrcSysID
													
-- Update the MdtMeetingsNetworkFlag
UPDATE		ts_mdt
SET			ts_mdt.MdtMeetingsNetworkFlag = mt.MDT_DESC
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMDT_MEETINGS	M
												ON	ts_mdt.SrcSysID = M.SrcSysID
												AND	ts_mdt.MeetingTemplateID = M.MEETING_ID
INNER JOIN	Merge_DM_MatchViews.ltblMDT_TYPE mt
												ON	M.SrcSysID = mt.SrcSysID
												AND	m.LOCAL_NETWORK = mt.MDT_ID

-- Update the CarePlan_SITE (using plan ID)
UPDATE		ts_mdt
SET			ts_mdt.CarePlanNetworkFlag = mcp.L_NETWORK
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID


/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Ascertain and Populate the Front End Status
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/

/*
UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = NULL
FROM		@TumourSiteMdtData ts_mdt
*/

UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = 'Not shown (tblMDT_LIST Palliative Care)'
FROM		@TumourSiteMdtData ts_mdt
WHERE		ts_mdt.tableName = 'tblMDT_LIST'
AND			ts_mdt.MeetingList_SITE = 'Palliative Care'
AND			ts_mdt.FrontEndStatus IS NULL

UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = 'Care PLAN / MDT'
FROM		@TumourSiteMdtData ts_mdt
WHERE		ts_mdt.CarePlan_TEMP_ID IS NOT NULL
AND			ts_mdt.FrontEndStatus IS NULL

UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = 'Pending MDTs'
FROM		@TumourSiteMdtData ts_mdt
WHERE		ts_mdt.CarePlan_TEMP_ID IS NULL
AND			ts_mdt.MeetingList_MDT_ID IS NOT NULL
AND			ts_mdt.MeetingList_MDT_ID_DONE IN (0,1)
AND			ts_mdt.FrontEndStatus IS NULL

UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = 'Not shown (pending but done)'
FROM		@TumourSiteMdtData ts_mdt
WHERE		ts_mdt.CarePlan_TEMP_ID IS NULL
AND			ts_mdt.MeetingList_MDT_ID IS NOT NULL
AND			ts_mdt.MeetingList_MDT_ID_DONE = 2
AND			ts_mdt.FrontEndStatus IS NULL

UPDATE		ts_mdt
SET			ts_mdt.FrontEndStatus = 'Not shown (no care plan or mdt list entry)'
FROM		@TumourSiteMdtData ts_mdt
WHERE		ts_mdt.CarePlan_TEMP_ID IS NULL
AND			ts_mdt.MeetingList_MDT_ID IS NULL
AND			ts_mdt.FrontEndStatus IS NULL


/***********************************************************************************************************************************************************************************************************************************************************************************************************************/
-- Retrieve the last updated information
/***********************************************************************************************************************************************************************************************************************************************************************************************************************/

-- Update the LastUpdated field from tblMDT_LIST.LAST_SAVED
UPDATE		ts_mdt
SET			ts_mdt.LastUpdated = ml.LAST_SAVED
FROM		@TumourSiteMdtData ts_mdt
LEFT JOIN	Merge_DM_MatchViews.tblMDT_LIST ml
									ON	ts_mdt.SrcSysID = ml.SrcSysID
									AND	ts_mdt.MeetingList_MDT_ID = ml.MDT_ID
									AND	ml.LAST_SAVED IS NOT NULL
WHERE		ml.LAST_SAVED > ts_mdt.LastUpdated
OR			ts_mdt.LastUpdated IS NULL


-- Update the LastUpdated field from tblMAIN_CARE_PLAN.ACTION_ID
UPDATE		ts_mdt
SET			ts_mdt.LastUpdated = aud.ACTION_DATE
FROM		@TumourSiteMdtData ts_mdt
INNER JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	ts_mdt.SrcSysID = mcp.SrcSysID
											AND	ts_mdt.PLAN_ID = mcp.PLAN_ID
INNER JOIN	Merge_DM_MatchViews.tblAUDIT aud
									ON	mcp.SrcSysID = aud.SrcSysID
									AND	mcp.ACTION_ID = aud.ACTION_ID
WHERE		aud.ACTION_DATE > ts_mdt.LastUpdated
OR			ts_mdt.LastUpdated IS NULL


RETURN

END



GO
