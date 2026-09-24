--  Smith_Waterman body — fixed DP matrix pool, linear-gap local alignment.

pragma Ada_2022;

package body Smith_Waterman
  with SPARK_Mode => Off
is

   use Ada.Strings.Unbounded;

   subtype Idx is Natural range 0 .. Max_Len;

   type Score_Matrix is array (Idx, Idx) of Integer;

   type Pred_Kind is (Stop, From_Diag, From_Up, From_Left);
   type Pred_Matrix is array (Idx, Idx) of Pred_Kind;

   --  Fixed educational pool sized to Max_Len (not heap-allocated per call).
   H : Score_Matrix;
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

   --  Fill H / P for A vs B; return best score and argmax (Bi, Bj).
   --  First maximum in row-major order wins on ties.
   procedure Fill_DP
     (A, B    : String;
      Scoring : Scoring_Scheme;
      Best    : out Integer;
      Bi, Bj  : out Natural)
   is
      M    : constant Natural := A'Length;
      N    : constant Natural := B'Length;
      Diag : Integer;
      Up   : Integer;
      Left : Integer;
      Cell : Integer;
      Pred : Pred_Kind;
   begin
      Best := 0;
      Bi   := 0;
      Bj   := 0;

      for J in 0 .. N loop
         H (0, J) := 0;
         P (0, J) := Stop;
      end loop;
      for I in 1 .. M loop
         H (I, 0) := 0;
         P (I, 0) := Stop;
      end loop;

      for I in 1 .. M loop
         for J in 1 .. N loop
            Diag := H (I - 1, J - 1)
              + Pair_Score (At_A (A, I), At_B (B, J), Scoring);
            Up   := H (I - 1, J) + Scoring.Gap;
            Left := H (I, J - 1) + Scoring.Gap;

            --  Prefer diagonal, then up, then left on equal scores.
            Cell := 0;
            Pred := Stop;
            if Diag > Cell then
               Cell := Diag;
               Pred := From_Diag;
            end if;
            if Up > Cell then
               Cell := Up;
               Pred := From_Up;
            end if;
            if Left > Cell then
               Cell := Left;
               Pred := From_Left;
            end if;

            H (I, J) := Cell;
            P (I, J) := Pred;

            if Cell > Best then
               Best := Cell;
               Bi   := I;
               Bj   := J;
            end if;
         end loop;
      end loop;
   end Fill_DP;

   function Best_Score
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Integer
   is
      Best   : Integer;
      Bi, Bj : Natural;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 or else B'Length = 0 then
         return 0;
      end if;

      Fill_DP (A, B, Scoring, Best, Bi, Bj);
      return Best;
   end Best_Score;

   function Align
     (A, B    : String;
      Scoring : Scoring_Scheme := Default_Scoring) return Alignment_Result
   is
      Best   : Integer;
      Bi, Bj : Natural;
      I, J   : Natural;
      Result : Alignment_Result;
   begin
      Check_Bounds (A, B);

      if A'Length = 0 or else B'Length = 0 then
         return Result;
      end if;

      Fill_DP (A, B, Scoring, Best, Bi, Bj);
      Result.Score := Best;

      if Best = 0 then
         return Result;
      end if;

      --  Traceback from argmax until score hits 0 / Stop.
      I := Bi;
      J := Bj;
      while I > 0 and then J > 0 and then H (I, J) > 0 loop
         case P (I, J) is
            when From_Diag =>
               I := I - 1;
               J := J - 1;
            when From_Up =>
               I := I - 1;
            when From_Left =>
               J := J - 1;
            when Stop =>
               exit;
         end case;
      end loop;

      Result.A_Start := I + 1;
      Result.A_End   := Bi;
      Result.B_Start := J + 1;
      Result.B_End   := Bj;
      return Result;
   end Align;

   procedure Align
     (A, B                 : String;
      Score                : out Integer;
      A_Aligned, B_Aligned : out Unbounded_String;
      Scoring              : Scoring_Scheme := Default_Scoring)
   is
      Best   : Integer;
      Bi, Bj : Natural;
      I, J   : Natural;
      --  Build reverse then flip; max gapped length ≤ |A|+|B|.
      Max_G  : constant Natural := A'Length + B'Length;
      RA     : String (1 .. Max_G);
      RB     : String (1 .. Max_G);
      Len    : Natural := 0;
   begin
      Check_Bounds (A, B);
      A_Aligned := Null_Unbounded_String;
      B_Aligned := Null_Unbounded_String;
      Score     := 0;

      if A'Length = 0 or else B'Length = 0 then
         return;
      end if;

      Fill_DP (A, B, Scoring, Best, Bi, Bj);
      Score := Best;

      if Best = 0 then
         return;
      end if;

      I := Bi;
      J := Bj;
      while I > 0 and then J > 0 and then H (I, J) > 0 loop
         case P (I, J) is
            when From_Diag =>
               Len := Len + 1;
               RA (Len) := At_A (A, I);
               RB (Len) := At_B (B, J);
               I := I - 1;
               J := J - 1;
            when From_Up =>
               Len := Len + 1;
               RA (Len) := At_A (A, I);
               RB (Len) := '-';
               I := I - 1;
            when From_Left =>
               Len := Len + 1;
               RA (Len) := '-';
               RB (Len) := At_B (B, J);
               J := J - 1;
            when Stop =>
               exit;
         end case;
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
   end Align;

end Smith_Waterman;
