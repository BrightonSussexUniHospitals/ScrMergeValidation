SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [Merge_DM_MatchViews].[tblMAIN_REFERRALS_vw_SCOPE]
				(@SrcSys_Major TINYINT = NULL
				,@Src_UID_Major VARCHAR(255) = NULL
				)
RETURNS @ReferralMajors TABLE
			(
			SrcSys_Major TINYINT NOT NULL
			,Src_UID_Major VARCHAR(255) NOT NULL
			)
AS

BEGIN

-- Run me
-- SELECT * FROM Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE (DEFAULT, DEFAULT)
-- SELECT * FROM Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE (1, '388974')
-- SELECT * FROM Merge_DM_MatchViews.tblMAIN_REFERRALS_vw_SCOPE (1, '430084')

/*******************************************************************************************************************************************************************************************************************************************************************************/
-- Find all related entities (if we have been provided paremeters to return a specific referral Major record)
/*******************************************************************************************************************************************************************************************************************************************************************************/

		-- Create the #RelatedEntities table
		DECLARE @RelatedEntities TABLE (IsSCR BIT NOT NULL, SrcSys TINYINT NOT NULL, Src_UID VARCHAR(255) NOT NULL)

		-- Find the related entities
		IF	@SrcSys_Major IS NOT NULL
		AND	@Src_UID_Major IS NOT NULL
		BEGIN

				-- Insert the records that relate to the Major ID supplied
				DECLARE @SrcSys TINYINT = 1
				DECLARE @Src_UID VARCHAR(255) = ''
				INSERT INTO	@RelatedEntities
							(IsSCR
							,SrcSys
							,Src_UID)
				SELECT		ISNULL(mc_minor.IsSCR, mc_major.IsSCR) AS IsSCR
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys) AS SrcSys
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) AS Src_UID
				FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_major
				LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc_minor
																	ON	mc_major.SrcSys_Major = mc_minor.SrcSys_Major
																	AND	mc_Major.Src_UID_Major = mc_minor.Src_UID_Major
				WHERE		(mc_major.SrcSys_Major = @SrcSys_Major
				AND			mc_major.Src_UID_Major = @Src_UID_Major)
				OR			(mc_major.SrcSys = @SrcSys_Major
				AND			mc_major.Src_UID = @Src_UID_Major)
				GROUP BY	ISNULL(mc_minor.IsSCR, mc_major.IsSCR)
							,ISNULL(mc_minor.SrcSys, mc_major.SrcSys)
							,ISNULL(mc_minor.Src_UID, mc_major.Src_UID) 

				-- Loop through the dataset to find any other records that were originally matched
				DECLARE @NoMoreUpdates SMALLINT = 0
				WHILE @NoMoreUpdates = 0
				BEGIN
			
						INSERT INTO	@RelatedEntities
									(IsSCR
									,SrcSys
									,Src_UID)
						SELECT		mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative
						FROM		@RelatedEntities inc
						INNER JOIN	(SELECT		SrcSys_A AS SrcSys_Link
												,Src_UID_A AS Src_UID_Link
												,SrcSys_B AS SrcSys_Iterative
												,Src_UID_B AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
			
									UNION
			
									SELECT		SrcSys_B AS SrcSys_Link
												,Src_UID_B AS Src_UID_Link
												,SrcSys_A AS SrcSys_Iterative
												,Src_UID_A AS Src_UID_Iterative
									FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_EntityPairs_Unique ep_u
												) IterateNext
																ON	inc.SrcSys = IterateNext.SrcSys_Link
																AND	inc.Src_UID = IterateNext.Src_UID_Link
						INNER JOIN	Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
															ON	IterateNext.SrcSys_Iterative = mc.SrcSys
															AND	IterateNext.Src_UID_Iterative = mc.Src_UID
						LEFT JOIN	@RelatedEntities inc_notPresent
															ON	IterateNext.SrcSys_Iterative = inc_notPresent.SrcSys
															AND	IterateNext.Src_UID_Iterative = inc_notPresent.Src_UID
						WHERE		inc_notPresent.SrcSys IS NULL
						GROUP BY	mc.IsSCR
									,IterateNext.SrcSys_Iterative
									,IterateNext.Src_UID_Iterative
			
						-- Exit the loop if there were no more instances to find
						IF @@ROWCOUNT = 0
						SET @NoMoreUpdates = 1
			
				END 
	
		END


/*******************************************************************************************************************************************************************************************************************************************************************************/
-- Find all related referral majors in scope
/*******************************************************************************************************************************************************************************************************************************************************************************/

		INSERT INTO		@ReferralMajors(
						SrcSys_Major 
 						,Src_UID_Major
						)
		SELECT		mc.SrcSys_Major
					,mc.Src_UID_Major
		FROM		Merge_DM_Match.tblMAIN_REFERRALS_Match_Control mc
		LEFT JOIN	@RelatedEntities re
										ON	mc.SrcSys = re.SrcSys
										AND	mc.Src_UID = re.Src_UID
		LEFT JOIN	Merge_DM_Match.tblMAIN_REFERRALS_mvw_UH uh
																	ON mc.SrcSys = uh.SrcSys
																	AND mc.Src_UID = uh.Src_UID
		WHERE		re.SrcSys IS NOT NULL
		OR			@Src_UID_Major IS NULL
		GROUP BY	mc.SrcSys_Major
					,mc.Src_UID_Major
		HAVING		COUNT(*) > 1
		AND			ISNULL(MAX(uh.N2_6_RECEIPT_DATE), GETDATE()) >= '2021-04-01' -- MostRecentDate
		AND			SUM(CASE WHEN mc.SrcSys = 2 THEN 1 ELSE 0 END) > 0 -- SrcSys_BSUH
		AND			SUM(CASE WHEN mc.SrcSys = 1 THEN 1 ELSE 0 END) > 0 -- SrcSys_WSHT

		RETURN

END

GO
