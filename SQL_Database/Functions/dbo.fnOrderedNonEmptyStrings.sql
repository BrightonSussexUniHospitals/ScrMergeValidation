SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/******************************************************** © Copyright & Licensing ****************************************************************
© 2020 Perspicacity Ltd & Brighton & Sussex University Hospitals

This code / file is part of Perspicacity & BSUH's Cancer Data Warehouse & Reporting suite.

This Cancer Data Warehouse & Reporting suite is free software: you can 
redistribute it and/or modify it under the terms of the GNU Affero 
General Public License as published by the Free Software Foundation, 
either version 3 of the License, or (at your option) any later version.

This Cancer Data Warehouse & Reporting suite is distributed in the hope 
that it will be useful, but WITHOUT ANY WARRANTY; without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

A full copy of this code can be found at https://github.com/BrightonSussexUniHospitals/CancerReportingSuite

You may also be interested in the other repositories at https://github.com/perspicacity-ltd or
https://github.com/BrightonSussexUniHospitals

Original Work Created Date:	05/07/2023
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Return the 1st/2nd/3rd/4th/5th non-empty string from a series of supplied strings
**************************************************************************************************************************************************/

-- test me
-- SELECT dbo.fnOrderedNonEmptyStings(1, 'test1',DEFAULT,DEFAULT,DEFAULT,DEFAULT)

CREATE FUNCTION [dbo].[fnOrderedNonEmptyStrings]

				(@NonEmptyOrder TINYINT
				,@String1 VARCHAR(4000)
				,@String2 VARCHAR(4000) = NULL
				,@String3 VARCHAR(4000) = NULL
				,@String4 VARCHAR(4000) = NULL
				,@String5 VARCHAR(4000) = NULL
				)

RETURNS VARCHAR(4000)
AS
BEGIN

		-- Declare an internal variable to represent the string
		DECLARE @EmptyString VARCHAR(4000)
		DECLARE @NonEmptyIx TINYINT = 0
		
		-- Check if the 1st string is not empty
		IF ISNULL(@String1, '') != ''
		SET @NonEmptyIx += 1

		-- Return the 1st string if that is what we want
		IF @NonEmptyIx = @NonEmptyOrder
		RETURN @String1
		
		-- Check if the 2nd string is not empty
		IF ISNULL(@String2, '') != ''
		SET @NonEmptyIx += 1

		-- Return the 2nd string if that is what we want
		IF @NonEmptyIx = @NonEmptyOrder
		RETURN @String2
		
		-- Check if the 3rd string is not empty
		IF ISNULL(@String3, '') != ''
		SET @NonEmptyIx += 1

		-- Return the 3rd string if that is what we want
		IF @NonEmptyIx = @NonEmptyOrder
		RETURN @String3
		
		-- Check if the 4th string is not empty
		IF ISNULL(@String4, '') != ''
		SET @NonEmptyIx += 1

		-- Return the 4th string if that is what we want
		IF @NonEmptyIx = @NonEmptyOrder
		RETURN @String4
		
		-- Check if the 5th string is not empty
		IF ISNULL(@String5, '') != ''
		SET @NonEmptyIx += 1

		-- Return the 5th string if that is what we want
		IF @NonEmptyIx = @NonEmptyOrder
		RETURN @String5

		-- Return the string
		RETURN	@EmptyString

END

GO
