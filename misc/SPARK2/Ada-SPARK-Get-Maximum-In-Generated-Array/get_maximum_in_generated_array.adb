pragma Ada_2022;
package body Get_Maximum_In_Generated_Array with SPARK_Mode => On is

   --  The second component of the pair for I is the first one for I + 1.
   procedure Lemma_Next (I : N_Value)
   with
     Ghost,
     Global             => null,
     Pre                => I < Max_N,
     Post               => Nums_Pair (I).Next = Nums_Pair (I + 1).This,
     Subprogram_Variant => (Decreases => I);

   procedure Lemma_Next (I : N_Value) is
   begin
      if I mod 2 = 1 then
         Lemma_Next (I / 2);
      end if;
   end Lemma_Next;

   procedure Lemma_Rules (I : N_Value) is
   begin
      if I >= 2 and then I mod 2 = 1 then
         Lemma_Next (I / 2);
      end if;
   end Lemma_Rules;

   function Generate (N : N_Value) return Value_Array is
      A : Value_Array (0 .. N) := [others => 0];
   begin
      if N >= 1 then
         A (1) := 1;
      end if;
      for I in 2 .. N loop
         pragma Loop_Invariant (for all J in 0 .. I - 1 => A (J) = Nums (J));
         Lemma_Rules (I);
         if I mod 2 = 0 then
            A (I) := A (I / 2);
         else
            A (I) := A (I / 2) + A (I / 2 + 1);
         end if;
      end loop;
      return A;
   end Generate;

   function Maximum (N : N_Value) return Natural is
      A    : constant Value_Array := Generate (N);
      Best : Natural := 0;
      At_I : N_Value := 0 with Ghost;
   begin
      for I in 0 .. N loop
         if A (I) > Best then
            Best := A (I);
            At_I := I;
         end if;
         pragma Loop_Invariant (for all J in 0 .. I => A (J) <= Best);
         pragma Loop_Invariant (At_I <= I and then A (At_I) = Best);
      end loop;
      return Best;
   end Maximum;
end Get_Maximum_In_Generated_Array;
