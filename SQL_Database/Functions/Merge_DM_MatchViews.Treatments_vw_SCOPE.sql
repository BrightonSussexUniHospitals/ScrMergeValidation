SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [Merge_DM_MatchViews].[Treatments_vw_SCOPE]
				(@Ref_SrcSys_Major TINYINT = NULL
				,@Ref_Src_UID_Major VARCHAR(255) = NULL
				)
RETURNS @Treatments TABLE
			(
			Ref_SrcSys_Major TINYINT NOT NULL
			,Ref_Src_UID_Major VARCHAR(255) NOT NULL
			,Ref_SrcSys_Minor TINYINT NOT NULL
			,Ref_Src_UID_Minor VARCHAR(255) NOT NULL
			,TreatmentDate SMALLDATETIME NULL
			,Treatment VARCHAR(255) NOT NULL
			,TreatmentSite VARCHAR(255) NULL
			,TreatmentID INT NOT NULL
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
-- SELECT * FROM Merge_DM_MatchViews.Treatments_vw_SCOPE (DEFAULT, DEFAULT)
-- SELECT * FROM Merge_DM_MatchViews.Treatments_vw_SCOPE (1, '360464')
-- SELECT * FROM Merge_DM_MatchViews.Treatments_vw_SCOPE (1, '388974')
 

--insert records from tblMAIN_CHEMOTHERAPY
INSERT INTO		@Treatments(
				Ref_SrcSys_Major 
 				,Ref_Src_UID_Major
				,Ref_SrcSys_Minor 
				,Ref_Src_UID_Minor
				,TreatmentDate
				,Treatment 
				,TreatmentSite
				,TreatmentID
				,Migrate
				,LastValidatedDttm
				,LastValidatedBy
				,LastValidated_SrcSys_Major
				,LastValidated_Src_UID_Major
				,LastProcessed
				,RefLastProcessed
				,InScope
				)
SELECT		DuplicateTreatments.Ref_SrcSys_Major
			,DuplicateTreatments.Ref_Src_UID_Major
			,UH.Ref_SrcSys_Minor
			,UH.Ref_Src_UID_Minor
			,UH.TreatmentDate
			,UH.Treatment
			,UH.TreatmentSite
			,UH.TreatmentID
			,mc.Migrate
			,mc.LastValidatedDttm
			,mc.LastValidatedBy
			,mc.LastValidated_SrcSys_Major
			,mc.LastValidated_Src_UID_Major
			,mc.LastProcessed
			,DuplicateTreatments.RefLastProcessed
			,CASE WHEN DuplicateTreatments.TreatmentCount > 1 THEN 1 ELSE 0 END
FROM		(SELECT		UH_outer.Ref_SrcSys_Major
						,UH_outer.Ref_Src_UID_Major
						,UH_outer.TreatmentDate
						,MAX(UH_outer.RefLastProcessed) AS RefLastProcessed
						,COUNT(*) AS TreatmentCount
			FROM		(SELECT		mc_inner.SrcSys_Major AS Ref_SrcSys_Major
									,mc_inner.Src_UID_Major AS Ref_Src_UID_Major
									,UH_inner.Ref_SrcSys_Minor
									,UH_inner.Ref_Src_UID_Minor
									,UH_inner.TreatmentDate
									,MAX(mc_inner.LastProcessed) AS RefLastProcessed
						FROM		Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(@Ref_SrcSys_Major, @Ref_Src_UID_Major) ref_scope -- Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE(DEFAULT, DEFAULT) ref_scope 
						INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_inner
																					ON	ref_scope.SrcSys_Major = mc_inner.SrcSys_Major
																					AND	ref_scope.Src_UID_Major = mc_inner.Src_UID_Major
						INNER JOIN	Merge_DM_Match.Treatments_mvw_UH UH_inner
																			ON	mc_inner.SrcSys = UH_inner.Ref_SrcSys_Minor
																			AND	mc_inner.Src_UID = UH_inner.Ref_Src_UID_Minor
						GROUP BY	mc_inner.SrcSys_Major
									,mc_inner.Src_UID_Major	
									,UH_inner.Ref_SrcSys_Minor
									,UH_inner.Ref_Src_UID_Minor
									,UH_inner.TreatmentDate
									) UH_outer
			GROUP BY	UH_outer.Ref_SrcSys_Major
						,UH_outer.Ref_Src_UID_Major	
						,UH_outer.TreatmentDate
						) DuplicateTreatments
INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control ref_mc
															ON	DuplicateTreatments.Ref_SrcSys_Major = ref_mc.SrcSys_Major
															AND	DuplicateTreatments.Ref_Src_UID_Major = ref_mc.Src_UID_Major
INNER JOIN	Merge_DM_Match.Treatments_mvw_UH UH
												ON	ref_mc.SrcSys = uh.Ref_SrcSys_Minor
												AND	ref_mc.Src_UID = UH.Ref_Src_UID_Minor
												AND	DuplicateTreatments.TreatmentDate = UH.TreatmentDate
LEFT JOIN	Merge_DM_Match.Treatments_Match_Control mc
														ON	ref_mc.SrcSys = mc.SrcSys
														AND	UH.Treatment = mc.Treatment
														AND	UH.TreatmentID = mc.TreatmentID


RETURN

END
GO
