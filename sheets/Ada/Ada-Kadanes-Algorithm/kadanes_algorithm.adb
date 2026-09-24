--  Kadanes_Algorithm body — linear Kadane scan + O(n²) brute oracle.

pragma Ada_2022;

package body Kadanes_Algorithm is

   procedure Check_Nonempty (A : Element_Array) is
   begin
      if A'Length = 0 then
         raise Invalid_Argument;
      end if;
      if A'Length > Max_Length then
         raise Invalid_Argument;
      end if;
   end Check_Nonempty;

   --  Element of A at 1-based logical position I.
   function Elem_At (A : Element_Array; I : Positive) return Element is
     (A (A'First + (I - 1)));

   ------------------------------------------------------------------
   -- Max_Subarray / Max_Subarray_Sum
   ------------------------------------------------------------------

   function Max_Subarray (A : Element_Array) return Result is
      Best_Sum    : Element;
      Current_Sum : Element;
      Best_First  : Positive;
      Best_Last   : Positive;
      Curr_First  : Positive;
   begin
      Check_Nonempty (A);

      declare
         N : constant Positive := A'Length;
      begin
         --  Initialize with the singleton A[1] (no empty subarray admitted).
         Best_Sum    := Elem_At (A, 1);
         Current_Sum := Elem_At (A, 1);
         Best_First  := 1;
         Best_Last   := 1;
         Curr_First  := 1;

         for J in 2 .. N loop
            declare
               X : constant Element := Elem_At (A, J);
            begin
               --  Extend or restart: current := max(A[j], current + A[j]).
               if Current_Sum + X < X then
                  Current_Sum := X;
                  Curr_First  := J;
               else
                  Current_Sum := Current_Sum + X;
               end if;

               if Current_Sum > Best_Sum then
                  Best_Sum   := Current_Sum;
                  Best_First := Curr_First;
                  Best_Last  := J;
               end if;
            end;
         end loop;

         return (Sum => Best_Sum, First => Best_First, Last => Best_Last);
      end;
   end Max_Subarray;

   function Max_Subarray_Sum (A : Element_Array) return Element is
   begin
      return Max_Subarray (A).Sum;
   end Max_Subarray_Sum;

   ------------------------------------------------------------------
   -- Brute-force oracles
   ------------------------------------------------------------------

   function Brute_Force (A : Element_Array) return Result is
      Best_Sum   : Element;
      Best_First : Positive := 1;
      Best_Last  : Positive := 1;
   begin
      Check_Nonempty (A);

      declare
         N : constant Positive := A'Length;
      begin
         --  Seed with the singleton A[1] so Best_Sum is always defined.
         Best_Sum := Elem_At (A, 1);

         for I in 1 .. N loop
            declare
               Running : Element := 0;
            begin
               for J in I .. N loop
                  Running := Running + Elem_At (A, J);
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

         return (Sum => Best_Sum, First => Best_First, Last => Best_Last);
      end;
   end Brute_Force;

   function Brute_Force_Sum (A : Element_Array) return Element is
   begin
      return Brute_Force (A).Sum;
   end Brute_Force_Sum;

end Kadanes_Algorithm;
