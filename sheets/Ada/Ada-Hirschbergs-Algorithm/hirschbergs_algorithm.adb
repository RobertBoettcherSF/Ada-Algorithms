--  Hirschbergs_Algorithm body — two-row NW last-row helper and
--  divide-and-conquer Hirschberg alignment in linear extra space.

pragma Ada_2022;

package body Hirschbergs_Algorithm
  with SPARK_Mode => Off
is

   use Ada.Strings.Unbounded;

   subtype Idx is Natural range 0 .. Max_Len;

   type Score_Row is array (Idx) of Integer;

   --  Fixed educational row pools (forward / reverse / scratch).
   --  Safe as non-reentrant scratch: each recursion level finishes its
   --  forward/reverse rows and stores Best_J before child calls overwrite.
   Fwd  : Score_Row;
   Rev  : Score_Row;
   Prev : Score_Row;
   Curr : Score_Row;

   procedure Check_Bounds (A, B : String) is
   begin
      if A'Length > Max_Len or else B'Length > Max_Len then
         raise Invalid_Argument
           with "string length exceeds Max_Len";
      end if;
   end Check_Bounds;

   function At_A (A : String; I : Positive) return Character is
     (A (A'First + (I - 1)));

   function At_B (B : String; J : Positive) return Character is
     (B (B'First + (J - 1)));

   function Pair_Score
     (Left, Right : Character;
      Scoring     : Scoring_Scheme := Default_Scoring) return Integer
   is
   begin
      if Left = Right then
         return Scoring.Match;
      else
         return Scoring.Mismatch;
      end if;
   end Pair_Score;

   --  Last row of NW scores for X vs Y into Dest(0 .. Y'Length).
   --  Dest(j) = F(|X|, j). Uses Prev/Curr scratch rows (O(|Y|) space).
   procedure NW_Last_Row
     (X, Y    : String;
      Scoring : Scoring_Scheme;
      Dest    : out Score_Row)
   is
      M : constant Natural := X'Length;
      N : constant Natural := Y'Length;
      Diag, Up, Left_S, Cell : Integer;
   begin
      for J in 0 .. N loop
         Prev (J) := J * Scoring.Gap;
      end loop;

      for I in 1 .. M loop
         Curr (0) := I * Scoring.Gap;
         for J in 1 .. N loop
            Diag   := Prev (J - 1)
              + Pair_Score (At_A (X, I), At_B (Y, J), Scoring);
            Up     := Prev (J) + Scoring.Gap;
            Left_S := Curr (J - 1) + Scoring.Gap;
            Cell   := Diag;
            if Up > Cell then
               Cell := Up;
            end if;
            if Left_S > Cell then
               Cell := Left_S;
            end if;
            Curr (J) := Cell;
         end loop;
         for J in 0 .. N loop
            Prev (J) := Curr (J);
         end loop;
      end loop;

      for J in 0 .. N loop
         Dest (J) := Prev (J);
      end loop;
   end NW_Last_Row;

   --  Optimal global score via two-row NW (swap so row length is shorter).
   function NW_Score
     (A, B    : String;
      Scoring : Scoring_Scheme) return Integer
   is
   begin
      if A'Length = 0 then
         return B'Length * Scoring.Gap;
      elsif B'Length = 0 then
         return A'Length * Scoring.Gap;
      elsif A'Length <= B'Length then
         NW_Last_Row (B, A, Scoring, Fwd);
         return Fwd (A'Length);
      else
         NW_Last_Row (A, B, Scoring, Fwd);
         return Fwd (B'Length);
      end if;
   end NW_Score;

   function Reversed (S : String) return String is
      R : String (1 .. S'Length);
   begin
      for I in 1 .. S'Length loop
         R (I) := S (S'Last - (I - 1));
      end loop;
      return R;
   end Reversed;

   function Slice_A (A : String; Lo, Hi : Natural) return String is
   begin
      if Lo = 0 or else Lo > Hi then
         return "";
      end if;
      return A (A'First + (Lo - 1) .. A'First + (Hi - 1));
   end Slice_A;

   function Slice_B (B : String; Lo, Hi : Natural) return String is
   begin
      if Lo = 0 or else Lo > Hi then
         return "";
      end if;
      return B (B'First + (Lo - 1) .. B'First + (Hi - 1));
   end Slice_B;

   --  Base-case alignment: empty side, or min(M,N) = 1.
   --  Uses O(M+N) predecessor storage (not a full Max_Len² matrix).
   procedure Align_Base
     (A, B                 : String;
      Scoring              : Scoring_Scheme;
      A_Aligned, B_Aligned : out Unbounded_String)
   is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
   begin
      A_Aligned := Null_Unbounded_String;
      B_Aligned := Null_Unbounded_String;

      if M = 0 and then N = 0 then
         return;
      elsif M = 0 then
         declare
            Gaps : constant String (1 .. N) := [others => '-'];
         begin
            A_Aligned := To_Unbounded_String (Gaps);
            B_Aligned := To_Unbounded_String
              (B (B'First .. B'First + N - 1));
            return;
         end;
      elsif N = 0 then
         declare
            Gaps : constant String (1 .. M) := [others => '-'];
         begin
            A_Aligned := To_Unbounded_String
              (A (A'First .. A'First + M - 1));
            B_Aligned := To_Unbounded_String (Gaps);
            return;
         end;
      end if;

      --  Unit-length NW with full small matrix allocated to actual M,N.
      declare
         type Pred_Kind is (Stop, From_Diag, From_Up, From_Left);
         type Score_Mat is array (0 .. M, 0 .. N) of Integer;
         type Pred_Mat  is array (0 .. M, 0 .. N) of Pred_Kind;
         F    : Score_Mat;
         P    : Pred_Mat;
         Diag : Integer;
         Up   : Integer;
         Left : Integer;
         Cell : Integer;
         Pred : Pred_Kind;
         I, J : Natural;
         Max_G : constant Natural := M + N;
         RA   : String (1 .. Max_G);
         RB   : String (1 .. Max_G);
         Len  : Natural := 0;
      begin
         F (0, 0) := 0;
         P (0, 0) := Stop;
         for JJ in 1 .. N loop
            F (0, JJ) := JJ * Scoring.Gap;
            P (0, JJ) := From_Left;
         end loop;
         for II in 1 .. M loop
            F (II, 0) := II * Scoring.Gap;
            P (II, 0) := From_Up;
         end loop;

         for II in 1 .. M loop
            for JJ in 1 .. N loop
               Diag := F (II - 1, JJ - 1)
                 + Pair_Score (At_A (A, II), At_B (B, JJ), Scoring);
               Up   := F (II - 1, JJ) + Scoring.Gap;
               Left := F (II, JJ - 1) + Scoring.Gap;
               Cell := Diag;
               Pred := From_Diag;
               if Up > Cell then
                  Cell := Up;
                  Pred := From_Up;
               end if;
               if Left > Cell then
                  Cell := Left;
                  Pred := From_Left;
               end if;
               F (II, JJ) := Cell;
               P (II, JJ) := Pred;
            end loop;
         end loop;

         I := M;
         J := N;
         while I > 0 or else J > 0 loop
            if I > 0 and then J > 0 and then P (I, J) = From_Diag then
               Len := Len + 1;
               RA (Len) := At_A (A, I);
               RB (Len) := At_B (B, J);
               I := I - 1;
               J := J - 1;
            elsif I > 0 and then (J = 0 or else P (I, J) = From_Up) then
               Len := Len + 1;
               RA (Len) := At_A (A, I);
               RB (Len) := '-';
               I := I - 1;
            else
               Len := Len + 1;
               RA (Len) := '-';
               RB (Len) := At_B (B, J);
               J := J - 1;
            end if;
         end loop;

         declare
            FA : String (1 .. Len);
            FB : String (1 .. Len);
         begin
            for K in 1 .. Len loop
               FA (K) := RA (Len - K + 1);
               FB (K) := RB (Len - K + 1);
            end loop;
            A_Aligned := To_Unbounded_String (FA);
            B_Aligned := To_Unbounded_String (FB);
         end;
      end;
   end Align_Base;

   procedure Hirschberg_Rec
     (A, B                 : String;
      Scoring              : Scoring_Scheme;
      A_Aligned, B_Aligned : out Unbounded_String)
   is
      M : constant Natural := A'Length;
      N : constant Natural := B'Length;
   begin
      if M = 0 or else N = 0 or else M = 1 or else N = 1 then
         Align_Base (A, B, Scoring, A_Aligned, B_Aligned);
         return;
      end if;

      declare
         Mid     : constant Positive := M / 2;
         Left_A  : constant String := Slice_A (A, 1, Mid);
         Right_A : constant String := Slice_A (A, Mid + 1, M);
         Rev_A   : constant String := Reversed (Right_A);
         Rev_B   : constant String := Reversed (B);
         Best_J  : Natural := 0;
         Best_S  : Integer;
         Cand    : Integer;
         Left_AA, Left_BB   : Unbounded_String;
         Right_AA, Right_BB : Unbounded_String;
      begin
         NW_Last_Row (Left_A, B, Scoring, Fwd);
         NW_Last_Row (Rev_A, Rev_B, Scoring, Rev);

         Best_S := Fwd (0) + Rev (N);
         Best_J := 0;
         for J in 1 .. N loop
            Cand := Fwd (J) + Rev (N - J);
            if Cand > Best_S then
               Best_S := Cand;
               Best_J := J;
            end if;
         end loop;

         Hirschberg_Rec
           (Left_A, Slice_B (B, 1, Best_J), Scoring, Left_AA, Left_BB);
         Hirschberg_Rec
           (Right_A, Slice_B (B, Best_J + 1, N), Scoring,
            Right_AA, Right_BB);

         A_Aligned := Left_AA & Right_AA;
         B_Aligned := Left_BB & Right_BB;
      end;
   end Hirschberg_Rec;

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer
   is
   begin
      Check_Bounds (A, B);
      return NW_Score (A, B, Scoring);
   end Best_Score;

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result
   is
      Result : Alignment_Result;
   begin
      Check_Bounds (A, B);
      Hirschberg_Rec (A, B, Scoring, Result.A_Aligned, Result.B_Aligned);
      --  Score from linear-space NW (equals Hirschberg path score).
      Result.Score := NW_Score (A, B, Scoring);
      return Result;
   end Align;

   procedure Align
     (A, B                 : String;
      Score                : out Integer;
      A_Aligned, B_Aligned : out Unbounded_String;
      Scoring              : Scoring_Scheme := Default_Scoring)
   is
      R : Alignment_Result;
   begin
      R := Align (A, B, Scoring);
      Score     := R.Score;
      A_Aligned := R.A_Aligned;
      B_Aligned := R.B_Aligned;
   end Align;

end Hirschbergs_Algorithm;
