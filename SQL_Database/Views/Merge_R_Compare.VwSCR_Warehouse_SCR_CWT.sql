SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE VIEW [Merge_R_Compare].[VwSCR_Warehouse_SCR_CWT]
AS

WITH	OrganisationSites_Id AS 
		(SELECT	dw_source_id
				,dw_source_system_id
				,id
				,code
				,description
		FROM	[SCR_DW].[SCR].[dbo_OrganisationSites]
							
		UNION ALL 
							
		SELECT	dw_source_patient_id AS dw_source_id
				,2 AS dw_source_system_id
				,id
				,code
				,description
		FROM	[SCR_DW].[SCR].[dbo_OrganisationSites]
		WHERE	dw_source_patient_id IS NOT NULL
		AND		dw_source_system_id = 1
		),OrganisationSites_Code AS 
		(SELECT	id
				,code
				,description
		FROM	[SCR_DW].[SCR].[dbo_OrganisationSites]
		)

SELECT		 pre.[CWTInsertIx]
			,pre.[OriginalCWTInsertIx]
			,pre.[CARE_ID] AS OrigCARE_ID
			,dwref.[CARE_ID]
			,pre.[SrcSysID] AS OrigSrcSysID
			,5 AS [SrcSysID] 
			,ss.[SrcSysCode] 
			,ss.[SrcSysName] 
			,pre.CWT_ID AS OrigCWT_ID
			,CWT_ID	=	CAST(5 AS VARCHAR(255)) + '|' + 
								CAST(dwref.CARE_ID AS VARCHAR(255)) + '|' + 
								ISNULL(CAST(dwtre.TREATMENT_ID AS VARCHAR(255)),'') + '|' +
								ISNULL(CAST(dwchem.CHEMO_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwtel.TELE_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwpal.PALL_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwbra.BRACHY_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwoth.OTHER_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwsur.SURGERY_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwmon.MONITOR_ID AS VARCHAR(255)),'0')
			,Tx_ID	=	CAST(5 AS VARCHAR(255)) + '|' + -- done
								CAST(dwref.CARE_ID AS VARCHAR(255)) + '|' + 
								ISNULL(CAST(dwchem.CHEMO_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwtel.TELE_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwpal.PALL_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwbra.BRACHY_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwoth.OTHER_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwsur.SURGERY_ID AS VARCHAR(255)),'0') + '|' +
								ISNULL(CAST(dwmon.MONITOR_ID AS VARCHAR(255)),'0')
			,dwtre.[TREATMENT_ID]
			,CASE WHEN pre.TREAT_ID = pre.CHEMO_ID THEN dwchem.[CHEMO_ID]
				WHEN pre.TREAT_ID = pre.TELE_ID THEN dwtel.[TELE_ID] 
				WHEN pre.TREAT_ID = pre.[PALL_ID] THEN dwpal.[PALL_ID]  
				WHEN pre.TREAT_ID = pre.[BRACHY_ID] THEN dwbra.[BRACHY_ID]
				WHEN pre.TREAT_ID = pre.[OTHER_ID] THEN dwoth.[OTHER_ID]  
				WHEN pre.TREAT_ID = pre.[SURGERY_ID] THEN dwsur.[SURGERY_ID] 
				WHEN pre.TREAT_ID = pre.[MONITOR_ID] THEN dwmon.[MONITOR_ID] 
				--WHEN pre.TREAT_ID = dwdec.AllTreatmentDeclinedID THEN dwdec.AllTreatmentDeclinedID
				WHEN pre.TREAT_ID = dwdec.DW_SOURCE_ID THEN dwdec.AllTreatmentDeclinedID
				WHEN pre.[SrcSysID] = 1 THEN pre.TREAT_ID
				END AS [TREAT_ID]
			,dwchem.[CHEMO_ID] 
			,dwtel.[TELE_ID] 
			,dwpal.[PALL_ID] 
			,dwbra.[BRACHY_ID]
			,dwoth.[OTHER_ID] 
			,dwsur.[SURGERY_ID] 
			,dwmon.[MONITOR_ID] 
			,chem_aud.ACTION_ID AS [ChemoActionId]
			,tel_aud.ACTION_ID AS [TeleActionId] 
			,pal_aud.ACTION_ID AS [PallActionId] 
			,bra_aud.ACTION_ID AS [BrachyActionId] 
			,oth_aud.ACTION_ID AS [OtherActionId] 
			,sur_aud.ACTION_ID AS [SurgeryActionId]
			,mon_aud.ACTION_ID AS [MonitorActionId]
			,pre.[DeftTreatmentEventCode]
			,pre.[DeftTreatmentEventDesc]
			,pre.[DeftTreatmentCode]
			,pre.[DeftTreatmentDesc]
			,pre.[DeftTreatmentSettingCode]
			,pre.[DeftTreatmentSettingDesc]
			,pre.[DeftDateDecisionTreat]
			,pre.[DeftDateTreatment]
			,pre.[DeftDTTAdjTime]
			,pre.[DeftDTTAdjReasonCode]
			,pre.[DeftDTTAdjReasonDesc]
			,org_deftDTT.[ID] AS [DeftOrgIdDecisionTreat]
			,pre.[DeftOrgCodeDecisionTreat]
			,org_deftDTT.Description AS [DeftOrgDescDecisionTreat]
			,org_deftTre.[ID] AS [DeftOrgIdTreatment]
			,pre.[DeftOrgCodeTreatment]
			,org_deftTre.Description AS [DeftOrgDescTreatment]
			,pre.[DeftDefinitiveTreatment]
			,pre.[DeftChemoRT]
			,pre.[TxModTreatmentEventCode]
			,pre.[TxModTreatmentEventDesc]
			,pre.[TxModTreatmentCode]
			,pre.[TxModTreatmentDesc]
			,pre.[TxModTreatmentSettingCode]
			,pre.[TxModTreatmentSettingDesc]
			,pre.[TxModDateDecisionTreat]
			,pre.[TxModDateTreatment]
			,org_txDTT.[ID] AS [TxModOrgIdDecisionTreat]
			,pre.[TxModOrgCodeDecisionTreat]
			,org_txDTT.Description AS [TxModOrgDescDecisionTreat]
			,org_txTre.[ID] AS [TxModOrgIdTreatment] 
			,pre.[TxModOrgCodeTreatment]
			,org_txTre.Description AS [TxModOrgDescTreatment]
			,pre.[TxModDefinitiveTreatment]
			,pre.[TxModChemoRadio]
			,pre.[TxModChemoRT]
			,pre.[TxModModalitySubCode]
			,pre.[TxModRadioSurgery]
			,pre.[ChemRtLinkTreatmentEventCode]
			,pre.[ChemRtLinkTreatmentEventDesc]
			,pre.[ChemRtLinkTreatmentCode]
			,pre.[ChemRtLinkTreatmentDesc]
			,pre.[ChemRtLinkTreatmentSettingCode]
			,pre.[ChemRtLinkTreatmentSettingDesc]
			,pre.[ChemRtLinkDateDecisionTreat]
			,pre.[ChemRtLinkDateTreatment]
			,org_chemDTT.[ID] AS [ChemRtLinkOrgIdDecisionTreat]
			,pre.[ChemRtLinkOrgCodeDecisionTreat]
			,org_chemDTT.Description AS [ChemRtLinkOrgDescDecisionTreat]
			,org_chemTre.[ID] AS [ChemRtLinkOrgIdTreatment]
			,pre.[ChemRtLinkOrgCodeTreatment]
			,org_chemTre.Description AS [ChemRtLinkOrgDescTreatment]
			,pre.[ChemRtLinkDefinitiveTreatment]
			,pre.[ChemRtLinkChemoRadio]
			,pre.[ChemRtLinkModalitySubCode]
			,pre.[ChemRtLinkRadioSurgery]
			,pre.[cwtFlag2WW]
			,pre.[cwtFlag28]
			,pre.[cwtFlag31]
			,pre.[cwtFlag62]
			,pre.[cwtFlagSurv]
			,pre.[cwtType2WW]
			,pre.[cwtType28]
			,pre.[cwtType31]
			,pre.[cwtType62]
			,pre.[cwtReason2WW]
			,pre.[cwtReason28]
			,pre.[cwtReason31]
			,pre.[cwtReason62]
			,pre.[HasTxMod]
			,pre.[HasChemRtLink]
			,pre.[ClockStartDate2WW]
			,pre.[ClockStartDate28]
			,pre.[ClockStartDate31]
			,pre.[ClockStartDate62]
			,pre.[ClockStartDateSurv]
			,pre.[AdjTime2WW]
			,pre.[AdjTime28]
			,pre.[AdjTime31]
			,pre.[AdjTime62]
			,pre.[TargetDate2WW]
			,pre.[TargetDate28]
			,pre.[TargetDate31]
			,pre.[TargetDate62]
			,pre.[DaysTo2WWBreach]
			,pre.[DaysTo28DayBreach]
			,pre.[DaysTo31DayBreach]
			,pre.[DaysTo62DayBreach]
			,pre.[ClockStopDate2WW]
			,pre.[ClockStopDate28]
			,pre.[ClockStopDate31]
			,pre.[ClockStopDate62]
			,pre.[ClockStopDateSurv]
			,pre.[Waitingtime2WW]
			,pre.[Waitingtime28]
			,pre.[Waitingtime31]
			,pre.[Waitingtime62]
			,pre.[WaitingtimeSurv]
			,pre.[Breach2WW]
			,pre.[Breach28]
			,pre.[Breach31]
			,pre.[Breach62]
			,pre.[WillBeClockStopDate2WW]
			,pre.[WillBeClockStopDate28]
			,pre.[WillBeClockStopDate31]
			,pre.[WillBeClockStopDate62]
			,pre.[WillBeWaitingtime2WW]
			,pre.[WillBeWaitingtime28]
			,pre.[WillBeWaitingtime31]
			,pre.[WillBeWaitingtime62]
			,pre.[WillBeBreach2WW]
			,pre.[WillBeBreach28]
			,pre.[WillBeBreach31]
			,pre.[WillBeBreach62]
			,pre.[DaysTo62DayBreachNoDTT]
			,pre.[Treated7Days]
			,pre.[Treated7Days62Days]
			,pre.[FutureAchieve62Days]
			,pre.[FutureFail62Days]
			,pre.[ActualWaitDTTTreatment]
			,pre.[DTTTreated7Days]
			,pre.[Treated7Days31Days]
			,pre.[Treated7DaysBreach31Days]
			,pre.[FutureAchieve31Days]
			,pre.[FutureFail31Days]
			,pre.[FutureDTT]
			,pre.[NoDTTDate]
			,pre.[RTTValidatedForUpload]
			,pre.[LastCommentUser]
			,pre.[LastCommentDate]
			,pre.[ReportDate]
			,pre.[DominantCWTStatusCode]
			,pre.[DominantCWTStatusDesc]
			,pre.[CWTStatusCode2WW]
			,pre.[CWTStatusDesc2WW]
			,pre.[CwtPathwayTypeId2WW]
			,pre.[CwtPathwayTypeDesc2WW]
			,pre.[DefaultShow2WW]
			,pre.[CWTStatusCode28]
			,pre.[CWTStatusDesc28]
			,pre.[CwtPathwayTypeId28] 
			,pre.[CwtPathwayTypeDesc28]
			,pre.[DefaultShow28]
			,pre.[CWTStatusCode31]
			,pre.[CWTStatusDesc31]
			,pre.[CwtPathwayTypeId31] 
			,pre.[CwtPathwayTypeDesc31]
			,pre.[DefaultShow31]
			,pre.[CWTStatusCode62]
			,pre.[CWTStatusDesc62]
			,pre.[CwtPathwayTypeId62] 
			,pre.[CwtPathwayTypeDesc62]
			,pre.[DefaultShow62]
			,pre.[CWTStatusCodeSurv]
			,pre.[CWTStatusDescSurv]
			,pre.[CwtPathwayTypeIdSurv]
			,pre.[CwtPathwayTypeDescSurv]
			,pre.[DefaultShowSurv]
			,pre.[UnifyPtlStatusCode]
			,pre.[UnifyPtlStatusDesc]
			,pre.[Pathway]
			,pre.[ReportingPathwayLength]
			,pre.[Weighting]
			,pre.[DominantColourValue]
			,pre.[ColourValue2WW]
			,pre.[ColourValue28Day]
			,pre.[ColourValue31Day]
			,pre.[ColourValue62Day]
			,pre.[ColourValueSurv]
			,pre.[DominantColourDesc]
			,pre.[ColourDesc2WW]
			,pre.[ColourDesc28Day]
			,pre.[ColourDesc31Day]
			,pre.[ColourDesc62Day]
			,pre.[ColourDescSurv]
			,pre.[DominantPriority]
			,pre.[Priority2WW]
			,pre.[Priority28]
			,pre.[Priority31]
			,pre.[Priority62]

