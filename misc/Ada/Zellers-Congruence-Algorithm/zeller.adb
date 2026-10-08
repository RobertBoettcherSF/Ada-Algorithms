-- zeller.adb
package body Zeller is

   -- HELPER: Checks leap year using the Gregorian rules (divisible by 4, but not 100 unless 400)
   function Is_Leap_Year_Gregorian (Year : Year_Type) return Boolean is
   begin
      return (Year mod 4 = 0 and then Year mod 100 /= 0) or else (Year mod 400 = 0);
   end Is_Leap_Year_Gregorian;

   -- HELPER: Checks leap year using Julian rules (simply divisible by 4)
   function Is_Leap_Year_Julian (Year : Year_Type) return Boolean is
   begin
      return Year mod 4 = 0;
   end Is_Leap_Year_Julian;

   -- HELPER: Validates edge cases like February 30th, April 31st, etc.
   procedure Validate_Date (Day : Day_Type; Month : Month_Type; Year : Year_Type; Is_Gregorian : Boolean) is
      Max_Day : Day_Type;
   begin
      case Month is
         when 4 | 6 | 9 | 11 => 
            Max_Day := 30;
         when 2 =>
            if (Is_Gregorian and then Is_Leap_Year_Gregorian(Year)) or else
               (not Is_Gregorian and then Is_Leap_Year_Julian(Year)) then
               Max_Day := 29;
            else
               Max_Day := 28;
            end if;
         when others => 
            Max_Day := 31;
      end case;

      if Day > Max_Day then
         raise Invalid_Date with "Day exceeds maximum days in the given month.";
      end if;
   end Validate_Date;

   -- HELPER: Pre-processes Jan and Feb to be the 13th and 14th months of the previous year.
   procedure Adjust_Month_Year(Month : in out Integer; Year : in out Integer) is
   begin
      if Month < 3 then
         Month := Month + 12;
         Year := Year - 1;
      end if;
   end Adjust_Month_Year;

   -- HELPER: Remaps Zeller output to ISO 8601 output mathematically.
   function To_ISO(D : Day_Of_Week) return ISO_Day_Of_Week is
      -- Zeller internal: 0=Sat, 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri
      -- Target ISO pos: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun
      H_Val   : constant Integer := Day_Of_Week'Pos(D);
      ISO_Val : constant Integer := ((H_Val + 5) mod 7);
   begin
      return ISO_Day_Of_Week'Val(ISO_Val);
   end To_ISO;

   -- VARIANT 1: Gregorian Calculation
   function Day_Of_Week_Gregorian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return Day_Of_Week is
      q : constant Integer := Integer(Day);
      m : Integer := Integer(Month);
      Y : Integer := Integer(Year);
      K, J, h : Integer;
   begin
      Validate_Date(Day, Month, Year, True);
      Adjust_Month_Year(m, Y);

      K := Y mod 100; -- Year of the century
      J := Y / 100;   -- Zero-based century

      -- Formula: h = (q + floor(13(m+1)/5) + K + floor(K/4) + floor(J/4) - 2J) mod 7
      h := (q + ((13 * (m + 1)) / 5) + K + (K / 4) + (J / 4) - (2 * J)) mod 7;
      
      return Day_Of_Week'Val(h);
   end Day_Of_Week_Gregorian;

   -- VARIANT 2: Julian Calculation
   function Day_Of_Week_Julian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return Day_Of_Week is
      q : constant Integer := Integer(Day);
      m : Integer := Integer(Month);
      Y : Integer := Integer(Year);
      K, J, h : Integer;
   begin
      Validate_Date(Day, Month, Year, False);
      Adjust_Month_Year(m, Y);

      K := Y mod 100; -- Year of the century
      J := Y / 100;   -- Zero-based century

      -- Formula: h = (q + floor(13(m+1)/5) + K + floor(K/4) + 5 - J) mod 7
      h := (q + ((13 * (m + 1)) / 5) + K + (K / 4) + 5 - J) mod 7;
      
      return Day_Of_Week'Val(h);
   end Day_Of_Week_Julian;

   -- VARIANT 3: ISO Representation (Gregorian)
   function Day_Of_Week_ISO_Gregorian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return ISO_Day_Of_Week is
   begin
      return To_ISO(Day_Of_Week_Gregorian(Day, Month, Year));
   end Day_Of_Week_ISO_Gregorian;

   -- VARIANT 4: ISO Representation (Julian)
   function Day_Of_Week_ISO_Julian (Day : Day_Type; Month : Month_Type; Year : Year_Type) return ISO_Day_Of_Week is
   begin
      return To_ISO(Day_Of_Week_Julian(Day, Month, Year));
   end Day_Of_Week_ISO_Julian;

end Zeller;
