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
Description:				A function that allow differential logic to compare each column of the
							tblDEMOGRAPHICS data
**************************************************************************************************************************************************/

-- Test me
-- SELECT [Merge_DM_Match].tblDEMOGRAPHICS_fnCompare('NhsNumber', '1234567890', '1234567890')

CREATE FUNCTION [Merge_DM_Match].[tblDEMOGRAPHICS_fnCompare]
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
		
		-- Forename - trim the forename on both sides to the shortest length of either side
		IF		@FieldName IN ('Forename')
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	4
						WHEN	LEFT(CAST(@ValueA AS VARCHAR(255)), dbo.fnLowestIntFromArray(0, LEN(CAST(@ValueA AS VARCHAR(255))), LEN(CAST(@ValueB AS VARCHAR(255))), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT))
						=		LEFT(CAST(@ValueB AS VARCHAR(255)), dbo.fnLowestIntFromArray(0, LEN(CAST(@ValueA AS VARCHAR(255))), LEN(CAST(@ValueB AS VARCHAR(255))), DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT))
						THEN	1
						ELSE	0
						END

		/*******************************************************************************************/
		-- Generic matches
		/*******************************************************************************************/
		
		-- Fields where a null value on either side is an acceptable match
		IF		@FieldName IN ('DoD', 'Address2', 'Address3', 'Address4', 'Address5', 'DeathStatus')
		RETURN	CASE	WHEN	@ReturnIsJoinType = 1
						THEN	3
						WHEN	@ValueA = @ValueB
						OR		@ValueA IS NULL
						OR		@ValueB IS NULL
						THEN	1
						ELSE	0
						END

		-- Fields where a null value on both sides is an acceptable match
		IF		@FieldName IN ('Sex', 'Title', 'Ethnicity', 'ReligionCode')
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
