--  Computus — Ada 2023 educational package for Wikipedia "Computus"
--  (Date of Easter). Implements the Anonymous Gregorian algorithm
--  (Meeus/Jones/Butcher) for Western Easter, plus the Meeus Julian
--  algorithm for Orthodox Pascha on the Julian calendar (with optional
--  conversion to Gregorian civil dates).
--
--  Source: https://en.wikipedia.org/wiki/Computus
--  Also: Meeus, Astronomical Algorithms (1991); Butcher (1876).

pragma Ada_2022;

package Computus
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   subtype Year_Number  is Integer range 1 .. 9999;
   subtype Month_Number is Integer range 1 .. 12;
   subtype Day_Number   is Integer range 1 .. 31;

   --  Civil date (Gregorian or Julian components as documented per API).
   type Date is record
      Year  : Year_Number  := 1;
      Month : Month_Number := 1;
      Day   : Day_Number   := 1;
   end record;

   --  ISO-like weekday: 0 = Sunday .. 6 = Saturday (Sakamoto / Zeller style).
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
   -- Gregorian (Western) Easter — Meeus/Jones/Butcher
   ---------------------------------------------------------------------------

   function Gregorian_Easter (Year : Year_Number) return Date
     with Global => null;
   --  Western Easter Sunday for Gregorian Year (valid for Year >= 1583).
   --  Anonymous Gregorian / Meeus–Jones–Butcher integer algorithm.
   --  Result Month is 3 (March) or 4 (April); Day in 22..31 (Mar) or 1..25 (Apr).

   function Easter (Year : Year_Number) return Date
     with Global => null;
   --  Alias for Gregorian_Easter.

   ---------------------------------------------------------------------------
   -- Julian (Eastern / Orthodox) computus
   ---------------------------------------------------------------------------

   function Julian_Easter (Year : Year_Number) return Date
     with Global => null;
   --  Orthodox Easter as a Julian-calendar date (Meeus Julian algorithm).
   --  Month is 3 or 4 on the Julian calendar.

   function Julian_To_Gregorian (D : Date) return Date
     with Global => null;
   --  Convert a Julian calendar date to the corresponding Gregorian date
   --  using the century offset floor(Y/100) - floor(Y/400) - 2 applied to
   --  the day ordinal (valid for common Orthodox year ranges).

   function Orthodox_Easter (Year : Year_Number) return Date
     with Global => null;
   --  Orthodox Easter expressed as a Gregorian civil date:
   --  Julian_To_Gregorian (Julian_Easter (Year)).

   ---------------------------------------------------------------------------
   -- Calendar helpers
   ---------------------------------------------------------------------------

   function Day_Of_Week (D : Date) return Weekday
     with Global => null;
   --  Gregorian weekday of D (0 = Sunday). Uses Sakamoto's method.

   function Is_Sunday (D : Date) return Boolean
     with Global => null;
   --  True iff Day_Of_Week (D) = Sunday.

   function Is_Gregorian_Leap (Year : Year_Number) return Boolean
     with Global => null;

   function Days_In_Month (Year : Year_Number; Month : Month_Number)
     return Day_Number
     with Global => null;

   function Ordinal_Day (D : Date) return Natural
     with Global => null;
   --  Day-of-year 1 .. 366 for a Gregorian date.

   function From_Ordinal
     (Year : Year_Number; Ordinal : Positive) return Date
     with Global => null;
   --  Inverse of Ordinal_Day. Raises Invalid_Argument if Ordinal too large.

   function Add_Days (D : Date; Delta_Days : Integer) return Date
     with Global => null;
   --  Add (or subtract) Delta_Days on the Gregorian calendar.

   function Day_Difference (A, B : Date) return Integer
     with Global => null;
   --  Signed day count B - A (Gregorian), via serial day numbers.

   ---------------------------------------------------------------------------
   -- Comparison / Near
   ---------------------------------------------------------------------------

   function Same_Date (A, B : Date) return Boolean
     with Global => null;

   function Near
     (A, B      : Date;
      Tol_Days  : Natural := 0) return Boolean
     with Global => null;
   --  True iff abs (Day_Difference (A, B)) <= Tol_Days.
   --  With Tol_Days = 0 this is exact date equality.

   function In_Easter_Window (D : Date) return Boolean
     with Global => null;
   --  True iff Gregorian Easter falls in Mar 22 .. Apr 25 inclusive
   --  (checks Month/Day of D, ignoring Year).

   ---------------------------------------------------------------------------
   -- Golden number / epact helpers (educational)
   ---------------------------------------------------------------------------

   function Golden_Number (Year : Year_Number) return Positive
     with Global => null,
          Post   => Golden_Number'Result in 1 .. 19;
   --  GN = (Year mod 19) + 1.

end Computus;