FROM		[SCR_Warehouse].[SCR_CWT] pre

-- Care ID mapping
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_REFERRALS dwref
											ON	pre.CARE_ID = dwref.DW_SOURCE_ID
											AND pre.SrcSysID = dwref.DW_SOURCE_SYSTEM_ID
LEFT JOIN	CancerReporting_MERGE.LocalConfig.SourceSystems ss
														ON ss.SrcSysID = 5
-- Treatment ID Mapping
LEFT JOIN	SCR_DW.SCR.dbo_tblDEFINITIVE_TREATMENT dwtre
													ON pre.TREATMENT_ID =  dwtre.DW_SOURCE_ID
													AND pre.SrcSysID = dwtre.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_CHEMOTHERAPY dwchem
												ON pre.CHEMO_ID = dwchem.DW_SOURCE_ID
												AND pre.SrcSysID = dwchem.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_TELETHERAPY dwtel
												ON pre.TELE_ID = dwtel.DW_SOURCE_ID
												AND pre.SrcSysID = dwtel.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_PALLIATIVE dwpal
												ON pre.PALL_ID = dwpal.DW_SOURCE_ID
												AND pre.SrcSysID = dwpal.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_BRACHYTHERAPY dwbra
												ON pre.BRACHY_ID = dwbra.DW_SOURCE_ID
												AND pre.SrcSysID = dwbra.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblOTHER_TREATMENT dwoth
											ON pre.OTHER_ID = dwoth.DW_SOURCE_ID
											AND pre.SrcSysID = dwoth.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMAIN_SURGERY dwsur
											ON pre.SURGERY_ID = dwsur.DW_SOURCE_ID
											AND pre.SrcSysID = dwsur.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblMONITORING dwmon
											ON pre.MONITOR_ID = dwmon.DW_SOURCE_ID
											AND pre.SrcSysID = dwmon.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAllTreatmentDeclined dwdec
											ON pre.TREAT_ID = dwdec.DW_SOURCE_ID
											AND pre.SrcSysID = dwdec.DW_SOURCE_SYSTEM_ID
											AND COALESCE(pre.CHEMO_ID,pre.TELE_ID,pre.PALL_ID,pre.BRACHY_ID,pre.OTHER_ID,pre.SURGERY_ID,pre.MONITOR_ID) IS NULL
