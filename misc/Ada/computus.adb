--  Computus body — Meeus/Jones/Butcher Gregorian + Meeus Julian Easter.

pragma Ada_2022;

package body Computus
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local integer helpers (floor division already matches Ada / for >= 0)
   -------------------------------------------------------------------------

   function Mod_Nonneg (A, M : Integer) return Integer is
      R : Integer;
   begin
      if M <= 0 then
         raise Invalid_Argument;
      end if;
      R := A rem M;
      if R < 0 then
         R := R + M;
      end if;
      return R;
   end Mod_Nonneg;

   -------------------------------------------------------------------------
   -- Gregorian Easter (Anonymous / Meeus–Jones–Butcher)
   -------------------------------------------------------------------------

   function Gregorian_Easter (Year : Year_Number) return Date is
      Y : constant Integer := Integer (Year);
      A : constant Integer := Y rem 19;
      B : constant Integer := Y / 100;
      C : constant Integer := Y rem 100;
      D : constant Integer := B / 4;
      E : constant Integer := B rem 4;
      F : constant Integer := (B + 8) / 25;
      G : constant Integer := (B - F + 1) / 3;
      H : constant Integer :=
        Mod_Nonneg (19 * A + B - D - G + 15, 30);
      I : constant Integer := C / 4;
      K : constant Integer := C rem 4;
      L : constant Integer :=
        Mod_Nonneg (32 + 2 * E + 2 * I - H - K, 7);
      M : constant Integer := (A + 11 * H + 22 * L) / 451;
      T : constant Integer := H + L - 7 * M + 114;
      N : constant Integer := T / 31;       -- month 3 or 4
      O : constant Integer := T rem 31;     -- day - 1
   begin
      return (Year => Year, Month => Month_Number (N), Day => Day_Number (O + 1));
   end Gregorian_Easter;

   function Easter (Year : Year_Number) return Date is
   begin
      return Gregorian_Easter (Year);
   end Easter;

   -------------------------------------------------------------------------
   -- Julian Easter (Meeus)
   -------------------------------------------------------------------------

   function Julian_Easter (Year : Year_Number) return Date is
      Y : constant Integer := Integer (Year);
      A : constant Integer := Y rem 4;
      B : constant Integer := Y rem 7;
      C : constant Integer := Y rem 19;
      D : constant Integer := Mod_Nonneg (19 * C + 15, 30);
      E : constant Integer := Mod_Nonneg (2 * A + 4 * B - D + 34, 7);
      T : constant Integer := D + E + 114;
      Mo : constant Integer := T / 31;
      Da : constant Integer := (T rem 31) + 1;
   begin
      return
        (Year  => Year,
         Month => Month_Number (Mo),
         Day   => Day_Number (Da));
   end Julian_Easter;

   -------------------------------------------------------------------------
   -- Julian → Gregorian conversion via day offset
   -------------------------------------------------------------------------

   function Julian_Gregorian_Offset (Year : Year_Number) return Integer is
      Y : constant Integer := Integer (Year);
   begin
      --  Days Gregorian is ahead of Julian at the start of Year
      --  (valid for Orthodox Easter years after the Gregorian reform).
      return Y / 100 - Y / 400 - 2;
   end Julian_Gregorian_Offset;

   function Is_Gregorian_Leap (Year : Year_Number) return Boolean is
      Y : constant Integer := Integer (Year);
   begin
      return (Y rem 4 = 0 and then Y rem 100 /= 0) or else (Y rem 400 = 0);
   end Is_Gregorian_Leap;

   function Days_In_Month
     (Year : Year_Number; Month : Month_Number) return Day_Number
   is
   begin
      case Month is
         when 1 | 3 | 5 | 7 | 8 | 10 | 12 =>
            return 31;
         when 4 | 6 | 9 | 11 =>
            return 30;
         when 2 =>
            if Is_Gregorian_Leap (Year) then
               return 29;
            else
               return 28;
            end if;
      end case;
   end Days_In_Month;

   function Ordinal_Day (D : Date) return Natural is
      N : Natural := 0;
   begin
      for M in 1 .. Integer (D.Month) - 1 loop
         N := N + Natural (Days_In_Month (D.Year, Month_Number (M)));
      end loop;
      return N + Natural (D.Day);
   end Ordinal_Day;

   function From_Ordinal
     (Year : Year_Number; Ordinal : Positive) return Date
   is
      Rem_Days : Integer := Integer (Ordinal);
      Dim      : Day_Number;
   begin
      for M in Month_Number loop
         Dim := Days_In_Month (Year, M);
         if Rem_Days <= Integer (Dim) then
            return
              (Year  => Year,
               Month => M,
               Day   => Day_Number (Rem_Days));
         end if;
         Rem_Days := Rem_Days - Integer (Dim);
      end loop;
      raise Invalid_Argument;
   end From_Ordinal;

   function Add_Days (D : Date; Delta_Days : Integer) return Date is
      --  Walk month-by-month (robust, no formula edge cases).
      Y   : Integer := Integer (D.Year);
      M   : Integer := Integer (D.Month);
      Day : Integer := Integer (D.Day) + Delta_Days;
      Dim : Integer;
   begin
      while Day > 0 loop
         Dim := Integer (Days_In_Month (Year_Number (Y), Month_Number (M)));
         if Day <= Dim then
            return
              (Year  => Year_Number (Y),
               Month => Month_Number (M),
               Day   => Day_Number (Day));
         end if;
         Day := Day - Dim;
         M := M + 1;
         if M > 12 then
            M := 1;
            Y := Y + 1;
            if Y > Integer (Year_Number'Last) then
               raise Invalid_Argument;
            end if;
         end if;
      end loop;

      --  Day <= 0: step backward
      while Day <= 0 loop
         M := M - 1;
         if M < 1 then
            M := 12;
            Y := Y - 1;
            if Y < Integer (Year_Number'First) then
               raise Invalid_Argument;
            end if;
         end if;
         Dim := Integer (Days_In_Month (Year_Number (Y), Month_Number (M)));
         Day := Day + Dim;
      end loop;

      return
        (Year  => Year_Number (Y),
         Month => Month_Number (M),
         Day   => Day_Number (Day));
   end Add_Days;

   function Julian_To_Gregorian (D : Date) return Date is
      Offset : constant Integer := Julian_Gregorian_Offset (D.Year);
   begin
      --  Treat Julian Y-M-D components as if they were Gregorian, then
      --  add the Julian→Gregorian day offset for that year. For Orthodox
      --  Easter (Mar/Apr Julian) this matches civil Gregorian dates.
      return Add_Days
        ((Year => D.Year, Month => D.Month, Day => D.Day), Offset);
   end Julian_To_Gregorian;

   function Orthodox_Easter (Year : Year_Number) return Date is
   begin
      return Julian_To_Gregorian (Julian_Easter (Year));
   end Orthodox_Easter;

   -------------------------------------------------------------------------
   -- Weekday (Sakamoto)
   -------------------------------------------------------------------------

   function Day_Of_Week (D : Date) return Weekday is
      T : constant array (1 .. 12) of Integer :=
        [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4];
      Y : Integer := Integer (D.Year);
      W : Integer;
   begin
      if Integer (D.Month) < 3 then
         Y := Y - 1;
      end if;
      W :=
        Y
        + Y / 4
        - Y / 100
        + Y / 400
        + T (Integer (D.Month))
        + Integer (D.Day);
      return Weekday (Mod_Nonneg (W, 7));
   end Day_Of_Week;

   function Is_Sunday (D : Date) return Boolean is
   begin
      return Day_Of_Week (D) = Sunday;
   end Is_Sunday;

   function Day_Difference (A, B : Date) return Integer is
      --  Convert both to absolute serial via Add_Days walking from a base.
      --  Use Ordinal + year contribution for speed.
      function Year_Days (Y : Integer) return Integer is
      begin
         if (Y rem 4 = 0 and then Y rem 100 /= 0) or else (Y rem 400 = 0) then
            return 366;
         else
            return 365;
         end if;
      end Year_Days;

      function Absolute (D : Date) return Integer is
         N : Integer := 0;
      begin
         for Y in 1 .. Integer (D.Year) - 1 loop
            N := N + Year_Days (Y);
         end loop;
         return N + Integer (Ordinal_Day (D));
      end Absolute;
   begin
      return Absolute (B) - Absolute (A);
   end Day_Difference;

   function Same_Date (A, B : Date) return Boolean is
   begin
      return A.Year = B.Year and then A.Month = B.Month and then A.Day = B.Day;
   end Same_Date;

   function Near
     (A, B     : Date;
      Tol_Days : Natural := 0) return Boolean
   is
      Diff : constant Integer := Day_Difference (A, B);
   begin
      if Diff >= 0 then
         return Diff <= Integer (Tol_Days);
      else
         return -Diff <= Integer (Tol_Days);
      end if;
   end Near;

   function In_Easter_Window (D : Date) return Boolean is
   begin
      if D.Month = 3 then
         return D.Day >= 22;
      elsif D.Month = 4 then
         return D.Day <= 25;
      else
         return False;
      end if;
   end In_Easter_Window;

   function Golden_Number (Year : Year_Number) return Positive is
   begin
      return Positive ((Integer (Year) rem 19) + 1);
   end Golden_Number;

end Computus;
