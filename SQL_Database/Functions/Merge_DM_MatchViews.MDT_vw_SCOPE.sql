SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [Merge_DM_MatchViews].[MDT_vw_SCOPE]
				(@Ref_SrcSys_Major TINYINT = NULL
				,@Ref_Src_UID_Major VARCHAR(255) = NULL
				)
RETURNS @MDT TABLE
			(
			Ref_SrcSys_Major TINYINT NOT NULL
			,Ref_Src_UID_Major VARCHAR(255) NOT NULL
			,Ref_SrcSys_Minor TINYINT NOT NULL
			,Ref_Src_UID_Minor VARCHAR(255) NOT NULL
			,MDT_DATE SMALLDATETIME NULL
			,RefCancerSite VARCHAR(50) NULL
			,CancerSite VARCHAR(50) NULL
			,tableName VARCHAR(255) NOT NULL
			,table_UID VARCHAR(255) NOT NULL
			,Migrate BIT NULL
			,LastValidatedDttm DATETIME2 NULL
			,LastValidatedBy VARCHAR(255) NULL
			,LastValidated_SrcSys_Major TINYINT NULL
			,LastValidated_Src_UID_Major VARCHAR(255) NULL
			,LastProcessed DATETIME2 NULL
			,RefLastProcessed DATETIME2 NULL
			,InScope BIT NOT NULL
			)
AS

BEGIN

-- Run me
-- SELECT * FROM Merge_DM_MatchViews.MDT_vw_SCOPE (DEFAULT, DEFAULT)
-- SELECT * FROM Merge_DM_MatchViews.MDT_vw_SCOPE (1, '360464')
-- SELECT * FROM Merge_DM_MatchViews.MDT_vw_SCOPE (1, '388974')
 

INSERT INTO		@MDT(
				Ref_SrcSys_Major 
 				,Ref_Src_UID_Major
				,Ref_SrcSys_Minor 
				,Ref_Src_UID_Minor
				,MDT_DATE
				,RefCancerSite
				,CancerSite
				,tableName 
				,table_UID
				,Migrate
				,LastValidatedDttm
				,LastValidatedBy
				,LastValidated_SrcSys_Major
				,LastValidated_Src_UID_Major
				,LastProcessed
				,RefLastProcessed
				,InScope
				)
SELECT		DuplicateMDT.Ref_SrcSys_Major
			,DuplicateMDT.Ref_Src_UID_Major
			,UH.Ref_SrcSys_Minor
			,UH.Ref_Src_UID_Minor
			,COALESCE(UH.CarePlan_MDT_DATE,UH.MDT_DATE,UH.MeetingList_MDT_DATE)
			,ref_UH.L_CANCER_SITE AS RefCancerSite
			,UH.CancerSite
			,UH.tableName
			,UH.table_UID
			,mc.Migrate
			,mc.LastValidatedDttm
			,mc.LastValidatedBy
			,mc.LastValidated_SrcSys_Major
			,mc.LastValidated_Src_UID_Major
			,mc.LastProcessed
			,DuplicateMDT.RefLastProcessed
			,CASE WHEN DuplicateMDT.MdtCount > 1 AND DuplicateMDT.HasWSHT > 0 AND DuplicateMDT.HasBSUH > 0 THEN 1 ELSE 0 END
FROM		(SELECT		ref_scope.SrcSys_Major AS Ref_SrcSys_Major
						,ref_scope.Src_UID_Major AS Ref_Src_UID_Major
						,COALESCE(UH_inner.CarePlan_MDT_DATE,UH_inner.MDT_DATE,UH_inner.MeetingList_MDT_DATE) AS MDT_DATE
						,COUNT(*) AS MdtCount
						,SUM(CASE WHEN mc_inner.SrcSys = 1 THEN 1 ELSE 0 END) AS HasWSHT
						,SUM(CASE WHEN mc_inner.SrcSys = 2 THEN 1 ELSE 0 END) AS HasBSUH
						,MAX(mc_inner.LastProcessed) AS RefLastProcessed
			FROM		Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(@Ref_SrcSys_Major,@Ref_Src_UID_Major) ref_scope
			INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_inner
																		ON	ref_scope.SrcSys_Major = mc_inner.SrcSys_Major
																		AND	ref_scope.Src_UID_Major = mc_inner.Src_UID_Major
			INNER JOIN	Merge_DM_Match.MDT_mvw_UH UH_inner
												ON	mc_inner.SrcSys = UH_inner.SrcSysID
												AND	mc_inner.Src_UID = UH_inner.CARE_ID
												AND	UH_inner.FrontEndStatus IN ('Care PLAN / MDT', 'Pending MDTs')
			GROUP BY	ref_scope.SrcSys_Major
						,ref_scope.Src_UID_Major
						,COALESCE(UH_inner.CarePlan_MDT_DATE,UH_inner.MDT_DATE,UH_inner.MeetingList_MDT_DATE)
						) DuplicateMDT
INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control ref_mc
															ON	DuplicateMDT.Ref_SrcSys_Major = ref_mc.SrcSys_Major
															AND	DuplicateMDT.Ref_Src_UID_Major = ref_mc.Src_UID_Major
INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH ref_UH
															ON	ref_mc.SrcSys_Major = ref_UH.SrcSys
															AND	ref_mc.Src_UID_Major = ref_UH.Src_UID
INNER JOIN	Merge_DM_Match.MDT_mvw_UH UH
												ON	ref_mc.SrcSys = uh.Ref_SrcSys_Minor
												AND	ref_mc.Src_UID = UH.Ref_Src_UID_Minor
												AND	DuplicateMDT.MDT_DATE = COALESCE(UH.CarePlan_MDT_DATE,UH.MDT_DATE,UH.MeetingList_MDT_DATE)
LEFT JOIN	Merge_DM_Match.MDT_Match_Control mc
														ON	ref_mc.SrcSys = mc.SrcSys
														AND	UH.tableName = mc.tableName
														AND	UH.table_UID = mc.table_UID

RETURN

END

GO
