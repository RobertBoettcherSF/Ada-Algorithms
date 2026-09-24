--  BLAST body — pedagogical seed + X-drop + optional Smith–Waterman.

pragma Ada_2022;

package body BLAST
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function To_Upper_ACGT (C : Character) return Character is
   begin
      case C is
         when 'a' | 'A' => return 'A';
         when 'c' | 'C' => return 'C';
         when 'g' | 'G' => return 'G';
         when 't' | 'T' => return 'T';
         when others    => return C;
      end case;
   end To_Upper_ACGT;

   function Window_All_ACGT (S : String; First, Last : Positive) return Boolean
   is
   begin
      for I in First .. Last loop
         if not Is_ACGT (S (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Window_All_ACGT;

   function Equal_Wmer
     (A : String; A0 : Positive;
      B : String; B0 : Positive;
      W : Positive) return Boolean
   is
   begin
      for K in 0 .. W - 1 loop
         if To_Upper_ACGT (A (A0 + K)) /= To_Upper_ACGT (B (B0 + K)) then
            return False;
         end if;
      end loop;
      return True;
   end Equal_Wmer;

   function Intervals_Overlap
     (A0, A1, B0, B1 : Positive) return Boolean
   is
   begin
      return not (A1 < B0 or else B1 < A0);
   end Intervals_Overlap;

   -------------------------------------------------------------------------
   -- Public helpers
   -------------------------------------------------------------------------

   function Is_ACGT (C : Character) return Boolean is
   begin
      case C is
         when 'A' | 'a' | 'C' | 'c' | 'G' | 'g' | 'T' | 't' =>
            return True;
         when others =>
            return False;
      end case;
   end Is_ACGT;

   function Normalize_Base (C : Character) return Character is
      U : constant Character := To_Upper_ACGT (C);
   begin
      if U = 'A' or else U = 'C' or else U = 'G' or else U = 'T' then
         return U;
      end if;
      raise Invalid_Argument with "Normalize_Base: non-ACGT character";
   end Normalize_Base;

   function Normalize_Sequence (S : String) return String is
      R : String (1 .. S'Length);
   begin
      if S'Length > Max_Seq_Len then
         raise Invalid_Argument with "Normalize_Sequence: sequence too long";
      end if;
      for I in S'Range loop
         R (I - S'First + 1) := Normalize_Base (S (I));
      end loop;
      return R;
   end Normalize_Sequence;

   function All_ACGT (S : String) return Boolean is
   begin
      for C of S loop
         if not Is_ACGT (C) then
            return False;
         end if;
      end loop;
      return True;
   end All_ACGT;

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Pair_Score
     (A, B   : Character;
      Params : Score_Params := Default_Scores) return Integer
   is
   begin
      if Is_ACGT (A) and then Is_ACGT (B)
        and then To_Upper_ACGT (A) = To_Upper_ACGT (B)
      then
         return Params.Match;
      end if;
      return Params.Mismatch;
   end Pair_Score;

   function Ungapped_Score
     (Query, Subject : String;
      Params         : Score_Params := Default_Scores) return Integer
   is
      N     : Natural;
      Total : Integer := 0;
      QI, SI : Positive;
   begin
      if Query'Length > Max_Seq_Len or else Subject'Length > Max_Seq_Len then
         raise Invalid_Argument with "Ungapped_Score: sequence too long";
      end if;
      if Query'Length < Subject'Length then
         N := Query'Length;
      else
         N := Subject'Length;
      end if;
      for K in 0 .. N - 1 loop
         QI := Query'First + K;
         SI := Subject'First + K;
         Total := Total + Pair_Score (Query (QI), Subject (SI), Params);
      end loop;
      return Total;
   end Ungapped_Score;

   function HSP_Length (H : HSP_Record) return Natural is
   begin
      if H.Q_End < H.Q_Start then
         return 0;
      end if;
      return Natural (H.Q_End - H.Q_Start + 1);
   end HSP_Length;

   function HSPs_Overlap (A, B : HSP_Record) return Boolean is
   begin
      return Intervals_Overlap (A.Q_Start, A.Q_End, B.Q_Start, B.Q_End)
        and then Intervals_Overlap
          (A.S_Start, A.S_End, B.S_Start, B.S_End);
   end HSPs_Overlap;

   function Best_HSP (List : HSP_List) return HSP_Record is
      Best : HSP_Record;
   begin
      if List.Count = 0 then
         return (Q_Start => 1, Q_End => 1, S_Start => 1, S_End => 1,
                 Score => 0);
      end if;
      Best := List.HSPs (1);
      for I in 2 .. List.Count loop
         if List.HSPs (I).Score > Best.Score then
            Best := List.HSPs (I);
         end if;
      end loop;
      return Best;
   end Best_HSP;

   -------------------------------------------------------------------------
   -- Word index
   -------------------------------------------------------------------------

   function Build_Index
     (Subject : String;
      W       : Word_Length) return Word_Index
   is
      Idx : Word_Index;
      Len : constant Natural := Subject'Length;
      Pos : Positive;
   begin
      if Len > Max_Seq_Len then
         raise Invalid_Argument with "Build_Index: Subject too long";
      end if;
      Idx.W := W;
      Idx.Subject_Len := Len;
      Idx.Count := 0;
      if Len = 0 then
         return Idx;
      end if;
      --  Copy / normalize into 1 .. Len buffer.
      for I in Subject'Range loop
         Idx.Subject (I - Subject'First + 1) := To_Upper_ACGT (Subject (I));
      end loop;
      if Len < W then
         return Idx;
      end if;
      for Start in 1 .. Len - W + 1 loop
         if Window_All_ACGT (Idx.Subject, Start, Start + W - 1) then
            if Idx.Count >= Max_Seq_Len then
               raise Capacity_Exceeded with "Build_Index: too many k-mers";
            end if;
            Idx.Count := Idx.Count + 1;
            Pos := Start;
            Idx.Positions (Idx.Count) := Pos;
         end if;
      end loop;
      return Idx;
   end Build_Index;

   function Index_W (Idx : Word_Index) return Word_Length is
   begin
      return Idx.W;
   end Index_W;

   function Index_Subject_Length (Idx : Word_Index) return Seq_Length is
   begin
      return Idx.Subject_Len;
   end Index_Subject_Length;

   function Index_Entry_Count (Idx : Word_Index) return Natural is
   begin
      return Idx.Count;
   end Index_Entry_Count;

   -------------------------------------------------------------------------
   -- Word hits
   -------------------------------------------------------------------------

   function Find_Word_Hits
     (Idx   : Word_Index;
      Query : String) return Hit_List
   is
      Result : Hit_List;
      QLen   : constant Natural := Query'Length;
      W      : constant Word_Length := Idx.W;
      QBuf   : String (1 .. Max_Seq_Len) := [others => ' '];
      SPos   : Positive;
   begin
      if QLen > Max_Seq_Len then
         raise Invalid_Argument with "Find_Word_Hits: Query too long";
      end if;
      Result.Count := 0;
      if QLen < W or else Idx.Subject_Len < W or else Idx.Count = 0 then
         return Result;
      end if;
      for I in Query'Range loop
         QBuf (I - Query'First + 1) := To_Upper_ACGT (Query (I));
      end loop;
      for QStart in 1 .. QLen - W + 1 loop
         if Window_All_ACGT (QBuf, QStart, QStart + W - 1) then
            for E in 1 .. Idx.Count loop
               SPos := Idx.Positions (E);
               if Equal_Wmer
                    (QBuf, QStart, Idx.Subject, SPos, W)
               then
                  if Result.Count >= Max_Hits then
                     raise Capacity_Exceeded
                       with "Find_Word_Hits: Max_Hits exceeded";
                  end if;
                  Result.Count := Result.Count + 1;
                  Result.Hits (Result.Count) :=
                    (Q_Start => QStart, S_Start => SPos);
               end if;
            end loop;
         end if;
      end loop;
      return Result;
   end Find_Word_Hits;

   -------------------------------------------------------------------------
   -- Ungapped X-drop extension
   -------------------------------------------------------------------------

   function Extend_HSP
     (Query, Subject : String;
      Q_Seed, S_Seed : Positive;
      W              : Word_Length;
      X_Drop         : Natural;
      Params         : Score_Params := Default_Scores) return HSP_Record
   is
      QLen : constant Natural := Query'Length;
      SLen : constant Natural := Subject'Length;
      QBuf : String (1 .. Max_Seq_Len) := [others => ' '];
      SBuf : String (1 .. Max_Seq_Len) := [others => ' '];
      Q_Off : constant Integer := Query'First - 1;
      S_Off : constant Integer := Subject'First - 1;
      QS, SS : Positive;
      Seed_Score : Integer := 0;
      Right_Best, Left_Best, Combined : Integer;
      Right_QR, Right_SR, Left_QL, Left_SL : Positive;
      QR, SR, QL, SL : Positive;
      Run : Integer;
   begin
      if QLen = 0 or else SLen = 0 then
         raise Invalid_Argument with "Extend_HSP: empty sequence";
      end if;
      if QLen > Max_Seq_Len or else SLen > Max_Seq_Len then
         raise Invalid_Argument with "Extend_HSP: sequence too long";
      end if;
      if Q_Seed < Query'First
        or else S_Seed < Subject'First
        or else Q_Seed > Query'Last
        or else S_Seed > Subject'Last
        or else Q_Seed + W - 1 > Query'Last
        or else S_Seed + W - 1 > Subject'Last
      then
         raise Invalid_Argument with "Extend_HSP: seed out of range";
      end if;
      QS := Q_Seed - Q_Off;
      SS := S_Seed - S_Off;

      for I in Query'Range loop
         QBuf (I - Q_Off) := To_Upper_ACGT (Query (I));
      end loop;
      for I in Subject'Range loop
         SBuf (I - S_Off) := To_Upper_ACGT (Subject (I));
      end loop;

      for K in 0 .. W - 1 loop
         Seed_Score := Seed_Score
           + Pair_Score (QBuf (QS + K), SBuf (SS + K), Params);
      end loop;

      --  Right X-drop from after the seed.
      Right_Best := Seed_Score;
      Right_QR := QS + W - 1;
      Right_SR := SS + W - 1;
      QR := Right_QR;
      SR := Right_SR;
      Run := Seed_Score;
      while QR < QLen and then SR < SLen loop
         QR := QR + 1;
         SR := SR + 1;
         Run := Run + Pair_Score (QBuf (QR), SBuf (SR), Params);
         if Run > Right_Best then
            Right_Best := Run;
            Right_QR := QR;
            Right_SR := SR;
         end if;
         if Run < Right_Best - Integer (X_Drop) then
            exit;
         end if;
      end loop;

      --  Left X-drop from before the seed.
      Left_Best := Seed_Score;
      Left_QL := QS;
      Left_SL := SS;
      QL := Left_QL;
      SL := Left_SL;
      Run := Seed_Score;
      while QL > 1 and then SL > 1 loop
         QL := QL - 1;
         SL := SL - 1;
         Run := Run + Pair_Score (QBuf (QL), SBuf (SL), Params);
         if Run > Left_Best then
            Left_Best := Run;
            Left_QL := QL;
            Left_SL := SL;
         end if;
         if Run < Left_Best - Integer (X_Drop) then
            exit;
         end if;
      end loop;

      --  left_gain + seed + right_gain
      Combined := Left_Best + Right_Best - Seed_Score;

      return
        (Q_Start => Left_QL + Q_Off,
         Q_End   => Right_QR + Q_Off,
         S_Start => Left_SL + S_Off,
         S_End   => Right_SR + S_Off,
         Score   => Combined);
   end Extend_HSP;

   -------------------------------------------------------------------------
   -- Dedup / sort helpers for Search
   -------------------------------------------------------------------------

   procedure Sort_By_Score_Desc (List : in out HSP_List) is
      Tmp : HSP_Record;
   begin
      for I in 1 .. List.Count loop
         for J in I + 1 .. List.Count loop
            if List.HSPs (J).Score > List.HSPs (I).Score then
               Tmp := List.HSPs (I);
               List.HSPs (I) := List.HSPs (J);
               List.HSPs (J) := Tmp;
            end if;
         end loop;
      end loop;
   end Sort_By_Score_Desc;

   function Deduplicate (List : HSP_List) return HSP_List is
      Out_L : HSP_List;
      Keep  : Boolean;
   begin
      Out_L.Count := 0;
      for I in 1 .. List.Count loop
         Keep := True;
         for J in 1 .. Out_L.Count loop
            if HSPs_Overlap (List.HSPs (I), Out_L.HSPs (J)) then
               if List.HSPs (I).Score > Out_L.HSPs (J).Score then
                  Out_L.HSPs (J) := List.HSPs (I);
               end if;
               Keep := False;
               exit;
            end if;
         end loop;
         if Keep then
            if Out_L.Count >= Max_HSPs then
               exit;
            end if;
            Out_L.Count := Out_L.Count + 1;
            Out_L.HSPs (Out_L.Count) := List.HSPs (I);
         end if;
      end loop;
      return Out_L;
   end Deduplicate;

   -------------------------------------------------------------------------
   -- Search pipeline
   -------------------------------------------------------------------------

   function Search
     (Query, Subject : String;
      W              : Word_Length  := 3;
      X_Drop         : Natural      := 16;
      Min_Score      : Integer      := 1;
      Max_Results    : Positive     := Max_HSPs;
      Params         : Score_Params := Default_Scores) return HSP_List
   is
      Idx   : Word_Index;
      Hits  : Hit_List;
      Raw   : HSP_List;
      H     : HSP_Record;
      Out_L : HSP_List;
      Limit : Positive;
   begin
      if Query'Length > Max_Seq_Len or else Subject'Length > Max_Seq_Len then
         raise Invalid_Argument with "Search: sequence too long";
      end if;
      if Max_Results > Max_HSPs then
         raise Invalid_Argument with "Search: Max_Results > Max_HSPs";
      end if;
      Limit := Max_Results;
      Idx := Build_Index (Subject, W);
      Hits := Find_Word_Hits (Idx, Query);
      Raw.Count := 0;
      for I in 1 .. Hits.Count loop
         H := Extend_HSP
           (Query, Subject,
            Hits.Hits (I).Q_Start, Hits.Hits (I).S_Start,
            W, X_Drop, Params);
         if H.Score >= Min_Score and then Raw.Count < Max_HSPs then
            Raw.Count := Raw.Count + 1;
            Raw.HSPs (Raw.Count) := H;
         end if;
      end loop;
      Out_L := Deduplicate (Raw);
      Sort_By_Score_Desc (Out_L);
      if Out_L.Count > Limit then
         Out_L.Count := Limit;
      end if;
      return Out_L;
   end Search;

   -------------------------------------------------------------------------
   -- Smith–Waterman (linear gap)
   -------------------------------------------------------------------------

   function Smith_Waterman_Local
     (Query, Subject : String;
      Params         : Score_Params := Default_Scores) return SW_Result
   is
      QLen : constant Natural := Query'Length;
      SLen : constant Natural := Subject'Length;
      type Matrix is array
        (0 .. Max_Seq_Len, 0 .. Max_Seq_Len) of Integer;
      --  Allocate on heap via access to avoid huge stack frames.
      type Matrix_Access is access Matrix;
      H : Matrix_Access;
      Best : Integer := 0;
      Bi, Bj : Natural := 0;
      QBuf : String (1 .. Max_Seq_Len) := [others => ' '];
      SBuf : String (1 .. Max_Seq_Len) := [others => ' '];
      Diag, Up, Left, Cell : Integer;
      Result : SW_Result;
      --  Traceback via storing predecessor codes.
      type Pred_Kind is (None, Diag_P, Up_P, Left_P);
      type Pred_Matrix is array
        (0 .. Max_Seq_Len, 0 .. Max_Seq_Len) of Pred_Kind;
      type Pred_Access is access Pred_Matrix;
      P : Pred_Access;
      I, J : Natural;
      Q_Off : constant Integer := Query'First - 1;
      S_Off : constant Integer := Subject'First - 1;
   begin
      if QLen = 0 or else SLen = 0 then
         raise Invalid_Argument with "Smith_Waterman_Local: empty sequence";
      end if;
      if QLen > Max_Seq_Len or else SLen > Max_Seq_Len then
         raise Invalid_Argument with "Smith_Waterman_Local: too long";
      end if;
      for K in Query'Range loop
         QBuf (K - Q_Off) := To_Upper_ACGT (Query (K));
      end loop;
      for K in Subject'Range loop
         SBuf (K - S_Off) := To_Upper_ACGT (Subject (K));
      end loop;

      H := new Matrix'(others => [others => 0]);
      P := new Pred_Matrix'(others => [others => None]);

      for Ii in 1 .. QLen loop
         for Jj in 1 .. SLen loop
            Diag := H (Ii - 1, Jj - 1)
              + Pair_Score (QBuf (Ii), SBuf (Jj), Params);
            Up := H (Ii - 1, Jj) + Params.Gap;
            Left := H (Ii, Jj - 1) + Params.Gap;
            Cell := 0;
            P (Ii, Jj) := None;
            if Diag > Cell then
               Cell := Diag;
               P (Ii, Jj) := Diag_P;
            end if;
            if Up > Cell then
               Cell := Up;
               P (Ii, Jj) := Up_P;
            end if;
            if Left > Cell then
               Cell := Left;
               P (Ii, Jj) := Left_P;
            end if;
            H (Ii, Jj) := Cell;
            if Cell > Best then
               Best := Cell;
               Bi := Ii;
               Bj := Jj;
            end if;
         end loop;
      end loop;

      Result.Score := Best;
      if Best = 0 then
         Result.Q_Start := Query'First;
         Result.Q_End   := Query'First;
         Result.S_Start := Subject'First;
         Result.S_End   := Subject'First;
         return Result;
      end if;

      --  Traceback to local start.
      I := Bi;
      J := Bj;
      while I > 0 and then J > 0 and then H (I, J) > 0 loop
         case P (I, J) is
            when Diag_P =>
               I := I - 1;
               J := J - 1;
            when Up_P =>
               I := I - 1;
            when Left_P =>
               J := J - 1;
            when None =>
               exit;
         end case;
      end loop;
      --  After leaving the path, start is one step forward.
      Result.Q_Start := I + 1 + Q_Off;
      Result.S_Start := J + 1 + S_Off;
      Result.Q_End   := Bi + Q_Off;
      Result.S_End   := Bj + S_Off;
      return Result;
   end Smith_Waterman_Local;

end BLAST;
