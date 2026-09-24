--  Dice_Coefficient body — unique character-bigram sets and Dice similarity.

pragma Ada_2022;

package body Dice_Coefficient is

   subtype Bigram is String (1 .. 2);

   --  Unbounded educational buffer for unique bigrams (≤ Max_Len − 1).
   type Bigram_Array is array (Positive range <>) of Bigram;

   procedure Check_Len (S : String) is
   begin
      if S'Length > Max_Len then
         raise Invalid_Argument;
      end if;
   end Check_Len;

   --  Contiguous length-2 window of S starting at 1-based logical position P
   --  (P = 1 .. S'Length − 1). Works for any S'First.
   function Window (S : String; P : Positive) return Bigram is
      F : constant Positive := S'First + (P - 1);
   begin
      return S (F .. F + 1);
   end Window;

   --  Build the unique bigram set of S into Buf (1 .. Count).
   --  Linear membership scan — clear for teaching; O(u · n) with u ≤ n−1.
   procedure Collect_Unique
     (S     : String;
      Buf   : out Bigram_Array;
      Count : out Natural)
   is
      Occ : constant Natural :=
        (if S'Length < 2 then 0 else S'Length - 1);
      --  Fully initialize out-array so -gnatwa is happy before partial fills.
      Local : Bigram_Array (Buf'Range) := [others => "  "];
   begin
      Count := 0;
      for P in 1 .. Occ loop
         declare
            T     : constant Bigram := Window (S, P);
            Found : Boolean := False;
         begin
            for J in 1 .. Count loop
               if Local (J) = T then
                  Found := True;
                  exit;
               end if;
            end loop;
            if not Found then
               Count := Count + 1;
               Local (Count) := T;
            end if;
         end;
      end loop;
      Buf := Local;
   end Collect_Unique;

   function Member (Set : Bigram_Array; T : Bigram) return Boolean is
   begin
      for J in Set'Range loop
         if Set (J) = T then
            return True;
         end if;
      end loop;
      return False;
   end Member;

   function Intersection_Size (A, B : Bigram_Array) return Natural is
      N : Natural := 0;
   begin
      for I in A'Range loop
         if Member (B, A (I)) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Intersection_Size;

   function Bigram_Count (S : String) return Natural is
   begin
      Check_Len (S);
      if S'Length < 2 then
         return 0;
      end if;
      return S'Length - 1;
   end Bigram_Count;

   function Unique_Bigram_Count (S : String) return Natural is
      Occ : constant Natural := Bigram_Count (S);
      Buf : Bigram_Array (1 .. Natural'Max (1, Occ));
      N   : Natural;
   begin
      if Occ = 0 then
         return 0;
      end if;
      Collect_Unique (S, Buf, N);
      return N;
   end Unique_Bigram_Count;

   function Shared_Bigrams (A, B : String) return Natural is
      Occ_A : constant Natural := Bigram_Count (A);
      Occ_B : constant Natural := Bigram_Count (B);
      Buf_A : Bigram_Array (1 .. Natural'Max (1, Occ_A));
      Buf_B : Bigram_Array (1 .. Natural'Max (1, Occ_B));
      NA, NB : Natural;
   begin
      if Occ_A = 0 or else Occ_B = 0 then
         return 0;
      end if;
      Collect_Unique (A, Buf_A, NA);
      Collect_Unique (B, Buf_B, NB);
      return Intersection_Size (Buf_A (1 .. NA), Buf_B (1 .. NB));
   end Shared_Bigrams;

   function Coefficient (A, B : String) return Float is
      Buf_A : Bigram_Array (1 .. Natural'Max (1, A'Length));
      Buf_B : Bigram_Array (1 .. Natural'Max (1, B'Length));
      NA, NB, Inter : Natural;
      Denom : Float;
   begin
      Check_Len (A);
      Check_Len (B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;

      if A'Length = 0 or else B'Length = 0 then
         return 0.0;
      end if;

      Collect_Unique (A, Buf_A, NA);
      Collect_Unique (B, Buf_B, NB);
      Inter := Intersection_Size (Buf_A (1 .. NA), Buf_B (1 .. NB));
      Denom := Float (NA + NB);

      if Denom <= 0.0 then
         return 0.0;
      end if;

      return 2.0 * Float (Inter) / Denom;
   end Coefficient;

end Dice_Coefficient;
