-- subset_sum.adb
-- Implementation of the Subset Sum Problem algorithms.
with Ada.Containers.Vectors;
with Ada.Containers.Generic_Array_Sort;

package body Subset_Sum is

   -----------------------------------------------------------------------------
   -- 1. Recursive / Exhaustive Search
   -----------------------------------------------------------------------------
   function Recursive_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean is
   begin
      -- Base Case: Target is met perfectly
      if Target = 0 then 
         return True; 
      end if;
      
      -- Base Case: Exhausted all elements without hitting the target
      if Set'Length = 0 then 
         return False; 
      end if;

      -- Branch 1: Include the last element
      -- Branch 2: Exclude the last element
      return Recursive_Subset_Sum (Set (Set'First .. Set'Last - 1), Target - Set (Set'Last))
             or else 
             Recursive_Subset_Sum (Set (Set'First .. Set'Last - 1), Target);
   end Recursive_Subset_Sum;


   -----------------------------------------------------------------------------
   -- 2. Dynamic Programming Variant
   -----------------------------------------------------------------------------
   function DP_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean is
   begin
      if Target < 0 then
         return False; -- Cannot form negative sum with strictly non-negative elements
      end if;

      for I in Set'Range loop
         if Set (I) < 0 then
            raise Constraint_Error with "DP variant requires non-negative elements.";
         end if;
      end loop;

      declare
         -- DP_Table maps reachable sums. DP_Table(x) is True if sum x is achievable.
         DP_Table : array (0 .. Target) of Boolean := (0 => True, others => False);
      begin
         for I in Set'Range loop
            -- Iterate backwards to prevent elements from being used more than once
            for J in reverse Set(I) .. Target loop
               if DP_Table (J - Set(I)) then
                  DP_Table (J) := True;
               end if;
            end loop;
         end loop;
         
         return DP_Table (Target);
      end;
   end DP_Subset_Sum;


   -----------------------------------------------------------------------------
   -- 3. Meet-In-The-Middle Variant
   -----------------------------------------------------------------------------
   function Meet_In_The_Middle_Subset_Sum (Set : Element_Array; Target : Element_Type) return Boolean is
      -- Define dynamic array type for generated sums
      type Sum_Array is array (Positive range <>) of Element_Type;
      
      -- Instantiate generic sorting for the sum arrays
      procedure Sort_Sums is new Ada.Containers.Generic_Array_Sort
        (Index_Type => Positive, Element_Type => Element_Type, Array_Type => Sum_Array);

      -- Helper Function: Generate all possible subset sums for a given subset
      function Generate_Sums (Sub_Set : Element_Array) return Sum_Array is
         Total_Subsets : constant Natural := 2 ** Sub_Set'Length;
         Result : Sum_Array (1 .. Total_Subsets);
         Current_Sum : Element_Type;
      begin
         for I in 0 .. Total_Subsets - 1 loop
            Current_Sum := 0;
            for Bit in 0 .. Sub_Set'Length - 1 loop
               if (I / (2 ** Bit)) mod 2 = 1 then
                  Current_Sum := Current_Sum + Sub_Set (Sub_Set'First + Bit);
               end if;
            end loop;
            Result (I + 1) := Current_Sum;
         end loop;
         return Result;
      end Generate_Sums;

   begin
      -- Edge cases
      if Set'Length = 0 then
         return Target = 0;
      end if;
      if Set'Length > 60 then
         raise Constraint_Error with "MITM variant limited to 60 elements to prevent integer overflow.";
      end if;

      declare
         Mid : constant Natural := Set'Length / 2;
         Left_Set  : Element_Array (1 .. Mid);
         Right_Set : Element_Array (1 .. Set'Length - Mid);
      begin
         -- Split the set in half
         for I in 1 .. Mid loop
            Left_Set (I) := Set (Set'First + I - 1);
         end loop;
         for I in 1 .. Set'Length - Mid loop
            Right_Set (I) := Set (Set'First + Mid + I - 1);
         end loop;

         declare
            Left_Sums  : constant Sum_Array := Generate_Sums (Left_Set);
            Right_Sums : Sum_Array := Generate_Sums (Right_Set);
            Required   : Element_Type;
            Low, High, M : Natural; -- Changed from Positive to Natural to allow 0 when searching lower bounds
         begin
            Sort_Sums (Right_Sums);

            -- Binary search over the sorted right-half sums
            for I in Left_Sums'Range loop
               Required := Target - Left_Sums (I);
               Low := Right_Sums'First;
               High := Right_Sums'Last;

               while Low <= High loop
                  M := Low + (High - Low) / 2;
                  if Right_Sums (M) = Required then
                     return True;
                  elsif Right_Sums (M) < Required then
                     Low := M + 1;
                  else
                     High := M - 1;
                  end if;
               end loop;
            end loop;
         end;
      end;
      
      return False;
   end Meet_In_The_Middle_Subset_Sum;


   -----------------------------------------------------------------------------
   -- 4. FPTAS (Approximation) Variant
   -----------------------------------------------------------------------------
   function Approximate_Subset_Sum (Set : Element_Array; Target : Element_Type; C : Float) return Element_Type is
      package Element_Vectors is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Element_Type);
      package Element_Sorting is new Element_Vectors.Generic_Sorting;
      use Element_Vectors;

      L, L_New : Vector;
      N : constant Integer := Set'Length;
      Tolerance : Float;
      Last_Val : Element_Type;
      Max_Val : Element_Type := 0;
   begin
      if N = 0 then return 0; end if;
      
      for I in Set'Range loop
         if Set (I) < 0 then
            raise Constraint_Error with "FPTAS requires non-negative elements.";
         end if;
      end loop;

      Tolerance := C / Float (N);
      L.Append (0);

      for I in Set'Range loop
         L_New := L;
         -- Append merged element (if it doesn't exceed Target boundary immediately)
         for J in 1 .. Integer (L.Length) loop
            if L.Element(J) + Set(I) <= Target then
               L_New.Append (L.Element(J) + Set(I));
            end if;
         end loop;

         Element_Sorting.Sort (L_New);

         -- Trim the list to enforce polynomial bounds
         L.Clear;
         if not L_New.Is_Empty then
            L.Append (L_New.First_Element);
            Last_Val := L_New.First_Element;
            
            for J in 2 .. Integer (L_New.Length) loop
               -- Keep element if it exceeds the boundary threshold (1 + Tolerance)
               if Float (L_New.Element(J)) > Float (Last_Val) * (1.0 + Tolerance) then
                  L.Append (L_New.Element(J));
                  Last_Val := L_New.Element(J);
               end if;
            end loop;
         end if;
      end loop;

      -- Iterate and find the absolute mathematical maximum within bounded list
      for J in 1 .. Integer (L.Length) loop
         if L.Element(J) > Max_Val and then L.Element(J) <= Target then
            Max_Val := L.Element(J);
         end if;
      end loop;

      return Max_Val;
   end Approximate_Subset_Sum;

end Subset_Sum;
