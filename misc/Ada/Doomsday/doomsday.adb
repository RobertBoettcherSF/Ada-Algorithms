--  Doomsday body — Gregorian Conway Doomsday rule + Sakamoto oracle.

pragma Ada_2022;

package body Doomsday
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Mod7 (A : Integer) return Weekday is
      R : Integer := A rem 7;
   begin
      if R < 0 then
         R := R + 7;
      end if;
      return Weekday (R);
   end Mod7;

   function Days_In_Month (Year : Year_Number; Month : Month_Number)
     return Day_Number
   is
   begin
      case Month is
         when 1 | 3 | 5 | 7 | 8 | 10 | 12 =>
            return 31;
         when 4 | 6 | 9 | 11 =>
            return 30;
         when 2 =>
            if Is_Leap (Year) then
               return 29;
            else
               return 28;
            end if;
      end case;
   end Days_In_Month;

   -------------------------------------------------------------------------
   -- Is_Leap
   -------------------------------------------------------------------------

   function Is_Leap (Year : Year_Number) return Boolean is
      Y : constant Integer := Integer (Year);
   begin
      if Y rem 400 = 0 then
         return True;
      elsif Y rem 100 = 0 then
         return False;
      else
         return Y rem 4 = 0;
      end if;
   end Is_Leap;

   -------------------------------------------------------------------------
   -- Century_Anchor  —  (5*(c mod 4)) mod 7 + Tuesday
   -------------------------------------------------------------------------

   function Century_Anchor (Year : Year_Number) return Weekday is
      C : constant Integer := Integer (Year) / 100;
      R : constant Integer := C rem 4;
   begin
      --  r=0 Tue, r=1 Sun, r=2 Fri, r=3 Wed
      case R is
         when 0 => return Tuesday;
         when 1 => return Sunday;
         when 2 => return Friday;
         when others => return Wednesday;  -- R = 3
      end case;
   end Century_Anchor;

   -------------------------------------------------------------------------
   -- Year_Doomsday  —  Conway dozen + century anchor
   -------------------------------------------------------------------------

   function Year_Doomsday (Year : Year_Number) return Weekday is
      Y : constant Integer := Integer (Year) rem 100;
      A : constant Integer := Y / 12;
      B : constant Integer := Y rem 12;
      C : constant Integer := B / 4;
      D : constant Integer := A + B + C;
   begin
      return Mod7 (Integer (Century_Anchor (Year)) + D);
   end Year_Doomsday;

   -------------------------------------------------------------------------
   -- Closest_Doomsday
   -------------------------------------------------------------------------

   function Closest_Doomsday
     (Year  : Year_Number;
      Month : Month_Number) return Day_Number
   is
   begin
      case Month is
         when 1 =>
            if Is_Leap (Year) then
               return 4;
            else
               return 3;
            end if;
         when 2 =>
            return Days_In_Month (Year, 2);  -- 28 or 29
         when 3 =>
            return 0;  -- March 0 = last day of February
         when 4 =>
            return 4;
         when 5 =>
            return 9;
         when 6 =>
            return 6;
         when 7 =>
            return 11;
         when 8 =>
            return 8;
         when 9 =>
            return 5;
         when 10 =>
            return 10;
         when 11 =>
            return 7;
         when 12 =>
            return 12;
      end case;
   end Closest_Doomsday;

   -------------------------------------------------------------------------
   -- Day_Of_Week
   -------------------------------------------------------------------------

   function Day_Of_Week
     (Year  : Year_Number;
      Month : Month_Number;
      Day   : Day_Number) return Weekday
   is
      DD     : constant Day_Number := Closest_Doomsday (Year, Month);
      Anchor : constant Weekday    := Year_Doomsday (Year);
      Max_D  : Day_Number;
   begin
      if Month = 3 and then Day = 0 then
         --  March 0 is a valid mnemonic doomsday reference.
         return Anchor;
      end if;

      if Day < 1 then
         raise Invalid_Argument;
      end if;

      Max_D := Days_In_Month (Year, Month);
      if Day > Max_D then
         raise Invalid_Argument;
      end if;

      return Mod7 (Integer (Anchor) + Integer (Day) - Integer (DD));
   end Day_Of_Week;

   -------------------------------------------------------------------------
   -- Weekday_Name
   -------------------------------------------------------------------------

   function Weekday_Name (W : Weekday) return String is
   begin
      case W is
         when Sunday    => return "Sunday";
         when Monday    => return "Monday";
         when Tuesday   => return "Tuesday";
         when Wednesday => return "Wednesday";
         when Thursday  => return "Thursday";
         when Friday    => return "Friday";
         when Saturday  => return "Saturday";
      end case;
   end Weekday_Name;

   -------------------------------------------------------------------------
   -- Sakamoto_Day_Of_Week (independent reference)
   -------------------------------------------------------------------------

   function Sakamoto_Day_Of_Week
     (Year  : Year_Number;
      Month : Month_Number;
      Day   : Positive) return Weekday
   is
      --  t[m] offsets for months 1..12 (Sakamoto).
      T : constant array (Month_Number) of Natural :=
        [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
      Y : Integer := Integer (Year);
   begin
      if Day > Positive (Days_In_Month (Year, Month)) then
         raise Invalid_Argument;
      end if;
      if Month < 3 then
         Y := Y - 1;
      end if;
      return Mod7
        (Y + Y / 4 - Y / 100 + Y / 400
         + Integer (T (Month)) + Integer (Day));
   end Sakamoto_Day_Of_Week;

end Doomsday;
