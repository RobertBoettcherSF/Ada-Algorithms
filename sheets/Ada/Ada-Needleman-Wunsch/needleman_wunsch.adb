--  Needleman_Wunsch body — fixed DP matrix pool, linear-gap global alignment.

pragma Ada_2022;

package body Needleman_Wunsch
  with SPARK_Mode => Off
is

   use Ada.Strings.Unbounded;

   subtype Idx is Natural range 0 .. Max_Len;

   type Score_Matrix is array (Idx, Idx) of Integer;

   type Pred_Kind is (Stop, From_Diag, From_Up, From_Left);
   type Pred_Matrix is array (Idx, Idx) of Pred_Kind;

   --  Fixed educational pool sized to Max_Len (not heap-allocated per call).
   F : Score_Matrix;
   P : Pred_Matrix;

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

   --  Fill F / P for A vs B (global NW). Score is always F(M,N).
   procedure Fill_DP
     (A, B    : String;
      Scoring : Scoring_Scheme)
   is
      M    : constant Natural := A'Length;
      N    : constant Natural := B'Length;
      Diag : Integer;
      Up   : Integer;
      Left : Integer;
      Cell : Integer;
      Pred : Pred_Kind;
   begin
      F (0, 0) := 0;
      P (0, 0) := Stop;

      for J in 1 .. N loop
         F (0, J) := J * Scoring.Gap;
         P (0, J) := From_Left;
      end loop;
      for I in 1 .. M loop
         F (I, 0) := I * Scoring.Gap;
         P (I, 0) := From_Up;
      end loop;

      for I in 1 .. M loop
         for J in 1 .. N loop
            Diag := F (I - 1, J - 1)
              + Pair_Score (At_A (A, I), At_B (B, J), Scoring);
            Up   := F (I - 1, J) + Scoring.Gap;
            Left := F (I, J - 1) + Scoring.Gap;

            --  Prefer diagonal, then up, then left on equal scores.
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

            F (I, J) := Cell;
            P (I, J) := Pred;
         end loop;
      end loop;
   end Fill_DP;

   --  Traceback from (M,N) to (0,0); build reverse then flip.
   procedure Traceback
     (A, B                 : String;
      A_Aligned, B_Aligned : out Unbounded_String)
   is
      M     : constant Natural := A'Length;
      N     : constant Natural := B'Length;
      I, J  : Natural;
      Max_G : constant Natural := M + N;
      RA    : String (1 .. Max_G);
      RB    : String (1 .. Max_G);
      Len   : Natural := 0;
   begin
      A_Aligned := Null_Unbounded_String;
      B_Aligned := Null_Unbounded_String;

      if M = 0 and then N = 0 then
         return;
      end if;

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
            --  From_Left, or J > 0 on the top border.
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
   end Traceback;

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer
   is
   begin
      Check_Bounds (A, B);
      Fill_DP (A, B, Scoring);
      return F (A'Length, B'Length);
   end Best_Score;

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result
   is
      Result : Alignment_Result;
   begin
      Check_Bounds (A, B);
      Fill_DP (A, B, Scoring);
      Result.Score := F (A'Length, B'Length);
      Traceback (A, B, Result.A_Aligned, Result.B_Aligned);
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

end Needleman_Wunsch;
