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

Original Work Created Date:	12/02/2023
Original Work Created By:	Perspicacity Ltd (Matthew Bishop)
Original Work Contact:		07545 878906
Original Work Contact:		matthew.bishop@perspicacityltd.co.uk
Description:				Return the lowest integer from an array of integers
**************************************************************************************************************************************************/

-- Test me
-- SELECT dbo.fnLowestIntFromArray(0, 7, 4, 10, -5, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
-- SELECT dbo.fnLowestIntFromArray(1, 7, 4, 10, -5, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
-- SELECT dbo.fnLowestIntFromArray(0, -7, -4, -10, -5, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
-- SELECT dbo.fnLowestIntFromArray(1, -7, -4, -10, -5, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)

CREATE FUNCTION [dbo].[fnLowestIntFromArray]
		(@ExcludeNegatives BIT = 1
		,@Int01 INT
		,@Int02 INT = NULL
		,@Int03 INT = NULL
		,@Int04 INT = NULL
		,@Int05 INT = NULL
		,@Int06 INT = NULL
		,@Int07 INT = NULL
		,@Int08 INT = NULL
		,@Int09 INT = NULL
		,@Int10 INT = NULL
		)

RETURNS INT
AS
BEGIN

	-- Declare an internal variable to represent the last integer from the array
	DECLARE @FirstIntFromArray INT

	-- Set the initial value for @FirstIntFromArray
	SET @FirstIntFromArray = COALESCE(@Int01, @Int02, @Int03, @Int04, @Int05, @Int06, @Int07, @Int08, @Int09, @Int10)

	-- Set the initial value to null if it is negative and we are excluding negatives
	IF @FirstIntFromArray < 0 AND @ExcludeNegatives = 1
	SET @FirstIntFromArray = NULL

	-- Update @FirstIntFromArray if the current value is later than @Int02
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int02) AND (@Int02 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int02

	-- Update @FirstIntFromArray if the current value is later than @Int03
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int03) AND (@Int03 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int03

	-- Update @FirstIntFromArray if the current value is later than @Int04
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int04) AND (@Int04 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int04

	-- Update @FirstIntFromArray if the current value is later than @Int05
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int05) AND (@Int05 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int05

	-- Update @FirstIntFromArray if the current value is later than @Int06
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int06) AND (@Int06 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int06

	-- Update @FirstIntFromArray if the current value is later than @Int07
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int07) AND (@Int07 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int07

	-- Update @FirstIntFromArray if the current value is later than @Int08
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int08) AND (@Int08 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int08

	-- Update @FirstIntFromArray if the current value is later than @Int09
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int09) AND (@Int09 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int09

	-- Update @FirstIntFromArray if the current value is later than @Int10
	IF (@FirstIntFromArray IS NULL OR @FirstIntFromArray > @Int10) AND (@Int10 >= 0 OR @ExcludeNegatives = 0)
	SET @FirstIntFromArray = @Int10

	-- Return the @FirstIntFromArray
	RETURN	@FirstIntFromArray

END
GO
