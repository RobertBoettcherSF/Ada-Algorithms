--  Standalone test suite for Division_Algorithms (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Division_Algorithms; use Division_Algorithms;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Agree_Int (A, B : Division_Result) return Boolean is
   begin
      return A.Quotient = B.Quotient and then A.Remainder = B.Remainder;
   end Agree_Int;

   function Identity (N, D : Integer; R : Division_Result) return Boolean is
   begin
      return N = R.Quotient * D + R.Remainder;
   end Identity;

   function Float_Near
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return Near (A, B, Tol);
   end Float_Near;

   function OB return Integer is (Operand_Bits);
   function OMin return Integer is (Operand_Min);
   function OMax return Integer is (Operand_Max);

begin
   Put_Line ("Division_Algorithms — educational survey tests");
   Put_Line ("Operand_Bits =" & Operand_Bits'Image);

   ------------------------------------------------------------------
   Section ("1. Taxonomy / Method_Kind");
   ------------------------------------------------------------------
   Check (Is_Slow (Schoolbook), "Schoolbook is slow");
   Check (Is_Slow (Restoring), "Restoring is slow");
   Check (Is_Slow (Non_Restoring), "Non-restoring is slow");
   Check (Is_Slow (SRT_Catalogue), "SRT catalogue is slow");
   Check (Is_Fast (Newton_Raphson), "NR is fast");
   Check (Is_Fast (Goldschmidt), "Goldschmidt is fast");
   Check (Is_Implemented (Schoolbook), "Schoolbook implemented");
   Check (Is_Implemented (Restoring), "Restoring implemented");
   Check (Is_Implemented (Non_Restoring), "Non-restoring implemented");
   Check (Is_Implemented (Newton_Raphson), "NR implemented");
   Check (Is_Implemented (Goldschmidt), "Goldschmidt implemented");
   Check (not Is_Implemented (SRT_Catalogue), "SRT catalogue only");
   Check (Method_Name (Restoring) = "Restoring", "Method_Name Restoring");

   ------------------------------------------------------------------
   Section ("2. Digit_Vector construction");
   ------------------------------------------------------------------
   Check (Is_Zero (Zero), "Zero is zero");
   Check (not Is_Zero (One), "One is not zero");
   Check (To_Natural (Zero) = 0, "To_Natural Zero");
   Check (To_Natural (One) = 1, "To_Natural One");
   Check (To_Natural (From_Natural (0)) = 0, "From/To 0");
   Check (To_Natural (From_Natural (42)) = 42, "From/To 42");
   Check (To_String (From_Natural (0)) = "0", "To_String 0");
   Check (To_String (From_Natural (1234)) = "1234", "To_String 1234");
   Check (Compare (From_Natural (5), From_Natural (5)) = 0, "Compare eq");
   Check (Compare (From_Natural (3), From_Natural (7)) < 0, "Compare lt");
   Check (Compare (From_Natural (9), From_Natural (2)) > 0, "Compare gt");

   ------------------------------------------------------------------
   Section ("3. Schoolbook / long division vs oracle");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of
        Natural :=
          [0, 1, 7, 3, 100, 7, 1234, 56, 42, 42, 81, 9];
      I : Positive := 1;
   begin
      while I <= Pairs'Last loop
         declare
            N : constant Natural := Pairs (I);
            D : constant Natural := Pairs (I + 1);
            S : constant Division_Result := Divide_Schoolbook (N, D);
            O : constant Division_Result := Divide_Oracle (Integer (N), Integer (D));
            Dig : constant Digit_Division_Result :=
              Divide_Long (From_Natural (N), From_Natural (D));
         begin
            Check (Agree_Int (S, O)
                   and then Identity (Integer (N), Integer (D), S),
                   "Schoolbook" & N'Image & " /" & D'Image);
            Check (To_Natural (Dig.Quotient) = Natural (O.Quotient)
                   and then To_Natural (Dig.Remainder) = Natural (O.Remainder),
                   "Divide_Long" & N'Image & " /" & D'Image);
         end;
         I := I + 2;
      end loop;
   end;

   --  Dividend < divisor
   declare
      S : constant Division_Result := Divide_Schoolbook (3, 10);
   begin
      Check (S.Quotient = 0 and then S.Remainder = 3, "Schoolbook 3/10");
   end;

   ------------------------------------------------------------------
   Section ("4. Restoring vs oracle (8-bit)");
   ------------------------------------------------------------------
   Check (OB = 8, "Operand_Bits = 8");
   Check (OMin = -128, "Operand_Min");
   Check (OMax = 127, "Operand_Max");

   declare
      Cases : constant array (Positive range <>) of Integer :=
        [0, 1, 7, 3, 100, 7, 127, 2,
         -7, 3, 7, -3, -100, 7, 50, -8,
         1, -1, 64, 8];
      I : Positive := 1;
   begin
      while I <= Cases'Last loop
         declare
            N : constant Integer := Cases (I);
            D : constant Integer := Cases (I + 1);
            S : constant Division_Result := Divide_Restoring (N, D);
            O : constant Division_Result := Divide_Oracle (N, D);
         begin
            Check (Agree_Int (S, O) and then Identity (N, D, S),
                   "Restoring" & N'Image & " /" & D'Image);
         end;
         I := I + 2;
      end loop;
   end;

   --  Unsigned core spot check
   declare
      Q, R : Natural;
      Bits : Quotient_Bit_Array (0 .. 7);
   begin
      Divide_Restoring_Unsigned (100, 7, 8, Q, R, Bits);
      Check (Q = 14 and then R = 2, "Restoring unsigned 100/7");
      Divide_Restoring_Unsigned (0, 5, 8, Q, R, Bits);
      Check (Q = 0 and then R = 0, "Restoring unsigned 0/5");
   end;

   ------------------------------------------------------------------
   Section ("5. Non-restoring vs oracle (8-bit)");
   ------------------------------------------------------------------
   declare
      Cases : constant array (Positive range <>) of Integer :=
        [0, 1, 7, 3, 100, 7, 127, 2,
         -7, 3, 7, -3, -100, 7, 50, -8,
         1, -1, 27, 5];
      I : Positive := 1;
   begin
      while I <= Cases'Last loop
         declare
            N : constant Integer := Cases (I);
            D : constant Integer := Cases (I + 1);
            S : constant Division_Result := Divide_Non_Restoring (N, D);
            O : constant Division_Result := Divide_Oracle (N, D);
         begin
            Check (Agree_Int (S, O) and then Identity (N, D, S),
                   "NonRest" & N'Image & " /" & D'Image);
         end;
         I := I + 2;
      end loop;
   end;

   declare
      Q, R : Natural;
      Digs : Signed_Digit_Array (0 .. 7);
   begin
      Divide_Non_Restoring_Unsigned (100, 7, 8, Q, R, Digs);
      Check (Q = 14 and then R = 2, "NonRest unsigned 100/7");
   end;

   ------------------------------------------------------------------
   Section ("6. Cross-check: Schoolbook = Restoring = Non-restoring");
   ------------------------------------------------------------------
   declare
      Ns : constant array (Positive range <>) of Natural :=
        [0, 17, 42, 100, 127];
      Ds : constant array (Positive range <>) of Natural :=
        [1, 3, 7, 10];
   begin
      for N of Ns loop
         for D of Ds loop
            if N <= Natural (Operand_Max) and then D <= Natural (Operand_Max)
            then
               declare
                  Sch : constant Division_Result := Divide_Schoolbook (N, D);
                  Res : constant Division_Result :=
                    Divide_Restoring (Integer (N), Integer (D));
                  Non : constant Division_Result :=
                    Divide_Non_Restoring (Integer (N), Integer (D));
                  Ora : constant Division_Result :=
                    Divide_Oracle (Integer (N), Integer (D));
               begin
                  Check (Agree_Int (Sch, Ora)
                         and then Agree_Int (Res, Ora)
                         and then Agree_Int (Non, Ora),
                         "Cross N=" & N'Image & " D=" & D'Image);
               end;
            end if;
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("7. Newton–Raphson Float vs Exact_Quotient");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of Long_Float :=
        [1.0, 2.0, 15.0, 3.0, -10.0, 4.0, 10.0, -3.0,
         3.14159, 2.71828, 100.0, 0.1];
      I : Positive := 1;
   begin
      while I <= Pairs'Last loop
         declare
            N : constant Long_Float := Pairs (I);
            D : constant Long_Float := Pairs (I + 1);
            R : constant Float_Division_Result := Divide_NR_Detail (N, D);
            E : constant Long_Float := Exact_Quotient (N, D);
         begin
            Check (R.Status = Converged,
                   "NR converged" & Long_Float'Image (N)
                   & " /" & Long_Float'Image (D));
            Check (Float_Near (R.Quotient, E, 1.0E-9)
                   and then Float_Near (Divide_NR (N, D), E, 1.0E-9),
                   "NR vs oracle" & Long_Float'Image (N)
                   & " /" & Long_Float'Image (D));
         end;
         I := I + 2;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("8. Goldschmidt Float vs Exact_Quotient");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of Long_Float :=
        [1.0, 2.0, 15.0, 3.0, -10.0, 4.0, 10.0, -3.0,
         3.14159, 2.71828, 100.0, 0.1];
      I : Positive := 1;
   begin
      while I <= Pairs'Last loop
         declare
            N : constant Long_Float := Pairs (I);
            D : constant Long_Float := Pairs (I + 1);
            R : constant Float_Division_Result :=
              Divide_Goldschmidt_Detail (N, D);
            E : constant Long_Float := Exact_Quotient (N, D);
         begin
            Check (R.Status = Converged
                   and then Float_Near (R.Final_Denom, 1.0, 1.0E-9),
                   "Gold converged" & Long_Float'Image (N)
                   & " /" & Long_Float'Image (D));
            Check (Float_Near (R.Quotient, E, 1.0E-9)
                   and then Float_Near (Divide_Goldschmidt (N, D), E, 1.0E-9),
                   "Gold vs oracle" & Long_Float'Image (N)
                   & " /" & Long_Float'Image (D));
         end;
         I := I + 2;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. NR ≈ Goldschmidt");
   ------------------------------------------------------------------
   declare
      Ns : constant array (Positive range <>) of Long_Float :=
        [1.0, 100.0, -5.0];
      Ds : constant array (Positive range <>) of Long_Float :=
        [2.0, 11.0, -4.0];
   begin
      for N of Ns loop
         for D of Ds loop
            declare
               A : constant Long_Float := Divide_NR (N, D);
               B : constant Long_Float := Divide_Goldschmidt (N, D);
            begin
               Check (Float_Near (A, B, 1.0E-8),
                      "NR~Gold N=" & Long_Float'Image (N)
                      & " D=" & Long_Float'Image (D));
            end;
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument / Bad_Domain (D = 0)");
   ------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : Division_Result := Divide_Oracle (1, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Oracle D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result := Divide_Schoolbook (5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Schoolbook D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result := Divide_Restoring (5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Restoring D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result := Divide_Non_Restoring (5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "NonRestoring D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Exact_Quotient (1.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Exact_Quotient D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide_NR (1.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Divide_NR D=0 raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Divide_Goldschmidt (1.0, 0.0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Divide_Goldschmidt D=0 raises");

      Check (Divide_NR_Detail (1.0, 0.0).Status = Bad_Domain,
             "NR_Detail Bad_Domain");
      Check (Divide_Goldschmidt_Detail (1.0, 0.0).Status = Bad_Domain,
             "Gold_Detail Bad_Domain");

      Raised := False;
      begin
         declare
            Unused : Digit_Division_Result :=
              Divide_Long (From_Natural (10), Zero);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Divide_Long zero divisor raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result :=
              Divide (1, 1, SRT_Catalogue);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Divide SRT_Catalogue raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result :=
              Divide (1, 1, Newton_Raphson);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Divide NR integer path raises");
   end;

   ------------------------------------------------------------------
   Section ("11. Dispatcher Divide(..., Method)");
   ------------------------------------------------------------------
   declare
      O : constant Division_Result := Divide_Oracle (42, 5);
   begin
      Check (Agree_Int (Divide (42, 5, Schoolbook), O), "Dispatch Schoolbook");
      Check (Agree_Int (Divide (42, 5, Restoring), O), "Dispatch Restoring");
      Check (Agree_Int (Divide (42, 5, Non_Restoring), O),
             "Dispatch Non_Restoring");
      Check (Agree_Int (Divide (42, 5, Oracle), O), "Dispatch Oracle");
      Check (Agree_Int (Divide (-42, 5, Restoring), Divide_Oracle (-42, 5)),
             "Dispatch Restoring signed");
      Check (Agree_Int (Divide (-42, 5, Non_Restoring),
                        Divide_Oracle (-42, 5)),
             "Dispatch NonRest signed");
   end;

   ------------------------------------------------------------------
   Section ("12. Helpers Near / Rel_Error");
   ------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny");
   Check (not Near (1.0, 2.0), "Near reject");
   Check (Rel_Error (2.0, 2.0) = 0.0, "Rel_Error exact");
   Check (Rel_Error (0.0, 0.0) = 0.0, "Rel_Error both zero");
   Check (Float_Near (Rel_Error (1.1, 1.0), 0.1, 1.0E-12), "Rel_Error 10%");

   ------------------------------------------------------------------
   Section ("13. Edge: Min/-1 overflow, range checks");
   ------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : Division_Result :=
              Divide_Restoring (Operand_Min, -1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Restoring Min/-1 raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result :=
              Divide_Non_Restoring (Operand_Min, -1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "NonRestoring Min/-1 raises");

      Raised := False;
      begin
         declare
            Unused : Division_Result := Divide_Restoring (200, 3);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Restoring out of range raises");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
