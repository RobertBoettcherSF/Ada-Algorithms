pragma Ada_2022;
--  Own tests for Computus (see tests/SOURCES.txt).
--  Easter dates against own references built from the definitions:
--  * Gregorian: an own Lilius/Clavius epact computation (golden number, solar and lunar corrections,
--    epact with the 24/25 exceptions, paschal full moon, next Sunday), checked for every year 1583 .. 9999,
--    plus "is a Sunday" from an own Julian Day Number and the Mar 22 .. Apr 25 window.
--  * Julian: Sunday strictly after the Julian paschal full moon (Mar 21 + (19 (Y mod 19) + 15) mod 30),
--    weekday from an own Julian-calendar day number, for every year 1 .. 9999.
--  * Orthodox_Easter: the Gregorian date with the same day number as Julian_Easter (1583 .. 9999).
--  * Day_Of_Week and Day_Difference on random dates against the own day numbers.
with Ada.Text_IO; use Ada.Text_IO;
with Computus; use Computus;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function JDN_G (Y, M, D : Integer) return Integer is
      A : constant Integer := (14 - M) / 12;
      YY : constant Integer := Y + 4800 - A;
      MM : constant Integer := M + 12 * A - 3;
   begin
      return D + (153 * MM + 2) / 5 + 365 * YY + YY / 4 - YY / 100 + YY / 400 - 32045;
   end JDN_G;
   function JDN_J (Y, M, D : Integer) return Integer is
      A : constant Integer := (14 - M) / 12;
      YY : constant Integer := Y + 4800 - A;
      MM : constant Integer := M + 12 * A - 3;
   begin
      return D + (153 * MM + 2) / 5 + 365 * YY + YY / 4 - 32083;
   end JDN_J;
   function Dow (J : Integer) return Natural is ((J + 1) mod 7);   --  0 = Sunday
   function Leap (Y : Integer) return Boolean is (Y mod 4 = 0 and then (Y mod 100 /= 0 or else Y mod 400 = 0));
   ML : constant array (1 .. 12) of Integer := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
   function Len (Y, M : Integer) return Integer is (if M = 2 and then Leap (Y) then 29 else ML (M));
   procedure Clavius (Y : Integer; M, D : out Integer) is
      G : constant Integer := Y mod 19 + 1;
      C : constant Integer := Y / 100 + 1;
      X : constant Integer := 3 * C / 4 - 12;          --  solar correction
      Z : constant Integer := (8 * C + 5) / 25 - 5;     --  lunar correction
      S : constant Integer := 5 * Y / 4 - X - 10;       --  Sunday key
      E : Integer := (11 * G + 20 + Z - X) mod 30;      --  epact
      N : Integer;
   begin
      if (E = 25 and then G > 11) or else E = 24 then E := E + 1; end if;
      N := 44 - E;                                      --  paschal full moon as a March day
      if N < 21 then N := N + 30; end if;
      N := N + 7 - ((S + N) mod 7);                     --  next Sunday
      if N > 31 then M := 4; D := N - 31; else M := 3; D := N; end if;
   end Clavius;
begin
   for Y in 1583 .. 9999 loop
      declare
         M, D : Integer;
         G : constant Date := Gregorian_Easter (Y);
         E : constant Date := Easter (Y);
      begin
         Clavius (Y, M, D);
         Report (G.Year = Y and then G.Month = M and then G.Day = D and then E = G,
                 "Gregorian Easter" & Y'Image & " gave" & G.Month'Image & G.Day'Image & ", own" & M'Image & D'Image);
         Report (Dow (JDN_G (Y, G.Month, G.Day)) = 0 and then Is_Sunday (G)
                 and then ((G.Month = 3 and then G.Day >= 22) or else (G.Month = 4 and then G.Day <= 25)),
                 "Gregorian Easter not a Sunday in Mar 22 .. Apr 25:" & Y'Image);
      end;
   end loop;
   for Y in 1 .. 9999 loop
      declare
         J : constant Date := Julian_Easter (Y);
         PFM : constant Integer := JDN_J (Y, 3, 21) + (19 * (Y mod 19) + 15) mod 30;
         EJ : constant Integer := JDN_J (Y, J.Month, J.Day);
      begin
         Report (J.Year = Y and then J.Month in 3 .. 4 and then Dow (EJ) = 0 and then EJ - PFM in 1 .. 7,
                 "Julian Easter" & Y'Image & " gave" & J.Month'Image & J.Day'Image);
         if Y >= 1583 then
            declare
               O : constant Date := Orthodox_Easter (Y);
            begin
               Report (JDN_G (O.Year, O.Month, O.Day) = EJ,
                       "Orthodox Easter" & Y'Image & " gave" & O.Year'Image & O.Month'Image & O.Day'Image);
            end;
         end if;
      end;
   end loop;
   for Run in 1 .. 20000 loop
      declare
         Y1 : constant Integer := Next (1583, 9998);
         M1 : constant Integer := Next (1, 12);
         A : constant Date := (Y1, M1, Next (1, Len (Y1, M1)));
         Y2 : constant Integer := Next (1583, 9998);
         M2 : constant Integer := Next (1, 12);
         B : constant Date := (Y2, M2, Next (1, Len (Y2, M2)));
      begin
         Report (Day_Of_Week (A) = Dow (JDN_G (A.Year, A.Month, A.Day)), "Day_Of_Week run" & Run'Image);
         Report (Day_Difference (A, B) = JDN_G (B.Year, B.Month, B.Day) - JDN_G (A.Year, A.Month, A.Day),
                 "Day_Difference run" & Run'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
