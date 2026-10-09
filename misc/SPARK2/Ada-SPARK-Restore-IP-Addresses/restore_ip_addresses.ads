pragma Ada_2022;

package Restore_IP_Addresses with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 12;
   subtype Start_Index is Positive range 1 .. 10;
   subtype Segment_Length is Positive range 1 .. 3;
   subtype Digit is Natural range 0 .. 9;
   type Digit_Sequence is array (Index) of Digit;
   function Valid_Segment
     (D : Digit_Sequence; Start : Start_Index; Length : Segment_Length)
      return Boolean with Global => null;
   function Count_Valid_Segments (D : Digit_Sequence) return Natural with Global => null;

   --  Restore IP addresses: every way to cut the digit string D (1 .. Len)
   --  into 4 parts, each 0 .. 255 without a leading zero. An address is
   --  given by its 4 part lengths (the dots go after A (1), A (1) + A (2),
   --  A (1) + A (2) + A (3)). The last length is fixed by the other three,
   --  so there are at most 3 ** 3 = 27 addresses (the Post's completeness
   --  clause ranges over the 27 choices of the first three lengths).
   Max_Len : constant := 20;
   Max_Addresses : constant := 27;
   subtype String_Length is Natural range 0 .. Max_Len;
   subtype String_Index is Positive range 1 .. Max_Len;
   subtype Address_Count is Natural range 0 .. Max_Addresses;
   type Digit_String is array (String_Index) of Digit;
   type Address is array (1 .. 4) of Segment_Length;
   type Address_List is array (1 .. Max_Addresses) of Address;

   function Part_Value (D : Digit_String; From : String_Index; L : Segment_Length) return Natural is
     (case L is
         when 1 => D (From),
         when 2 => D (From) * 10 + D (From + 1),
         when 3 => (D (From) * 10 + D (From + 1)) * 10 + D (From + 2))
     with Pre => From + L - 1 <= Max_Len;

   --  D (From .. From + L - 1) is one part of an address.
   function Part_Ok (D : Digit_String; From : String_Index; L : Segment_Length) return Boolean is
     (From + L - 1 <= Max_Len
      and then (L = 1 or else D (From) /= 0)
      and then Part_Value (D, From, L) <= 255);

   function Valid (D : Digit_String; Len : String_Length; L1, L2, L3, L4 : Segment_Length) return Boolean is
     (L1 + L2 + L3 + L4 = Len
      and then Part_Ok (D, 1, L1)
      and then Part_Ok (D, 1 + L1, L2)
      and then Part_Ok (D, 1 + L1 + L2, L3)
      and then Part_Ok (D, 1 + L1 + L2 + L3, L4));

   function Valid (D : Digit_String; Len : String_Length; A : Address) return Boolean is
     (Valid (D, Len, A (1), A (2), A (3), A (4)));

   --  The first three lengths L1, L2, L3 (and the rest of the string as the
   --  fourth part) make a valid address.
   function Splits (D : Digit_String; Len : String_Length; L1, L2, L3 : Segment_Length) return Boolean is
     (Len - L1 - L2 - L3 in Segment_Length
      and then Valid (D, Len, L1, L2, L3, Len - L1 - L2 - L3));

   --  (M1, M2, M3) comes before (X1, X2, X3) lexicographically.
   function Before (M1, M2, M3, X1, X2, X3 : Positive) return Boolean is
     (M1 < X1 or else (M1 = X1 and then (M2 < X2 or else (M2 = X2 and then M3 < X3))));

   function Less (A, B : Address) return Boolean is
     (Before (A (1), A (2), A (3), B (1), B (2), B (3))
      or else (A (1) = B (1) and then A (2) = B (2) and then A (3) = B (3) and then A (4) < B (4)));

   --  A has the part lengths L1, L2, L3, L4.
   function Has_Lengths (A : Address; L1, L2, L3, L4 : Segment_Length) return Boolean is
     (A (1) = L1 and then A (2) = L2 and then A (3) = L3 and then A (4) = L4);

   --  The 27 choices C = 0 .. 26 of the first three part lengths, in
   --  lexicographic order: C = 9 (L1 - 1) + 3 (L2 - 1) + (L3 - 1), so
   --  every triple of lengths in 1 .. 3 is exactly one C.
   subtype Choice is Natural range 0 .. 26;
   type Length_Table is array (Choice) of Segment_Length;
   First_Of  : constant Length_Table := [for C in Choice => 1 + C / 9];
   Second_Of : constant Length_Table := [for C in Choice => 1 + (C / 3) mod 3];
   Third_Of  : constant Length_Table := [for C in Choice => 1 + C mod 3];

   --  Index of the first address in List (1 .. Count) with these lengths,
   --  0 when there is none (proof only: names the witness in the Post).
   function Position (List : Address_List; Count : Address_Count; L1, L2, L3, L4 : Segment_Length)
     return Address_Count
     with Ghost,
          Post => (if Position'Result = 0 then
                     (for all K in 1 .. Count => not Has_Lengths (List (K), L1, L2, L3, L4))
                   else Position'Result <= Count
                        and then Has_Lengths (List (Position'Result), L1, L2, L3, L4));

   procedure Restore
     (D : Digit_String; Len : String_Length; List : out Address_List; Count : out Address_Count)
     with Global => null,
          Post   => (for all K in 1 .. Count => Valid (D, Len, List (K)))
                    and then (for all K in 1 .. Count - 1 => Less (List (K), List (K + 1)))
                    and then (for all C in Choice =>
                                (if Splits (D, Len, First_Of (C), Second_Of (C), Third_Of (C)) then
                                   Position (List, Count, First_Of (C), Second_Of (C), Third_Of (C),
                                             Len - First_Of (C) - Second_Of (C) - Third_Of (C)) /= 0));
end Restore_IP_Addresses;
