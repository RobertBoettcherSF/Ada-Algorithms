pragma SPARK_Mode (On);
pragma Ada_2022;
package body Nested_Iterator_Stub is
   function Empty return Nested_Data is
     (Entries => [others => (Kind => Int_Entry, Val => 0)], Size => 0, Depth => 0);

   procedure Add (N : in out Nested_Data; V : Value) is
   begin
      N.Size := N.Size + 1;
      N.Entries (N.Size) := (Kind => Int_Entry, Val => V);
   end Add;

   procedure Open_List (N : in out Nested_Data) is
   begin
      N.Size := N.Size + 1;
      N.Entries (N.Size) := (Kind => List_Start, Val => 0);
      N.Depth := N.Depth + 1;
   end Open_List;

   procedure Close_List (N : in out Nested_Data) is
   begin
      N.Size := N.Size + 1;
      N.Entries (N.Size) := (Kind => List_End, Val => 0);
      N.Depth := N.Depth - 1;
   end Close_List;

   --  The first integer entry at or after From (Size + 1 when none):
   --  list starts and ends, so also empty lists, are stepped over.
   function Skip (E : Entry_Array; Size : Count; From : Position) return Position
     with Pre  => From <= Size + 1,
          Post => Skip'Result in From .. Size + 1
                  and then (for all I in From .. Skip'Result - 1 => E (I).Kind /= Int_Entry)
                  and then (if Skip'Result <= Size then E (Skip'Result).Kind = Int_Entry)
   is
   begin
      for I in From .. Size loop
         if E (I).Kind = Int_Entry then
            return I;
         end if;
         pragma Loop_Invariant (for all J in From .. I => E (J).Kind /= Int_Entry);
      end loop;
      return Size + 1;
   end Skip;

   function Create (N : Nested_Data) return Iterator is
     (Entries => N.Entries, Size => N.Size, Pos => Skip (N.Entries, N.Size, 1));

   function Has_Next (It : Iterator) return Boolean is (It.Pos <= It.Size);

   procedure Next (It : in out Iterator; Result : out Value) is
   begin
      Result := It.Entries (It.Pos).Val;
      It.Pos := Skip (It.Entries, It.Size, It.Pos + 1);
   end Next;
end Nested_Iterator_Stub;
