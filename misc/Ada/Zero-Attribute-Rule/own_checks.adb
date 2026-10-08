pragma Ada_2022;
--  Own tests for Zero_Attribute_Rule (see tests/SOURCES.txt).
--  ZeroR predictions (own references): mean = sum / count; median = middle value of the sorted
--  targets, or the average of the two middle values for an even count (the standard definition);
--  mode = most frequent value, ties to the smallest value (as the spec states). Empty input is
--  rejected by the Safe_ variants with Empty_Dataset_Error.
with Ada.Text_IO; use Ada.Text_IO;
with Zero_Attribute_Rule; use Zero_Attribute_Rule;

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
   procedure Sort (A : in out Numeric_Array) is
      T : Numeric_Value; J : Integer;
   begin
      for P in A'First + 1 .. A'Last loop
         T := A (P); J := P - 1;
         while J >= A'First and then A (J) > T loop A (J + 1) := A (J); J := J - 1; end loop;
         A (J + 1) := T;
      end loop;
   end Sort;
   function Close (X, Y : Numeric_Value) return Boolean is (abs (X - Y) <= 1.0E-3 * Numeric_Value'Max (1.0, abs Y));
begin
   for Run in 1 .. 10000 loop
      declare
         N : constant Positive := Next (1, 15);
         A, S : Numeric_Array (1 .. N);
         B : Nominal_Array (1 .. N);
         Sum : Numeric_Value := 0.0;
         Med : Numeric_Value;
         Best, Best_Count, C : Natural := 0;
         Hi : constant Natural := (if Run mod 2 = 0 then 3 else 50);
      begin
         for I in 1 .. N loop
            A (I) := Numeric_Value (Next (-1000, 1000)); Sum := Sum + A (I);
            B (I) := Nominal_Value (Next (0, Hi));
         end loop;
         S := A; Sort (S);
         Med := (if N mod 2 = 1 then S ((N + 1) / 2) else (S (N / 2) + S (N / 2 + 1)) / 2.0);
         for V in 0 .. Hi loop
            C := 0;
            for X of B loop if Natural (X) = V then C := C + 1; end if; end loop;
            if C > Best_Count then Best := V; Best_Count := C; end if;   --  strict: ties keep the smaller value
         end loop;
         Report (Close (Predict_Numeric_Mean (A), Sum / Numeric_Value (N))
                 and then Close (Safe_Predict_Numeric_Mean (A), Sum / Numeric_Value (N)), "mean run" & Run'Image);
         Report (Close (Predict_Numeric_Median (A), Med) and then Close (Safe_Predict_Numeric_Median (A), Med),
                 "median run" & Run'Image & " N =" & N'Image);
         Report (Natural (Predict_Nominal_Mode (B)) = Best and then Natural (Safe_Predict_Nominal_Mode (B)) = Best,
                 "mode run" & Run'Image);
      end;
   end loop;
   declare
      E : Numeric_Array (1 .. 0);
      X : Numeric_Value;
   begin
      X := Safe_Predict_Numeric_Mean (E);
      Report (False, "Safe_Predict_Numeric_Mean accepted an empty array:" & X'Image);
   exception
      when Empty_Dataset_Error => Report (True, "");
   end;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
