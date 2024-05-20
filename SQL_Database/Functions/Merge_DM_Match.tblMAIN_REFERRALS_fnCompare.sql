SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

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
Description:				A template function that encapsulates the differential logic required
							to compare each column of a merge table
**************************************************************************************************************************************************/

-- Test me
-- SELECT Merge_DM_Match.tblMAIN_REFERRALS_fnCompare(0, 'DummyField', 'foo', 'bar')

CREATE FUNCTION [Merge_DM_Match].[tblMAIN_REFERRALS_fnCompare]
	(@FieldName VARCHAR(255)
	,@ReturnIsJoinType BIT -- return the type of join rather than evaluate 2 values
	,@ValueA SQL_VARIANT
	,@ValueB SQL_VARIANT
	)

RETURNS TINYINT
AS
BEGIN

		/*******************************************************************************************/
		-- Bespoke matches
		/*******************************************************************************************/
		
		-- Put your first bespoke match here and return the value 4 if @ReturnIsJoinType = 1
		IF		@FieldName IN ('DummyField')
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	4
						WHEN	@ValueA = 'foo'
						AND		@ValueB = 'bar'
						THEN	1
						ELSE	0
						END

		/*******************************************************************************************/
		-- Generic matches
		/*******************************************************************************************/
		
		-- Fields where a null value on either side is an acceptable match
		IF		@FieldName IN ('N2_12_CANCER_TYPE','N2_9_FIRST_SEEN_DATE','N1_3_ORG_CODE_SEEN','L_OTHER_DIAG_DATE'
								,'N_UPGRADE_ORG_CODE','FasterDiagnosisOrganisationID','FasterDiagnosisExclusionReasonID','N4_3_LATERALITY')
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	3
						WHEN	@ValueA = @ValueB
						OR		@ValueA IS NULL
						OR		@ValueB IS NULL
						THEN	1
						ELSE	0
						END

		-- Fields where a null value on both sides is an acceptable match
		IF		@FieldName IN ('N_UPGRADE_DATE')
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	2
						WHEN	@ValueA = @ValueB
						OR		(@ValueA IS NULL
						AND		@ValueB IS NULL)
						THEN	1
						ELSE	0
						END
		
		-- Remaining fields will assume a non-null match is required
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	1
						WHEN	@ValueA = @ValueB
						THEN	1
						ELSE	0
						END
		
END

GO
