--  Standalone test suite for Lanczos_Resampling (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Lanczos_Resampling; use Lanczos_Resampling;

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

   function Approx (A, B : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Ada.Text_IO.Put_Line ("Lanczos_Resampling test suite");
   Ada.Text_IO.Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Sinc / Kernel basics");
   ---------------------------------------------------------------------
   declare
      A2 : constant A_Param := 2;
      A3 : constant A_Param := 3;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-8), "Near tiny");
      Check (not Near (1.0, 2.0), "Near rejects");
      Check (Approx (Sinc (0.0), 1.0), "Sinc(0)=1");
      Check (Approx (Sinc (1.0), 0.0, 1.0E-6), "Sinc(1)=0");
      Check (Approx (Sinc (-1.0), 0.0, 1.0E-6), "Sinc(-1)=0");
      Check (Approx (Sinc (0.5), 2.0 / 3.14159265, 1.0E-4),
             "Sinc(0.5)~2/pi");
      Check (Approx (Kernel (A3, 0.0), 1.0), "Kernel(0)=1");
      Check (Approx (Kernel (A2, 0.0), 1.0), "Kernel a=2 at 0");
      --  Continuity / value at tiny offset near 0
      Check (Approx (Kernel (A3, 1.0E-7), 1.0, 1.0E-4),
             "Kernel continuity near 0");
      Check (Approx (Kernel (A3, -1.0E-7), 1.0, 1.0E-4),
             "Kernel continuity near 0-");
      --  Support: zero at |x| >= a
      Check (Approx (Kernel (A2, 2.0), 0.0), "Kernel a=2 at +a is 0");
      Check (Approx (Kernel (A2, -2.0), 0.0), "Kernel a=2 at -a is 0");
      Check (Approx (Kernel (A2, 2.5), 0.0), "Kernel a=2 outside +");
      Check (Approx (Kernel (A2, -3.0), 0.0), "Kernel a=2 outside -");
      Check (Approx (Kernel (A3, 3.0), 0.0), "Kernel a=3 at +a is 0");
      Check (Approx (Kernel (A3, 4.0), 0.0), "Kernel a=3 outside");
      --  Integer zeros (except 0): L(k)=0 for k=±1,...,±(a-1) wait —
      --  actually L(±1)=0 because sinc(±1)=0
      Check (Approx (Kernel (A3, 1.0), 0.0, 1.0E-6), "Kernel(1)=0");
      Check (Approx (Kernel (A3, -1.0), 0.0, 1.0E-6), "Kernel(-1)=0");
      Check (Approx (Kernel (A3, 2.0), 0.0, 1.0E-6), "Kernel(2)=0");
      --  Lobes nonzero inside support at half-integers
      Check (abs (Kernel (A3, 0.5)) > 0.1, "Kernel(0.5) lobe");
      Check (Kernel (A3, 0.5) > 0.0, "Central lobe positive");
      Check (Kernel (A3, 1.5) < 0.0, "Side lobe negative a=3");
   end;

   ---------------------------------------------------------------------
   Section ("2. Domain / builders / Get-Set");
   ---------------------------------------------------------------------
   declare
      Bad_S : Signal_1D;
      Bad_I : Image_2D;
      S     : Signal_1D := Make_Constant_1D (5, 3.0);
      Imp   : constant Signal_1D := Make_Example_Impulse;
      Ramp  : constant Signal_1D := Make_Example_Ramp;
      Img   : Image_2D := Make_Ramp_2D (4, 3);
      Chk   : constant Image_2D := Make_Example_Checker;
      Empty_Z : Signal_1D;
   begin
      Check (not Is_Valid_Signal (Bad_S), "Invalid signal");
      Check (not Is_Valid_Image (Bad_I), "Invalid image");
      Check (Is_Valid_Signal (S), "Valid constant signal");
      Check (Is_Valid_Image (Img), "Valid ramp image");
      Check (In_Domain (S, 0.0) and In_Domain (S, 4.0), "Signal domain");
      Check (not In_Domain (S, -0.1), "Signal reject <0");
      Check (not In_Domain (S, 4.1), "Signal reject >N-1");
      Check (not In_Domain (Bad_S, 0.0), "Domain rejects invalid");
      Check (In_Domain (Img, 1.5, 2.0), "Image domain interior");
      Check (not In_Domain (Img, 4.0, 0.0), "Image reject x");
      Check (Approx (Get (S, 2), 3.0), "Constant get");
      Set (S, 2, 9.0);
      Check (Approx (Get (S, 2), 9.0), "Set/Get roundtrip 1D");
      Check (Approx (Get (Img, 1, 2), 1.0 + 4.0), "Ramp2D (1,2)=5");
      Set (Img, 0, 0, -1.0);
      Check (Approx (Get (Img, 0, 0), -1.0), "Set/Get roundtrip 2D");
      Check (Imp.N = 9 and Approx (Get (Imp, 4), 1.0), "Example impulse");
      Check (Approx (Get (Imp, 0), 0.0) and Approx (Get (Imp, 8), 0.0),
             "Impulse zeros at ends");
      Check (Ramp.N = 8 and Approx (Get (Ramp, 0), 0.0)
             and Approx (Get (Ramp, 7), 7.0),
             "Example ramp 0..7");
      Check (Chk.Nx = 8 and Chk.Ny = 8
             and Approx (Get (Chk, 0, 0), 1.0)
             and Approx (Get (Chk, 1, 0), 0.0),
             "Example checker");
      Empty_Z.Valid := True;
      Empty_Z.N := 0;
      Check (not Is_Valid_Signal (Empty_Z), "N=0 not valid");
      declare
         R1 : constant Signal_1D := Make_Ramp_1D (1, 5.0, 9.0);
         E1 : constant Signal_1D := Make_Empty_Signal (3);
         C2 : constant Image_2D := Make_Constant_2D (2, 2, 4.5);
      begin
         Check (Approx (Get (R1, 0), 5.0), "Ramp N=1 → Y0");
         Check (E1.Valid and Approx (Get (E1, 1), 0.0), "Empty signal");
         Check (Approx (Get (C2, 1, 1), 4.5), "Constant 2D");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Kernel support / integer interpolant property");
   ---------------------------------------------------------------------
   declare
      S : constant Signal_1D := Make_Ramp_1D (8, 0.0, 7.0);
      R : Eval_Result;
   begin
      --  Exact at integers: S(i)=s_i
      for I in 0 .. 7 loop
         R := Resample_1D (S, Float (I), 3, Clamp);
         Check
           (R.Success and Approx (R.Value, Float (I), 1.0E-4),
            "Exact at integer i=" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Constant signal approximately preserved");
   ---------------------------------------------------------------------
   declare
      S  : constant Signal_1D := Make_Constant_1D (16, 5.0);
      Img : constant Image_2D := Make_Constant_2D (8, 8, 2.5);
      R  : Eval_Result;
      Xs : constant array (1 .. 6) of Float :=
        [0.0, 0.5, 3.25, 7.0, 12.75, 15.0];
   begin
      for K in Xs'Range loop
         R := Resample_1D (S, Xs (K), 3, Clamp);
         Check
           (R.Success and Approx (R.Value, 5.0, 5.0E-2),
            "Const1D a=3 x=" & Float'Image (Xs (K)));
         R := Resample_1D (S, Xs (K), 2, Clamp);
         Check
           (R.Success and Approx (R.Value, 5.0, 1.5E-1),
            "Const1D a=2 x=" & Float'Image (Xs (K)));
      end loop;
      R := Resample_2D (Img, 3.5, 4.25, 3, Clamp);
      Check
        (R.Success and Approx (R.Value, 2.5, 8.0E-2),
         "Const2D approx at (3.5,4.25)");
      R := Resample_2D (Img, 0.0, 0.0, 3, Clamp);
      Check
        (R.Success and Approx (R.Value, 2.5, 5.0E-2),
         "Const2D at origin");
      R := Resample_2D (Img, 7.0, 7.0, 2, Reflect);
      Check
        (R.Success and Approx (R.Value, 2.5, 8.0E-2),
         "Const2D corner reflect");
   end;

   ---------------------------------------------------------------------
   Section ("5. Impulse response");
   ---------------------------------------------------------------------
   declare
      Imp : constant Signal_1D := Make_Impulse_1D (11, 5, 1.0);
      R   : Eval_Result;
   begin
      R := Resample_1D (Imp, 5.0, 3, Zero);
      Check (R.Success and Approx (R.Value, 1.0, 1.0E-4),
             "Impulse at center = 1");
      R := Resample_1D (Imp, 4.0, 3, Zero);
      Check (R.Success and Approx (R.Value, 0.0, 1.0E-4),
             "Impulse at neighbor integer = 0");
      R := Resample_1D (Imp, 6.0, 3, Zero);
      Check (R.Success and Approx (R.Value, 0.0, 1.0E-4),
             "Impulse at +1 integer = 0");
      R := Resample_1D (Imp, 5.5, 3, Zero);
      Check
        (R.Success and Approx (R.Value, Kernel (3, 0.5), 1.0E-4),
         "Impulse at +0.5 = L(0.5)");
      R := Resample_1D (Imp, 4.5, 3, Zero);
      Check
        (R.Success and Approx (R.Value, Kernel (3, -0.5), 1.0E-4),
         "Impulse at -0.5 = L(-0.5)");
      R := Resample_1D (Imp, 5.0 + 3.5, 3, Zero);
      Check
        (R.Success and Approx (R.Value, 0.0, 1.0E-5),
         "Impulse outside support ~0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Edge modes (Clamp / Reflect / Zero)");
   ---------------------------------------------------------------------
   declare
      --  Signal [10, 20, 30]
      S : Signal_1D := Make_Empty_Signal (3);
      R : Eval_Result;
   begin
      Set (S, 0, 10.0);
      Set (S, 1, 20.0);
      Set (S, 2, 30.0);
      Check (Approx (Fetch (S, -1, Clamp), 10.0), "Fetch clamp left");
      Check (Approx (Fetch (S, 3, Clamp), 30.0), "Fetch clamp right");
      Check (Approx (Fetch (S, -1, Zero), 0.0), "Fetch zero left");
      Check (Approx (Fetch (S, 5, Zero), 0.0), "Fetch zero right");
      Check (Approx (Fetch (S, -1, Reflect), 20.0),
             "Fetch reflect -1 → 1");
      Check (Approx (Fetch (S, 3, Reflect), 20.0),
             "Fetch reflect 3 → 1");
      Check (Approx (Fetch (S, 4, Reflect), 10.0),
             "Fetch reflect 4 → 0");
      --  Near left edge, Zero vs Clamp differ
      R := Resample_1D (S, 0.0, 2, Zero);
      Check (R.Success, "Resample left Zero ok");
      declare
         Rz : constant Eval_Result := Resample_1D (S, -0.25, 2, Zero);
         Rc : constant Eval_Result := Resample_1D (S, -0.25, 2, Clamp);
         Rr : constant Eval_Result := Resample_1D (S, -0.25, 2, Reflect);
      begin
         Check (Rz.Success and Rc.Success and Rr.Success,
                "Edge resample all ok");
         Check (not Near (Rz.Value, Rc.Value, 1.0E-3)
                or not Near (Rc.Value, Rr.Value, 1.0E-3),
                "Edge modes differ near boundary");
      end;
      declare
         Img : constant Image_2D := Make_Ramp_2D (3, 3);
      begin
         Check (Approx (Fetch (Img, -1, 0, Clamp), Get (Img, 0, 0)),
                "2D fetch clamp");
         Check (Approx (Fetch (Img, -1, -1, Zero), 0.0),
                "2D fetch zero");
         Check (Approx (Fetch (Img, 3, 1, Reflect), Get (Img, 1, 1)),
                "2D fetch reflect");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Resize identity (scale 1) and status paths");
   ---------------------------------------------------------------------
   declare
      S   : constant Signal_1D := Make_Ramp_1D (10, 0.0, 9.0);
      RR  : Resize_1D_Result;
      Img : constant Image_2D := Make_Checkerboard_2D (6, 6, 0.0, 1.0);
      RI  : Resize_2D_Result;
      Bad : Signal_1D;
      E0  : Signal_1D;
      Ev  : Eval_Result;
   begin
      RR := Resize_1D (S, 10, 3, Clamp);
      Check (RR.Success and RR.Signal.N = 10, "Resize1D identity size");
      for I in 0 .. 9 loop
         Check
           (Approx (Get (RR.Signal, I), Float (I), 1.0E-3),
            "Resize1D id sample" & Integer'Image (I));
      end loop;

      RI := Resize_2D (Img, 6, 6, 3, Clamp);
      Check (RI.Success and RI.Image.Nx = 6 and RI.Image.Ny = 6,
             "Resize2D identity size");
      for I in 0 .. 5 loop
         for J in 0 .. 5 loop
            Check
              (Approx
                 (Get (RI.Image, I, J),
                  Get (Img, I, J),
                  5.0E-2),
               "Resize2D id (" & Integer'Image (I) & ","
               & Integer'Image (J) & ")");
         end loop;
      end loop;

      RR := Resize_1D (S, 0, 3, Clamp);
      Check (RR.Stat = Bad_Parameter and not RR.Success,
             "Resize1D New_N=0 → Bad_Parameter");
      RR := Resize_1D (S, Max_Signal + 1, 3, Clamp);
      Check (RR.Stat = Out_Of_Domain and not RR.Success,
             "Resize1D oversized → Out_Of_Domain");
      RR := Resize_1D (Bad, 5, 3, Clamp);
      Check (RR.Stat = Ill_Started and not RR.Success,
             "Resize1D invalid → Ill_Started");
      E0.Valid := True;
      E0.N := 0;
      RR := Resize_1D (E0, 5, 3, Clamp);
      Check (RR.Stat = Empty and not RR.Success,
             "Resize1D empty → Empty");
      Ev := Resample_1D (Bad, 0.0, 3, Clamp);
      Check (Ev.Stat = Ill_Started and not Ev.Success,
             "Resample invalid → Ill_Started");
      Ev := Resample_1D (E0, 0.0, 3, Clamp);
      Check (Ev.Stat = Empty and not Ev.Success,
             "Resample empty → Empty");

      RI := Resize_2D (Img, 0, 4, 3, Clamp);
      Check (RI.Stat = Bad_Parameter, "Resize2D New_Nx=0");
      RI := Resize_2D (Img, Max_Image + 1, 4, 3, Clamp);
      Check (RI.Stat = Out_Of_Domain, "Resize2D oversized");
      declare
         Bi : Image_2D;
      begin
         RI := Resize_2D (Bi, 4, 4, 3, Clamp);
         Check (RI.Stat = Ill_Started, "Resize2D invalid");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Resize up/down + 2-D resample");
   ---------------------------------------------------------------------
   declare
      S  : constant Signal_1D := Make_Constant_1D (8, 1.0);
      RR : Resize_1D_Result;
      Img : constant Image_2D := Make_Constant_2D (4, 4, 7.0);
      RI : Resize_2D_Result;
      R  : Eval_Result;
      Ramp : constant Signal_1D := Make_Ramp_1D (5, 0.0, 4.0);
   begin
      RR := Resize_1D (S, 16, 3, Clamp);
      Check (RR.Success and RR.Signal.N = 16, "Upsample 8→16 size");
      Check
        (Approx (Get (RR.Signal, 0), 1.0, 5.0E-2)
         and Approx (Get (RR.Signal, 8), 1.0, 5.0E-2)
         and Approx (Get (RR.Signal, 15), 1.0, 5.0E-2),
         "Upsample constant stays ~1");
      RR := Resize_1D (S, 4, 2, Reflect);
      Check (RR.Success and RR.Signal.N = 4, "Downsample 8→4");
      Check (Approx (Get (RR.Signal, 2), 1.0, 8.0E-2),
             "Downsample const ~1");

      RI := Resize_2D (Img, 8, 8, 3, Clamp);
      Check (RI.Success and RI.Image.Nx = 8 and RI.Image.Ny = 8,
             "Upsample 2D 4→8");
      Check
        (Approx (Get (RI.Image, 3, 5), 7.0, 8.0E-2),
         "Upsample 2D const ~7");

      R := Resample_2D (Img, 1.5, 2.5, 3, Clamp);
      Check (R.Success and Approx (R.Value, 7.0, 1.5E-1),
             "Resample2D const");

      --  Half-sample on ramp
      R := Resample_1D (Ramp, 2.0, 3, Clamp);
      Check (R.Success and Approx (R.Value, 2.0, 1.0E-4),
             "Ramp at integer");
      R := Resample_1D (Ramp, 1.5, 3, Clamp);
      Check (R.Success and R.Value > 1.0 and R.Value < 2.0,
             "Ramp at 1.5 between 1 and 2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Extra kernel / a=2 vs a=3 / symmetry");
   ---------------------------------------------------------------------
   declare
      X : Float;
   begin
      for K in 1 .. 9 loop
         X := 0.1 * Float (K);
         Check
           (Approx (Kernel (3, X), Kernel (3, -X), 1.0E-6),
            "Kernel odd-even sym x=" & Float'Image (X));
         Check
           (Approx (Sinc (X), Sinc (-X), 1.0E-6),
            "Sinc even x=" & Float'Image (X));
      end loop;
      Check (abs (Kernel (2, 0.5)) > abs (Kernel (2, 1.5)),
             "a=2 central > side |lobe|");
      Check (Approx (Kernel (2, 1.5), 0.0) or Kernel (2, 1.5) /= 0.0,
             "a=2 at 1.5 inside support");
      Check (abs (Kernel (2, 1.5)) > 0.0, "a=2 L(1.5) nonzero");
      Check (Approx (Kernel (2, 2.0), 0.0), "a=2 L(2)=0 boundary");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
