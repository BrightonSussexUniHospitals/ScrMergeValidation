CREATE TABLE [Merge_R_Compare].[pre_scr_cwt]
(
[CWTInsertIx] [int] NOT NULL,
[OriginalCWTInsertIx] [int] NULL,
[OrigCARE_ID] [int] NOT NULL,
[CARE_ID] [int] NULL,
[OrigSrcSysID] [tinyint] NOT NULL,
[SrcSysID] [int] NOT NULL,
[SrcSysCode] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SrcSysName] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[OrigCWT_ID] [varchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[CWT_ID] [varchar] (2559) COLLATE Latin1_General_CI_AS NULL,
[Tx_ID] [varchar] (2303) COLLATE Latin1_General_CI_AS NULL,
[TREATMENT_ID] [int] NULL,
[TREAT_ID] [int] NULL,
[CHEMO_ID] [int] NULL,
[TELE_ID] [int] NULL,
[PALL_ID] [int] NULL,
[BRACHY_ID] [int] NULL,
[OTHER_ID] [int] NULL,
[SURGERY_ID] [int] NULL,
[MONITOR_ID] [int] NULL,
[ChemoActionId] [int] NULL,
[TeleActionId] [int] NULL,
[PallActionId] [int] NULL,
[BrachyActionId] [int] NULL,
[OtherActionId] [int] NULL,
[SurgeryActionId] [int] NULL,
[MonitorActionId] [int] NULL,
[DeftTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[DeftTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[DeftDateDecisionTreat] [smalldatetime] NULL,
[DeftDateTreatment] [smalldatetime] NULL,
[DeftDTTAdjTime] [int] NULL,
[DeftDTTAdjReasonCode] [int] NULL,
[DeftDTTAdjReasonDesc] [varchar] (150) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgIdDecisionTreat] [int] NULL,
[DeftOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgDescDecisionTreat] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgIdTreatment] [int] NULL,
[DeftOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[DeftOrgDescTreatment] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[DeftDefinitiveTreatment] [int] NULL,
[DeftChemoRT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[TxModTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TxModDateDecisionTreat] [smalldatetime] NULL,
[TxModDateTreatment] [smalldatetime] NULL,
[TxModOrgIdDecisionTreat] [int] NULL,
[TxModOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgDescDecisionTreat] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgIdTreatment] [int] NULL,
[TxModOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[TxModOrgDescTreatment] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[TxModDefinitiveTreatment] [int] NULL,
[TxModChemoRadio] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModChemoRT] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModModalitySubCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TxModRadioSurgery] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentEventCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentEventDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentCode] [char] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentSettingCode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkTreatmentSettingDesc] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkDateDecisionTreat] [smalldatetime] NULL,
[ChemRtLinkDateTreatment] [smalldatetime] NULL,
[ChemRtLinkOrgIdDecisionTreat] [int] NULL,
[ChemRtLinkOrgCodeDecisionTreat] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgDescDecisionTreat] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgIdTreatment] [int] NULL,
[ChemRtLinkOrgCodeTreatment] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkOrgDescTreatment] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkDefinitiveTreatment] [int] NULL,
[ChemRtLinkChemoRadio] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkModalitySubCode] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[ChemRtLinkRadioSurgery] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[cwtFlag2WW] [int] NULL,
[cwtFlag28] [int] NULL,
[cwtFlag31] [int] NULL,
[cwtFlag62] [int] NULL,
[cwtFlagSurv] [int] NULL,
[cwtType2WW] [int] NULL,
[cwtType28] [int] NULL,
[cwtType31] [int] NULL,
[cwtType62] [int] NULL,
[cwtReason2WW] [int] NULL,
[cwtReason28] [int] NULL,
[cwtReason31] [int] NULL,
[cwtReason62] [int] NULL,
[HasTxMod] [int] NULL,
[HasChemRtLink] [int] NULL,
[ClockStartDate2WW] [smalldatetime] NULL,
[ClockStartDate28] [smalldatetime] NULL,
[ClockStartDate31] [smalldatetime] NULL,
[ClockStartDate62] [smalldatetime] NULL,
[ClockStartDateSurv] [smalldatetime] NULL,
[AdjTime2WW] [int] NULL,
[AdjTime28] [int] NULL,
[AdjTime31] [int] NULL,
[AdjTime62] [int] NULL,
[TargetDate2WW] [smalldatetime] NULL,
[TargetDate28] [smalldatetime] NULL,
[TargetDate31] [smalldatetime] NULL,
[TargetDate62] [smalldatetime] NULL,
[DaysTo2WWBreach] [int] NULL,
[DaysTo28DayBreach] [int] NULL,
[DaysTo31DayBreach] [int] NULL,
[DaysTo62DayBreach] [int] NULL,
[ClockStopDate2WW] [smalldatetime] NULL,
[ClockStopDate28] [smalldatetime] NULL,
[ClockStopDate31] [smalldatetime] NULL,
[ClockStopDate62] [smalldatetime] NULL,
[ClockStopDateSurv] [smalldatetime] NULL,
[Waitingtime2WW] [int] NULL,
[Waitingtime28] [int] NULL,
[Waitingtime31] [int] NULL,
[Waitingtime62] [int] NULL,
[WaitingtimeSurv] [int] NULL,
[Breach2WW] [int] NULL,
[Breach28] [int] NULL,
[Breach31] [int] NULL,
[Breach62] [int] NULL,
[WillBeClockStopDate2WW] [smalldatetime] NULL,
[WillBeClockStopDate28] [smalldatetime] NULL,
[WillBeClockStopDate31] [smalldatetime] NULL,
[WillBeClockStopDate62] [smalldatetime] NULL,
[WillBeWaitingtime2WW] [int] NULL,
[WillBeWaitingtime28] [int] NULL,
[WillBeWaitingtime31] [int] NULL,
[WillBeWaitingtime62] [int] NULL,
[WillBeBreach2WW] [int] NULL,
[WillBeBreach28] [int] NULL,
[WillBeBreach31] [int] NULL,
[WillBeBreach62] [int] NULL,
[DaysTo62DayBreachNoDTT] [int] NULL,
[Treated7Days] [int] NULL,
[Treated7Days62Days] [int] NULL,
[FutureAchieve62Days] [int] NULL,
[FutureFail62Days] [int] NULL,
[ActualWaitDTTTreatment] [int] NULL,
[DTTTreated7Days] [int] NULL,
[Treated7Days31Days] [int] NULL,
[Treated7DaysBreach31Days] [int] NULL,
[FutureAchieve31Days] [int] NULL,
[FutureFail31Days] [int] NULL,
[FutureDTT] [int] NULL,
[NoDTTDate] [int] NULL,
[RTTValidatedForUpload] [int] NULL,
[LastCommentUser] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LastCommentDate] [datetime] NULL,
[ReportDate] [datetime] NULL,
[DominantCWTStatusCode] [int] NULL,
[DominantCWTStatusDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CWTStatusCode2WW] [int] NULL,
[CWTStatusDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CwtPathwayTypeId2WW] [int] NULL,
[CwtPathwayTypeDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DefaultShow2WW] [bit] NULL,
[CWTStatusCode28] [int] NULL,
[CWTStatusDesc28] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CwtPathwayTypeId28] [int] NULL,
[CwtPathwayTypeDesc28] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DefaultShow28] [bit] NULL,
[CWTStatusCode31] [int] NULL,
[CWTStatusDesc31] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CwtPathwayTypeId31] [int] NULL,
[CwtPathwayTypeDesc31] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DefaultShow31] [bit] NULL,
[CWTStatusCode62] [int] NULL,
[CWTStatusDesc62] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CwtPathwayTypeId62] [int] NULL,
[CwtPathwayTypeDesc62] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DefaultShow62] [bit] NULL,
[CWTStatusCodeSurv] [int] NULL,
[CWTStatusDescSurv] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CwtPathwayTypeIdSurv] [int] NULL,
[CwtPathwayTypeDescSurv] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DefaultShowSurv] [bit] NULL,
[UnifyPtlStatusCode] [int] NULL,
[UnifyPtlStatusDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Pathway] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ReportingPathwayLength] [int] NULL,
[Weighting] [numeric] (2, 1) NULL,
[DominantColourValue] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValue62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourValueSurv] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DominantColourDesc] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc2WW] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc28Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc31Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDesc62Day] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ColourDescSurv] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DominantPriority] [int] NULL,
[Priority2WW] [int] NULL,
[Priority28] [int] NULL,
[Priority31] [int] NULL,
[Priority62] [int] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_brachy_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [BRACHY_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_chemo_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [CHEMO_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_monitor_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [MONITOR_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_other_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [OTHER_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pall_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [PALL_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_surgery_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [SURGERY_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_tele_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [TELE_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_treat_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [TREAT_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_treatment_id] ON [Merge_R_Compare].[pre_scr_cwt] ([SrcSysID], [TREATMENT_ID]) ON [PRIMARY]
GO
