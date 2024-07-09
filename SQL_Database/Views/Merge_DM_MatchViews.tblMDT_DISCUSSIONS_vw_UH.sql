SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Merge_DM_MatchViews].[tblMDT_DISCUSSIONS_vw_UH] AS 

SELECT		MeetingAttendee.SrcSysID
			,MeetingInstance.MEETING_ID
			,MeetingInstance.CA_SITE
			,MeetingInstance.SUB_DESC
			,MeetingInstance.LOCATION
			,MeetingAttendee.MDT_ID
			,MeetingAttendee.MDT_DATE
			,MeetingAttendee.OTHER_SITE
			,MeetingAttendee.PATIENT_ID
			,MeetingAttendee.CARE_ID
			,CASE WHEN  MeetingInstance.SUB_DESC LIKE '%SPEC%' THEN 1 ELSE 0 END AS SPEC
			,COALESCE(mcp.PLAN_ID, mcp_byDate.PLAN_ID, CASE WHEN MeetingAttendee.MdtListsInCareId = 1 AND mcp_single.PlansInCareId = 1 THEN mcp_single.PLAN_ID END) AS PLAN_ID
FROM		(SELECT		*
						,COUNT(*) OVER (PARTITION BY SrcSysID, CARE_ID) AS MdtListsInCareId
			FROM		Merge_DM_MatchViews.tblMDT_LIST
						) MeetingAttendee
		
LEFT JOIN	(SELECT		ML_inner.SrcSysID
						,ML_inner.MDT_ID  
						,ML_inner.Meeting_ID	
						,MeetingDetails.CA_SITE
						,MeetingDetails.SUB_DESC
						,MeetingDetails.LOCATION
			FROM		Merge_DM_MatchViews.tblMDT_LIST AS ML_inner

			LEFT JOIN	(SELECT		M.SrcSysID
									,M.MEETING_ID
									,M.MEETING_TYPE_ID
									,CS.CA_SITE	
									,M.SUB_SITE
									,SS.SUB_DESC
									,M.LOCATION
						FROM		Merge_DM_MatchViews.tblMDT_MEETINGS	M				
						INNER JOIN	Merge_DM_MatchViews.ltblCANCER_SITES CS
																			ON	M.MEETING_TYPE_ID = CS.CA_ID 
																			AND	M.SrcSysID = CS.SrcSysID
						INNER JOIN	Merge_DM_MatchViews.ltblCANCER_SUB_SITE SS
																			ON	M.SUB_SITE = SS.SUB_ID
																			AND	M.SrcSysID = SS.SrcSysID

								   ) MeetingDetails
											ON	ML_inner.SrcSysID = MeetingDetails.SrcSysID
											AND	ML_inner.MEETING_ID = MeetingDetails.MEETING_ID
						) MeetingInstance
							ON	MeetingAttendee.Meeting_ID = MeetingInstance.MDT_ID
							AND	MeetingAttendee.SrcSysID = MeetingInstance.SrcSysID
LEFT JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp
											ON	MeetingAttendee.SrcSysID = mcp.SrcSysID
											AND	MeetingAttendee.MDT_ID = mcp.TEMP_ID
											AND mcp.TEMP_ID <= '2147483647'
											AND LEN(mcp.TEMP_ID) <= 10
LEFT JOIN	Merge_DM_MatchViews.tblMAIN_CARE_PLAN mcp_byDate
											ON	MeetingAttendee.SrcSysID = mcp_byDate.SrcSysID
											AND	MeetingAttendee.CARE_ID = mcp_byDate.CARE_ID
											AND	MeetingAttendee.MDT_DATE = mcp_byDate.N5_2_MDT_DATE
LEFT JOIN	(SELECT		*
						,COUNT(*) OVER (PARTITION BY SrcSysID, CARE_ID) AS PlansInCareId
			FROM		Merge_DM_MatchViews.tblMAIN_CARE_PLAN
						) mcp_single
										ON	MeetingAttendee.SrcSysID = mcp_single.SrcSysID
										AND	MeetingAttendee.CARE_ID = mcp_single.CARE_ID
										AND	mcp_single.PlansInCareId = 1
GO
