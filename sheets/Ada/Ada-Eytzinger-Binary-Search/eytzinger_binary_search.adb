--  Eytzinger_Binary_Search body — BFS / heap-layout build and search.

pragma Ada_2022;

package body Eytzinger_Binary_Search
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Build: inorder fill of the complete binary tree (heap) shape
   -------------------------------------------------------------------------

   procedure Build (Sorted : Element_Array; Layout : out Element_Array) is
      N : constant Natural := Sorted'Length;
      K : Natural := 0;  -- next Sorted offset (0 .. N-1)

      procedure Fill (Offset : Natural) is
      begin
         if Offset >= N then
            return;
         end if;
         --  Left child
         Fill (2 * Offset + 1);
         --  Visit: write next sorted element into this heap slot
         Layout (Layout'First + Offset) := Sorted (Sorted'First + K);
         K := K + 1;
         --  Right child
         Fill (2 * Offset + 2);
      end Fill;

   begin
      if N /= Layout'Length then
         raise Invalid_Argument with
           "Build: Sorted and Layout lengths differ";
      end if;

      if N > Max_N then
         raise Invalid_Argument with
           "Build: length exceeds Max_N";
      end if;

      if N = 0 then
         return;
      end if;

      Fill (0);
   end Build;

   -------------------------------------------------------------------------
   -- Find: walk 2i+1 / 2i+2 from the root
   -------------------------------------------------------------------------

   function Find (Layout : Element_Array; Key : Integer) return Integer is
      N        : constant Natural := Layout'Length;
      Sentinel : constant Integer := Integer (Layout'First) - 1;
      Offset   : Natural := 0;
      Idx      : Natural;
   begin
      if N > Max_N then
         raise Invalid_Argument with
           "Find: length exceeds Max_N";
      end if;

      if N = 0 then
         return Sentinel;
      end if;

      while Offset < N loop
         Idx := Layout'First + Offset;
         if Key = Layout (Idx) then
            return Integer (Idx);
         elsif Key < Layout (Idx) then
            Offset := 2 * Offset + 1;   -- left
         else
            Offset := 2 * Offset + 2;   -- right
         end if;
      end loop;

      return Sentinel;
   end Find;

   -------------------------------------------------------------------------
   -- Sorted_Index: inorder rank of a layout node → sorted absolute index
   -------------------------------------------------------------------------

   function Sorted_Index
     (Layout_Index : Natural;
      Length       : Natural;
      First        : Natural := 0) return Integer
   is
      Target : Natural;
      Rank   : Natural := 0;
      Found  : Boolean := False;

      procedure Walk (Offset : Natural) is
      begin
         if Offset >= Length or else Found then
            return;
         end if;
         Walk (2 * Offset + 1);
         if Found then
            return;
         end if;
         if Offset = Target then
            Found := True;
            return;
         end if;
         Rank := Rank + 1;
         Walk (2 * Offset + 2);
      end Walk;

   begin
      if Length > Max_N then
         raise Invalid_Argument with
           "Sorted_Index: length exceeds Max_N";
      end if;

      if Length = 0 then
         raise Invalid_Argument with
           "Sorted_Index: empty layout";
      end if;

      if Layout_Index < First
        or else Layout_Index > First + Length - 1
      then
         raise Invalid_Argument with
           "Sorted_Index: layout index out of range";
      end if;

      Target := Layout_Index - First;
      Walk (0);

      if not Found then
         raise Invalid_Argument with
           "Sorted_Index: node not found";
      end if;

      return Integer (First + Rank);
   end Sorted_Index;

   -------------------------------------------------------------------------
   -- Classic_Binary_Search
   -------------------------------------------------------------------------

   function Classic_Binary_Search
     (Sorted : Element_Array; Key : Integer) return Integer
   is
      Lo  : Integer;
      Hi  : Integer;
      Mid : Integer;
   begin
      if Sorted'Length > Max_N then
         raise Invalid_Argument with
           "Classic_Binary_Search: length exceeds Max_N";
      end if;

      if Sorted'Length = 0 then
         return Integer (Sorted'First) - 1;
      end if;

      Lo := Integer (Sorted'First);
      Hi := Integer (Sorted'Last);

      while Lo <= Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if Key = Sorted (Natural (Mid)) then
            return Mid;
         elsif Key < Sorted (Natural (Mid)) then
            Hi := Mid - 1;
         else
            Lo := Mid + 1;
         end if;
      end loop;

      return Integer (Sorted'First) - 1;
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

end Eytzinger_Binary_Search;
