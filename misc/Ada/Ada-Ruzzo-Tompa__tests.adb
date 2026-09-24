--  Standalone test suite for Ruzzo_Tompa (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Ruzzo_Tompa; use Ruzzo_Tompa;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   ------------------------------------------------------------------
   -- Helpers
   ------------------------------------------------------------------

   function Window_Sum (A : Element_Array; First, Last : Positive)
     return Element
   is
      S : Element := 0;
   begin
      for I in First .. Last loop
         S := S + A (A'First + (I - 1));
      end loop;
      return S;
   end Window_Sum;

   --  Brute Kadane (nonempty): max contiguous sum + leftmost witness.
   function Brute_Kadane (A : Element_Array) return Segment is
      Best_Sum   : Element;
      Best_First : Positive := 1;
      Best_Last  : Positive := 1;
      N          : constant Positive := A'Length;
   begin
      Best_Sum := A (A'First);
      for I in 1 .. N loop
         declare
            Running : Element := 0;
         begin
            for J in I .. N loop
               Running := Running + A (A'First + (J - 1));
               if Running > Best_Sum
                 or else
                   (Running = Best_Sum
                    and then (I < Best_First
                              or else (I = Best_First
                                       and then J < Best_Last)))
               then
                  Best_Sum   := Running;
                  Best_First := I;
                  Best_Last  := J;
               end if;
            end loop;
         end;
      end loop;
      return (First => Best_First, Last => Best_Last, Score => Best_Sum);
   end Brute_Kadane;

   function Segments_Nonoverlapping (Segs : Segment_Array) return Boolean is
   begin
      for I in Segs'First .. Segs'Last - 1 loop
         if Segs (I).Last >= Segs (I + 1).First then
            return False;
         end if;
         if Segs (I).First > Segs (I).Last then
            return False;
         end if;
      end loop;
      if Segs'Length > 0
        and then Segs (Segs'Last).First > Segs (Segs'Last).Last
      then
         return False;
      end if;
      return True;
   end Segments_Nonoverlapping;

   function All_Positive_Scores (Segs : Segment_Array) return Boolean is
   begin
      for S of Segs loop
         if S.Score <= 0 then
            return False;
         end if;
      end loop;
      return True;
   end All_Positive_Scores;

   function Scores_Match_Windows
     (A : Element_Array; Segs : Segment_Array) return Boolean
   is
   begin
      for S of Segs loop
         if Window_Sum (A, S.First, S.Last) /= S.Score then
            return False;
         end if;
      end loop;
      return True;
   end Scores_Match_Windows;

   function MS_Raises (A : Element_Array) return Boolean is
   begin
      declare
         Unused : constant Segment_Array := Maximal_Segments (A);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end MS_Raises;

   function Max_Raises (A : Element_Array) return Boolean is
      Unused : Segment;
   begin
      Unused := Max_Segment (A);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Max_Raises;

   function Real_MS_Raises (A : Real_Array) return Boolean is
   begin
      declare
         Unused : constant Real_Segment_Array := Maximal_Segments (A);
         pragma Unreferenced (Unused);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Real_MS_Raises;

   procedure Expect_Seg
     (S : Segment; F, L : Positive; Sc : Element; Label : String)
   is
   begin
      Check (S.First = F,
             Label & ": First" & Positive'Image (S.First)
             & " expect" & Positive'Image (F));
      Check (S.Last = L,
             Label & ": Last" & Positive'Image (S.Last)
             & " expect" & Positive'Image (L));
      Check (S.Score = Sc,
             Label & ": Score" & Element'Image (S.Score)
             & " expect" & Element'Image (Sc));
   end Expect_Seg;

   procedure Check_RT_Properties (A : Element_Array; Label : String) is
      Segs : constant Segment_Array := Maximal_Segments (A);
      Best : constant Segment := Max_Segment (A);
      Brute : constant Segment := Brute_Kadane (A);
   begin
      Check (Segments_Nonoverlapping (Segs),
             Label & ": non-overlapping");
      Check (All_Positive_Scores (Segs),
             Label & ": all scores > 0");
      Check (Scores_Match_Windows (A, Segs),
             Label & ": Score = window sum");

      if Segs'Length > 0 then
         --  Max_Segment score equals brute / Kadane max sum.
         Check (Best.Score = Brute.Score,
                Label & ": Max_Segment Score ≡ brute Kadane ("
                & Element'Image (Best.Score) & ")");
         Check (Best.Score = Window_Sum (A, Best.First, Best.Last),
                Label & ": Max_Segment window matches Score");
         --  Best must be one of the RT segments.
         declare
            Found : Boolean := False;
         begin
            for S of Segs loop
               if S.First = Best.First
                 and then S.Last = Best.Last
                 and then S.Score = Best.Score
               then
                  Found := True;
               end if;
            end loop;
            Check (Found, Label & ": Max_Segment is an RT segment");
         end;
      else
         --  All nonpositive: Max_Segment is least-negative singleton.
         Check (Best.First = Best.Last,
                Label & ": all-nonpos Max_Segment is singleton");
         Check (Best.Score = Brute.Score,
                Label & ": all-nonpos Max_Segment ≡ brute");
      end if;
   end Check_RT_Properties;

begin
   Ada.Text_IO.Put_Line ("Ruzzo_Tompa test suite");
   Ada.Text_IO.Put_Line ("======================");

   ------------------------------------------------------------------
   Section ("1. Ruzzo & Tompa ISMB 1999 paper example");
   ------------------------------------------------------------------
   --  (4, -5, 3, -3, 1, 2, -2, 2, -2, 1, 5)
   --  Maximal: (4), (3), M=(1,2,-2,2,-2,1,5) score 7
   declare
      Paper : constant Element_Array :=
        [4, -5, 3, -3, 1, 2, -2, 2, -2, 1, 5];
      Segs  : constant Segment_Array := Maximal_Segments (Paper);
   begin
      Check (Segs'Length = 3, "paper: 3 maximal segments");
      Expect_Seg (Segs (1), 1, 1, 4, "paper I1");
      Expect_Seg (Segs (2), 3, 3, 3, "paper I2");
      Expect_Seg (Segs (3), 5, 11, 7, "paper M");
      Expect_Seg (Max_Segment (Paper), 5, 11, 7, "paper Max_Segment");
      Check_RT_Properties (Paper, "paper");
   end;

   ------------------------------------------------------------------
   Section ("2. Wikipedia classic maximum-subarray array");
   ------------------------------------------------------------------
   declare
      Wiki : constant Element_Array :=
        [-2, 1, -3, 4, -1, 2, 1, -5, 4];
      Segs : constant Segment_Array := Maximal_Segments (Wiki);
   begin
      Check (Segs'Length = 3, "wiki: 3 segments");
      Expect_Seg (Segs (1), 2, 2, 1, "wiki seg1");
      Expect_Seg (Segs (2), 4, 7, 6, "wiki seg2 (max)");
      Expect_Seg (Segs (3), 9, 9, 4, "wiki seg3");
      Expect_Seg (Max_Segment (Wiki), 4, 7, 6, "wiki Max_Segment");
      Check_RT_Properties (Wiki, "wiki");
   end;

   ------------------------------------------------------------------
   Section ("3. Simple merge / split cases");
   ------------------------------------------------------------------
   declare
      A : constant Element_Array := [4, -2, 5, -6, 3];
      Segs : constant Segment_Array := Maximal_Segments (A);
   begin
      Check (Segs'Length = 2, "simple: 2 segments");
      Expect_Seg (Segs (1), 1, 3, 7, "simple left");
      Expect_Seg (Segs (2), 5, 5, 3, "simple right");
      Expect_Seg (Max_Segment (A), 1, 3, 7, "simple max");
      Check_RT_Properties (A, "simple");
   end;

   declare
      A : constant Element_Array := [1, -2, 3, -4, 5];
      Segs : constant Segment_Array := Maximal_Segments (A);
   begin
      Check (Segs'Length = 3, "sep: 3 isolated positives");
      Expect_Seg (Segs (1), 1, 1, 1, "sep 1");
      Expect_Seg (Segs (2), 3, 3, 3, "sep 2");
      Expect_Seg (Segs (3), 5, 5, 5, "sep 3");
      Expect_Seg (Max_Segment (A), 5, 5, 5, "sep max");
      Check_RT_Properties (A, "sep");
   end;

   declare
      A : constant Element_Array := [10, -1, -1, -1, 10];
      Segs : constant Segment_Array := Maximal_Segments (A);
   begin
      Check (Segs'Length = 1, "bridge: single merged segment");
      Expect_Seg (Segs (1), 1, 5, 17, "bridge whole");
      Check_RT_Properties (A, "bridge");
   end;

   ------------------------------------------------------------------
   Section ("4. All-nonpositive → empty RT list; Max_Segment singleton");
   ------------------------------------------------------------------
   declare
      Neg : constant Element_Array := [-5, -1, -3, -4];
      Segs : constant Segment_Array := Maximal_Segments (Neg);
      M    : constant Segment := Max_Segment (Neg);
   begin
      Check (Segs'Length = 0, "all-neg: empty Maximal_Segments");
      Expect_Seg (M, 2, 2, -1, "all-neg: least-neg singleton");
      Check_RT_Properties (Neg, "all-neg");
   end;
   declare
      Z : constant Element_Array := [0, 0, 0];
      Segs : constant Segment_Array := Maximal_Segments (Z);
   begin
      Check (Segs'Length = 0, "all-zero: empty Maximal_Segments");
      Expect_Seg (Max_Segment (Z), 1, 1, 0, "all-zero Max_Segment");
      Check_RT_Properties (Z, "all-zero");
   end;
   declare
      Single_Neg : constant Element_Array := [-7];
      Segs_Neg   : constant Segment_Array := Maximal_Segments (Single_Neg);
   begin
      Check (Segs_Neg'Length = 0, "single-neg: empty list");
      Expect_Seg (Max_Segment (Single_Neg), 1, 1, -7, "single-neg max");
   end;

   ------------------------------------------------------------------
   Section ("5. Single positive / all positive");
   ------------------------------------------------------------------
   declare
      Single_Pos : constant Element_Array := [5];
      Segs_Pos   : constant Segment_Array := Maximal_Segments (Single_Pos);
   begin
      Expect_Seg (Max_Segment (Single_Pos), 1, 1, 5, "single pos");
      Check (Segs_Pos'Length = 1, "single pos length");
   end;
   declare
      Pos  : constant Element_Array := [1, 2, 3, 4];
      Segs : constant Segment_Array := Maximal_Segments (Pos);
   begin
      Expect_Seg (Segs (1), 1, 4, 10, "all-pos whole");
      Expect_Seg (Max_Segment (Pos), 1, 4, 10, "all-pos max");
      Check_RT_Properties (Pos, "all-pos");
   end;

   ------------------------------------------------------------------
   Section ("6. Empty / oversize raise Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
   begin
      Check (MS_Raises (Empty), "empty Maximal_Segments raises");
      Check (Max_Raises (Empty), "empty Max_Segment raises");
   end;
   declare
      Big : constant Element_Array (1 .. Max_Length + 1) := [others => 1];
   begin
      Check (MS_Raises (Big), "oversize Maximal_Segments raises");
      Check (Max_Raises (Big), "oversize Max_Segment raises");
   end;
   declare
      Empty_R : Real_Array (1 .. 0);
   begin
      Check (Real_MS_Raises (Empty_R), "empty Real Maximal_Segments raises");
   end;

   ------------------------------------------------------------------
   Section ("7. Non-1-based array bounds");
   ------------------------------------------------------------------
   declare
      Buf : constant Element_Array (5 .. 15) :=
        [4, -5, 3, -3, 1, 2, -2, 2, -2, 1, 5];
      Segs : constant Segment_Array := Maximal_Segments (Buf);
   begin
      Check (Segs'Length = 3, "slice paper: 3 segments");
      Expect_Seg (Segs (1), 1, 1, 4, "slice I1 logical");
      Expect_Seg (Segs (3), 5, 11, 7, "slice M logical");
      Check_RT_Properties (Buf, "slice");
   end;

   ------------------------------------------------------------------
   Section ("8. Mixed arrays: RT properties + Max ≡ Kadane");
   ------------------------------------------------------------------
   Check_RT_Properties ([8, -19, 5, -4, 20], "mixed 1");
   Check_RT_Properties ([5, -2, -1, 3, -1], "mixed 2");
   Check_RT_Properties ([1, -1, 1], "mixed 3");
   Check_RT_Properties ([-2, -3, 4, -1, -2, 1, 5, -3], "mixed 4");
   Check_RT_Properties ([2, -1, 2], "mixed 5");
   Check_RT_Properties ([1, 2, -1, -3, 4, 5, -2], "mixed 6");
   Check_RT_Properties ([-4, 1, 2, -5, 3], "mixed 7");
   Check_RT_Properties ([9, -10, 8], "mixed 8");

   ------------------------------------------------------------------
   Section ("9. Long_Float path");
   ------------------------------------------------------------------
   declare
      R : constant Real_Array :=
        [4.0, -5.0, 3.0, -3.0, 1.0, 2.0, -2.0, 2.0, -2.0, 1.0, 5.0];
      Segs : constant Real_Segment_Array := Maximal_Segments (R);
      M    : constant Real_Segment := Max_Segment (R);
   begin
      Check (Segs'Length = 3, "real paper: 3 segments");
      Check (Segs (1).First = 1 and then Segs (1).Last = 1
             and then Segs (1).Score = 4.0,
             "real paper I1");
      Check (Segs (2).First = 3 and then Segs (2).Last = 3
             and then Segs (2).Score = 3.0,
             "real paper I2");
      Check (Segs (3).First = 5 and then Segs (3).Last = 11
             and then Segs (3).Score = 7.0,
             "real paper M");
      Check (M.Score = 7.0 and then M.First = 5 and then M.Last = 11,
             "real Max_Segment");
   end;
   declare
      Neg : constant Real_Array := [-2.5, -0.5, -3.0];
      Segs : constant Real_Segment_Array := Maximal_Segments (Neg);
      M    : constant Real_Segment := Max_Segment (Neg);
   begin
      Check (Segs'Length = 0, "real all-neg empty");
      Check (M.First = 2 and then M.Last = 2 and then M.Score = -0.5,
             "real all-neg singleton");
   end;

   ------------------------------------------------------------------
   Section ("10. Max_Length boundary");
   ------------------------------------------------------------------
   declare
      Edge : Element_Array (1 .. Max_Length) := [others => -1];
   begin
      Edge (Max_Length / 2) := 5;
      declare
         Segs : constant Segment_Array := Maximal_Segments (Edge);
         M    : constant Segment := Max_Segment (Edge);
      begin
         Check (Segs'Length = 1, "Max_Length: one positive segment");
         Expect_Seg (Segs (1), Max_Length / 2, Max_Length / 2, 5,
                     "Max_Length seg");
         Expect_Seg (M, Max_Length / 2, Max_Length / 2, 5,
                     "Max_Length max");
      end;
   end;

   ------------------------------------------------------------------
   Section ("11. Known Max_Segment vs brute on more arrays");
   ------------------------------------------------------------------
   declare
      procedure Agree (A : Element_Array; Label : String) is
         M : constant Segment := Max_Segment (A);
         B : constant Segment := Brute_Kadane (A);
      begin
         Check (M.Score = B.Score,
                Label & ": score" & Element'Image (M.Score));
      end Agree;
   begin
      Agree ([-2, 1, -3, 4, -1, 2, 1, -5, 4], "agree wiki");
      Agree ([4, -5, 3, -3, 1, 2, -2, 2, -2, 1, 5], "agree paper");
      Agree ([-8, -3, -9], "agree all-neg");
      Agree ([7], "agree single");
      Agree ([3, -1, -1, 3], "agree twin peaks");
      Agree ([1, -10, 1, -10, 1], "agree three ones");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