-- OrgID Mapping
LEFT JOIN	OrganisationSites_Code org_deftDTT
									ON pre.DeftOrgCodeDecisionTreat = org_deftDTT.code 
LEFT JOIN	OrganisationSites_Code org_deftTre
									ON pre.DeftOrgCodeTreatment = org_deftTre.code
LEFT JOIN	OrganisationSites_Code org_txDTT
									ON pre.TxModOrgCodeDecisionTreat = org_txDTT.code
LEFT JOIN	OrganisationSites_Code org_txTre
									ON pre.TxModOrgCodeTreatment = org_txTre.code
LEFT JOIN	OrganisationSites_Code org_chemDTT
									ON pre.ChemRtLinkOrgCodeDecisionTreat = org_chemDTT.code
LEFT JOIN	OrganisationSites_Code org_chemTre
									ON pre.ChemRtLinkOrgCodeTreatment = org_chemTre.code

-- ActionID Mapping
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT chem_aud
											ON	pre.ChemoActionId = chem_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = chem_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT tel_aud
											ON	pre.TeleActionId = tel_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = tel_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT pal_aud
											ON	pre.PallActionId = pal_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = pal_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT bra_aud
											ON	pre.BrachyActionId = bra_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = bra_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT oth_aud
											ON	pre.OtherActionId = oth_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = oth_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT sur_aud
											ON	pre.SurgeryActionId = sur_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = sur_aud.DW_SOURCE_SYSTEM_ID
LEFT JOIN	SCR_DW.SCR.dbo_tblAUDIT mon_aud
											ON	pre.MonitorActionId = mon_aud.DW_SOURCE_ID
											AND	pre.SrcSysID = mon_aud.DW_SOURCE_SYSTEM_ID
GO
