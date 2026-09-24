--  Trigram_Search body — unique character-trigram sets and Dice similarity.

pragma Ada_2022;

package body Trigram_Search is

   subtype Trigram is String (1 .. 3);

   --  Unbounded educational buffer for unique trigrams (≤ Max_Len − 2).
   type Trigram_Array is array (Positive range <>) of Trigram;

   procedure Check_Len (S : String) is
   begin
      if S'Length > Max_Len then
         raise Invalid_Argument;
      end if;
   end Check_Len;

   --  Contiguous length-3 window of S starting at 1-based logical position P
   --  (P = 1 .. S'Length − 2). Works for any S'First.
   function Window (S : String; P : Positive) return Trigram is
      F : constant Positive := S'First + (P - 1);
   begin
      return S (F .. F + 2);
   end Window;

   --  Build the unique trigram set of S into Buf (1 .. Count).
   --  Linear membership scan — clear for teaching; O(u · n) with u ≤ n−2.
   procedure Collect_Unique
     (S     : String;
      Buf   : out Trigram_Array;
      Count : out Natural)
   is
      Occ : constant Natural :=
        (if S'Length < 3 then 0 else S'Length - 2);
      --  Fully initialize out-array so -gnatwa is happy before partial fills.
      Local : Trigram_Array (Buf'Range) := [others => "   "];
   begin
      Count := 0;
      for P in 1 .. Occ loop
         declare
            T     : constant Trigram := Window (S, P);
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

   function Member (Set : Trigram_Array; T : Trigram) return Boolean is
   begin
      for J in Set'Range loop
         if Set (J) = T then
            return True;
         end if;
      end loop;
      return False;
   end Member;

   function Intersection_Size (A, B : Trigram_Array) return Natural is
      N : Natural := 0;
   begin
      for I in A'Range loop
         if Member (B, A (I)) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Intersection_Size;

   function Trigram_Count (S : String) return Natural is
   begin
      Check_Len (S);
      if S'Length < 3 then
         return 0;
      end if;
      return S'Length - 2;
   end Trigram_Count;

   function Unique_Trigram_Count (S : String) return Natural is
      Occ : constant Natural := Trigram_Count (S);
      Buf : Trigram_Array (1 .. Natural'Max (1, Occ));
      N   : Natural;
   begin
      if Occ = 0 then
         return 0;
      end if;
      Collect_Unique (S, Buf, N);
      return N;
   end Unique_Trigram_Count;

   function Shared_Trigrams (A, B : String) return Natural is
      Occ_A : constant Natural := Trigram_Count (A);
      Occ_B : constant Natural := Trigram_Count (B);
      Buf_A : Trigram_Array (1 .. Natural'Max (1, Occ_A));
      Buf_B : Trigram_Array (1 .. Natural'Max (1, Occ_B));
      NA, NB : Natural;
   begin
      if Occ_A = 0 or else Occ_B = 0 then
         return 0;
      end if;
      Collect_Unique (A, Buf_A, NA);
      Collect_Unique (B, Buf_B, NB);
      return Intersection_Size (Buf_A (1 .. NA), Buf_B (1 .. NB));
   end Shared_Trigrams;

   function Dice_Coefficient (A, B : String) return Float is
      Buf_A : Trigram_Array (1 .. Natural'Max (1, A'Length));
      Buf_B : Trigram_Array (1 .. Natural'Max (1, B'Length));
      NA, NB, Inter : Natural;
      Denom : Float;
   begin
      Check_Len (A);
      Check_Len (B);

      if A'Length = 0 and then B'Length = 0 then
         return 1.0;
      end if;

      if A'Length < 3 or else B'Length < 3 then
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
   end Dice_Coefficient;

   function Contains_Trigram (Haystack, Needle : String) return Boolean is
      Occ_H : constant Natural := Trigram_Count (Haystack);
      Occ_N : constant Natural := Trigram_Count (Needle);
      Buf_H : Trigram_Array (1 .. Natural'Max (1, Occ_H));
      Buf_N : Trigram_Array (1 .. Natural'Max (1, Occ_N));
      NH, NN : Natural;
   begin
      if Occ_N = 0 then
         return True;
      end if;
      if Occ_H = 0 then
         return False;
      end if;
      Collect_Unique (Haystack, Buf_H, NH);
      Collect_Unique (Needle, Buf_N, NN);
      for I in 1 .. NN loop
         if not Member (Buf_H (1 .. NH), Buf_N (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Contains_Trigram;

   function Has_Trigram (Haystack : String; Tri : String) return Boolean is
      Occ : Natural;
   begin
      Check_Len (Haystack);
      if Tri'Length /= 3 then
         raise Invalid_Argument;
      end if;
      Occ := (if Haystack'Length < 3 then 0 else Haystack'Length - 2);
      for P in 1 .. Occ loop
         if Window (Haystack, P) = Tri then
            return True;
         end if;
      end loop;
      return False;
   end Has_Trigram;

end Trigram_Search;
