pragma SPARK_Mode (On);
pragma Ada_2022;
package Nested_Iterator_Stub is
   Capacity : constant := 1_000;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity;

   --  A nested list: integers and nested lists, written left to right as
   --  entries (an integer, the start of a list, the end of a list).
   type Nested_Data is private;
   type Iterator is private;

   function Empty return Nested_Data
     with Global => null, Post => Length (Empty'Result) = 0 and then Depth (Empty'Result) = 0;
   --  Number of entries written so far (integers and list starts / ends).
   function Length (N : Nested_Data) return Count with Global => null;
   --  Number of lists started and not yet ended.
   function Depth (N : Nested_Data) return Count with Global => null;

   --  Entry I is an integer (Data_Int) or a list start / end (not Data_Is_Int).
   function Data_Is_Int (N : Nested_Data; I : Index) return Boolean with Global => null;
   function Data_Int (N : Nested_Data; I : Index) return Value with Global => null;
   --  Entries 1 .. Length (N) unchanged
   function Same_Prefix (A, B : Nested_Data) return Boolean is
     (for all I in 1 .. Length (A) =>
        Data_Is_Int (B, I) = Data_Is_Int (A, I) and then Data_Int (B, I) = Data_Int (A, I))
     with Global => null, Pre => Length (A) <= Length (B);

   --  Append an integer to the innermost open list (or the top level).
   procedure Add (N : in out Nested_Data; V : Value)
     with Global => null, Pre => Length (N) < Capacity,
          Post => Length (N) = Length (N'Old) + 1 and then Depth (N) = Depth (N'Old)
                  and then Same_Prefix (N'Old, N)
                  and then Data_Is_Int (N, Length (N)) and then Data_Int (N, Length (N)) = V;
   --  Start a nested list inside the innermost open list.
   procedure Open_List (N : in out Nested_Data)
     with Global => null, Pre => Length (N) < Capacity and then Depth (N) < Capacity,
          Post => Length (N) = Length (N'Old) + 1 and then Depth (N) = Depth (N'Old) + 1
                  and then Same_Prefix (N'Old, N) and then not Data_Is_Int (N, Length (N));
   --  End the innermost open list.
   procedure Close_List (N : in out Nested_Data)
     with Global => null, Pre => Length (N) < Capacity and then Depth (N) > 0,
          Post => Length (N) = Length (N'Old) + 1 and then Depth (N) = Depth (N'Old) - 1
                  and then Same_Prefix (N'Old, N) and then not Data_Is_Int (N, Length (N));

   --  Iterator model: entries 1 .. Size; Is_Int (It, I) / Int (It, I) give
   --  entry I; Pos (It) is the next integer entry, Size + 1 when none is left.
   function Size (It : Iterator) return Count with Global => null;
   function Pos (It : Iterator) return Positive with Global => null;
   function Is_Int (It : Iterator; I : Index) return Boolean with Global => null;
   function Int (It : Iterator; I : Index) return Value with Global => null;

   --  The flattened integers of N, left to right (empty lists contribute
   --  nothing).
   function Create (N : Nested_Data) return Iterator
     with Global => null, Pre => Depth (N) = 0,
          Post => Size (Create'Result) = Length (N)
                  and then (for all I in 1 .. Length (N) =>
                              Is_Int (Create'Result, I) = Data_Is_Int (N, I)
                              and then Int (Create'Result, I) = Data_Int (N, I))
                  and then (for all I in 1 .. Pos (Create'Result) - 1 => not Is_Int (Create'Result, I));
   function Has_Next (It : Iterator) return Boolean
     with Global => null, Post => Has_Next'Result = (Pos (It) <= Size (It));
   --  The next integer; Pos moves to the following integer entry.
   procedure Next (It : in out Iterator; Result : out Value)
     with Global => null, Pre => Has_Next (It),
          Post => Result = Int (It'Old, Pos (It'Old))
                  and then Pos (It) > Pos (It'Old)
                  and then (for all I in Pos (It'Old) + 1 .. Pos (It) - 1 => not Is_Int (It'Old, I))
                  and then Size (It) = Size (It'Old)
                  and then (for all I in Index =>
                              Is_Int (It, I) = Is_Int (It'Old, I) and then Int (It, I) = Int (It'Old, I));
private
   type Entry_Kind is (Int_Entry, List_Start, List_End);
   type Entry_Rec is record
      Kind : Entry_Kind := Int_Entry;
      Val  : Value := 0;
   end record;
   type Entry_Array is array (Index) of Entry_Rec;
   type Nested_Data is record
      Entries : Entry_Array := [others => (Kind => Int_Entry, Val => 0)];
      Size    : Count := 0;
      Depth   : Count := 0;
   end record
     with Type_Invariant => Depth <= Size;
   subtype Position is Positive range 1 .. Capacity + 1;
   type Iterator is record
      Entries : Entry_Array := [others => (Kind => Int_Entry, Val => 0)];
      Size    : Count := 0;
      Pos     : Position := 1;
   end record
     with Type_Invariant => Pos <= Size + 1 and then (if Pos <= Size then Entries (Pos).Kind = Int_Entry);
   function Length (N : Nested_Data) return Count is (N.Size);
   function Depth (N : Nested_Data) return Count is (N.Depth);
   function Data_Is_Int (N : Nested_Data; I : Index) return Boolean is (N.Entries (I).Kind = Int_Entry);
   function Data_Int (N : Nested_Data; I : Index) return Value is (N.Entries (I).Val);
   function Size (It : Iterator) return Count is (It.Size);
   function Pos (It : Iterator) return Positive is (It.Pos);
   function Is_Int (It : Iterator; I : Index) return Boolean is (It.Entries (I).Kind = Int_Entry);
   function Int (It : Iterator; I : Index) return Value is (It.Entries (I).Val);
end Nested_Iterator_Stub;
