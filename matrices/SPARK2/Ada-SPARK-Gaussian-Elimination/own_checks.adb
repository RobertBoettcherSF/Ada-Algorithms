--  Own tests for Gaussian_Elimination (see tests/SOURCES.txt).
--  An elimination step must give R (2, 1) = 0 and keep the solution set: every integer (X, Y) in a
--  grid solves the original two equations exactly when it solves the reduced ones.
with Ada.Text_IO; use Ada.Text_IO;
with Gaussian_Elimination; use Gaussian_Elimination;

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
   function Solves_Input (A : Input_Matrix; X, Y : Integer) return Boolean is
     (for all I in Row => Long_Long_Integer (A (I, 1) * X + A (I, 2) * Y) = Long_Long_Integer (A (I, 3)));
   function Solves_Reduced (R : Reduced_Matrix; X, Y : Integer) return Boolean is
     (for all I in Row => R (I, 1) * Long_Long_Integer (X) + R (I, 2) * Long_Long_Integer (Y) = R (I, 3));

   procedure Check (A : Input_Matrix) is
      R : constant Reduced_Matrix := Eliminate (A);
      Same : Boolean := True;
   begin
      for X in -15 .. 15 loop
         for Y in -15 .. 15 loop
            if Solves_Input (A, X, Y) /= Solves_Reduced (R, X, Y) then Same := False; end if;
         end loop;
      end loop;
      Report (R (2, 1) = 0 and then Same,
              "matrix" & Integer'Image (A (1, 1)) & Integer'Image (A (1, 2)) & Integer'Image (A (1, 3))
              & " /" & Integer'Image (A (2, 1)) & Integer'Image (A (2, 2)) & Integer'Image (A (2, 3)));
   end Check;

   A : Input_Matrix;
begin
   --  every pair of first-column entries, 60 random completions each; every third completion is
   --  built around an integer solution (X, Y) so that the solution set is not empty
   for P in Entry_Value loop
      for F in Entry_Value loop
         for Trial in 1 .. 60 loop
            A (1, 1) := P; A (2, 1) := F;
            A (1, 2) := Next (-10, 10); A (2, 2) := Next (-10, 10);
            A (1, 3) := Next (-10, 10); A (2, 3) := Next (-10, 10);
            if Trial mod 3 = 0 then
               declare
                  X : constant Integer := Next (-2, 2);
                  Y : constant Integer := Next (-2, 2);
               begin
                  A (1, 2) := Next (-4, 4); A (2, 2) := Next (-4, 4);
                  if abs (P * X + A (1, 2) * Y) <= 10 and then abs (F * X + A (2, 2) * Y) <= 10 then
                     A (1, 3) := P * X + A (1, 2) * Y;
                     A (2, 3) := F * X + A (2, 2) * Y;
                  end if;
               end;
            end if;
            Check (A);
         end loop;
      end loop;
   end loop;
   Check ([[0, 1, 1], [1, 0, 2]]);   --  zero pivot, unique solution (2, 1)
   Check ([[0, 0, 0], [0, 3, 6]]);   --  first column all zero
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
