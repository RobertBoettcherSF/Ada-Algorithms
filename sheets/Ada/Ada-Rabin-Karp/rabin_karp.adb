--  Rabin_Karp body — polynomial rolling hash + exact verification.
--  Recurrence (Wikipedia / CLRS style):
--    H_new = ((H_old − T[i] · B^(m−1)) · B + T[i+m]) mod Q
--  Character equality is always checked on hash hits.

pragma Ada_2022;

package body Rabin_Karp is

   subtype Hash_Int is Long_Long_Integer;

   function Ord (C : Character) return Hash_Int is
   begin
      return Hash_Int (Character'Pos (C));
   end Ord;

   procedure Check_Bounds (Pattern, Text : String) is
   begin
      if Pattern'Length = 0 then
         raise Invalid_Argument with "empty pattern";
      end if;
      if Pattern'Length > Max_Pattern_Length then
         raise Invalid_Argument with "pattern too long";
      end if;
      if Text'Length > Max_Text_Length then
         raise Invalid_Argument with "text too long";
      end if;
   end Check_Bounds;

   procedure Check_Hash_Params (Modulus : Positive) is
   begin
      if Modulus < 2 then
         raise Invalid_Argument with "modulus must be >= 2";
      end if;
   end Check_Hash_Params;

   ---------------------------------------------------------------------------
   -- Naive oracle
   ---------------------------------------------------------------------------

   function Naive_Search (Pattern, Text : String) return Match_Index_Array is
      M : constant Natural := Pattern'Length;
      N : constant Natural := Text'Length;
   begin
      Check_Bounds (Pattern, Text);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         PF       : constant Positive := Pattern'First;
         TF       : constant Positive := Text'First;
         Ok       : Boolean;
      begin
         for Start in 0 .. N - M loop
            Ok := True;
            for K in 0 .. M - 1 loop
               if Pattern (PF + K) /= Text (TF + Start + K) then
                  Ok := False;
                  exit;
               end if;
            end loop;
            if Ok then
               Count := Count + 1;
               Buf (Count) := Start + 1;
            end if;
         end loop;
         return Buf (1 .. Count);
      end;
   end Naive_Search;

   ---------------------------------------------------------------------------
   -- Rolling-hash helpers
   ---------------------------------------------------------------------------

   function Window_Hash
     (S      : String;
      First  : Positive;
      Length : Positive;
      Base   : Hash_Int;
      Q      : Hash_Int) return Hash_Int
   is
      H : Hash_Int := 0;
   begin
      for K in 0 .. Length - 1 loop
         H := (H * Base + Ord (S (First + K))) mod Q;
      end loop;
      return H;
   end Window_Hash;

   function Exact_Match
     (Pattern : String;
      Text    : String;
      Start   : Natural) return Boolean
   is
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
      M  : constant Natural  := Pattern'Length;
   begin
      for K in 0 .. M - 1 loop
         if Pattern (PF + K) /= Text (TF + Start + K) then
            return False;
         end if;
      end loop;
      return True;
   end Exact_Match;

   ---------------------------------------------------------------------------
   -- Rabin–Karp search
   ---------------------------------------------------------------------------

   function Search
     (Pattern, Text : String;
      Base          : Positive := Default_Base;
      Modulus       : Positive := Default_Modulus)
      return Match_Index_Array
   is
      M  : constant Natural := Pattern'Length;
      N  : constant Natural := Text'Length;
      PF : constant Positive := Pattern'First;
      TF : constant Positive := Text'First;
   begin
      Check_Bounds (Pattern, Text);
      Check_Hash_Params (Modulus);

      if M > N then
         declare
            Empty : Match_Index_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      declare
         Q        : constant Hash_Int := Hash_Int (Modulus);
         B        : constant Hash_Int := Hash_Int (Base) mod Q;
         High_Pow : Hash_Int := 1;
         --  B^(m-1) mod Q — weight of the character leaving the window
         Pat_Hash : Hash_Int;
         Win_Hash : Hash_Int;
         Max_Hits : constant Natural := N - M + 1;
         Buf      : Match_Index_Array (1 .. Max_Hits);
         Count    : Natural := 0;
         Lead     : Hash_Int;
      begin
         for I in 1 .. M - 1 loop
            High_Pow := (High_Pow * B) mod Q;
         end loop;

         Pat_Hash := Window_Hash (Pattern, PF, M, B, Q);
         Win_Hash := Window_Hash (Text, TF, M, B, Q);

         --  First window
         if Win_Hash = Pat_Hash and then Exact_Match (Pattern, Text, 0) then
            Count := Count + 1;
            Buf (Count) := 1;
         end if;

         --  Slide: remove leading char, multiply by base, add trailing char
         for Start in 0 .. N - M - 1 loop
            Lead := (Ord (Text (TF + Start)) * High_Pow) mod Q;
            Win_Hash := (Win_Hash - Lead) mod Q;
            Win_Hash :=
              (Win_Hash * B + Ord (Text (TF + Start + M))) mod Q;

            if Win_Hash = Pat_Hash
              and then Exact_Match (Pattern, Text, Start + 1)
            then
               Count := Count + 1;
               Buf (Count) := Start + 2;
            end if;
         end loop;

         return Buf (1 .. Count);
      end;
   end Search;

end Rabin_Karp;
