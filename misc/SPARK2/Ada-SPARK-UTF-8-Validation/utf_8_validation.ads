pragma Ada_2022;
package UTF_8_Validation with SPARK_Mode => On is
   subtype Byte is Natural range 0 .. 255;
   Max_Length : constant := 1_000_000;
   subtype Index is Positive range 1 .. Max_Length;
   type Byte_Array is array (Index range <>) of Byte;

   --  Length of the sequence a lead byte starts (RFC 3629): 1 for ASCII,
   --  2 for C2..DF, 3 for E0..EF, 4 for F0..F4; 0 for a continuation byte
   --  (80..BF) and for bytes that never occur (C0, C1, F5..FF).
   subtype Seq_Length is Natural range 0 .. 4;
   function Seq_Len (B : Byte) return Seq_Length is
     (case B is
         when 16#00# .. 16#7F# => 1,
         when 16#C2# .. 16#DF# => 2,
         when 16#E0# .. 16#EF# => 3,
         when 16#F0# .. 16#F4# => 4,
         when others           => 0);

   function Is_Cont (B : Byte) return Boolean is (B in 16#80# .. 16#BF#);

   --  Allowed second byte after a multi-byte lead; the narrowed ranges
   --  exclude overlong forms (E0, F0), surrogates (ED) and code points
   --  above 16#10FFFF# (F4).
   function Second_Ok (Lead, B : Byte) return Boolean is
     (case Lead is
         when 16#E0# => B in 16#A0# .. 16#BF#,
         when 16#ED# => B in 16#80# .. 16#9F#,
         when 16#F0# => B in 16#90# .. 16#BF#,
         when 16#F4# => B in 16#80# .. 16#8F#,
         when others => Is_Cont (B));

   --  A (I) starts a complete, well-formed sequence.
   function Lead_Ok (A : Byte_Array; I : Index) return Boolean is
     (Seq_Len (A (I)) >= 1
      and then Seq_Len (A (I)) - 1 <= A'Last - I
      and then (if Seq_Len (A (I)) >= 2 then Second_Ok (A (I), A (I + 1)))
      and then (if Seq_Len (A (I)) >= 3 then Is_Cont (A (I + 2)))
      and then (if Seq_Len (A (I)) = 4 then Is_Cont (A (I + 3))))
     with Ghost, Pre => I in A'Range;

   --  Continuation byte A (J) lies inside the sequence of a lead 1 to 3
   --  bytes before it.
   function Covered (A : Byte_Array; J : Index) return Boolean is
     ((J - 1 >= A'First and then Seq_Len (A (J - 1)) > 1)
      or else (J - 2 >= A'First and then Seq_Len (A (J - 2)) > 2)
      or else (J - 3 >= A'First and then Seq_Len (A (J - 3)) > 3))
     with Ghost, Pre => J in A'Range;

   --  A is well-formed UTF-8: every byte either starts a well-formed
   --  sequence or is a continuation byte inside one.
   function Is_Valid (A : Byte_Array) return Boolean
     with Global => null,
          Post   => Is_Valid'Result =
                      (for all J in A'Range =>
                         (if Is_Cont (A (J)) then Covered (A, J) else Lead_Ok (A, J)));
end UTF_8_Validation;
