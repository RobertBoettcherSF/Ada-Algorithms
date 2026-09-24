with Ada.Containers.Generic_Array_Sort;

package body Sort_Merge_Join is

   -- Comparator for the sorting mechanism
   function "<" (L, R : Row) return Boolean is
   begin
      return L.Key < R.Key;
   end "<";

   -- Instantiating standard library sort for arrays
   procedure Sort_Rel is new Ada.Containers.Generic_Array_Sort
     (Index_Type   => Positive,
      Element_Type => Row,
      Array_Type   => Relation);

   procedure Sort (Rel : in out Relation) is
   begin
      Sort_Rel (Rel);
   end Sort;

   -- Validates if a relation is pre-sorted to avoid redundant sorting overhead
   function Is_Sorted (Rel : Relation) return Boolean is
   begin
      if Rel'Length <= 1 then
         return True;
      end if;
      
      for I in Rel'First .. Rel'Last - 1 loop
         if Rel (I + 1).Key < Rel (I).Key then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

   -----------------------------------------------------------------------------
   -- Variant 1: Standard Inner Join (Preemptive Sorting, Many-to-Many Support)
   -----------------------------------------------------------------------------
   function Inner_Join
     (Left, Right : Relation; Auto_Sort : Boolean := True)
      return Joined_Relation
   is
      Result      : Joined_Relation;
      L_Sorted    : Relation (Left'Range) := Left;
      R_Sorted    : Relation (Right'Range) := Right;
      I, J        : Positive;
      Match_Start : Positive;
      Current_Key : Join_Key;
   begin
      if Auto_Sort then
         Sort (L_Sorted);
         Sort (R_Sorted);
      else
         if not Is_Sorted (Left) or else not Is_Sorted (Right) then
            raise Unsorted_Relation_Error;
         end if;
      end if;

      if L_Sorted'Length = 0 or else R_Sorted'Length = 0 then
         return Result;
      end if;

      I := L_Sorted'First;
      J := R_Sorted'First;

      -- Core Merge Algorithm
      while I <= L_Sorted'Last and then J <= R_Sorted'Last loop
         if L_Sorted (I).Key < R_Sorted (J).Key then
            I := I + 1;
         elsif L_Sorted (I).Key > R_Sorted (J).Key then
            J := J + 1;
         else
            -- Match found, begin tracking for Cartesian product of duplicate keys
            Current_Key := L_Sorted (I).Key;
            Match_Start := J;

            while I <= L_Sorted'Last and then L_Sorted (I).Key = Current_Key loop
               declare
                  Temp_J : Positive := Match_Start;
               begin
                  while Temp_J <= R_Sorted'Last and then R_Sorted (Temp_J).Key = Current_Key loop
                     Result.Append ((L_Sorted (I), R_Sorted (Temp_J)));
                     Temp_J := Temp_J + 1;
                  end loop;
               end;
               I := I + 1;
            end loop;

            -- Advance J past the block of duplicates we just matched against
            while J <= R_Sorted'Last and then R_Sorted (J).Key = Current_Key loop
               J := J + 1;
            end loop;
         end if;
      end loop;

      return Result;
   end Inner_Join;

   -----------------------------------------------------------------------------
   -- Variant 2: Unique-Key Join (Static Assumption, No Backtracking)
   -----------------------------------------------------------------------------
   function Unique_Key_Join
     (Left, Right : Relation; Auto_Sort : Boolean := True)
      return Joined_Relation
   is
      Result   : Joined_Relation;
      L_Sorted : Relation (Left'Range) := Left;
      R_Sorted : Relation (Right'Range) := Right;
      I, J     : Positive;
   begin
      if Auto_Sort then
         Sort (L_Sorted);
         Sort (R_Sorted);
      else
         if not Is_Sorted (Left) or else not Is_Sorted (Right) then
            raise Unsorted_Relation_Error;
         end if;
      end if;

      -- Edge case: Empty input arrays
      if L_Sorted'Length = 0 or else R_Sorted'Length = 0 then
         return Result;
      end if;

      -- Validate primary key uniqueness constraint
      for K in L_Sorted'First .. L_Sorted'Last - 1 loop
         if L_Sorted (K).Key = L_Sorted (K + 1).Key then
            raise Non_Unique_Key_Error;
         end if;
      end loop;

      I := L_Sorted'First;
      J := R_Sorted'First;

      -- Streamlined Merge logic
      while I <= L_Sorted'Last and then J <= R_Sorted'Last loop
         if L_Sorted (I).Key < R_Sorted (J).Key then
            I := I + 1;
         elsif L_Sorted (I).Key > R_Sorted (J).Key then
            J := J + 1;
         else
            -- Direct append without nested iteration/backtracking
            Result.Append ((L_Sorted (I), R_Sorted (J)));
            J := J + 1;
         end if;
      end loop;

      return Result;
   end Unique_Key_Join;

end Sort_Merge_Join;
