pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Every pair (Num1, Num2) in 0 .. 32
--  (1,089 pairs) against an independent count: repeated subtraction of the
--  smaller from the larger is Euclid's division step done one subtraction
--  at a time, so the number of operations is the sum of the quotients of
--  Euclid's algorithm: Ops (A, B) = A / B + Ops (B, A mod B) for A >= B > 0,
--  and 0 once either number is 0. Also symmetry for unequal non-zero
--  numbers and Ops (K, K) = 1 for K > 0.
with Ada.Text_IO;
with Count_Operations_To_Obtain_Zero; use Count_Operations_To_Obtain_Zero;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Quotient_Sum (A, B : Natural) return Natural is
      Big   : Natural := Natural'Max (A, B);
      Small : Natural := Natural'Min (A, B);
      Sum   : Natural := 0;
      T     : Natural;
   begin
      while Small /= 0 loop
         Sum := Sum + Big / Small;
         T := Big mod Small;
         Big := Small;
         Small := T;
      end loop;
      return Sum;
   end Quotient_Sum;

   R1, R2 : Natural;
begin
   for A in Number loop
      for B in Number loop
         R1 := Operations (A, B);
         Report (R1 = Quotient_Sum (A, B),
                 "Euclid quotient sum" & A'Image & B'Image);
         if A /= B then
            declare
               X : constant Number := B;
               Y : constant Number := A;
            begin
               R2 := Operations (X, Y);
            end;
            Report (R1 = R2, "symmetric" & A'Image & B'Image);
         elsif A > 0 then
            Report (R1 = 1, "equal numbers take one step" & A'Image);
         end if;
      end loop;
   end loop;
   Ada.Text_IO.Put_Line
     ("Own checks:" & Checked'Image & " checks," & Failures'Image
      & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
