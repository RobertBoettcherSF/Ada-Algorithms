--  Standalone test suite for Coppersmith_Winograd educational survey.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Coppersmith_Winograd;

procedure Tests is
   package MM renames Coppersmith_Winograd;
   use MM;
   --  Enum literal Coppersmith_Winograd collides with the package name;
   --  always write MM.Coppersmith_Winograd for that Method_Kind value.

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Leading (R : Multiply_Result) return Matrix is
   begin
      return Product_Matrix (R);
   end Leading;

begin
   Ada.Text_IO.Put_Line
     ("Coppersmith-Winograd educational survey test suite");
   Ada.Text_IO.Put_Line
     ("==================================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Mat_Near / Norm / Diff");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[3.0, 4.0], [0.0, 0.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[3.0, 4.0], [0.0, 0.0]];
      C : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 0.0], [0.0, 0.0]];
      Z : constant Matrix := Zeros (2);
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Mat_Near (A, B), "Mat_Near equal");
      Check (not Mat_Near (A, C), "Mat_Near rejects");
      Check (Approx (Norm_Frobenius (A), 5.0), "Frobenius 3-4");
      Check (Approx (Norm_Frobenius (Z), 0.0), "Frobenius zero");
      Check (Approx (Diff_Frobenius (A, B), 0.0), "Diff zero");
      Check (Approx (Diff_Frobenius (A, C), 4.472_136, 1.0E-4),
             "Diff 3-4 vs e1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Structure / power-of-two");
   ---------------------------------------------------------------------
   declare
      S : constant Matrix := Identity (3);
      R : constant Matrix (1 .. 2, 1 .. 3) :=
        [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]];
   begin
      Check (Is_Square (S), "Identity square");
      Check (not Is_Square (R), "2x3 not square");
      Check (Is_Power_Of_Two (1), "1 is 2^0");
      Check (Is_Power_Of_Two (8), "8 is 2^3");
      Check (Is_Power_Of_Two (32), "32 is 2^5");
      Check (not Is_Power_Of_Two (0), "0 not power");
      Check (not Is_Power_Of_Two (3), "3 not power");
      Check (Next_Power_Of_Two (3) = 4, "next(3)=4");
      Check (Next_Power_Of_Two (5) = 8, "next(5)=8");
      Check (Next_Power_Of_Two (17) = 32, "next(17)=32");
      Check (Next_Power_Of_Two (0) = 0, "next(0)=0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Mat_Add / Mat_Sub / Mat_Scale");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      S : constant Matrix := Mat_Add (A, B);
      D : constant Matrix := Mat_Sub (A => B, B => A);
      T : constant Matrix := Mat_Scale (A, 2.0);
   begin
      Check (Approx (S (1, 1), 6.0) and Approx (S (2, 2), 12.0), "Add");
      Check (Approx (D (1, 1), 4.0) and Approx (D (2, 1), 4.0), "Sub");
      Check (Approx (T (1, 2), 4.0) and Approx (T (2, 2), 8.0), "Scale");
   end;

   ---------------------------------------------------------------------
   Section ("4. Builders");
   ---------------------------------------------------------------------
   declare
      Z : constant Matrix := Zeros (3);
      O : constant Matrix := Ones (2, 7.0);
      I : constant Matrix := Identity (4);
      S : constant Matrix := Sequential_Fill (2);
      D : constant Matrix := Deterministic (3, 1);
      H : constant Matrix := Make_Hilbert (3);
   begin
      Check (Approx (Z (2, 2), 0.0), "Zeros");
      Check (Approx (O (1, 1), 7.0) and Approx (O (2, 2), 7.0), "Ones");
      Check (Approx (I (1, 1), 1.0) and Approx (I (2, 3), 0.0), "Identity");
      Check (Approx (S (1, 1), 1.0) and Approx (S (2, 2), 4.0),
             "Sequential_Fill");
      Check (D (1, 1) >= 0.0 and D (1, 1) < 1.0, "Deterministic range");
      Check (Approx (H (1, 1), 1.0) and Approx (H (1, 2), 0.5), "Hilbert");
   end;

   ---------------------------------------------------------------------
   Section ("5. Pad / Trim");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Sequential_Fill (3);
      P : constant Matrix := Pad_To_Power_Of_Two (A);
      T : constant Matrix := Trim (P, 3);
   begin
      Check (P'Length (1) = 4, "pad 3→4 size");
      Check (Approx (P (4, 4), 0.0) and Approx (P (3, 3), 9.0),
             "pad zeros + keep");
      Check (Mat_Near (T, A), "trim recovers");
   end;

   ---------------------------------------------------------------------
   Section ("6. Taxonomy coverage");
   ---------------------------------------------------------------------
   declare
      Names_Ok : Boolean := True;
   begin
      Check (Method_Count = 4, "Method_Count = 4");
      Check (Method_Name (Classical) = "Classical", "name Classical");
      Check (Method_Name (Strassen) = "Strassen", "name Strassen");
      Check (Method_Name (MM.Coppersmith_Winograd) = "Coppersmith-Winograd",
             "name CW");
      Check (Method_Name (Laser_Family) = "Laser-Family", "name Laser");

      Check (Approx (Exponent_Of (Classical), 3.0), "exp Classical=3");
      Check (Approx (Exponent_Of (Strassen), 2.807_355, 1.0E-5),
             "exp Strassen~log2(7)");
      Check (Approx (Exponent_Of (MM.Coppersmith_Winograd), 2.3755, 1.0E-6),
             "exp CW=2.3755");
      Check (Approx (Exponent_Of (Laser_Family), 2.373, 1.0E-6),
             "exp Laser~2.373");

      Check (Exponent_Of (Classical) > Exponent_Of (Strassen),
             "Classical > Strassen");
      Check (Exponent_Of (Strassen) > Exponent_Of (MM.Coppersmith_Winograd),
             "Strassen > CW");
      Check (Exponent_Of (MM.Coppersmith_Winograd) > Exponent_Of (Laser_Family),
             "CW > Laser");

      Check (Is_Practical (Classical), "Classical practical");
      Check (Is_Practical (Strassen), "Strassen practical");
      Check (not Is_Practical (MM.Coppersmith_Winograd), "CW not practical");
      Check (not Is_Practical (Laser_Family), "Laser not practical");

      Check (Supports_Runnable (Classical), "Classical runnable");
      Check (Supports_Runnable (Strassen), "Strassen runnable");
      Check (not Supports_Runnable (MM.Coppersmith_Winograd),
             "CW not runnable");
      Check (not Supports_Runnable (Laser_Family), "Laser not runnable");

      Check (Describe (Classical)'Length > 10, "Describe Classical");
      Check (Describe (Strassen)'Length > 10, "Describe Strassen");
      Check (Describe (MM.Coppersmith_Winograd)'Length > 10, "Describe CW");
      Check (Describe (Laser_Family)'Length > 10, "Describe Laser");

      for M in Method_Kind loop
         declare
            Info : constant Method_Info := Classify_Method (M);
         begin
            if Info.Kind /= M then
               Names_Ok := False;
            end if;
            if abs (Info.Exponent - Exponent_Of (M)) > 1.0E-6 then
               Names_Ok := False;
            end if;
            if Info.Practical /= Is_Practical (M) then
               Names_Ok := False;
            end if;
            if Info.Runnable_Sketch /= Supports_Runnable (M) then
               Names_Ok := False;
            end if;
         end;
      end loop;
      Check (Names_Ok, "Classify_Method consistent for all kinds");

      Check (Classify_Method (Strassen).Year = 1969, "Strassen year 1969");
      Check (Classify_Method (MM.Coppersmith_Winograd).Year = 1990,
             "CW year 1990");
      Check (Classify_Method (Laser_Family).Year = 2010, "Laser year 2010");
   end;

   ---------------------------------------------------------------------
   Section ("7. Milestone table");
   ---------------------------------------------------------------------
   declare
      Prev_Year : Natural := 0;
      Ordered   : Boolean := True;
   begin
      declare
         Count_Ok : Boolean := False;
      begin
         --  Avoid -gnatwc on comparing two static constants.
         case Milestone_Count is
            when 6 =>
               Count_Ok := True;
            when others =>
               Count_Ok := False;
         end case;
         Check (Count_Ok, "Milestone_Count = 6");
      end;
      for I in 1 .. Milestone_Count loop
         declare
            M : constant Milestone := Get_Milestone (I);
         begin
            Check (M.Year >= 1969, "milestone year >= 1969 #" &
                     Integer'Image (I));
            Check (M.Exponent > 2.0 and then M.Exponent < 3.0,
                   "milestone exp in (2,3) #" & Integer'Image (I));
            Check (Milestone_Label (I)'Length > 5,
                   "milestone label #" & Integer'Image (I));
            if M.Year < Prev_Year then
               Ordered := False;
            end if;
            Prev_Year := M.Year;
         end;
      end loop;
      Check (Ordered, "milestones nondecreasing year");
      Check (Approx (Get_Milestone (3).Exponent, 2.3755),
             "milestone 3 is CW 2.3755");
      Check (Get_Milestone (1).Year = 1969, "first milestone Strassen 1969");
   end;

   ---------------------------------------------------------------------
   Section ("8. Estimated_Ops monotonic / ordering");
   ---------------------------------------------------------------------
   declare
      N4  : constant Natural := 4;
      N8  : constant Natural := 8;
      N16 : constant Natural := 16;
   begin
      Check (Estimated_Ops (N4, Classical) >
               Estimated_Ops (N4, Strassen),
             "ops Classical > Strassen at n=4");
      Check (Estimated_Ops (N4, Strassen) >
               Estimated_Ops (N4, MM.Coppersmith_Winograd),
             "ops Strassen > CW at n=4");
      Check (Estimated_Ops (N4, MM.Coppersmith_Winograd) >
               Estimated_Ops (N4, Laser_Family),
             "ops CW > Laser at n=4");

      Check (Estimated_Ops (N8, Classical) >
               Estimated_Ops (N4, Classical),
             "Classical ops grow with n");
      Check (Estimated_Ops (N16, Strassen) >
               Estimated_Ops (N8, Strassen),
             "Strassen ops grow with n");
      Check (Estimated_Ops (N16, MM.Coppersmith_Winograd) >
               Estimated_Ops (N8, MM.Coppersmith_Winograd),
             "CW ops grow with n");
      Check (Estimated_Ops (N16, Laser_Family) >
               Estimated_Ops (N8, Laser_Family),
             "Laser ops grow with n");

      Check (Approx (Estimated_Ops (2, Classical), 8.0), "2^3=8 classical");
      Check (Approx (Estimated_Ops (1, Classical), 1.0), "1^3=1 classical");
      Check (Approx (Estimated_Ops (1, Strassen), 1.0), "1^ω=1 Strassen");
   end;

   ---------------------------------------------------------------------
   Section ("9. Classical multiply correctness");
   ---------------------------------------------------------------------
   declare
      I : constant Matrix := Identity (3);
      A : constant Matrix := Sequential_Fill (3);
      R : constant Multiply_Result := Multiply_Classical (A, I);
      P : constant Matrix := Leading (R);
   begin
      Check (R.Success and then R.Stat = Ok, "classical I success");
      Check (Mat_Near (P, A), "A*I = A");
      Check (R.Scalar_Multiplies = 27, "classical mults 3^3=27");
      Check (R.Recursion_Depth = 0, "classical depth 0");
   end;

   declare
      A : constant Matrix (1 .. 2, 1 .. 2) := [[1.0, 2.0], [3.0, 4.0]];
      B : constant Matrix (1 .. 2, 1 .. 2) := [[5.0, 6.0], [7.0, 8.0]];
      R : constant Multiply_Result := Multiply_Classical (A, B);
      P : constant Matrix := Leading (R);
   begin
      Check (Approx (P (1, 1), 19.0) and Approx (P (1, 2), 22.0)
               and Approx (P (2, 1), 43.0) and Approx (P (2, 2), 50.0),
             "classical 2x2 known product");
   end;

   ---------------------------------------------------------------------
   Section ("10. Strassen ≡ Classical small n");
   ---------------------------------------------------------------------
   declare
      All_Match : Boolean := True;
   begin
      for N in 1 .. 8 loop
         declare
            A  : constant Matrix := Deterministic (N, 11);
            B  : constant Matrix := Deterministic (N, 29);
            Rc : constant Multiply_Result := Multiply_Classical (A, B);
            Rs : constant Multiply_Result := Multiply_Strassen (A, B);
         begin
            if not (Rc.Success and then Rs.Success) then
               All_Match := False;
            elsif not Mat_Near (Leading (Rc), Leading (Rs), 1.0E-4) then
               All_Match := False;
            end if;
         end;
      end loop;
      Check (All_Match, "classical≡Strassen for n=1..8 Deterministic");
   end;

   declare
      A  : constant Matrix := Sequential_Fill (4);
      B  : constant Matrix := Identity (4);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
   begin
      Check (Rs.Success, "Strassen A*I success n=4");
      Check (Mat_Near (Leading (Rs), A, 1.0E-4), "Strassen A*I = A");
      Check (Rs.Padded_N = 4, "power-of-2 no extra pad");
      Check (Rs.Scalar_Multiplies = 7 ** 2, "pure Strassen n=4 → 49 mults");
   end;

   declare
      A  : constant Matrix := Deterministic (3, 3);
      B  : constant Matrix := Deterministic (3, 7);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
   begin
      Check (Rs.Padded_N = 4, "pad 3→4");
      Check (Mat_Near (Leading (Rc), Leading (Rs), 1.0E-4),
             "classical≡Strassen n=3 padded");
   end;

   declare
      A  : constant Matrix := Make_Hilbert (5);
      B  : constant Matrix := Deterministic (5, 2);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
      D  : constant Float := Diff_Frobenius (Leading (Rc), Leading (Rs));
   begin
      Check (Rs.Success and Rc.Success, "Hilbert n=5 both succeed");
      Check (D < 1.0E-3, "Hilbert Strassen residual small");
   end;

   ---------------------------------------------------------------------
   Section ("11. Dispatch Multiply + galactic reject");
   ---------------------------------------------------------------------
   declare
      A : constant Matrix := Identity (2);
      B : constant Matrix := Ones (2, 3.0);
      Rc : constant Multiply_Result := Multiply (A, B, Classical);
      Rs : constant Multiply_Result := Multiply (A, B, Strassen);
      Rw : constant Multiply_Result :=
        Multiply (A, B, MM.Coppersmith_Winograd);
      Rl : constant Multiply_Result := Multiply (A, B, Laser_Family);
   begin
      Check (Rc.Success and then Rc.Stat = Ok, "dispatch Classical Ok");
      Check (Rs.Success and then Rs.Stat = Ok, "dispatch Strassen Ok");
      Check (Mat_Near (Leading (Rc), Leading (Rs), 1.0E-5),
             "dispatch Classical≡Strassen");

      Check (not Rw.Success, "CW Multiply not Success");
      Check (Rw.Stat = Not_Implemented or else Rw.Stat = Galactic_Only,
             "CW Stat Not_Implemented or Galactic_Only");
      Check (not Supports_Runnable (MM.Coppersmith_Winograd),
             "Supports_Runnable CW False");

      Check (not Rl.Success, "Laser Multiply not Success");
      Check (Rl.Stat = Galactic_Only or else Rl.Stat = Not_Implemented,
             "Laser Stat Galactic_Only or Not_Implemented");
      Check (not Supports_Runnable (Laser_Family),
             "Supports_Runnable Laser False");
   end;

   --  Extra galactic rejects at several sizes
   for N in 1 .. 4 loop
      declare
         A  : constant Matrix := Zeros (N);
         B  : constant Matrix := Identity (N);
         Rw : constant Multiply_Result :=
           Multiply (A, B, MM.Coppersmith_Winograd);
         Rl : constant Multiply_Result :=
           Multiply (A, B, Laser_Family);
      begin
         Check (not Rw.Success,
                "CW reject n=" & Integer'Image (N));
         Check (not Rl.Success,
                "Laser reject n=" & Integer'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("12. More classical≡Strassen + counters");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Ones (1, 4.0);
      B  : constant Matrix := Ones (1, 5.0);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
   begin
      Check (Approx (Leading (Rc) (1, 1), 20.0), "1x1 classical");
      Check (Approx (Leading (Rs) (1, 1), 20.0), "1x1 Strassen");
      Check (Rc.Scalar_Multiplies = 1, "1x1 classical mults");
   end;

   declare
      A  : constant Matrix := Deterministic (8, 1);
      B  : constant Matrix := Deterministic (8, 2);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
   begin
      Check (Mat_Near (Leading (Rc), Leading (Rs), 1.0E-3),
             "classical≡Strassen n=8");
      Check (Rc.Scalar_Multiplies = 512, "classical 8^3=512");
      Check (Rs.Scalar_Multiplies = 7 ** 3, "Strassen 8 → 343 mults");
      Check (Rs.Recursion_Depth = 3, "Strassen depth log2(8)=3");
   end;

   declare
      A  : constant Matrix := Sequential_Fill (2);
      B  : constant Matrix := Sequential_Fill (2);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B, Leaf => 2);
   begin
      Check (Rs.Success, "Strassen Leaf=2 succeeds");
      Check (Rs.Recursion_Depth = 0, "Leaf=2 → classical base immediately");
   end;

   ---------------------------------------------------------------------
   Section ("13. Exponent constants vs Estimated_Ops consistency");
   ---------------------------------------------------------------------
   declare
      N : constant Natural := 10;
   begin
      Check (Approx (Estimated_Ops (N, Classical), 1000.0, 1.0E-3),
             "Estimated_Ops Classical 10^3");
      Check (Estimated_Ops (N, Classical) >
               Estimated_Ops (N, Strassen),
             "ops Classical > Strassen at n=10");
      Check (Estimated_Ops (N, Strassen) >
               Estimated_Ops (N, MM.Coppersmith_Winograd),
             "ops Strassen > CW at n=10");
      Check (Estimated_Ops (N, MM.Coppersmith_Winograd) >
               Estimated_Ops (N, Laser_Family),
             "ops CW > Laser at n=10");
      Check (Approx (Classical_Exponent_Const, 3.0), "const Classical");
      Check (Approx (CW_Exponent_Const, 2.3755), "const CW");
      Check (Approx (Laser_Exponent_Const, 2.373), "const Laser");
      Check (Estimated_Ops (N, Classical) >
               Estimated_Ops (N, Laser_Family) * 2.0,
             "classical much larger ops than laser at n=10");
   end;

   ---------------------------------------------------------------------
   Section ("14. Method field on results");
   ---------------------------------------------------------------------
   declare
      A  : constant Matrix := Identity (2);
      B  : constant Matrix := Identity (2);
      Rc : constant Multiply_Result := Multiply_Classical (A, B);
      Rs : constant Multiply_Result := Multiply_Strassen (A, B);
      Rw : constant Multiply_Result :=
        Multiply (A, B, MM.Coppersmith_Winograd);
   begin
      Check (Rc.Method = Method_Kind'Pos (Classical), "Method Classical");
      Check (Rs.Method = Method_Kind'Pos (Strassen), "Method Strassen");
      Check (Rw.Method = Method_Kind'Pos (MM.Coppersmith_Winograd),
             "Method CW on reject");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count)
      & "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
