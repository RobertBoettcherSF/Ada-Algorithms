pragma SPARK_Mode (On);
pragma Ada_2022;
package Combination_Iterator_Stub is
   Capacity : constant := 20;
   subtype Count is Natural range 0 .. Capacity;
   subtype Choose_Count is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Combination is record
      Values : Value_Array := [others => 0];
      Size   : Count := 0;
   end record;
   type Iterator is private;

   --  Model: Items (1 .. Item_Count); the next combination to return is the
   --  positions Pos (It, 1) < ... < Pos (It, Choose), unless Done.
   function Item_Count (It : Iterator) return Count with Global => null;
   function Choose (It : Iterator) return Choose_Count with Global => null;
   function Item (It : Iterator; I : Index) return Value with Global => null;
   function Pos (It : Iterator; J : Index) return Index with Global => null;
   function Done (It : Iterator) return Boolean with Global => null;

   --  The last combination (in lexicographic order of positions).
   function Is_Last (It : Iterator) return Boolean is
     (for all J in 1 .. Choose (It) => Pos (It, J) = Item_Count (It) - Choose (It) + J)
     with Global => null, Pre => Choose (It) <= Item_Count (It);

   --  The rightmost position that can still move right, 0 for the last
   --  combination (Knuth, TAOCP Vol. 4A, 7.2.1.3, lexicographic
   --  combinations: the successor raises this position by one and sets the
   --  positions after it to the smallest values that follow).
   function Pivot (It : Iterator) return Natural
     with Global => null, Pre => Choose (It) <= Item_Count (It),
          Post => Pivot'Result <= Choose (It)
                  and then (Pivot'Result = 0) = Is_Last (It)
                  and then (for all M in Pivot'Result + 1 .. Choose (It) =>
                              Pos (It, M) = Item_Count (It) - Choose (It) + M)
                  and then (if Pivot'Result > 0 then
                              Pos (It, Pivot'Result) < Item_Count (It) - Choose (It) + Pivot'Result);

   --  The K-element combinations of Items (1 .. Item_Count), in
   --  lexicographic order of positions, starting with 1, 2, ..., K.
   function Create (Items : Value_Array; Item_Count : Count; Choose : Choose_Count) return Iterator
     with Global => null, Pre => Choose <= Item_Count,
          Post => Combination_Iterator_Stub.Item_Count (Create'Result) = Item_Count
                  and then Combination_Iterator_Stub.Choose (Create'Result) = Choose
                  and then not Done (Create'Result)
                  and then (for all J in 1 .. Choose => Pos (Create'Result, J) = J)
                  and then (for all I in Index => Item (Create'Result, I) = Items (I));
   function Has_Next (It : Iterator) return Boolean
     with Global => null, Post => Has_Next'Result = not Done (It);
   --  R holds the items at Pos (It'Old, 1 .. Choose); the iterator moves to
   --  the next combination in lexicographic order of positions (positions
   --  before the pivot unchanged, the pivot one higher, the positions after
   --  it consecutive), or is Done after the last one.
   procedure Next (It : in out Iterator; R : out Combination)
     with Global => null, Pre => Has_Next (It),
          Post => R.Size = Choose (It'Old)
                  and then (for all J in 1 .. Choose (It'Old) =>
                              R.Values (J) = Item (It'Old, Pos (It'Old, J)))
                  and then Done (It) = Is_Last (It'Old)
                  and then (if not Is_Last (It'Old) then
                              (for all M in 1 .. Pivot (It'Old) - 1 => Pos (It, M) = Pos (It'Old, M))
                              and then Pos (It, Pivot (It'Old)) = Pos (It'Old, Pivot (It'Old)) + 1
                              and then (for all M in Pivot (It'Old) + 1 .. Choose (It'Old) =>
                                          Pos (It, M) = Pos (It, Pivot (It'Old)) + (M - Pivot (It'Old))))
                  and then Item_Count (It) = Item_Count (It'Old)
                  and then Choose (It) = Choose (It'Old)
                  and then (for all I in Index => Item (It, I) = Item (It'Old, I));
private
   type Position_Array is array (Index) of Index;
   type Iterator is record
      Items      : Value_Array := [others => 0];
      Item_Count : Count := 1;
      Choose     : Choose_Count := 1;
      Pos        : Position_Array := [others => 1];
      Done       : Boolean := False;
   end record
     with Type_Invariant =>
       Choose <= Item_Count
       and then (for all J in 1 .. Choose =>
                   Pos (J) in J .. Item_Count - Choose + J)
       and then (for all J in 1 .. Choose - 1 => Pos (J) < Pos (J + 1));
   function Item_Count (It : Iterator) return Count is (It.Item_Count);
   function Choose (It : Iterator) return Choose_Count is (It.Choose);
   function Item (It : Iterator; I : Index) return Value is (It.Items (I));
   function Pos (It : Iterator; J : Index) return Index is (It.Pos (J));
   function Done (It : Iterator) return Boolean is (It.Done);
end Combination_Iterator_Stub;
