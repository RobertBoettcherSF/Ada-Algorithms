--  Ruzzo_Tompa body — I-list / stack-style Ruzzo–Tompa scan plus
--  Max_Segment (best RT segment, or Kadane singleton when all nonpositive).

pragma Ada_2022;

package body Ruzzo_Tompa is

   procedure Check_Input_Length (Len : Natural) is
   begin
      if Len = 0 or else Len > Max_Length then
         raise Invalid_Argument;
      end if;
   end Check_Input_Length;

   --  Element of A at 1-based logical position I.
   function Elem_At (A : Element_Array; I : Positive) return Element is
     (A (A'First + (I - 1)));

   function Elem_At (A : Real_Array; I : Positive) return Long_Float is
     (A (A'First + (I - 1)));

   ------------------------------------------------------------------
   -- Integer Ruzzo–Tompa (I-list)
   ------------------------------------------------------------------
   --  Maintain ordered list I_1 .. I_k of disjoint candidate segments.
   --  For each I_j store:
   --    L_j = prefix sum of scores strictly before First of I_j
   --    R_j = prefix sum through Last of I_j
   --    Lidx_j = 0-based start index (First - 1)
   --  Nonpositive scores only advance the running prefix sum.
   --  A positive score seeds a length-1 I_k and is integrated by searching
   --  right-to-left for the largest j with L_j < L_k; if R_j < R_k the
   --  new segment absorbs I_j .. I_{k-1} and the merge is reconsidered
   --  (stack/I-list style). Remaining I entries are maximal.

   function Maximal_Segments (A : Element_Array) return Segment_Array is
      N : constant Natural := A'Length;
   begin
      Check_Input_Length (N);

      declare
         --  I-list working stores (0-based slot indices 0 .. N-1).
         I_First : array (0 .. N - 1) of Natural;
         I_Last  : array (0 .. N - 1) of Natural;  -- exclusive end, 0-based
         L_Arr   : array (0 .. N - 1) of Long_Integer;
         R_Arr   : array (0 .. N - 1) of Long_Integer;
         Lidx    : array (0 .. N - 1) of Natural;
         K       : Natural := 0;  -- next free slot / length of I-list
         Total   : Long_Integer := 0;
      begin
         for I in 1 .. N loop
            declare
               S : constant Element := Elem_At (A, I);
               --  0-based index matching the Wikipedia Python loop variable.
               Idx : constant Natural := I - 1;
            begin
               Total := Total + Long_Integer (S);
               if S > 0 then
                  I_First (K) := Idx;
                  I_Last (K)  := Idx + 1;
                  Lidx (K)    := Idx;
                  L_Arr (K)   := Total - Long_Integer (S);
                  R_Arr (K)   := Total;

                  Integrate :
                  loop
                     declare
                        Max_J   : Integer := -1;
                        L_K     : constant Long_Integer := L_Arr (K);
                        R_K     : constant Long_Integer := R_Arr (K);
                     begin
                        for J in reverse 0 .. Integer (K) - 1 loop
                           if L_Arr (J) < L_K then
                              Max_J := J;
                              exit;
                           end if;
                        end loop;

                        if Max_J >= 0 and then R_Arr (Max_J) < R_K then
                           I_First (Max_J) := Lidx (Max_J);
                           I_Last (Max_J)  := Idx + 1;
                           R_Arr (Max_J)   := Total;
                           K := Natural (Max_J);
                        else
                           K := K + 1;
                           exit Integrate;
                        end if;
                     end;
                  end loop Integrate;
               end if;
            end;
         end loop;

         declare
            Result : Segment_Array (1 .. K);
         begin
            for J in 0 .. Integer (K) - 1 loop
               declare
                  F0 : constant Natural := I_First (J);
                  L0 : constant Natural := I_Last (J);  -- exclusive
                  Sc : Element := 0;
               begin
                  for P in F0 .. L0 - 1 loop
                     Sc := Sc + Elem_At (A, P + 1);
                  end loop;
                  Result (J + 1) :=
                    (First => F0 + 1,
                     Last  => L0,
                     Score => Sc);
               end;
            end loop;
            return Result;
         end;
      end;
   end Maximal_Segments;

   ------------------------------------------------------------------
   -- Long_Float Ruzzo–Tompa
   ------------------------------------------------------------------

   function Maximal_Segments (A : Real_Array) return Real_Segment_Array is
      N : constant Natural := A'Length;
   begin
      Check_Input_Length (N);

      declare
         I_First : array (0 .. N - 1) of Natural;
         I_Last  : array (0 .. N - 1) of Natural;
         L_Arr   : array (0 .. N - 1) of Long_Float;
         R_Arr   : array (0 .. N - 1) of Long_Float;
         Lidx    : array (0 .. N - 1) of Natural;
         K       : Natural := 0;
         Total   : Long_Float := 0.0;
      begin
         for I in 1 .. N loop
            declare
               S   : constant Long_Float := Elem_At (A, I);
               Idx : constant Natural := I - 1;
            begin
               Total := Total + S;
               if S > 0.0 then
                  I_First (K) := Idx;
                  I_Last (K)  := Idx + 1;
                  Lidx (K)    := Idx;
                  L_Arr (K)   := Total - S;
                  R_Arr (K)   := Total;

                  Integrate :
                  loop
                     declare
                        Max_J : Integer := -1;
                        L_K   : constant Long_Float := L_Arr (K);
                        R_K   : constant Long_Float := R_Arr (K);
                     begin
                        for J in reverse 0 .. Integer (K) - 1 loop
                           if L_Arr (J) < L_K then
                              Max_J := J;
                              exit;
                           end if;
                        end loop;

                        if Max_J >= 0 and then R_Arr (Max_J) < R_K then
                           I_First (Max_J) := Lidx (Max_J);
                           I_Last (Max_J)  := Idx + 1;
                           R_Arr (Max_J)   := Total;
                           K := Natural (Max_J);
                        else
                           K := K + 1;
                           exit Integrate;
                        end if;
                     end;
                  end loop Integrate;
               end if;
            end;
         end loop;

         declare
            Result : Real_Segment_Array (1 .. K);
         begin
            for J in 0 .. Integer (K) - 1 loop
               declare
                  F0 : constant Natural := I_First (J);
                  L0 : constant Natural := I_Last (J);
                  Sc : Long_Float := 0.0;
               begin
                  for P in F0 .. L0 - 1 loop
                     Sc := Sc + Elem_At (A, P + 1);
                  end loop;
                  Result (J + 1) :=
                    (First => F0 + 1,
                     Last  => L0,
                     Score => Sc);
               end;
            end loop;
            return Result;
         end;
      end;
   end Maximal_Segments;

   ------------------------------------------------------------------
   -- Max_Segment (Integer): best RT segment or Kadane singleton
   ------------------------------------------------------------------

   function Max_Segment (A : Element_Array) return Segment is
      Segs : constant Segment_Array := Maximal_Segments (A);
   begin
      if Segs'Length > 0 then
         declare
            Best : Segment := Segs (Segs'First);
         begin
            for S of Segs loop
               if S.Score > Best.Score then
                  Best := S;
               end if;
            end loop;
            return Best;
         end;
      end if;

      --  All nonpositive: Kadane nonempty — least-negative singleton.
      declare
         Best_Idx : Positive := 1;
         Best_Val : Element := Elem_At (A, 1);
         N        : constant Positive := A'Length;
      begin
         for I in 2 .. N loop
            declare
               X : constant Element := Elem_At (A, I);
            begin
               if X > Best_Val then
                  Best_Val := X;
                  Best_Idx := I;
               end if;
            end;
         end loop;
         return (First => Best_Idx, Last => Best_Idx, Score => Best_Val);
      end;
   end Max_Segment;

   function Max_Segment (A : Real_Array) return Real_Segment is
      Segs : constant Real_Segment_Array := Maximal_Segments (A);
   begin
      if Segs'Length > 0 then
         declare
            Best : Real_Segment := Segs (Segs'First);
         begin
            for S of Segs loop
               if S.Score > Best.Score then
                  Best := S;
               end if;
            end loop;
            return Best;
         end;
      end if;

      declare
         Best_Idx : Positive := 1;
         Best_Val : Long_Float := Elem_At (A, 1);
         N        : constant Positive := A'Length;
      begin
         for I in 2 .. N loop
            declare
               X : constant Long_Float := Elem_At (A, I);
            begin
               if X > Best_Val then
                  Best_Val := X;
                  Best_Idx := I;
               end if;
            end;
         end loop;
         return (First => Best_Idx, Last => Best_Idx, Score => Best_Val);
      end;
   end Max_Segment;

end Ruzzo_Tompa;
