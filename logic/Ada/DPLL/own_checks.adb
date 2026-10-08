--  Own tests for DPLL (see tests/SOURCES.txt).
--  Solve against an own brute-force satisfiability check (all 2**N assignments); a returned model
--  must satisfy every clause (own evaluator) and assign every used variable; From_DIMACS_Lite of
--  the same formula must give the same answer.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with DPLL; use DPLL;

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
   N_Max : constant := 8;

   type Raw_Clause is record
      Len : Natural := 0;
      L : Literal_List := [others => 0];
   end record;
   type Raw_Formula is array (Positive range <>) of Raw_Clause;

   function Holds (C : Raw_Clause; Bits : Natural) return Boolean is
   begin
      for I in 1 .. C.Len loop
         declare
            V : constant Positive := abs C.L (I);
            Val : constant Boolean := (Bits / 2**(V - 1)) mod 2 = 1;
         begin
            if (C.L (I) > 0) = Val then return True; end if;
         end;
      end loop;
      return False;
   end Holds;

   function Brute (R : Raw_Formula; N : Natural) return Boolean is
   begin
      for Bits in 0 .. 2**N - 1 loop
         if (for all C of R => Holds (C, Bits)) then return True; end if;
      end loop;
      return False;
   end Brute;

   function Model_Ok (R : Raw_Formula; M : Model) return Boolean is
   begin
      for C of R loop
         declare
            Sat : Boolean := False;
         begin
            for I in 1 .. C.Len loop
               declare
                  T : constant Truth_Value := M.Values (abs C.L (I));
               begin
                  if T = Unassigned then return False; end if;   --  used variable left open
                  if (C.L (I) > 0) = (T = Is_True) then Sat := True; end if;
               end;
            end loop;
            if not Sat then return False; end if;
         end;
      end loop;
      return True;
   end Model_Ok;

   function Img (I : Integer) return String is
      S : constant String := Integer'Image (I);
   begin
      return (if I < 0 then S else S (S'First + 1 .. S'Last));
   end Img;
begin
   for Trial in 1 .. 3_000 loop
      declare
         N : constant Positive := Next (1, N_Max);
         M : constant Natural := Next (0, 4 * N + 2);
         R : Raw_Formula (1 .. M);
         F, G : Formula;
         Text : Ada.Strings.Unbounded.Unbounded_String :=
           Ada.Strings.Unbounded.To_Unbounded_String ("c own test" & ASCII.LF & "p cnf" & Integer'Image (N) & Integer'Image (M) & ASCII.LF);
         Expected : Boolean;
         S : Solve_Result;
      begin
         Clear (F);
         Set_Num_Vars (F, N);
         for J in R'Range loop
            declare
               Len : constant Natural := (if Next (0, 30) = 0 then 0 else Next (1, Integer'Min (N, 4)));
               Used : array (1 .. N_Max) of Boolean := [others => False];
            begin
               R (J).Len := Len;
               for I in 1 .. Len loop
                  declare
                     V : Positive;
                  begin
                     loop   --  distinct variables within a clause
                        V := Next (1, N);
                        exit when not Used (V);
                     end loop;
                     Used (V) := True;
                     R (J).L (I) := (if Next (0, 1) = 0 then V else -V);
                     Ada.Strings.Unbounded.Append (Text, Img (R (J).L (I)) & " ");
                  end;
               end loop;
               Ada.Strings.Unbounded.Append (Text, "0" & ASCII.LF);
               Add_Clause_From_Literals (F, R (J).L, Len);
            end;
         end loop;
         Expected := Brute (R, N);
         S := Solve (F);
         Report ((S.Status = Satisfiable) = Expected, "status, trial" & Integer'Image (Trial));
         if S.Status = Satisfiable then
            Report (Model_Ok (R, S.Result_Model), "model, trial" & Integer'Image (Trial));
         end if;
         Report (Is_Satisfiable (F) = Expected, "Is_Satisfiable, trial" & Integer'Image (Trial));
         From_DIMACS_Lite (G, Ada.Strings.Unbounded.To_String (Text));
         Report ((Solve (G).Status = Satisfiable) = Expected, "DIMACS, trial" & Integer'Image (Trial));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;
