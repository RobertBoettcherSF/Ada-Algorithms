pragma Ada_2022;
--  Own tests for Division_Algorithms (see tests/SOURCES.txt).
--  Division identities (own properties): N = Q * D + R with |R| < |D| and R zero or of the sign
--  of N (truncating division, as the spec states); unsigned cores with 0 <= R < D; float methods
--  within a relative 1e-9 of N / D.
with Ada.Text_IO; use Ada.Text_IO;
with Division_Algorithms; use Division_Algorithms;

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
   function Trunc_Ok (N, D : Integer; Res : Division_Result) return Boolean is
     (N = Res.Quotient * D + Res.Remainder and then abs Res.Remainder < abs D
      and then (Res.Remainder = 0 or else (Res.Remainder > 0) = (N > 0)));
begin
   for N in Operand_Min .. Operand_Max loop
      for D in Operand_Min .. Operand_Max loop
         if D /= 0 and then not (N = Operand_Min and then D = -1) then
            Report (Trunc_Ok (N, D, Divide_Restoring (N, D)), "Restoring" & N'Image & D'Image);
            Report (Trunc_Ok (N, D, Divide_Non_Restoring (N, D)), "Non_Restoring" & N'Image & D'Image);
         end if;
      end loop;
   end loop;
   for N in 0 .. 255 loop
      for D in 1 .. 255 loop
         declare
            Q, R : Natural;
            B : Quotient_Bit_Array (0 .. 7);
            S : Signed_Digit_Array (0 .. 7);
         begin
            Divide_Restoring_Unsigned (N, D, 8, Q, R, B);
            Report (N = Q * D + R and then R < D, "Restoring_Unsigned" & N'Image & D'Image);
            Divide_Non_Restoring_Unsigned (N, D, 8, Q, R, S);
            Report (N = Q * D + R and then R < D, "Non_Restoring_Unsigned" & N'Image & D'Image);
         end;
      end loop;
   end loop;
   for Run in 1 .. 20000 loop
      declare
         N : constant Natural := Next (0, 1_000_000_000);
         D : constant Positive := (if Run mod 2 = 0 then Next (1, 100) else Next (1, 1_000_000_000));
         Res : constant Division_Result := Divide_Schoolbook (N, D);
      begin
         Report (N = Res.Quotient * D + Res.Remainder and then Res.Remainder in 0 .. D - 1,
                 "Schoolbook" & N'Image & D'Image);
      end;
   end loop;
   for Run in 1 .. 20000 loop
      declare
         N : constant Long_Float := Long_Float (Next (-1_000_000, 1_000_000)) / 1000.0;
         D : constant Long_Float := (Long_Float (Next (1, 1_000_000)) / 1000.0) * (if Next (0, 1) = 0 then 1.0 else -1.0);
         E : constant Long_Float := N / D;
      begin
         Report (abs (Divide_NR (N, D) - E) <= 1.0E-9 * Long_Float'Max (1.0, abs E), "NR" & N'Image & D'Image);
         Report (abs (Divide_Goldschmidt (N, D) - E) <= 1.0E-9 * Long_Float'Max (1.0, abs E), "Goldschmidt" & N'Image & D'Image);
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
