CREATE TABLE [Merge_DM_Match].[ValidationSummary]
(
[SnapshotDate] [datetime2] NULL,
[TableBeingValidated] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ConfirmedSoFar] [int] NULL,
[AutoConfirmedSoFar] [int] NULL,
[TotalToBeConfirmed] [int] NULL,
[ManuallyConfirmedSoFar] [int] NULL,
[StillToBeManuallyConfirmed] [int] NULL,
[TotalToBeManuallyConfirmed] [int] NULL,
[PercentComplete] [real] NULL
) ON [PRIMARY]
GO
