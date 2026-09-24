package body Quantum_Sort is

   function Is_Sorted (Arr : Element_Array) return Boolean is
   begin
      if Arr'Length <= 1 then
         return True;
      end if;
      for I in Arr'First .. Index_Type'Pred (Arr'Last) loop
         if Arr (I) > Arr (Index_Type'Succ (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   --  Variant 1: Quantum Comparison Sort (Insertion Sort)
   procedure Sort_Comparison (Arr : in out Element_Array) is
      Key : Element_Value;
      J   : Index_Type;
   begin
      if Arr'Length <= 1 then
         return;
      end if;
      for I in Index_Type'Succ (Arr'First) .. Arr'Last loop
         Key := Arr (I);
         J := I;
         while J > Arr'First and then Arr (Index_Type'Pred (J)) > Key loop
            Arr (J) := Arr (Index_Type'Pred (J));
            J := Index_Type'Pred (J);
         end loop;
         Arr (J) := Key;
      end loop;
   end Sort_Comparison;

   --  Variant 2: Quantum Parallel Network Sort (Shell Sort with decreasing gaps)
   procedure Sort_Parallel_Network (Arr : in out Element_Array) is
      Len  : constant Integer := Integer (Arr'Length);
      Gap  : Integer;
      Temp : Element_Value;
      J    : Index_Type;
   begin
      if Len <= 1 then
         return;
      end if;

      Gap := Len / 2;
      while Gap > 0 loop
         for I in Arr'First + Index_Type (Gap) .. Arr'Last loop
            Temp := Arr (I);
            J := I;
            while J >= Arr'First + Index_Type (Gap)
              and then Arr (J - Index_Type (Gap)) > Temp
            loop
               Arr (J) := Arr (J - Index_Type (Gap));
               J := J - Index_Type (Gap);
            end loop;
            Arr (J) := Temp;
         end loop;
         Gap := Gap / 2;
      end loop;
   end Sort_Parallel_Network;

   --  Variant 3: Quantum Frequency / Distribution Sort (Selection Sort)
   procedure Sort_Frequency (Arr : in out Element_Array) is
      Min_Index : Index_Type;
      Temp      : Element_Value;
   begin
      if Arr'Length <= 1 then
         return;
      end if;

      for I in Arr'First .. Index_Type'Pred (Arr'Last) loop
         Min_Index := I;
         for J in Index_Type'Succ (I) .. Arr'Last loop
            if Arr (J) < Arr (Min_Index) then
               Min_Index := J;
            end if;
         end loop;
         if Min_Index /= I then
            Temp := Arr (I);
            Arr (I) := Arr (Min_Index);
            Arr (Min_Index) := Temp;
         end if;
      end loop;
   end Sort_Frequency;

   --  Variant 4: Space-Bounded Quantum Sort (Cocktail Shaker Sort)
   procedure Sort_Space_Bounded (Arr : in out Element_Array) is
      Low     : Index_Type := Arr'First;
      High    : Index_Type := Arr'Last;
      Swapped : Boolean := True;
      Temp    : Element_Value;
   begin
      if Arr'Length <= 1 then
         return;
      end if;

      while Swapped loop
         Swapped := False;
         for I in Low .. High - 1 loop
            if Arr (I) > Arr (I + 1) then
               Temp := Arr (I);
               Arr (I) := Arr (I + 1);
               Arr (I + 1) := Temp;
               Swapped := True;
            end if;
         end loop;

         if not Swapped then
            exit;
         end if;

         Swapped := False;
         High := High - 1;

         for I in reverse Low .. High loop
            if I > Low and then Arr (I - 1) > Arr (I) then
               Temp := Arr (I);
               Arr (I) := Arr (I - 1);
               Arr (I - 1) := Temp;
               Swapped := True;
            end if;
         end loop;

         Low := Low + 1;
      end loop;
   end Sort_Space_Bounded;

end Quantum_Sort;
