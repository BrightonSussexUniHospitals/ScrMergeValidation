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

/******************************************************** © Copyright & Licensing ****************************************************************
© 2024 Perspicacity Ltd & University Hospitals Sussex

This code / file is part of Perspicacity & University Hospitals Sussex SCR merge validation suite.

This SCR merge validation suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This SCR migration merge suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/ScrMergeValidation

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	31/01/2024
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				A stored procedure to audit processes used in matching / deduplication
**************************************************************************************************************************************************/

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
