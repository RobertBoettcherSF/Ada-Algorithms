-- zeller.ads
package Zeller is
   -- Strong typing for algorithm-specific data
   type Day_Type is new Integer range 1 .. 31;
   type Month_Type is new Integer range 1 .. 12;
   -- Valid year range (limiting to 1..9999 to avoid BCE negative mod complexities)
   type Year_Type is new Integer range 1 .. 9999;

   -- Standard Day of Week for Zeller's Congruence (Saturday = 0 .. Friday = 6)
   type Day_Of_Week is (Saturday, Sunday, Monday, Tuesday, Wednesday, Thursday, Friday);
   
   -- ISO 8601 Day of Week (Monday = 1 .. Sunday = 7)
   type ISO_Day_Of_Week is (Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday);

   -- Exception raised when a mathematically impossible date is passed (e.g., Feb 29 on non-leap year)
   Invalid_Date : exception;

   -- =========================================================
   -- ALGORITHM VARIANTS
   -- =========================================================

   -- 1. Standard Gregorian Calendar variant
   function Day_Of_Week_Gregorian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return Day_Of_Week;

   -- 2. Julian Calendar variant
   function Day_Of_Week_Julian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return Day_Of_Week;

   -- 3. ISO Format - Gregorian Calendar
   function Day_Of_Week_ISO_Gregorian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return ISO_Day_Of_Week;

   -- 4. ISO Format - Julian Calendar
   function Day_Of_Week_ISO_Julian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return ISO_Day_Of_Week;

private
   -- Helper Functions
   function Is_Leap_Year_Gregorian (Year : Year_Type) return Boolean;
   function Is_Leap_Year_Julian (Year : Year_Type) return Boolean;
   
   -- Validates date constraints based on the calendar system
   procedure Validate_Date (Day : Day_Type; Month : Month_Type; Year : Year_Type; Is_Gregorian : Boolean);
   
   -- Zeller's algorithm shifts Jan/Feb to months 13/14 of the previous year
   procedure Adjust_Month_Year(Month : in out Integer; Year : in out Integer);
   
   -- Converts Zeller's 0-indexed format to ISO 8601 representation
   function To_ISO(D : Day_Of_Week) return ISO_Day_Of_Week;
end Zeller;
