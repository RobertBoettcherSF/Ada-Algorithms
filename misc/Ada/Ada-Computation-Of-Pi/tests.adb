--  Standalone test suite for Computation_Of_Pi (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Computation_Of_Pi; use Computation_Of_Pi;

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

begin
   Ada.Text_IO.Put_Line ("Computation_Of_Pi survey test suite");
   Ada.Text_IO.Put_Line ("===================================");

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
      Check (Near (Pi_Constant, Pi_Constant), "Near Pi_Constant");
      E := Abs_Error (3.0, 1.0);
      Check (Close (E, 2.0), "Abs_Error 3-1");
      Check (Close (Abs_Error (1.0, 1.0), 0.0), "Abs_Error zero");
      Check (Close (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
      Check (Close (Abs_Error (Pi_Constant, Pi_Constant), 0.0),
             "Abs_Error Pi self");
      R := Rel_Error (5.1, 5.0);
      Check (Close (R, 0.02, 1.0E-12), "Rel_Error 5.1 vs 5");
      Check (Close (Rel_Error (0.0, 0.0), 0.0), "Rel_Error 0/0");
      Check (Rel_Error (1.0, 0.0) > 1.0E20, "Rel_Error nonzero/0 sentinel");
      Check (Close (Rel_Error (2.0, 1.0), 1.0), "Rel_Error 2 vs 1");
      Check (Close (Rel_Error (-2.0, -1.0), 1.0), "Rel_Error signed ratio");
   end;

   ---------------------------------------------------------------------
   Section ("2. Pi_Constant / Ada_Pi / Elementary_Pi");
   ---------------------------------------------------------------------
   declare
      A, E, P : Long_Float;
   begin
      P := Pi_Constant;
      A := Ada_Pi;
      E := Elementary_Pi;
      Check (P > 3.14 and then P < 3.15, "Pi_Constant in (3.14,3.15)");
      Check (Close (P, A, 1.0E-14), "Pi_Constant ≈ Ada_Pi");
      Check (Close (P, E, 1.0E-14), "Pi_Constant ≈ Elementary_Pi");
      Check (Close (A, E, 1.0E-14), "Ada_Pi ≈ Elementary_Pi");
      Check (Close (Abs_Error (P, A), 0.0, 1.0E-14), "Abs_Error Pi refs");
      Check (Rel_Error (P, A) < 1.0E-14, "Rel_Error Pi refs tiny");
      Check (Close (P, 3.141_592_653_589_793, 1.0E-15),
             "Pi_Constant known digits");
      Check (not Near (P, 22.0 / 7.0, 1.0E-4), "Pi ≠ 22/7 at 1e-4");
      Check (Near (P, 22.0 / 7.0, 2.0E-3), "Pi near 22/7 at 2e-3");
   end;

   ---------------------------------------------------------------------
   Section ("3. Domain constants / Method'Range");
   ---------------------------------------------------------------------
   declare
      Count : Natural := 0;
      Est_Def, Est_Bare, Est_Maxish : Long_Float;
      Tol : Long_Float;
      E : Effort_Count;
   begin
      for M in Method loop
         Count := Count + 1;
      end loop;
      Check (Count = 7, "seven methods");
      Check (Method'Image (Method'First) = "LEIBNIZ", "Leibniz first image");
      Check (Method'Image (Method'Last) = "CHUDNOVSKY_TERM",
             "Chudnovsky_Term last image");
      Est_Def  := Approximate_Pi (Leibniz, Default_Effort);
      Est_Bare := Approximate_Pi (Leibniz);
      Check (Close (Est_Def, Est_Bare), "Default_Effort drives bare call");
      Check (Close (Est_Def, Leibniz_Pi (Default_Effort)),
             "Default_Effort matches Leibniz sketch");
      Tol := Near_Tol;
      Check (Near (0.0, 0.0, Tol), "Near_Tol usable as tolerance");
      Check (not Near (0.0, 1.0, Tol), "Near_Tol rejects unit gap");
      E := Default_Effort;
      Est_Maxish := Approximate_Pi (BBP_Partial, E);
      Check (Est_Maxish > 3.0 and then Est_Maxish < 3.2,
             "Default_Effort usable for BBP");
   end;

   ---------------------------------------------------------------------
   Section ("4. Leibniz series");
   ---------------------------------------------------------------------
   declare
      P1, P10, P100, P1000, E10, E1000 : Long_Float;
   begin
      P1    := Leibniz_Pi (1);
      P10   := Leibniz_Pi (10);
      P100  := Leibniz_Pi (100);
      P1000 := Leibniz_Pi (1000);
      Check (Close (P1, 4.0), "Leibniz 1 term = 4");
      Check (P10 > 3.0 and then P10 < 3.3, "Leibniz 10 in band");
      Check (Abs_Error (P100, Pi_Constant) < Abs_Error (P10, Pi_Constant),
             "Leibniz 100 better than 10");
      Check (Abs_Error (P1000, Pi_Constant) < Abs_Error (P100, Pi_Constant),
             "Leibniz 1000 better than 100");
      Check (Abs_Error (P1000, Pi_Constant) < 0.002,
             "Leibniz 1000 abs err < 0.002");
      E10   := Abs_Error (Approximate_Pi (Leibniz, 10), Pi_Constant);
      E1000 := Abs_Error (Approximate_Pi (Leibniz, 1000), Pi_Constant);
      Check (E1000 < E10, "dispatcher Leibniz improves with effort");
      Check (Close (Approximate_Pi (Leibniz, 50), Leibniz_Pi (50)),
             "dispatcher Leibniz = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("5. Nilakantha series");
   ---------------------------------------------------------------------
   declare
      N5, N20, N100 : Long_Float;
   begin
      N5   := Nilakantha_Pi (5);
      N20  := Nilakantha_Pi (20);
      N100 := Nilakantha_Pi (100);
      Check (N5 > 3.1 and then N5 < 3.2, "Nilakantha 5 in band");
      Check (Abs_Error (N20, Pi_Constant) < Abs_Error (N5, Pi_Constant),
             "Nilakantha 20 better than 5");
      Check (Abs_Error (N100, Pi_Constant) < Abs_Error (N20, Pi_Constant),
             "Nilakantha 100 better than 20");
      Check (Abs_Error (N100, Pi_Constant) < 1.0E-6,
             "Nilakantha 100 abs err < 1e-6");
      Check (Abs_Error (N20, Pi_Constant) < Abs_Error (Leibniz_Pi (20),
                                                      Pi_Constant),
             "Nilakantha beats Leibniz at 20");
      Check (Close (Approximate_Pi (Nilakantha, 30), Nilakantha_Pi (30)),
             "dispatcher Nilakantha = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("6. Arctan_Series / Machin");
   ---------------------------------------------------------------------
   declare
      A1, M1, M5, M10, M20, L20 : Long_Float;
   begin
      A1 := Arctan_Series (1.0, 100);
      Check (Close (A1, Elementary_Pi / 4.0, 1.0E-2),
             "arctan(1) series ~ π/4 (100 terms)");
      Check (Close (Arctan_Series (0.0, 5), 0.0), "arctan(0)=0");
      M1  := Machin_Pi (1);
      M5  := Machin_Pi (5);
      M10 := Machin_Pi (10);
      M20 := Machin_Pi (20);
      L20 := Leibniz_Pi (20);
      Check (M1 > 3.0 and then M1 < 3.3, "Machin 1 in band");
      Check (Abs_Error (M5, Pi_Constant) < Abs_Error (M1, Pi_Constant),
             "Machin 5 better than 1");
      Check (Abs_Error (M10, Pi_Constant) < Abs_Error (M5, Pi_Constant),
             "Machin 10 better than 5");
      Check (Abs_Error (M20, Pi_Constant) < 1.0E-12,
             "Machin 20 abs err < 1e-12");
      Check (Abs_Error (M20, Pi_Constant) < Abs_Error (L20, Pi_Constant),
             "Machin much better than Leibniz at effort 20");
      Check (Abs_Error (Machin_Pi (10), Pi_Constant) <
             Abs_Error (Leibniz_Pi (10), Pi_Constant) / 100.0,
             "Machin 10 >> Leibniz 10 (100×)");
      Check (Close (Approximate_Pi (Machin, 15), Machin_Pi (15)),
             "dispatcher Machin = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("7. Archimedes polygon doubling");
   ---------------------------------------------------------------------
   declare
      A1, A3, A6, A10 : Long_Float;
   begin
      A1  := Archimedes_Pi (1);
      A3  := Archimedes_Pi (3);
      A6  := Archimedes_Pi (6);
      A10 := Archimedes_Pi (10);
      Check (A1 > 3.0 and then A1 < 3.2, "Archimedes 1 in band");
      Check (Abs_Error (A3, Pi_Constant) < Abs_Error (A1, Pi_Constant),
             "Archimedes 3 better than 1");
      Check (Abs_Error (A6, Pi_Constant) < Abs_Error (A3, Pi_Constant),
             "Archimedes 6 better than 3");
      Check (Abs_Error (A10, Pi_Constant) < 1.0E-6,
             "Archimedes 10 abs err < 1e-6");
      Check (A10 < Pi_Constant + 1.0E-5, "inscribed underestimates π");
      Check (Close (Approximate_Pi (Archimedes, 8), Archimedes_Pi (8)),
             "dispatcher Archimedes = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("8. BBP_Partial");
   ---------------------------------------------------------------------
   declare
      B1, B4, B8, B12 : Long_Float;
   begin
      B1  := BBP_Partial_Pi (1);
      B4  := BBP_Partial_Pi (4);
      B8  := BBP_Partial_Pi (8);
      B12 := BBP_Partial_Pi (12);
      Check (Close (B1, 3.133_333_333_333_333, 1.0E-9),
             "BBP 1 term known");
      Check (Abs_Error (B4, Pi_Constant) < Abs_Error (B1, Pi_Constant),
             "BBP 4 better than 1");
      Check (Abs_Error (B8, Pi_Constant) < Abs_Error (B4, Pi_Constant),
             "BBP 8 better than 4");
      Check (Near (B12, Pi_Constant, 1.0E-12), "BBP 12 near π");
      Check (Close (Approximate_Pi (BBP_Partial, 10), BBP_Partial_Pi (10)),
             "dispatcher BBP = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("9. AGM one-step / few steps");
   ---------------------------------------------------------------------
   declare
      G1, G2, G4, G8 : Long_Float;
   begin
      G1 := AGM_Pi (1);
      G2 := AGM_Pi (2);
      G4 := AGM_Pi (4);
      G8 := AGM_Pi (8);
      Check (G1 > 3.14 and then G1 < 3.15, "AGM 1 in band");
      Check (Abs_Error (G2, Pi_Constant) < Abs_Error (G1, Pi_Constant),
             "AGM 2 better than 1");
      Check (Near (G4, Pi_Constant, 1.0E-14), "AGM 4 near π");
      Check (Near (G8, Pi_Constant, 1.0E-14), "AGM 8 near π");
      Check (Abs_Error (G1, Pi_Constant) < 2.0E-3,
             "AGM one-step abs err < 2e-3");
      Check (Close (Approximate_Pi (AGM, 3), AGM_Pi (3)),
             "dispatcher AGM = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("10. Chudnovsky catalogue terms");
   ---------------------------------------------------------------------
   declare
      C1, C2, C3 : Long_Float;
   begin
      C1 := Chudnovsky_Pi (1);
      C2 := Chudnovsky_Pi (2);
      C3 := Chudnovsky_Pi (3);
      Check (Near (C1, Pi_Constant, 1.0E-12), "Chudnovsky 1 term near π");
      Check (Near (C2, Pi_Constant, 1.0E-14), "Chudnovsky 2 terms near π");
      Check (Near (C3, Pi_Constant, 1.0E-14), "Chudnovsky 3 terms near π");
      Check (Abs_Error (C1, Pi_Constant) < 1.0E-12,
             "Chudnovsky 1 abs err < 1e-12");
      Check (Close (Approximate_Pi (Chudnovsky_Term, 1), C1),
             "dispatcher Chudnovsky = sketch");
   end;

   ---------------------------------------------------------------------
   Section ("11. Approximate_Pi dispatcher + Abs_Err out");
   ---------------------------------------------------------------------
   declare
      Est, Err : Long_Float;
   begin
      Approximate_Pi (Machin, 20, Est, Err);
      Check (Near (Est, Pi_Constant, 1.0E-12), "proc Machin Est near π");
      Check (Close (Err, Abs_Error (Est, Pi_Constant)), "proc Abs_Err matches");
      Approximate_Pi (Leibniz, 100, Est, Err);
      Check (Err > 1.0E-4, "Leibniz 100 still coarse");
      Approximate_Pi (BBP_Partial, 12, Est, Err);
      Check (Err < 1.0E-12, "BBP 12 Abs_Err tiny");
      Approximate_Pi (AGM, 5, Est, Err);
      Check (Err < 1.0E-14, "AGM 5 Abs_Err tiny");
      Check (Close (Approximate_Pi (Leibniz), Leibniz_Pi (Default_Effort)),
             "default Effort = Default_Effort");
   end;

   ---------------------------------------------------------------------
   Section ("12. Cross-method taxonomy (slow vs fast)");
   ---------------------------------------------------------------------
   declare
      E_Leib, E_Mach, E_Nil, E_Arch, E_BBP, E_AGM, E_Chu : Long_Float;
   begin
      E_Leib := Abs_Error (Approximate_Pi (Leibniz, 50), Pi_Constant);
      E_Mach := Abs_Error (Approximate_Pi (Machin, 50), Pi_Constant);
      E_Nil  := Abs_Error (Approximate_Pi (Nilakantha, 50), Pi_Constant);
      E_Arch := Abs_Error (Approximate_Pi (Archimedes, 10), Pi_Constant);
      E_BBP  := Abs_Error (Approximate_Pi (BBP_Partial, 10), Pi_Constant);
      E_AGM  := Abs_Error (Approximate_Pi (AGM, 4), Pi_Constant);
      E_Chu  := Abs_Error (Approximate_Pi (Chudnovsky_Term, 1), Pi_Constant);
      Check (E_Mach < E_Leib / 1.0E6, "Machin << Leibniz (taxonomy)");
      Check (E_Nil < E_Leib, "Nilakantha faster than Leibniz");
      Check (E_BBP < E_Leib, "BBP faster than Leibniz at small effort");
      Check (E_AGM < 1.0E-14, "AGM saturates Long_Float");
      Check (E_Chu < 1.0E-12, "Chudnovsky one-term already tiny");
      Check (E_Arch < 1.0E-5, "Archimedes 10 useful");
      Check (E_Mach < 1.0E-14 or else E_Mach < E_Nil,
             "Machin competitive vs Nilakantha");
   end;

   ---------------------------------------------------------------------
   Section ("13. Invalid_Argument defence");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : Long_Float := Leibniz_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Leibniz_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Machin_Pi (Max_Effort + 1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Machin_Pi(Max+1) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Archimedes_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Archimedes_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := AGM_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "AGM_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Nilakantha_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Nilakantha_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := BBP_Partial_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "BBP_Partial_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Chudnovsky_Pi (0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Chudnovsky_Pi(0) raises");

      Raised := False;
      begin
         declare
            Unused : Long_Float := Arctan_Series (0.5, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Arctan_Series(_,0) raises");
   end;

   ---------------------------------------------------------------------
   Section ("14. Methods approach π with effort");
   ---------------------------------------------------------------------
   declare
      E_Lo, E_Hi : Long_Float;
   begin
      for M in Method loop
         case M is
            when Leibniz =>
               E_Lo := Abs_Error (Approximate_Pi (M, 20), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 200), Pi_Constant);
               Check (E_Hi < E_Lo, "Leibniz approaches");
            when Nilakantha =>
               E_Lo := Abs_Error (Approximate_Pi (M, 5), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 50), Pi_Constant);
               Check (E_Hi < E_Lo, "Nilakantha approaches");
            when Machin =>
               E_Lo := Abs_Error (Approximate_Pi (M, 2), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 12), Pi_Constant);
               Check (E_Hi < E_Lo, "Machin approaches");
            when Archimedes =>
               E_Lo := Abs_Error (Approximate_Pi (M, 2), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 8), Pi_Constant);
               Check (E_Hi < E_Lo, "Archimedes approaches");
            when BBP_Partial =>
               E_Lo := Abs_Error (Approximate_Pi (M, 2), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 8), Pi_Constant);
               Check (E_Hi < E_Lo, "BBP approaches");
            when AGM =>
               E_Lo := Abs_Error (Approximate_Pi (M, 1), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 3), Pi_Constant);
               Check (E_Hi < E_Lo or else E_Hi < 1.0E-14,
                      "AGM approaches / saturates");
            when Chudnovsky_Term =>
               E_Lo := Abs_Error (Approximate_Pi (M, 1), Pi_Constant);
               E_Hi := Abs_Error (Approximate_Pi (M, 2), Pi_Constant);
               Check (E_Hi <= E_Lo + 1.0E-15 or else E_Hi < 1.0E-14,
                      "Chudnovsky saturates");
         end case;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("15. Estimates stay in sensible band");
   ---------------------------------------------------------------------
   declare
      Est : Long_Float;
   begin
      for M in Method loop
         case M is
            when Leibniz =>
               Est := Approximate_Pi (M, 50);
            when others =>
               Est := Approximate_Pi (M, 5);
         end case;
         Check (Est > 3.0 and then Est < 3.3,
                "band for " & Method'Image (M));
      end loop;
      Est := Approximate_Pi (Leibniz, 1);
      Check (Close (Est, 4.0), "Leibniz first = 4");
      Est := Approximate_Pi (Nilakantha, 1);
      Check (Est > 3.1 and then Est < 3.2, "Nilakantha first term");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("========================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Natural'Image (Pass_Count) &
      "  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
