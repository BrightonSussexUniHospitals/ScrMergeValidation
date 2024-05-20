SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [Merge_DM_MatchAudit].[uspProcessAudit]

		(@IsUpdate BIT
		,@SessionID SMALLINT
		,@UserID VARCHAR(255)
		,@ProcName VARCHAR(255)
		,@Section VARCHAR(255)
		,@StartDttm DATETIME2 = NULL
		,@EndDttm DATETIME2 = NULL
		,@Success BIT = NULL
		,@ErrorMessage VARCHAR(MAX) = NULL
		)

AS 

		-- If this is intended to be a new record (or it is intended as an update but there is nothing to update)
		IF		@IsUpdate = 0
		OR		(SELECT		COUNT(*)
				FROM		Merge_DM_MatchAudit.tblProcessAudit
				WHERE		SessionID = @SessionID
				AND			UserID = @UserID
				AND			ProcName = @ProcName
				AND			Section = @Section) = 0
		BEGIN 
				-- Delete any existing records with the same session / user / procname / section
				DELETE
				FROM		Merge_DM_MatchAudit.tblProcessAudit
				WHERE		SessionID = @SessionID
				AND			UserID = @UserID
				AND			ProcName = @ProcName
				AND			Section = @Section

				IF @StartDttm IS NOT NULL
				-- Insert the new record where a start dttm is passed
				INSERT INTO	Merge_DM_MatchAudit.tblProcessAudit
							(SessionID
							,UserID
							,ProcName
							,Section
							,StartDttm
							,EndDttm
							,Success
							,ErrorMessage
							)
				VALUES		(@SessionID
							,@UserID
							,@ProcName
							,@Section
							,@StartDttm
							,@EndDttm
							,@Success
							,@ErrorMessage
							)

				IF @StartDttm IS NULL
				-- Insert the new record where a start dttm is passed
				INSERT INTO	Merge_DM_MatchAudit.tblProcessAudit
							(SessionID
							,UserID
							,ProcName
							,Section
							,EndDttm
							,Success
							,ErrorMessage
							)
				VALUES		(@SessionID
							,@UserID
							,@ProcName
							,@Section
							,@EndDttm
							,@Success
							,@ErrorMessage
							)

		END

		-- If this is intended to be an update
		IF	@IsUpdate = 1
		BEGIN 
				-- Update the record
				UPDATE		Merge_DM_MatchAudit.tblProcessAudit
				SET			StartDttm		= ISNULL(@StartDttm, StartDttm)
							,EndDttm		= ISNULL(@EndDttm, EndDttm)
							,Success		= ISNULL(@Success, Success)
							,ErrorMessage	= ISNULL(@ErrorMessage, ErrorMessage)
				WHERE		SessionID = @SessionID
				AND			UserID = @UserID
				AND			ProcName = @ProcName
				AND			Section = @Section


		END

GO
