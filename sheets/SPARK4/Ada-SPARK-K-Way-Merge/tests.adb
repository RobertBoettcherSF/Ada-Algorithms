--  Standalone test suite for K_Way_Merge (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Sortedness is proved by SPARK; multiset / permutation equality is
--  checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with K_Way_Merge; use K_Way_Merge;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Nat (X : Natural) return Natural is (X);
   function Boo (X : Boolean) return Boolean is (X);

   procedure Reference_Sort (A : in out Element_Array) is
   begin
      if A'Length <= 1 then
         return;
      end if;
      for I in A'First + 1 .. A'Last loop
         declare
            Key : constant Integer := A (I);
            J   : Integer := Integer (I) - 1;
         begin
            while J >= Integer (A'First) and then A (J) > Key loop
               A (J + 1) := A (J);
               J := J - 1;
            end loop;
            A (J + 1) := Key;
         end;
      end loop;
   end Reference_Sort;

   function Same (A, B : Element_Array) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            return False;
         end if;
      end loop;
      return True;
   end Same;

   function Is_Permutation (A, B : Element_Array) return Boolean is
      SA : Element_Array := A;
      SB : Element_Array := B;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      Reference_Sort (SA);
      Reference_Sort (SB);
      return Same (SA, SB);
   end Is_Permutation;

   procedure Fill_List
     (Store : in out List_Store;
      I     : Index_K;
      Vals  : Element_Array)
   is
   begin
      for J in Vals'Range loop
         Store (I, J - Vals'First + 1) := Vals (J);
      end loop;
   end Fill_List;

   function Concat_Store
     (Store : List_Store;
      Lens  : Len_Array;
      K     : Index_K) return Element_Array
   is
      Total : constant Natural := Total_Length (Lens, K);
      C     : Element_Array (1 .. Total);
      P     : Natural := 0;
   begin
      for I in 1 .. K loop
         for J in 1 .. Lens (I) loop
            P := P + 1;
            C (P) := Store (I, J);
         end loop;
      end loop;
      return C;
   end Concat_Store;

   procedure Expect_Merge_K
     (Store : List_Store;
      Lens  : Len_Array;
      K     : Index_K;
      Label : String)
   is
      Output : Element_Array (1 .. Max_Total);
      Last   : Natural;
      Ref    : Element_Array := Concat_Store (Store, Lens, K);
      Orig   : constant Element_Array := Concat_Store (Store, Lens, K);
   begin
      Merge_K (Store, Lens, K, Output, Last);
      declare
         Got : constant Element_Array := Output (1 .. Last);
      begin
         Reference_Sort (Ref);
         Check (Boo (Is_Sorted (Got)), Label & " Is_Sorted");
         Check (Same (Got, Ref), Label & " matches sort(concat)");
         Check (Nat (Got'Length) = Nat (Ref'Length), Label & " length");
         Check (Is_Permutation (Got, Orig), Label & " permutation");
      end;
   end Expect_Merge_K;

   procedure Expect_Merge_2
     (A, B  : Element_Array;
      Label : String)
   is
      Output : Element_Array (1 .. Max_Total);
      Last   : Natural;
      Ref    : Element_Array (1 .. A'Length + B'Length);
      Orig   : Element_Array (1 .. A'Length + B'Length);
   begin
      for I in A'Range loop
         Ref (I - A'First + 1) := A (I);
         Orig (I - A'First + 1) := A (I);
      end loop;
      for I in B'Range loop
         Ref (A'Length + I - B'First + 1) := B (I);
         Orig (A'Length + I - B'First + 1) := B (I);
      end loop;
      Merge (A, B, Output, Last);
      declare
         Got : constant Element_Array := Output (1 .. Last);
      begin
         Reference_Sort (Ref);
         Check (Boo (Is_Sorted (Got)), Label & " Is_Sorted");
         Check (Same (Got, Ref), Label & " matches sort(concat)");
         Check (Nat (Last) = Nat (A'Length + B'Length), Label & " length");
         Check (Is_Permutation (Got, Orig), Label & " permutation");
      end;
   end Expect_Merge_2;

   Seed : Natural := 42;

   function Next_Mod (Modulus : Positive) return Natural is
      Mult : constant := 1_103_515_245;
      Add  : constant := 12_345;
      X    : Natural;
   begin
      X := Natural ((Long_Long_Integer (Seed) * Mult + Add)
                    mod 2_147_483_647);
      Seed := X;
      return X rem Modulus;
   end Next_Mod;

   function Sorted_Random (Len : Natural; Lo, Hi : Integer)
     return Element_Array
   is
      Span : constant Positive := Hi - Lo + 1;
      A    : Element_Array (1 .. Len);
   begin
      for I in A'Range loop
         A (I) := Lo + Integer (Next_Mod (Span));
      end loop;
      Reference_Sort (A);
      return A;
   end Sorted_Random;

begin
   Put_Line ("K_Way_Merge (SPARK) tests");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Is_Sorted / In_Bounds / List_Is_Sorted");
   ---------------------------------------------------------------------
   declare
      Empty : Element_Array (1 .. 0);
      One   : constant Element_Array := [1 => 42];
      Asc   : constant Element_Array := [1, 2, 3, 4];
      Dup   : constant Element_Array := [2, 2, 2];
      Bad   : constant Element_Array := [1, 3, 2];
      Store : List_Store := [others => [others => 0]];
   begin
      Check (In_Bounds (Empty), "empty In_Bounds");
      Check (Boo (Is_Sorted (Empty)), "empty Is_Sorted");
      Check (In_Bounds (One), "singleton In_Bounds");
      Check (Boo (Is_Sorted (One)), "singleton Is_Sorted");
      Check (Boo (Is_Sorted (Asc)), "ascending Is_Sorted");
      Check (Boo (Is_Sorted (Dup)), "duplicates Is_Sorted");
      Check (not Boo (Is_Sorted (Bad)), "unsorted rejected");
      Fill_List (Store, 1, [1, 2, 3]);
      Check (Boo (List_Is_Sorted (Store, 1, 3)), "List_Is_Sorted ok");
      Store (1, 2) := 9;
      Check (not Boo (List_Is_Sorted (Store, 1, 3)),
             "List_Is_Sorted rejects");
      Check (Boo (List_Is_Sorted (Store, 2, 0)), "empty list sorted");
   end;

   ---------------------------------------------------------------------
   Section ("2. Total_Length");
   ---------------------------------------------------------------------
   declare
      Lens : constant Len_Array := [1 => 3, 2 => 2, 3 => 1, others => 0];
   begin
      Check (Nat (Total_Length (Lens, 1)) = 3, "Total_Length k=1");
      Check (Nat (Total_Length (Lens, 2)) = 5, "Total_Length k=2");
      Check (Nat (Total_Length (Lens, 3)) = 6, "Total_Length k=3");
   end;

   ---------------------------------------------------------------------
   Section ("3. Merge_K empty / k=1");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : Len_Array := [others => 0];
      Outp  : Element_Array (1 .. Max_Total);
      Last  : Natural;
   begin
      Merge_K (Store, Lens, 1, Outp, Last);
      Check (Nat (Last) = 0, "all-empty Last=0");
      Check (Boo (Is_Sorted (Outp (1 .. Last))), "all-empty sorted");

      Fill_List (Store, 1, [1, 3, 5, 7, 9]);
      Lens (1) := 5;
      Expect_Merge_K (Store, Lens, 1, "k=1 odd");

      Fill_List (Store, 1, [42]);
      Lens (1) := 1;
      Expect_Merge_K (Store, Lens, 1, "k=1 singleton");

      Fill_List (Store, 1, [0, 0, 0]);
      Lens (1) := 3;
      Expect_Merge_K (Store, Lens, 1, "k=1 zeros");
   end;

   ---------------------------------------------------------------------
   Section ("4. Classic 3-way Wikipedia example");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : constant Len_Array := [1 => 3, 2 => 3, 3 => 3, others => 0];
   begin
      Fill_List (Store, 1, [1, 4, 7]);
      Fill_List (Store, 2, [2, 5, 8]);
      Fill_List (Store, 3, [3, 6, 9]);
      Expect_Merge_K (Store, Lens, 3, "wiki 1..9");
   end;

   ---------------------------------------------------------------------
   Section ("5. Uneven lengths / empties mixed");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : constant Len_Array := [1 => 4, 2 => 0, 3 => 2, 4 => 1, others => 0];
   begin
      Fill_List (Store, 1, [1, 2, 3, 10]);
      Fill_List (Store, 3, [4, 5]);
      Fill_List (Store, 4, [7]);
      Expect_Merge_K (Store, Lens, 4, "uneven+empty");
   end;

   ---------------------------------------------------------------------
   Section ("6. Duplicates and negatives");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : constant Len_Array := [1 => 3, 2 => 3, 3 => 3, others => 0];
   begin
      Fill_List (Store, 1, [-5, -1, 0]);
      Fill_List (Store, 2, [-3, -1, 2]);
      Fill_List (Store, 3, [-1, 0, 0]);
      Expect_Merge_K (Store, Lens, 3, "neg+dups");
   end;

   ---------------------------------------------------------------------
   Section ("7. Two-way Merge procedure");
   ---------------------------------------------------------------------
   declare
      A : constant Element_Array := [1, 4, 7];
      B : constant Element_Array := [2, 5, 8];
      E : Element_Array (1 .. 0);
      S : constant Element_Array := [1 => 9];
   begin
      Expect_Merge_2 (A, B, "2-way classic");
      Expect_Merge_2 (E, E, "2-way both empty");
      Expect_Merge_2 (A, E, "2-way B empty");
      Expect_Merge_2 (E, B, "2-way A empty");
      Expect_Merge_2 (S, S, "2-way singletons");
      Expect_Merge_2 ([-2, 0, 3], [-1, 0, 4], "2-way signed");
   end;

   ---------------------------------------------------------------------
   Section ("8. Max_K / capacity edges");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : Len_Array := [others => 0];
   begin
      for I in Index_K loop
         Store (I, 1) := I;
         Lens (I) := 1;
      end loop;
      Expect_Merge_K (Store, Lens, Max_K, "Max_K singletons");

      Lens := [others => 0];
      declare
         Per : constant Len_Value := Max_Total / Max_K;
      begin
         for I in Index_K loop
            Lens (I) := Per;
            for J in 1 .. Per loop
               Store (I, J) := I * 100 + J;
            end loop;
         end loop;
         Check (Nat (Total_Length (Lens, Max_K)) = Nat (Max_Total),
                "Max_Total length");
         Expect_Merge_K (Store, Lens, Max_K, "Max_Total fill");
      end;

      Lens := [others => 0];
      Lens (1) := Max_Len;
      for J in 1 .. Max_Len loop
         Store (1, J) := J;
      end loop;
      Expect_Merge_K (Store, Lens, 1, "Max_Len single");
   end;

   ---------------------------------------------------------------------
   Section ("9. Random sorted lists");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : Len_Array;
      K     : Index_K;
      Used  : Natural;
   begin
      for Trial in 1 .. 20 loop
         K := Index_K (1 + Next_Mod (Max_K));
         Used := 0;
         Lens := [others => 0];
         for I in 1 .. K loop
            declare
               Room : constant Natural := Max_Total - Used;
               Cap  : constant Natural :=
                 (if Room < Max_Len then Room else Max_Len);
               L    : Natural;
            begin
               if Cap = 0 then
                  Lens (I) := 0;
               else
                  L := Next_Mod (Cap + 1);
                  Lens (I) := Len_Value (L);
                  if L > 0 then
                     declare
                        R : constant Element_Array :=
                          Sorted_Random (L, -50, 50);
                     begin
                        for J in 1 .. L loop
                           Store (I, J) := R (J);
                        end loop;
                     end;
                  end if;
                  Used := Used + L;
               end if;
            end;
         end loop;
         Expect_Merge_K
           (Store, Lens, K, "random#" & Integer'Image (Trial));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Identical / interleaved lists");
   ---------------------------------------------------------------------
   declare
      Store : List_Store := [others => [others => 0]];
      Lens  : constant Len_Array := [1 => 4, 2 => 4, others => 0];
   begin
      Fill_List (Store, 1, [1, 2, 3, 4]);
      Fill_List (Store, 2, [1, 2, 3, 4]);
      Expect_Merge_K (Store, Lens, 2, "identical lists");
      Fill_List (Store, 1, [1, 3, 5, 7]);
      Fill_List (Store, 2, [2, 4, 6, 8]);
      Expect_Merge_K (Store, Lens, 2, "perfect shuffle");
   end;

   New_Line;
   Put_Line
     ("Results: "
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
