with Ada.Containers.Vectors;

package body Petricks_Method is
   use Interfaces;

   package Product_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Unsigned_64);
   subtype Product_Vector is Product_Vectors.Vector;

   function Empty_Clause return Clause is
   begin
      return (Mask => 0);
   end Empty_Clause;

   function Add (C : Clause; PI : Prime_Implicant_ID) return Clause is
   begin
      return (Mask => C.Mask or Shift_Left (Unsigned_64'(1), Integer (PI) - 1));
   end Add;

   function Create_Clause (PIs : PI_Array) return Clause is
      Result : Clause := Empty_Clause;
   begin
      for PI of PIs loop
         Result := Add (Result, PI);
      end loop;
      return Result;
   end Create_Clause;

   -- Helper: Converts a bitmask back into a Solution record, populating the PIs array
   function To_Solution (Mask : Unsigned_64) return Solution is
      Res : Solution;
   begin
      for I in Integer range 1 .. Max_Prime_Implicants loop
         if (Mask and Shift_Left (Unsigned_64'(1), I - 1)) /= 0 then
            Res.Count := Res.Count + 1;
            Res.PIs (Res.Count) := Prime_Implicant_ID (I);
         end if;
      end loop;
      return Res;
   end To_Solution;

   -- Helper: Returns True if subset mask A is fully contained within B
   function Is_Subset (A, B : Unsigned_64) return Boolean is
   begin
      return (A and B) = A;
   end Is_Subset;

   -- Helper: Appends a term to a Sum-of-Products while applying Absorption Law (A + AB = A)
   procedure Add_Term_Simplified (SOP : in out Product_Vector; T : Unsigned_64) is
      Is_Super : Boolean := False;
      I        : Positive := 1;
   begin
      -- 1. Check if T is absorbed by (is a superset of) any existing term
      for Existing of SOP loop
         if Is_Subset (Existing, T) then
            Is_Super := True;
            exit;
         end if;
      end loop;

      if not Is_Super then
         -- 2. T is minimal compared to current elements.
         -- Remove any existing terms that are absorbed by T.
         while I <= SOP.Last_Index loop
            if Is_Subset (T, SOP.Element (I)) then
               SOP.Delete (I);
               -- Do not increment I because elements have shifted left
            else
               I := I + 1;
            end if;
         end loop;

         -- 3. Add T safely
         SOP.Append (T);
      end if;
   end Add_Term_Simplified;

   function Multiply_And_Simplify (Chart : Clause_List) return Solution_List is
      Current_SOP : Product_Vector;
      New_SOP     : Product_Vector;
   begin
      if Chart'Length = 0 then
         raise Empty_Chart_Error;
      end if;

      for C of Chart loop
         if C.Mask = 0 then
            raise Empty_Clause_Error;
         end if;
      end loop;

      -- Initialize the SOP with the elements of the very first clause
      for I in Integer range 1 .. Max_Prime_Implicants loop
         if (Chart (Chart'First).Mask and Shift_Left (Unsigned_64'(1), I - 1)) /= 0 then
            Current_SOP.Append (Shift_Left (Unsigned_64'(1), I - 1));
         end if;
      end loop;

      -- Multiply (distribute) the remaining clauses sequentially
      for I in Chart'First + 1 .. Chart'Last loop
         New_SOP.Clear;
         declare
            C_Mask : constant Unsigned_64 := Chart (I).Mask;
         begin
            for Term of Current_SOP loop
               for J in Integer range 1 .. Max_Prime_Implicants loop
                  if (C_Mask and Shift_Left (Unsigned_64'(1), J - 1)) /= 0 then
                     Add_Term_Simplified (New_SOP, Term or Shift_Left (Unsigned_64'(1), J - 1));
                  end if;
               end loop;
            end loop;
         end;
         
         Current_SOP := New_SOP;
         
         -- If SOP ever empties (impossible by Boolean rules given non-empty clauses, but defensive)
         if Current_SOP.Is_Empty then
            raise Unsolvable_Chart_Error;
         end if;
      end loop;

      -- Convert internal SOP representation to the public Solution_List type
      declare
         Result : Solution_List (1 .. Integer (Current_SOP.Length));
         Idx    : Positive := 1;
      begin
         for Term of Current_SOP loop
            Result (Idx) := To_Solution (Term);
            Idx := Idx + 1;
         end loop;
         return Result;
      end;
   end Multiply_And_Simplify;

   function Minimum_Terms (Chart : Clause_List) return Solution_List is
      All_Solutions : constant Solution_List := Multiply_And_Simplify (Chart);
      Min_Count     : Natural := Max_Prime_Implicants + 1;
      Match_Count   : Natural := 0;
   begin
      if All_Solutions'Length = 0 then
         return All_Solutions;
      end if;

      for S of All_Solutions loop
         if S.Count < Min_Count then
            Min_Count := S.Count;
         end if;
      end loop;

      for S of All_Solutions loop
         if S.Count = Min_Count then
            Match_Count := Match_Count + 1;
         end if;
      end loop;

      declare
         Result : Solution_List (1 .. Match_Count);
         Idx    : Positive := 1;
      begin
         for S of All_Solutions loop
            if S.Count = Min_Count then
               Result (Idx) := S;
               Idx := Idx + 1;
            end if;
         end loop;
         return Result;
      end;
   end Minimum_Terms;

   function Minimum_Cost_Terms (Chart : Clause_List; Costs : Cost_Map) return Solution_List is
      All_Solutions : constant Solution_List := Multiply_And_Simplify (Chart);
      Min_Cost      : Natural := Natural'Last;
      Match_Count   : Natural := 0;

      -- Calculates cost of a single solution
      function Calc_Cost (S : Solution) return Natural is
         C : Natural := 0;
      begin
         for I in 1 .. S.Count loop
            if S.PIs (I) in Costs'Range then
               C := C + Costs (S.PIs (I));
            else
               raise Missing_Cost_Error with "Cost not provided for PI " & 
                 Prime_Implicant_ID'Image (S.PIs (I));
            end if;
         end loop;
         return C;
      end Calc_Cost;
   begin
      if All_Solutions'Length = 0 then
         return All_Solutions;
      end if;

      -- Find absolute minimum cost across all valid minimal solutions
      for S of All_Solutions loop
         declare
            Cost : constant Natural := Calc_Cost (S);
         begin
            if Cost < Min_Cost then
               Min_Cost := Cost;
            end if;
         end;
      end loop;

      -- Count solutions that map to this minimal cost
      for S of All_Solutions loop
         if Calc_Cost (S) = Min_Cost then
            Match_Count := Match_Count + 1;
         end if;
      end loop;

      -- Extract and return
      declare
         Result : Solution_List (1 .. Match_Count);
         Idx    : Positive := 1;
      begin
         for S of All_Solutions loop
            if Calc_Cost (S) = Min_Cost then
               Result (Idx) := S;
               Idx := Idx + 1;
            end if;
         end loop;
         return Result;
      end;
   end Minimum_Cost_Terms;

end Petricks_Method;
