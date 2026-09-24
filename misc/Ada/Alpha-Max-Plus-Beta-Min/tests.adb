--  Standalone test suite for Alpha_Max_Plus_Beta_Min (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Alpha_Max_Plus_Beta_Min; use Alpha_Max_Plus_Beta_Min;

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

   function Close
     (A, B : Long_Float; Tol : Long_Float := 1.0E-9) return Boolean
   is
   begin
      return abs (A - B) <= Tol
        or else abs (A - B) <= Tol * (1.0 + abs (B));
   end Close;

   --  Scan unit circle angles via rational samples on [0,1] for r = Min/Max.
   --  Relative error of Approx_Fn vs Exact_Hypot over modest magnitudes.
   generic
      with function Approx_Fn (A, B : Long_Float) return Long_Float;
   function Max_Rel_Over_Grid
     (Bound : Long_Float;
      Steps : Positive := 64) return Long_Float;

   function Max_Rel_Over_Grid
     (Bound : Long_Float;
      Steps : Positive := 64) return Long_Float
   is
      Worst : Long_Float := 0.0;
      R     : Long_Float;
      A, B  : Long_Float;
      Est   : Long_Float;
      Ex    : Long_Float;
      Rel   : Long_Float;
      Scale : constant Long_Float := 10.0;
   begin
      --  Axes and equal cases at several scales.
      declare
         Scales : constant array (Positive range <>) of Long_Float :=
           [0.5, 1.0, 3.0, 10.0, Scale];
      begin
         for S of Scales loop
            Est := Approx_Fn (S, 0.0);
            Ex  := Exact_Hypot (S, 0.0);
            Rel := Rel_Error (Est, Ex);
            if Rel > Worst then
               Worst := Rel;
            end if;
            Est := Approx_Fn (0.0, S);
            Ex  := Exact_Hypot (0.0, S);
            Rel := Rel_Error (Est, Ex);
            if Rel > Worst then
               Worst := Rel;
            end if;
            Est := Approx_Fn (S, S);
            Ex  := Exact_Hypot (S, S);
            Rel := Rel_Error (Est, Ex);
            if Rel > Worst then
               Worst := Rel;
            end if;
         end loop;
      end;

      --  Ratios r = Min/Max in [0,1]: A=1, B=r (and swapped).
      for I in 0 .. Steps loop
         R := Long_Float (I) / Long_Float (Steps);
         A := Bound;
         B := Bound * R;
         Est := Approx_Fn (A, B);
         Ex  := Exact_Hypot (A, B);
         Rel := Rel_Error (Est, Ex);
         if Rel > Worst then
            Worst := Rel;
         end if;
         Est := Approx_Fn (A => B, B => A);
         Ex  := Exact_Hypot (A => B, B => A);
         Rel := Rel_Error (Est, Ex);
         if Rel > Worst then
            Worst := Rel;
         end if;
      end loop;
      return Worst;
   end Max_Rel_Over_Grid;

   function Worst_Rel_Half is new Max_Rel_Over_Grid (Approx_Half);
   function Worst_Rel_Quarter is new Max_Rel_Over_Grid (Approx_Quarter);
   function Worst_Rel_Shift is new Max_Rel_Over_Grid (Approx_Shift_Friendly);
   function Worst_Rel_Fifteenths is new Max_Rel_Over_Grid (Approx_Fifteenths);
   function Worst_Rel_Optimal is new Max_Rel_Over_Grid (Approx_Optimal);
   function Worst_Rel_Opt_Clamp is new Max_Rel_Over_Grid (Approx_Optimal_Clamped);

begin
   Ada.Text_IO.Put_Line ("Alpha_Max_Plus_Beta_Min test suite");
   Ada.Text_IO.Put_Line ("==================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Rel_Error helpers");
   ---------------------------------------------------------------------
   declare
      E, R : Long_Float;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects far");
      Check (Near (0.0, 0.0), "Near zeros");
      E := Abs_Error (3.0, 1.0);
      Check (Close (E, 2.0), "Abs_Error 3-1");
      Check (Close (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Close (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      R := Rel_Error (5.1, 5.0);
      Check (Close (R, 0.02, 1.0E-12), "Rel_Error 5.1 vs 5");
      Check (Close (Rel_Error (0.0, 0.0), 0.0), "Rel_Error 0/0");
      Check (Rel_Error (1.0, 0.0) > 1.0E20, "Rel_Error nonzero/0 sentinel");
   end;

   ---------------------------------------------------------------------
   Section ("2. Exact_Hypot oracle");
   ---------------------------------------------------------------------
   declare
      H : Long_Float;
   begin
      Check (Close (Exact_Hypot (0.0, 0.0), 0.0), "Hypot(0,0)=0");
      Check (Close (Exact_Hypot (3.0, 4.0), 5.0), "Hypot(3,4)=5");
      Check (Close (Exact_Hypot (-3.0, 4.0), 5.0), "Hypot(-3,4)=5");
      Check (Close (Exact_Hypot (3.0, -4.0), 5.0), "Hypot(3,-4)=5");
      Check (Close (Exact_Hypot (-3.0, -4.0), 5.0), "Hypot(-3,-4)=5");
      Check (Close (Exact_Hypot (5.0, 0.0), 5.0), "Hypot(5,0)=5");
      Check (Close (Exact_Hypot (0.0, 7.0), 7.0), "Hypot(0,7)=7");
      Check (Close (Exact_Hypot (1.0, 1.0), Exact_Hypot (1.0, -1.0)),
             "Hypot abs invariance 1,1");
      H := Exact_Hypot (6.0, 8.0);
      Check (Close (H, 10.0), "Hypot(6,8)=10");
      Check (Close (Exact_Hypot (5.0, 12.0), 13.0), "Hypot(5,12)=13");
      Check (Close (Exact_Hypot (8.0, 15.0), 17.0), "Hypot(8,15)=17");
   end;

   ---------------------------------------------------------------------
   Section ("3. Axes: (x,0) and (0,x)");
   ---------------------------------------------------------------------
   declare
      Xs : constant array (Positive range <>) of Long_Float :=
        [0.0, 1.0, 10.0];
   begin
      for X of Xs loop
         Check (Close (Approx_Half (X, 0.0), abs (X)),
                "Half axis (" & Long_Float'Image (X) & ",0)");
         Check (Close (Approx_Half (0.0, X), abs (X)),
                "Half axis (0," & Long_Float'Image (X) & ")");
         Check (Close (Approx_Shift_Friendly (X, 0.0), abs (X)),
                "Shift axis (" & Long_Float'Image (X) & ",0)");
         Check (Close (Approx_Quarter (0.0, X), abs (X)),
                "Quarter axis (0," & Long_Float'Image (X) & ")");
         --  Optimal with α<1 undershoots near axes: α·|x| < |x|.
         Check (Close (Approx_Optimal (X, 0.0), Alpha_Optimal * abs (X)),
                "Optimal raw axis (" & Long_Float'Image (X) & ",0)");
         Check (Close (Approx_Optimal_Clamped (X, 0.0), abs (X)),
                "Optimal clamped axis (" & Long_Float'Image (X) & ",0)");
         Check (Close (Approx_Fifteenths (X, 0.0),
                       Alpha_Fifteenths * abs (X)),
                "Fifteenths raw axis (" & Long_Float'Image (X) & ",0)");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("4. Equal |a|=|b|");
   ---------------------------------------------------------------------
   declare
      Vs : constant array (Positive range <>) of Long_Float :=
        [1.0, 5.0];
      Ex, Est : Long_Float;
   begin
      for V of Vs loop
         Ex := Exact_Hypot (V, V);
         --  Half: 1·V + 0.5·V = 1.5 V; exact = V√2 ≈ 1.414 V
         Est := Approx_Half (V, V);
         Check (Close (Est, 1.5 * V), "Half equal " & Long_Float'Image (V));
         Check (Rel_Error (Est, Ex) < Max_Rel_Half, "Half equal rel bound");

         Est := Approx_Shift_Friendly (V, V);
         Check (Close (Est, (1.0 + 0.375) * V),
                "Shift equal " & Long_Float'Image (V));
         Check (Rel_Error (Est, Ex) < Max_Rel_Shift, "Shift equal rel");

         Est := Approx_Optimal (V, V);
         Check (Close (Est, (Alpha_Optimal + Beta_Optimal) * V, 1.0E-12),
                "Optimal equal formula " & Long_Float'Image (V));
         Check (Rel_Error (Est, Ex) < Max_Rel_Optimal, "Optimal equal rel");

         Est := Approx_Quarter (V, V);
         Check (Close (Est, 1.25 * V), "Quarter equal " & Long_Float'Image (V));

         Est := Approx_Fifteenths (V, V);
         Check (Close (Est,
                       (Alpha_Fifteenths + Beta_Fifteenths) * V, 1.0E-12),
                "Fifteenths equal " & Long_Float'Image (V));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("5. Classic 3-4-5 triangle");
   ---------------------------------------------------------------------
   declare
      Ex  : constant Long_Float := 5.0;
      H   : Long_Float;
      Rel : Long_Float;
   begin
      Check (Close (Exact_Hypot (3.0, 4.0), Ex), "oracle 3-4-5");

      H := Approx_Half (3.0, 4.0);
      --  max=4, min=3 → 4 + 1.5 = 5.5
      Check (Close (H, 5.5), "Half(3,4)=5.5");
      Rel := Rel_Error (H, Ex);
      Check (Rel < Max_Rel_Half, "Half 3-4-5 rel bound");

      H := Approx_Shift_Friendly (3.0, 4.0);
      --  4 + 3*(3/8) = 4 + 1.125 = 5.125
      Check (Close (H, 5.125), "Shift(3,4)=5.125");
      Check (Rel_Error (H, Ex) < Max_Rel_Shift, "Shift 3-4-5 rel");

      H := Approx_Optimal (3.0, 4.0);
      --  ≈ 0.9604*4 + 0.3978*3 ≈ 5.035
      Check (Close (H, Alpha_Optimal * 4.0 + Beta_Optimal * 3.0, 1.0E-12),
             "Optimal(3,4) formula");
      Check (Rel_Error (H, Ex) < Max_Rel_Optimal, "Optimal 3-4-5 rel");
      Check (Close (H, 5.035, 0.01), "Optimal(3,4)~5.04");

      H := Approx_Quarter (3.0, 4.0);
      Check (Close (H, 4.0 + 0.75), "Quarter(3,4)=4.75");

      H := Approx_Fifteenths (3.0, 4.0);
      Check (Close (H,
                    Alpha_Fifteenths * 4.0 + Beta_Fifteenths * 3.0, 1.0E-12),
             "Fifteenths(3,4) formula");
      Check (Rel_Error (H, Ex) < Max_Rel_Fifteenths, "Fifteenths 3-4-5 rel");
   end;

   ---------------------------------------------------------------------
   Section ("6. Symmetry and absolute-value invariance");
   ---------------------------------------------------------------------
   declare
      type Pair2 is record
         A, B : Long_Float;
      end record;
      Pairs : constant array (Positive range <>) of Pair2 :=
        [(3.0, 4.0), (5.0, 12.0)];
   begin
      for P of Pairs loop
         declare
            A : constant Long_Float := P.A;
            B : constant Long_Float := P.B;
         begin
            Check (Close (Approx_Half (A, B), Approx_Half (A => B, B => A)),
                   "Half swap symmetry");
            Check (Close (Approx_Half (A, B), Approx_Half (-A, B)),
                   "Half sign A");
            Check (Close (Approx_Half (A, B), Approx_Half (A, -B)),
                   "Half sign B");
            Check (Close (Approx_Half (A, B), Approx_Half (-A, -B)),
                   "Half both signs");

            Check (Close (Approx_Optimal (A, B), Approx_Optimal (A => B, B => A)),
                   "Optimal swap");
            Check (Close (Approx_Optimal (A, B), Approx_Optimal (-A, B)),
                   "Optimal sign A");
            Check (Close (Approx_Shift_Friendly (A, B),
                          Approx_Shift_Friendly (A => -B, B => A)),
                   "Shift swap+sign");
            Check (Close (Approx_Fifteenths (A, B),
                          Approx_Fifteenths (-A, -B)),
                   "Fifteenths abs");
            Check (Close (Approx_Quarter (A, B), Approx_Quarter (A => B, B => A)),
                   "Quarter swap");
            Check (Close (Approx_Optimal_Clamped (A, B),
                          Approx_Optimal_Clamped (-A, B)),
                   "Clamped sign");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Core Approx matches presets");
   ---------------------------------------------------------------------
   declare
      A : constant Long_Float := 2.5;
      B : constant Long_Float := 6.0;
   begin
      Check (Close (Approx (A, B, 1.0, 0.5), Approx_Half (A, B)),
             "Approx ≡ Half");
      Check (Close (Approx (A, B, 1.0, 0.25), Approx_Quarter (A, B)),
             "Approx ≡ Quarter");
      Check (Close (Approx (A, B, 1.0, 0.375), Approx_Shift_Friendly (A, B)),
             "Approx ≡ Shift");
      Check (Close (Approx (A, B, Alpha_Optimal, Beta_Optimal),
                    Approx_Optimal (A, B)),
             "Approx ≡ Optimal");
      Check (Close (Approx (A, B, Alpha_Fifteenths, Beta_Fifteenths),
                    Approx_Fifteenths (A, B)),
             "Approx ≡ Fifteenths");
      Check (Close (Approx_Clamped (A, B, Alpha_Optimal, Beta_Optimal),
                    Approx_Optimal_Clamped (A, B)),
             "Clamped ≡ Optimal_Clamped");
   end;

   ---------------------------------------------------------------------
   Section ("8. Max relative error bounds (grid)");
   ---------------------------------------------------------------------
   declare
      W : Long_Float;
   begin
      W := Worst_Rel_Half (1.0);
      Check (W <= Max_Rel_Half, "Half max rel ≤ 12%");
      Ada.Text_IO.Put_Line
        ("    (Half worst rel ≈ " & Long_Float'Image (W) & ")");

      W := Worst_Rel_Quarter (1.0);
      Check (W <= Max_Rel_Quarter, "Quarter max rel ≤ 12%");
      Ada.Text_IO.Put_Line
        ("    (Quarter worst rel ≈ " & Long_Float'Image (W) & ")");

      W := Worst_Rel_Shift (1.0);
      Check (W <= Max_Rel_Shift, "Shift max rel ≤ 7%");
      Ada.Text_IO.Put_Line
        ("    (Shift worst rel ≈ " & Long_Float'Image (W) & ")");

      W := Worst_Rel_Fifteenths (1.0);
      Check (W <= Max_Rel_Fifteenths, "Fifteenths max rel ≤ 6.5%");
      Ada.Text_IO.Put_Line
        ("    (Fifteenths worst rel ≈ " & Long_Float'Image (W) & ")");

      W := Worst_Rel_Optimal (1.0);
      Check (W <= Max_Rel_Optimal, "Optimal max rel ≤ 4%");
      Ada.Text_IO.Put_Line
        ("    (Optimal worst rel ≈ " & Long_Float'Image (W) & ")");

      W := Worst_Rel_Opt_Clamp (1.0);
      Check (W <= Max_Rel_Optimal, "Optimal_Clamped max rel ≤ 4%");
      Ada.Text_IO.Put_Line
        ("    (OptClamp worst rel ≈ " & Long_Float'Image (W) & ")");
   end;

   ---------------------------------------------------------------------
   Section ("9. Clamped improvement near axes");
   ---------------------------------------------------------------------
   declare
      Raw, Clamped, Ex : Long_Float;
   begin
      --  Near axis: Min small, Optimal raw < Max.
      Raw := Approx_Optimal (10.0, 0.1);
      Clamped := Approx_Optimal_Clamped (10.0, 0.1);
      Ex := Exact_Hypot (10.0, 0.1);
      Check (Raw < 10.0, "Optimal raw < Max near axis");
      Check (Close (Clamped, 10.0) or else Clamped >= 10.0,
             "Clamped ≥ Max near axis");
      Check (Rel_Error (Clamped, Ex) <= Rel_Error (Raw, Ex) + 1.0E-12
             or else Clamped >= Raw,
             "Clamped not worse than raw near axis (geom)");

      --  Far from axis (equal), clamp should not change when Est ≥ Max.
      Raw := Approx_Optimal (5.0, 5.0);
      Clamped := Approx_Optimal_Clamped (5.0, 5.0);
      Check (Close (Raw, Clamped), "Clamped = raw when Est ≥ Max");

      --  Explicit clamp with α=0.9, β=0.1 on (1,0).
      Check (Close (Approx_Clamped (1.0, 0.0, 0.9, 0.1), 1.0),
             "Clamp forces Max on axis");
      Check (Close (Approx (1.0, 0.0, 0.9, 0.1), 0.9),
             "Unclamped undershoots axis");
   end;

   ---------------------------------------------------------------------
   Section ("10. Two-segment improvement");
   ---------------------------------------------------------------------
   declare
      --  Segment 0 ≈ axis: (1, 0); segment 1 ≈ optimal.
      Z : Long_Float;
      Ex : Long_Float;
   begin
      Z := Approx_Two_Segment
        (3.0, 4.0,
         1.0, 0.0,
         Alpha_Optimal, Beta_Optimal);
      Ex := Exact_Hypot (3.0, 4.0);
      Check (Z >= 4.0, "TwoSeg ≥ Max");
      Check (Rel_Error (Z, Ex) < Max_Rel_Optimal + 0.01,
             "TwoSeg 3-4-5 reasonable");

      Z := Approx_Two_Segment (5.0, 0.0, 1.0, 0.0, Alpha_Optimal, Beta_Optimal);
      Check (Close (Z, 5.0), "TwoSeg axis picks Max segment");

      Z := Approx_Two_Segment
        (1.0, 1.0, 1.0, 0.0, Alpha_Optimal, Beta_Optimal);
      Check (Z >= Exact_Hypot (1.0, 1.0) * 0.9, "TwoSeg equal ballpark");
   end;

   ---------------------------------------------------------------------
   Section ("11. More Pythagorean triples and samples");
   ---------------------------------------------------------------------
   declare
      type Pair is record
         A, B, H : Long_Float;
      end record;
      Triples : constant array (Positive range <>) of Pair :=
        [(3.0, 4.0, 5.0), (5.0, 12.0, 13.0), (8.0, 15.0, 17.0),
         (7.0, 24.0, 25.0)];
   begin
      for T of Triples loop
         Check (Close (Exact_Hypot (T.A, T.B), T.H),
                "oracle triple");
         Check (Rel_Error (Approx_Half (T.A, T.B), T.H) < Max_Rel_Half,
                "Half triple rel");
         Check (Rel_Error (Approx_Shift_Friendly (T.A, T.B), T.H)
                < Max_Rel_Shift,
                "Shift triple rel");
         Check (Rel_Error (Approx_Optimal (T.A, T.B), T.H) < Max_Rel_Optimal,
                "Optimal triple rel");
         Check (Rel_Error (Approx_Fifteenths (T.A, T.B), T.H)
                < Max_Rel_Fifteenths,
                "Fifteenths triple rel");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("12. Coefficient constants sanity");
   ---------------------------------------------------------------------
   begin
      Check (Close (Alpha_Half, 1.0), "Alpha_Half=1");
      Check (Close (Beta_Half, 0.5), "Beta_Half=1/2");
      Check (Close (Beta_Shift, 3.0 / 8.0), "Beta_Shift=3/8");
      Check (Close (Alpha_Fifteenths, 15.0 / 16.0), "Alpha_Fifteenths");
      Check (Close (Beta_Fifteenths, 15.0 / 32.0), "Beta_Fifteenths");
      Check (Close (Alpha_Optimal, 0.960_433_870_103, 1.0E-12),
             "Alpha_Optimal ~0.9604");
      Check (Close (Beta_Optimal, 0.397_824_734_759, 1.0E-12),
             "Beta_Optimal ~0.3978");
      Check (Close (Alpha_Optimal + Beta_Optimal,
                    0.960_433_870_103 + 0.397_824_734_759, 1.0E-12),
             "Optimal alpha+beta sum");
      Check (Close (Max_Rel_Optimal, 0.04), "Max_Rel_Optimal ceiling");
   end;

   ---------------------------------------------------------------------
   Section ("13. Zero and tiny magnitudes");
   ---------------------------------------------------------------------
   begin
      Check (Close (Approx_Half (0.0, 0.0), 0.0), "Half(0,0)");
      Check (Close (Approx_Optimal (0.0, 0.0), 0.0), "Optimal(0,0)");
      Check (Close (Approx_Optimal_Clamped (0.0, 0.0), 0.0), "Clamp(0,0)");
      Check (Close (Exact_Hypot (1.0E-6, 0.0), 1.0E-6), "Hypot tiny axis");
      Check (Close (Approx_Half (1.0E-6, 0.0), 1.0E-6), "Half tiny axis");
      Check (Rel_Error (Approx_Optimal (1.0E-3, 1.0E-3),
                        Exact_Hypot (1.0E-3, 1.0E-3)) < Max_Rel_Optimal,
             "Optimal tiny equal");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("==================================");
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
