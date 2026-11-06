pragma Ada_2022;

package body Quick_Sort with SPARK_Mode => On is

   procedure Swap (A : in out Input_Array; X, Y : Index) is
      T : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := T;
   end Swap;

   --  Lomuto partition of A (Lo .. Hi). The pivot is A (Hi). On return
   --  P is the pivot's index, A (Lo .. P - 1) <= A (P), and
   --  A (P + 1 .. Hi) >= A (P). Cells outside Lo .. Hi are untouched.
   procedure Partition_Range (A : in out Input_Array; Lo, Hi : Index; P : out Index) is
      Pivot : constant Value := A (Hi);
      I     : Index := Lo;
      J     : Index := Lo;
   begin
      while J < Hi loop
         pragma Loop_Invariant (J in Lo .. Hi - 1);
         pragma Loop_Invariant (I in Lo .. J);
         pragma Loop_Invariant (A (Hi) = Pivot);
         pragma Loop_Invariant
           (for all K in Lo .. Hi => (if K < I then A (K) <= Pivot));
         pragma Loop_Invariant
           (for all K in Lo .. Hi =>
              (if K >= I and then K < J then A (K) > Pivot));
         pragma Loop_Invariant
           (for all K in Index'First .. Lo - 1 => A (K) = A'Loop_Entry (K));
         pragma Loop_Invariant
           (for all K in Hi + 1 .. Index'Last => A (K) = A'Loop_Entry (K));
         pragma Loop_Variant (Increases => J);

         if A (J) <= Pivot then
            Swap (A, I, J);
            I := I + 1;
         end if;
         J := J + 1;
      end loop;

      Swap (A, I, Hi);
      P := I;
   end Partition_Range;

   procedure Sort_Range (A : in out Input_Array; Lo, Hi : Index)
   with
     Global             => null,
     Pre                => Lo <= Hi,
     Post               =>
       (for all K in Index'First .. Lo - 1 => A (K) = A'Old (K))
       and then (for all K in Hi + 1 .. Index'Last => A (K) = A'Old (K)),
     Subprogram_Variant => (Decreases => Hi - Lo)
   is
      P : Index;
   begin
      if Lo = Hi then
         return;
      end if;

      Partition_Range (A, Lo, Hi, P);

      if P > Lo then
         Sort_Range (A, Lo, P - 1);
      end if;
      if P < Hi then
         Sort_Range (A, P + 1, Hi);
      end if;
   end Sort_Range;

   function Sort (Input : Input_Array) return Input_Array is
      Work : Input_Array := Input;
   begin
      Sort_Range (Work, Index'First, Index'Last);
      return Work;
   end Sort;

   procedure Partition
     (Input : Input_Array; Output : out Input_Array; Pivot_Index : out Index)
   is
      Work : Input_Array := Input;
   begin
      Partition_Range (Work, Index'First, Index'Last, Pivot_Index);
      Output := Work;
   end Partition;

end Quick_Sort;
