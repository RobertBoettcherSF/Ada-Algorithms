--  Uniform_Binary_Search body — Knuth / Chandra delta-table search.

pragma Ada_2022;

package body Uniform_Binary_Search
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Build_Table
   -------------------------------------------------------------------------

   procedure Build_Table (N : Positive; Table : out Delta_Table) is
      Power : Natural := 1;
      Half  : Natural;
      I     : Natural := 0;
      Value : Natural;
   begin
      if N > Max_N then
         raise Invalid_Argument with
           "Build_Table: N exceeds Max_N";
      end if;

      Table.Length := N;
      Table.Deltas  := [others => 0];
      Table.Count  := 0;

      --  Wikipedia / Knuth:
      --    half = 2^i; power = 2^(i+1);
      --    delta[i] = (N + half) / power
      --  until a 0 is stored (terminator).
      loop
         if I >= Max_Delta_Entries then
            raise Invalid_Argument with
              "Build_Table: delta pool exhausted";
         end if;

         Half  := Power;
         --  power <<= 1, guarded against overflow past Natural'Last
         if Power > Natural'Last / 2 then
            Value := 0;
         else
            Power := Power * 2;
            Value := (N + Half) / Power;
         end if;

         Table.Deltas (I) := Value;
         I := I + 1;
         exit when Value = 0;
      end loop;

      Table.Count := I;
   end Build_Table;

   function Table_Length (Table : Delta_Table) return Natural is
   begin
      return Table.Length;
   end Table_Length;

   function Table_Entry_Count (Table : Delta_Table) return Natural is
   begin
      return Table.Count;
   end Table_Entry_Count;

   function Delta_At (Table : Delta_Table; Index : Natural) return Natural is
   begin
      if Table.Count = 0 or else Index >= Table.Count then
         raise Invalid_Argument with
           "Delta_At: index out of built range";
      end if;
      return Table.Deltas (Index);
   end Delta_At;

   -------------------------------------------------------------------------
   -- Core uniform search (0-based offset space, then map to A'First)
   -------------------------------------------------------------------------

   function Find_With_Table
     (A     : Element_Array;
      Key   : Integer;
      Table : Delta_Table) return Integer
   is
      Sentinel : constant Integer := Integer (A'First) - 1;
      --  Working index in A'Range (may temporarily leave the range).
      Index    : Integer;
      D        : Natural := 0;
   begin
      if A'Length = 0 then
         return Sentinel;
      end if;

      --  Wikipedia: i = delta[0] - 1 on a 0-based array.
      Index := Integer (A'First) + Integer (Table.Deltas (0)) - 1;

      loop
         --  Bounds guard: Wikipedia's C sketch can walk one step past the
         --  ends when Key is outside the value range; treat that as a miss.
         --  (Knuth's Algorithm C uses a 1-based array with a sentinel at 0.)
         if Index < Integer (A'First) or else Index > Integer (A'Last) then
            return Sentinel;
         end if;

         if Key = A (Natural (Index)) then
            return Index;
         elsif Table.Deltas (D) = 0 then
            return Sentinel;
         else
            D := D + 1;
            if D >= Table.Count then
               return Sentinel;
            end if;
            if Key < A (Natural (Index)) then
               Index := Index - Integer (Table.Deltas (D));
            else
               Index := Index + Integer (Table.Deltas (D));
            end if;
         end if;
      end loop;
   end Find_With_Table;

   -------------------------------------------------------------------------
   -- Public Find overloads
   -------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer is
      Table : Delta_Table;
   begin
      if A'Length > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if A'Length = 0 then
         return Integer (A'First) - 1;
      end if;

      Build_Table (Positive (A'Length), Table);
      return Find_With_Table (A, Key, Table);
   end Find;

   function Find
     (A     : Element_Array;
      Key   : Integer;
      Table : Delta_Table) return Integer
   is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if A'Length = 0 then
         return Integer (A'First) - 1;
      end if;

      if Table.Length /= A'Length then
         raise Invalid_Argument with
           "Find: delta table length does not match array length";
      end if;

      return Find_With_Table (A, Key, Table);
   end Find;

   -------------------------------------------------------------------------
   -- Classic_Binary_Search
   -------------------------------------------------------------------------

   function Classic_Binary_Search
     (A : Element_Array; Key : Integer) return Integer
   is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
   begin
      if A'Length > Max_N then
         raise Invalid_Argument with
           "Classic_Binary_Search: array length exceeds Max_N";
      end if;

      if A'Length = 0 then
         return Integer (A'First) - 1;
      end if;

      Lo := Integer (A'First);
      Hi := Integer (A'Last);

      while Lo <= Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if Key = A (Natural (Mid)) then
            return Mid;
         elsif Key < A (Natural (Mid)) then
            Hi := Mid - 1;
         else
            Lo := Mid + 1;
         end if;
      end loop;

      return Integer (A'First) - 1;
   end Classic_Binary_Search;

   -------------------------------------------------------------------------
   -- Is_Sorted_Ascending
   -------------------------------------------------------------------------

   function Is_Sorted_Ascending (A : Element_Array) return Boolean is
   begin
      if A'Length < 2 then
         return True;
      end if;
      for I in A'First .. A'Last - 1 loop
         if A (I) > A (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted_Ascending;

end Uniform_Binary_Search;
