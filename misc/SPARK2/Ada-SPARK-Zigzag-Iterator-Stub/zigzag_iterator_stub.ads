pragma SPARK_Mode (On);
pragma Ada_2022;
package Zigzag_Iterator_Stub is
   Capacity : constant := 1_000;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Iterator is private;

   --  Model: lists A (1 .. A_Size) and B (1 .. B_Size); A_Taken / B_Taken
   --  values of each have been returned.
   function A_Size (It : Iterator) return Count with Global => null;
   function B_Size (It : Iterator) return Count with Global => null;
   function A_Taken (It : Iterator) return Count with Global => null;
   function B_Taken (It : Iterator) return Count with Global => null;
   function A_Elem (It : Iterator; I : Index) return Value with Global => null;
   function B_Elem (It : Iterator; I : Index) return Value with Global => null;

   --  Zigzag order: A (1), B (1), A (2), B (2), ...; once one list is used
   --  up, the rest of the other. The next value comes from A exactly when A
   --  has one left and B is used up or has given as many values as A.
   function Next_From_A (It : Iterator) return Boolean is
     (A_Taken (It) < A_Size (It)
      and then (B_Taken (It) = B_Size (It) or else A_Taken (It) <= B_Taken (It)))
     with Global => null;

   function Create (A : Value_Array; A_Size : Count; B : Value_Array; B_Size : Count) return Iterator
     with Global => null,
          Post   => Zigzag_Iterator_Stub.A_Size (Create'Result) = A_Size
                    and then Zigzag_Iterator_Stub.B_Size (Create'Result) = B_Size
                    and then A_Taken (Create'Result) = 0 and then B_Taken (Create'Result) = 0
                    and then (for all I in Index => A_Elem (Create'Result, I) = A (I))
                    and then (for all I in Index => B_Elem (Create'Result, I) = B (I));
   function Has_Next (It : Iterator) return Boolean
     with Global => null,
          Post   => Has_Next'Result = (A_Taken (It) < A_Size (It) or else B_Taken (It) < B_Size (It));
   procedure Next (It : in out Iterator; Result : out Value)
     with Global => null, Pre => Has_Next (It),
          Post   => (if Next_From_A (It'Old)
                     then Result = A_Elem (It'Old, A_Taken (It'Old) + 1)
                          and then A_Taken (It) = A_Taken (It'Old) + 1
                          and then B_Taken (It) = B_Taken (It'Old)
                     else Result = B_Elem (It'Old, B_Taken (It'Old) + 1)
                          and then B_Taken (It) = B_Taken (It'Old) + 1
                          and then A_Taken (It) = A_Taken (It'Old))
                    and then A_Size (It) = A_Size (It'Old) and then B_Size (It) = B_Size (It'Old)
                    and then (for all I in Index => A_Elem (It, I) = A_Elem (It'Old, I))
                    and then (for all I in Index => B_Elem (It, I) = B_Elem (It'Old, I));
private
   type Iterator is record
      A, B             : Value_Array := [others => 0];
      A_Size, B_Size   : Count := 0;
      A_Taken, B_Taken : Count := 0;
   end record
     with Type_Invariant => A_Taken <= A_Size and then B_Taken <= B_Size;
   function A_Size (It : Iterator) return Count is (It.A_Size);
   function B_Size (It : Iterator) return Count is (It.B_Size);
   function A_Taken (It : Iterator) return Count is (It.A_Taken);
   function B_Taken (It : Iterator) return Count is (It.B_Taken);
   function A_Elem (It : Iterator; I : Index) return Value is (It.A (I));
   function B_Elem (It : Iterator; I : Index) return Value is (It.B (I));
end Zigzag_Iterator_Stub;
