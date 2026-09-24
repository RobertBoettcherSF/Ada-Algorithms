--  Doomsday — Ada 2023 educational package for Conway's Doomsday algorithm
--  (Gregorian day-of-week calculation via memorable "doomsdays").
--
--  Source: https://en.wikipedia.org/wiki/Doomsday_algorithm
--  Conway, "Tomorrow is the Day After Doomsday", Eureka 36 (1973).

pragma Ada_2022;

package Doomsday
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   subtype Year_Number  is Integer range 1 .. 9999;
   subtype Month_Number is Integer range 1 .. 12;
   subtype Day_Number   is Integer range 0 .. 31;
   --  Day 0 is allowed for March 0 (mnemonic for last day of February).

   --  Conway numbering: 0 = Sunday .. 6 = Saturday.
   subtype Weekday is Natural range 0 .. 6;

   Sunday    : constant Weekday := 0;
   Monday    : constant Weekday := 1;
   Tuesday   : constant Weekday := 2;
   Wednesday : constant Weekday := 3;
   Thursday  : constant Weekday := 4;
   Friday    : constant Weekday := 5;
   Saturday  : constant Weekday := 6;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Core Gregorian Doomsday API
   ---------------------------------------------------------------------------

   function Is_Leap (Year : Year_Number) return Boolean
     with Global => null;
   --  Gregorian leap year: divisible by 4, except centuries not divisible by 400.

   function Century_Anchor (Year : Year_Number) return Weekday
     with Global => null;
   --  Gregorian century anchor for the century containing Year.
   --  Formula: (5 * (c mod 4)) mod 7 + Tuesday, with c = floor(Year/100).
   --  Anchors: 1600 Tue, 1700 Sun, 1800 Fri, 1900 Wed, 2000 Tue, 2100 Sun.

   function Year_Doomsday (Year : Year_Number) return Weekday
     with Global => null;
   --  Weekday of all memorable doomsdays in Year.
   --  Uses Conway's dozen shortcut:
   --    (floor(y/12) + (y mod 12) + floor((y mod 12)/4) + anchor) mod 7
   --  equivalent to (y + floor(y/4) + anchor) mod 7, y = Year mod 100.

   function Closest_Doomsday
     (Year  : Year_Number;
      Month : Month_Number) return Day_Number
     with Global => null;
   --  Memorable doomsday day-of-month for Month in Year:
   --    Jan 3 (common) / 4 (leap); Feb last day; Mar 0 (= last of Feb);
   --    4/4, 5/9, 6/6, 7/11, 8/8, 9/5, 10/10, 11/7, 12/12.

   function Day_Of_Week
     (Year  : Year_Number;
      Month : Month_Number;
      Day   : Day_Number) return Weekday
     with Global => null;
   --  Gregorian weekday of Year-Month-Day via the Doomsday rule.
   --  Raises Invalid_Argument for impossible dates (e.g. Day = 0 outside March,
   --  or Day beyond the length of Month).

   function Weekday_Name (W : Weekday) return String
     with Global => null;
   --  English name: "Sunday" .. "Saturday".

   ---------------------------------------------------------------------------
   -- Independent reference (Sakamoto) for cross-checks
   ---------------------------------------------------------------------------

   function Sakamoto_Day_Of_Week
     (Year  : Year_Number;
      Month : Month_Number;
      Day   : Positive) return Weekday
     with Global => null;
   --  Tomohiko Sakamoto's compact DOW formula (0 = Sunday). Independent of
   --  the Doomsday path; used by tests as an oracle.

end Doomsday;
