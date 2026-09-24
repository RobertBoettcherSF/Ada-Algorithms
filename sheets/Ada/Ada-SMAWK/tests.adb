--  Standalone test suite for Smawk (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Smawk; use Smawk;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   function Arg_Eq (A, B : Argmin_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for K in 0 .. A'Length - 1 loop
         if A (A'First + K) /= B (B'First + K) then
            return False;
         end if;
      end loop;
      return True;
   end Arg_Eq;

begin
   Ada.Text_IO.Put_Line ("Smawk test suite");
   Ada.Text_IO.Put_Line ("================");

   ---------------------------------------------------------------------
   Section ("1. Caps / Zero_Dense / Get-Set");
   ---------------------------------------------------------------------
   declare
      Z  : constant Dense_Matrix := Zero_Dense (0, 0);
      Z3 : Dense_Matrix := Zero_Dense (3, 4);
   begin
      Check (Z'Length (1) = 0 and then Z'Length (2) = 0, "Zero 0x0");
      Check (Z3'Length (1) = 3 and then Z3'Length (2) = 4, "Zero 3x4");
      declare
         Cap_N : constant Dense_Matrix := Zero_Dense (Max_N, 1);
         Cap_M : constant Dense_Matrix := Zero_Dense (1, Max_M);
      begin
         Check (Cap_N'Length (1) = Cap_N'Last (1), "cap rows contiguous");
         Check (Cap_M'Length (2) = Cap_M'Last (2), "cap cols contiguous");
         Check (Cap_N'Length (1) > 0 and then Cap_M'Length (2) > 0,
                "caps positive");
         Check (Cap_N'Length (1) = Cap_M'Length (2), "Max_N = Max_M = 64");
      end;
      Check (Near (Get (Z3, 2, 3), 0.0), "Get zero");
      Set (Z3, 2, 3, 7.5);
      Check (Near (Get (Z3, 2, 3), 7.5), "Set/Get");
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near reject");
   end;

   ---------------------------------------------------------------------
   Section ("2. Monge builders + Is_Monge / Is_Totally_Monotone");
   ---------------------------------------------------------------------
   declare
      A : constant Dense_Matrix := Build_Monge_Product (4, 5, -1.0);
      B : constant Dense_Matrix := Build_Squared_Distance (5, 5);
      C : constant Dense_Matrix := Build_Antitone_Product (3, 4);
      Bad : constant Dense_Matrix := Build_Non_Monotone_Example;
   begin
      Check (Is_Monge (A), "Monge_Product is Monge");
      Check (Is_Totally_Monotone (A), "Monge_Product is TM");
      Check (Is_Row_Minima_Monotone (A), "Monge_Product row-min monotone");
      Check (Is_Monge (B), "Squared_Distance is Monge");
      Check (Is_Totally_Monotone (B), "Squared_Distance is TM");
      Check (Is_Monge (C), "Antitone_Product is Monge");
      Check (Is_Totally_Monotone (C), "Antitone_Product is TM");
      Check (not Is_Totally_Monotone (Bad), "non-TM detected");
      Check (not Is_Monge (Bad), "non-Monge detected");
      Check (not Is_Row_Minima_Monotone (Bad), "non-monotone row mins");
   end;

   ---------------------------------------------------------------------
   Section ("3. Naive vs SMAWK on Monge_Product sizes");
   ---------------------------------------------------------------------
   declare
      Sizes : constant array (1 .. 8) of Positive :=
        [1, 2, 3, 4, 5, 7, 8, 12];
   begin
      for N of Sizes loop
         for M of Sizes loop
            declare
               A : constant Dense_Matrix :=
                 Build_Monge_Product (N, M, -1.0);
               Naive : constant Argmin_Array := Naive_Row_Minima (A);
               Fast  : constant Argmin_Array := SMAWK_Row_Minima (A);
            begin
               Check (Arg_Eq (Naive, Fast),
                      "Monge C=-1 " & N'Image & "x" & M'Image);
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Squared distance + antitone product");
   ---------------------------------------------------------------------
   for N in 1 .. 10 loop
      for M in 1 .. 10 loop
         declare
            A : constant Dense_Matrix := Build_Squared_Distance (N, M);
            B : constant Dense_Matrix := Build_Antitone_Product (N, M);
         begin
            if N <= 6 and then M <= 6 then
               Check (Arg_Eq (Naive_Row_Minima (A), SMAWK_Row_Minima (A)),
                      "sq " & N'Image & "x" & M'Image);
               Check (Arg_Eq (Naive_Row_Minima (B), SMAWK_Row_Minima (B)),
                      "anti " & N'Image & "x" & M'Image);
            end if;
         end;
      end loop;
   end loop;
   --  A few larger squared / antitone checks
   declare
      A : constant Dense_Matrix := Build_Squared_Distance (16, 20);
      B : constant Dense_Matrix := Build_Antitone_Product (15, 9);
      C : constant Dense_Matrix := Build_Monge_Product (20, 16, -0.5);
   begin
      Check (Arg_Eq (Naive_Row_Minima (A), SMAWK_Row_Minima (A)),
             "sq 16x20");
      Check (Arg_Eq (Naive_Row_Minima (B), SMAWK_Row_Minima (B)),
             "anti 15x9");
      Check (Arg_Eq (Naive_Row_Minima (C), SMAWK_Row_Minima (C)),
             "Monge C=-0.5 20x16");
      Check (Is_Monge (C) and then Is_Totally_Monotone (C),
             "C=-0.5 Monge+TM");
   end;

   ---------------------------------------------------------------------
   Section ("5. Access-to-function Lookup path");
   ---------------------------------------------------------------------
   declare
      Dense : constant Dense_Matrix := Build_Monge_Product (5, 7, -1.0);
      Sq    : constant Dense_Matrix := Build_Squared_Distance (4, 6);
   begin
      Bind_Dense (Dense);
      declare
         N1 : constant Argmin_Array :=
           Naive_Row_Minima (Bound_Lookup'Access, 5, 7);
         S1 : constant Argmin_Array :=
           SMAWK_Row_Minima (Bound_Lookup'Access, 5, 7);
      begin
         Check (Bound_Rows = 5 and then Bound_Cols = 7, "Bind dims 5x7");
         Check (Arg_Eq (N1, S1), "Lookup Monge 5x7 naive=SMAWK");
         Check (Arg_Eq (N1, Naive_Row_Minima (Dense)),
                "Lookup matches dense naive");
         Check (Arg_Eq (S1, SMAWK_Row_Minima (Dense)),
                "Lookup matches dense SMAWK");
      end;

      Bind_Dense (Sq);
      declare
         N2 : constant Argmin_Array :=
           Naive_Row_Minima (Bound_Lookup'Access, 4, 6);
         S2 : constant Argmin_Array :=
           SMAWK_Row_Minima (Bound_Lookup'Access, 4, 6);
      begin
         Check (Bound_Rows = 4 and then Bound_Cols = 6, "Bind dims 4x6");
         Check (Arg_Eq (N2, S2), "Lookup sq 4x6 naive=SMAWK");
         Check (Arg_Eq (N2, Naive_Row_Minima (Sq)),
                "Lookup sq=dense naive");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Tiny hand cases / ties / single row-col");
   ---------------------------------------------------------------------
   declare
      A1 : constant Dense_Matrix (1 .. 1, 1 .. 1) :=
        [1 => [1 => 3.0]];
      A2 : constant Dense_Matrix (1 .. 1, 1 .. 4) :=
        [1 => [4.0, 2.0, 2.0, 5.0]];  -- leftmost tie at col 2
      A3 : constant Dense_Matrix (1 .. 3, 1 .. 1) :=
        [1 => [1 => 1.0], 2 => [1 => 0.0], 3 => [1 => 9.0]];
      R1 : constant Argmin_Array := SMAWK_Row_Minima (A1);
      R2 : constant Argmin_Array := SMAWK_Row_Minima (A2);
      R3 : constant Argmin_Array := SMAWK_Row_Minima (A3);
   begin
      Check (R1 (1) = 1, "1x1 argmin");
      Check (Arg_Eq (R1, Naive_Row_Minima (A1)), "1x1 match");
      Check (R2 (1) = 2, "leftmost tie col 2");
      Check (Arg_Eq (R2, Naive_Row_Minima (A2)), "tie match");
      Check (R3 (1) = 1 and then R3 (2) = 1 and then R3 (3) = 1,
             "single-col all 1");
      Check (Arg_Eq (R3, Naive_Row_Minima (A3)), "Nx1 match");
   end;

   ---------------------------------------------------------------------
   Section ("7. Varying C <= 0 Monge family");
   ---------------------------------------------------------------------
   declare
      Cs : constant array (1 .. 5) of Float :=
        [0.0, -0.1, -1.0, -2.0, -5.0];
   begin
      for C of Cs loop
         declare
            A : constant Dense_Matrix :=
              Build_Monge_Product (6, 8, C);
         begin
            Check (Is_Monge (A), "Monge C=" & C'Image);
            Check (Is_Totally_Monotone (A), "TM C=" & C'Image);
            Check (Arg_Eq (Naive_Row_Minima (A), SMAWK_Row_Minima (A)),
                   "SMAWK C=" & C'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Rectangular extremes + identity-ish Monge");
   ---------------------------------------------------------------------
   declare
      Tall : constant Dense_Matrix := Build_Monge_Product (24, 3, -1.0);
      Wide : constant Dense_Matrix := Build_Monge_Product (3, 24, -1.0);
      Sq   : constant Dense_Matrix := Build_Squared_Distance (1, 32);
      Sq2  : constant Dense_Matrix := Build_Squared_Distance (32, 1);
   begin
      Check (Arg_Eq (Naive_Row_Minima (Tall), SMAWK_Row_Minima (Tall)),
             "tall 24x3");
      Check (Arg_Eq (Naive_Row_Minima (Wide), SMAWK_Row_Minima (Wide)),
             "wide 3x24");
      Check (Arg_Eq (Naive_Row_Minima (Sq), SMAWK_Row_Minima (Sq)),
             "1x32 sq");
      Check (Arg_Eq (Naive_Row_Minima (Sq2), SMAWK_Row_Minima (Sq2)),
             "32x1 sq");
      Check (Is_Totally_Monotone (Tall), "tall TM");
      Check (Is_Totally_Monotone (Wide), "wide TM");
   end;

   ---------------------------------------------------------------------
   Section ("9. Explicit 3x3 Monge hand argmins");
   ---------------------------------------------------------------------
   declare
      --  A(i,j) = (i-j)^2 on 3x3:
      --  row1: 0,1,4 → argmin 1
      --  row2: 1,0,1 → argmin 2
      --  row3: 4,1,0 → argmin 3
      A : constant Dense_Matrix := Build_Squared_Distance (3, 3);
      R : constant Argmin_Array := SMAWK_Row_Minima (A);
   begin
      Check (R (1) = 1 and then R (2) = 2 and then R (3) = 3,
             "sq 3x3 diagonal argmins");
      Check (Is_Row_Minima_Monotone (A), "sq 3x3 monotone argmins");
   end;

   ---------------------------------------------------------------------
   Section ("10. Larger Monge stress (still within caps)");
   ---------------------------------------------------------------------
   declare
      A : constant Dense_Matrix := Build_Monge_Product (32, 32, -1.0);
      B : constant Dense_Matrix := Build_Squared_Distance (28, 30);
   begin
      Check (Arg_Eq (Naive_Row_Minima (A), SMAWK_Row_Minima (A)),
             "Monge 32x32");
      Check (Arg_Eq (Naive_Row_Minima (B), SMAWK_Row_Minima (B)),
             "sq 28x30");
      Check (Is_Monge (A) and then Is_Totally_Monotone (A),
             "32x32 Monge+TM");
   end;

   ---------------------------------------------------------------------
   Section ("11. Empty / degenerate checkers");
   ---------------------------------------------------------------------
   declare
      E : constant Dense_Matrix := Zero_Dense (0, 5);
      F : constant Dense_Matrix := Zero_Dense (5, 0);
   begin
      Check (Is_Monge (E), "empty rows Monge");
      Check (Is_Totally_Monotone (E), "empty rows TM");
      Check (Is_Row_Minima_Monotone (E), "empty rows mono");
      Check (Is_Monge (F), "empty cols Monge");
      Check (Is_Totally_Monotone (F), "empty cols TM");
   end;

   ---------------------------------------------------------------------
   Section ("12. Non-monotone larger reject");
   ---------------------------------------------------------------------
   declare
      Bad : Dense_Matrix := Zero_Dense (4, 4);
   begin
      --  Plant a forbidden 2×2 pattern in the corner.
      Set (Bad, 1, 1, 2.0);
      Set (Bad, 1, 2, 1.0);
      Set (Bad, 2, 1, 0.0);
      Set (Bad, 2, 2, 3.0);
      --  Fill rest with zeros (still breaks TM via the 2×2).
      Check (not Is_Totally_Monotone (Bad), "4x4 planted non-TM");
      Check (not Is_Monge (Bad), "4x4 planted non-Monge");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
