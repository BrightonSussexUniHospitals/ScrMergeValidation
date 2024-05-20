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
Description:				Return the latest date from an array of dates
**************************************************************************************************************************************************/

-- Test me
-- SELECT dbo.LastDateFromArray('01 Jan 2023', '02 Jan 2023', '03 Jan 2023', DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)

CREATE FUNCTION [dbo].[fnLastDateFromArray]
		(@ExcludeFutureDates BIT = 1
		,@Date01 DATETIME2
		,@Date02 DATETIME2 = NULL
		,@Date03 DATETIME2 = NULL
		,@Date04 DATETIME2 = NULL
		,@Date05 DATETIME2 = NULL
		,@Date06 DATETIME2 = NULL
		,@Date07 DATETIME2 = NULL
		,@Date08 DATETIME2 = NULL
		,@Date09 DATETIME2 = NULL
		,@Date10 DATETIME2 = NULL
		)

RETURNS DATETIME2
AS
BEGIN

	-- Declare an internal variable to represent the last date from the array
	DECLARE @LastDateFromArray DATETIME2

	-- Set the initial value for @LastDateFromArray
	SET @LastDateFromArray = COALESCE(@Date01, @Date02, @Date03, @Date04, @Date05, @Date06, @Date07, @Date08, @Date09, @Date10)

	-- Update @LastDateFromArray if the current value is earlier than @Date02
	IF @LastDateFromArray < @Date02 AND (@Date02 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date02

	-- Update @LastDateFromArray if the current value is earlier than @Date03
	IF @LastDateFromArray < @Date03 AND (@Date03 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date03

	-- Update @LastDateFromArray if the current value is earlier than @Date04
	IF @LastDateFromArray < @Date04 AND (@Date04 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date04

	-- Update @LastDateFromArray if the current value is earlier than @Date05
	IF @LastDateFromArray < @Date05 AND (@Date05 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date05

	-- Update @LastDateFromArray if the current value is earlier than @Date06
	IF @LastDateFromArray < @Date06 AND (@Date06 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date06

	-- Update @LastDateFromArray if the current value is earlier than @Date07
	IF @LastDateFromArray < @Date07 AND (@Date07 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date07

	-- Update @LastDateFromArray if the current value is earlier than @Date08
	IF @LastDateFromArray < @Date08 AND (@Date08 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date08

	-- Update @LastDateFromArray if the current value is earlier than @Date09
	IF @LastDateFromArray < @Date09 AND (@Date09 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date09

	-- Update @LastDateFromArray if the current value is earlier than @Date10
	IF @LastDateFromArray < @Date10 AND (@Date10 <= GETDATE() OR @ExcludeFutureDates = 0)
	SET @LastDateFromArray = @Date10

	-- Return the @LastDateFromArray
	RETURN	@LastDateFromArray

END
GO
